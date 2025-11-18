package com.eds.catalog.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.CacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.StringRedisSerializer;
import org.springframework.data.redis.serializer.JdkSerializationRedisSerializer;

import java.time.Duration;

@Configuration
public class CacheConfig {
    
    @Value("${cache.mode:ttl_invalidate}")
    private String cacheMode;

    @Bean
    public CacheManager cacheManager(RedisConnectionFactory connectionFactory) {
        if ("none".equals(cacheMode)) {
            return new org.springframework.cache.support.NoOpCacheManager();
        }

        // Use JDK serialization for reliability with complex objects
        // This handles Instant, BigDecimal, and MongoDB annotations properly
        RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig()
                .entryTtl(Duration.ofMinutes(5))
                .serializeKeysWith(RedisSerializationContext.SerializationPair.fromSerializer(new StringRedisSerializer()))
                .serializeValuesWith(RedisSerializationContext.SerializationPair.fromSerializer(new JdkSerializationRedisSerializer()))
                .disableCachingNullValues();

        return RedisCacheManager.builder(connectionFactory)
                .cacheDefaults(config)
                .build();
    }
}

