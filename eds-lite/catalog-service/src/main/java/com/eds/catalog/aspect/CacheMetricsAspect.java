package com.eds.catalog.aspect;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.stereotype.Component;

@Aspect
@Component
public class CacheMetricsAspect {
    private final Counter cacheHits;
    private final Counter cacheMisses;
    private final CacheManager cacheManager;

    public CacheMetricsAspect(MeterRegistry meterRegistry,
                             CacheManager cacheManager) {
        this.cacheHits = Counter.builder("cache_hits").register(meterRegistry);
        this.cacheMisses = Counter.builder("cache_misses").register(meterRegistry);
        this.cacheManager = cacheManager;
    }

    @Around("execution(* com.eds.catalog.service.ProductService.getProduct(..))")
    public Object trackCacheMetrics(ProceedingJoinPoint joinPoint) throws Throwable {
        // Get the cache and key
        String cacheName = "productById";
        String key = joinPoint.getArgs()[0].toString();
        
        Cache cache = cacheManager.getCache(cacheName);
        boolean wasInCache = false;
        
        if (cache != null) {
            Cache.ValueWrapper valueWrapper = cache.get(key);
            wasInCache = (valueWrapper != null);
        }
        
        // Proceed with the method call (Spring Cache will handle caching)
        Object result = joinPoint.proceed();
        
        // Record metrics: if it was in cache before the call, it's a hit
        // If it wasn't in cache, it's a miss (and Spring Cache will have cached it now)
        if (wasInCache) {
            cacheHits.increment();
        } else {
            cacheMisses.increment();
        }
        
        return result;
    }
}

