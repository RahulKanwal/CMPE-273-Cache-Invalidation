package com.eds.catalog.service;

import com.eds.catalog.model.CacheInvalidationEvent;
import com.eds.catalog.model.Product;
import com.eds.catalog.model.ProductUpdateRequest;
import com.eds.catalog.repository.ProductRepository;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
public class ProductService {
    private final ProductRepository productRepository;
    private final KafkaTemplate<String, CacheInvalidationEvent> kafkaTemplate;
    private final Counter invalidationsSent;
    private final Counter staleReadsDetected;
    private final Counter cacheHits;
    private final Counter cacheMisses;
    private final Timer getProductTimer;
    private final CacheManager cacheManager;
    
    @Value("${cache.mode:ttl_invalidate}")
    private String cacheMode;

    public ProductService(ProductRepository productRepository,
                         KafkaTemplate<String, CacheInvalidationEvent> kafkaTemplate,
                         MeterRegistry meterRegistry,
                         CacheManager cacheManager) {
        this.productRepository = productRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.cacheManager = cacheManager;
        this.invalidationsSent = Counter.builder("invalidations_sent").register(meterRegistry);
        this.staleReadsDetected = Counter.builder("stale_reads_detected").register(meterRegistry);
        this.cacheHits = Counter.builder("cache_hits").register(meterRegistry);
        this.cacheMisses = Counter.builder("cache_misses").register(meterRegistry);
        this.getProductTimer = Timer.builder("get_product_latency").register(meterRegistry);
    }

    @Cacheable(value = "productById", key = "#id", unless = "#result == null")
    public Product getProduct(String id) {
        try {
            return getProductTimer.recordCallable(() -> {
                // Cache hit/miss tracking is done by CacheMetricsAspect
                return productRepository.findById(id).orElse(null);
            });
        } catch (Exception e) {
            throw new RuntimeException("Error getting product: " + id, e);
        }
    }

    public Product getProductWithCacheMetrics(String id) {
        try {
            return getProductTimer.recordCallable(() -> {
                // Use a more reliable approach: manually handle caching with proper metrics
                Cache cache = cacheManager.getCache("productById");
                Product cachedProduct = null;
                boolean wasInCache = false;
                
                // Try to get from cache first
                if (cache != null) {
                    Cache.ValueWrapper valueWrapper = cache.get(id);
                    if (valueWrapper != null) {
                        cachedProduct = (Product) valueWrapper.get();
                        wasInCache = true;
                        cacheHits.increment();
                        
                        // Check for stale reads if caching is enabled
                        if (!"none".equals(System.getenv().getOrDefault("CACHE_MODE", "ttl_invalidate"))) {
                            Product dbProduct = productRepository.findById(id).orElse(null);
                            if (dbProduct != null && !dbProduct.getVersion().equals(cachedProduct.getVersion())) {
                                staleReadsDetected.increment();
                                System.out.println("Stale read detected for product " + id + ": cached version " + cachedProduct.getVersion() + ", DB version " + dbProduct.getVersion());
                            }
                        }
                        
                        return cachedProduct;
                    }
                }
                
                // Cache miss - get from database and cache it
                cacheMisses.increment();
                Product product = productRepository.findById(id).orElse(null);
                
                // Cache the result if we got one
                if (cache != null && product != null) {
                    try {
                        cache.put(id, product);
                        System.out.println("Cached product " + id + " with version " + product.getVersion());
                    } catch (Exception e) {
                        System.err.println("Failed to cache product " + id + ": " + e.getMessage());
                    }
                }
                
                return product;
            });
        } catch (Exception e) {
            throw new RuntimeException("Error getting product with metrics: " + id, e);
        }
    }

