package com.eds.catalog.service;

import com.eds.catalog.model.CacheInvalidationEvent;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.TimeUnit;

@Service
@ConditionalOnProperty(name = "spring.cache.type", havingValue = "redis")
public class CacheInvalidationConsumer {
    @Autowired(required = false)
    private RedisTemplate<String, Object> redisTemplate;
    private final Counter invalidationsReceived;
    private final Timer inconsistencyWindowTimer;
    
    @Value("${cache.mode:ttl_invalidate}")
    private String cacheMode;

    public CacheInvalidationConsumer(MeterRegistry meterRegistry) {
        this.invalidationsReceived = Counter.builder("invalidations_received").register(meterRegistry);
        this.inconsistencyWindowTimer = Timer.builder("inconsistency_window").register(meterRegistry);
    }

    @KafkaListener(topics = "cache.invalidate", groupId = "cache-evictors")
    public void handleCacheInvalidation(CacheInvalidationEvent event) {
        if (!"ttl_invalidate".equals(cacheMode)) {
            return;
        }

        invalidationsReceived.increment();
        
        // Delete keys from Redis
        // Note: Spring Cache uses "cacheName::key" format in Redis
        // The event contains just the productId, we need to add the cache prefix
        if (redisTemplate != null) {
            for (String productId : event.getKeys()) {
                // Delete the actual Redis key (Spring Cache format: productById::1)
                redisTemplate.delete("productById::" + productId);
            }
        }

        // Calculate inconsistency window (time from event creation to processing)
        if (event.getTs() != null) {
            long inconsistencyWindowMs = Duration.between(event.getTs(), Instant.now()).toMillis();
            inconsistencyWindowTimer.record(inconsistencyWindowMs, TimeUnit.MILLISECONDS);
            System.out.println("Inconsistency window: " + inconsistencyWindowMs + "ms");
        }
    }
}

