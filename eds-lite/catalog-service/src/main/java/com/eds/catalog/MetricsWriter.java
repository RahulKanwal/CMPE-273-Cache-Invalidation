package com.eds.catalog;

import io.micrometer.core.instrument.MeterRegistry;
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
        System.out.println("MetricsWriter: Initializing...");
        Files.createDirectories(Paths.get("/tmp/metrics"));
        writer = new BufferedWriter(new FileWriter("/tmp/metrics/catalog.jsonl", true));
        System.out.println("MetricsWriter: Created writer for /tmp/metrics/catalog.jsonl");
        
        scheduler.scheduleAtFixedRate(this::writeMetrics, 5, 5, TimeUnit.SECONDS);
        System.out.println("MetricsWriter: Scheduled metrics writing every 5 seconds");
    }

    private void writeMetrics() {
        try {
            // Ensure directory exists and writer is valid
            Files.createDirectories(Paths.get("/tmp/metrics"));
            
            // Check if file exists, if not recreate writer
            if (writer == null || !Files.exists(Paths.get("/tmp/metrics/catalog.jsonl"))) {
                if (writer != null) {
                    try {
                        writer.close();
                    } catch (IOException e) {
                        // Ignore close errors
                    }
                }
                writer = new BufferedWriter(new FileWriter("/tmp/metrics/catalog.jsonl", true));
                System.out.println("MetricsWriter: (Re)created writer for /tmp/metrics/catalog.jsonl");
            }
            
            String timestamp = Instant.now().toString();
            int meterCount = 0;
            int measurementCount = 0;
            
            for (var meter : meterRegistry.getMeters()) {
                meterCount++;
                for (var measurement : meter.measure()) {
                    measurementCount++;
                    String json = String.format(
                        "{\"timestamp\":\"%s\",\"service\":\"catalog\",\"metric\":\"%s\",\"tags\":%s,\"value\":%f}\n",
                        timestamp,
                        meter.getId().getName(),
                        meter.getId().getTags().toString(),
                        measurement.getValue()
                    );
                    
                    try {
                        writer.write(json);
                    } catch (IOException e) {
                        System.err.println("MetricsWriter: Error writing metric: " + e.getMessage());
                        // Try to recreate writer on IO error
                        try {
                            writer.close();
                            writer = new BufferedWriter(new FileWriter("/tmp/metrics/catalog.jsonl", true));
                            writer.write(json);
                        } catch (IOException e2) {
                            System.err.println("MetricsWriter: Failed to recreate writer: " + e2.getMessage());
                        }
                    }
                }
            }
            writer.flush();
            System.out.println("MetricsWriter: Wrote " + measurementCount + " measurements from " + meterCount + " meters");
        } catch (Exception e) {
            System.err.println("MetricsWriter: Error in writeMetrics: " + e.getMessage());
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