    @CacheEvict(value = "productById", key = "#id")
    public Product updateProduct(String id, ProductUpdateRequest request) {
        // Retry logic for optimistic locking
        // Note: @Transactional removed to allow fresh reads on retry
        int maxRetries = 5;
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                // CRITICAL: Clear cache before fetching to ensure we get fresh data from database
                if (cacheManager != null) {
                    var cache = cacheManager.getCache("productById");
                    if (cache != null) {
                        cache.evict(id);
                        System.out.println("Cache cleared for product " + id + " on attempt " + attempt);
                    }
                }
                
                // Fetch fresh product from database each attempt (bypassing cache)
                // Using repository directly ensures we get the latest version from MongoDB
                Product product = productRepository.findById(id)
                        .orElseThrow(() -> new RuntimeException("Product not found: " + id));

                int currentVersion = product.getVersion();
                System.out.println("Attempt " + attempt + ": Fetched from DB - Version: " + currentVersion + ", Price: " + product.getPrice() + ", Stock: " + product.getStock());

                // Update fields
                if (request.getName() != null) product.setName(request.getName());
                if (request.getDescription() != null) product.setDescription(request.getDescription());
                if (request.getPrice() != null) product.setPrice(request.getPrice());
                if (request.getStock() != null) product.setStock(request.getStock());

                // Don't manually increment version - Spring Data's @Version annotation handles this automatically
                product.setUpdatedAt(Instant.now());

                System.out.println("Attempt " + attempt + ": Trying to save - Current version: " + currentVersion + " (Spring will auto-increment)");

                // Save - this may throw exception if version changed
                Product saved = productRepository.save(product);
                
                System.out.println("Attempt " + attempt + ": Save successful! Saved version: " + saved.getVersion());
                
                System.out.println("Update successful on attempt " + attempt + "! New version: " + saved.getVersion());
                
                // Evict cache manually since we removed @Transactional
                // (CacheEvict annotation still works, but we do it explicitly too)
                
                // Publish cache invalidation event
                // Wrap in try-catch to prevent Kafka errors from breaking the update
                if ("ttl_invalidate".equals(cacheMode)) {
                    try {
                        publishCacheInvalidation(id, saved.getVersion());
                    } catch (Exception e) {
                        // Log but don't fail the update if Kafka is down
                        System.err.println("Warning: Failed to publish cache invalidation event: " + e.getMessage());
                    }
                }
                
                return saved;
            } catch (Exception e) {
                String errorMsg = e.getMessage() != null ? e.getMessage() : "";
                boolean isVersionConflict = errorMsg.contains("Cannot save entity") && 
                                          errorMsg.contains("Has it been modified meanwhile");
                
                System.out.println("Exception on attempt " + attempt + ": " + e.getClass().getSimpleName());
                System.out.println("Full error: " + errorMsg);
                
                // Double-check what's actually in the database right now
                try {
                    // Clear cache again before checking
                    if (cacheManager != null) {
                        var cache = cacheManager.getCache("productById");
                        if (cache != null) {
                            cache.evict(id);
                        }
                    }
                    Product dbCheck = productRepository.findById(id).orElse(null);
                    if (dbCheck != null) {
                        System.out.println("Database check: Actual version in DB is " + dbCheck.getVersion());
                    }
                } catch (Exception checkEx) {
                    System.out.println("Could not verify database: " + checkEx.getMessage());
                }
                
                // Check if it's an optimistic locking or version conflict error
                if (e instanceof org.springframework.dao.OptimisticLockingFailureException || isVersionConflict) {
                    System.out.println("Caught version conflict on attempt " + attempt + " of " + maxRetries);
                    if (attempt == maxRetries) {
                        throw new RuntimeException("Product was modified by another operation. Please try again.");
                    }
                    // Wait longer before retrying to allow other operations to complete
                    try {
                        Thread.sleep(100 * attempt); // Exponential backoff: 100ms, 200ms, 300ms, 400ms, 500ms
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        throw new RuntimeException("Update interrupted", ie);
                    }
                } else {
                    // Not a version conflict, rethrow immediately
                    System.out.println("Not a version conflict - rethrowing");
                    if (e instanceof RuntimeException) {
                        throw (RuntimeException) e;
                    } else {
                        throw new RuntimeException("Error updating product: " + errorMsg, e);
                    }
                }
            }
        }
        throw new RuntimeException("Failed to update product after " + maxRetries + " attempts");
    }

    private void publishCacheInvalidation(String productId, Integer version) {
        // Spring Cache uses "cacheName::key" format in Redis
        // So the key is just the productId, and Spring adds "productById::" prefix
        CacheInvalidationEvent event = new CacheInvalidationEvent(
                "product",
                List.of(productId),  // Just the productId, Spring Cache adds prefix
                version,
                Instant.now(),
                "product_update"
        );

        kafkaTemplate.send("cache.invalidate", productId, event);
        invalidationsSent.increment();
    }

    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }
}

