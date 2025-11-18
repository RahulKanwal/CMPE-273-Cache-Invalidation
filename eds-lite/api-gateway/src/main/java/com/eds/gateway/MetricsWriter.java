package com.eds.gateway;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.springframework.stereotype.Component;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.Instant;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

@Component
public class MetricsWriter {
    private final MeterRegistry meterRegistry;
    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);
    private BufferedWriter writer;

    public MetricsWriter(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
    }

    @PostConstruct
    public void init() throws IOException {
        Files.createDirectories(Paths.get("/tmp/metrics"));
        writer = new BufferedWriter(new FileWriter("/tmp/metrics/gateway.jsonl", true));
        
        scheduler.scheduleAtFixedRate(this::writeMetrics, 5, 5, TimeUnit.SECONDS);
    }

    private void writeMetrics() {
        try {
            String timestamp = Instant.now().toString();
            
            meterRegistry.getMeters().forEach(meter -> {
                meter.measure().forEach(measurement -> {
                    try {
                        String json = String.format(
                            "{\"timestamp\":\"%s\",\"service\":\"gateway\",\"metric\":\"%s\",\"tags\":%s,\"value\":%f}\n",
                            timestamp,
                            meter.getId().getName(),
                            meter.getId().getTags().toString(),
                            measurement.getValue()
                        );
                        writer.write(json);
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                });
            });
            writer.flush();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @PreDestroy
    public void cleanup() throws IOException {
        scheduler.shutdown();
        if (writer != null) {
            writer.close();
        }
    }
}

