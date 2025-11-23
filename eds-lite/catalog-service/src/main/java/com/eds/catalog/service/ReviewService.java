package com.eds.catalog.service;

import com.eds.catalog.model.CacheInvalidationEvent;
import com.eds.catalog.model.Product;
import com.eds.catalog.model.Review;
import com.eds.catalog.model.ReviewRequest;
import com.eds.catalog.repository.ProductRepository;
import com.eds.catalog.repository.ReviewRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
public class ReviewService {
    
    private final ReviewRepository reviewRepository;
    private final ProductRepository productRepository;
    private final KafkaTemplate<String, CacheInvalidationEvent> kafkaTemplate;
    
    @Value("${cache.mode:ttl_invalidate}")
    private String cacheMode;

    public ReviewService(ReviewRepository reviewRepository, 
                        ProductRepository productRepository,
                        KafkaTemplate<String, CacheInvalidationEvent> kafkaTemplate) {
        this.reviewRepository = reviewRepository;
        this.productRepository = productRepository;
        this.kafkaTemplate = kafkaTemplate;
    }

    public List<Review> getProductReviews(String productId) {
        return reviewRepository.findByProductIdOrderByCreatedAtDesc(productId);
    }

    @Transactional
    public Review addReview(String productId, String userId, ReviewRequest request) {
        // Check if user already reviewed this product
        if (reviewRepository.existsByProductIdAndUserId(productId, userId)) {
            throw new RuntimeException("You have already reviewed this product");
        }

        // Validate rating
        if (request.getRating() == null || request.getRating() < 1 || request.getRating() > 5) {
            throw new RuntimeException("Rating must be between 1 and 5 stars");
        }

        // Create review
        Review review = new Review();
        review.setProductId(productId);
        review.setUserId(userId);
        review.setUserName(request.getUserName());
        review.setRating(request.getRating());
        review.setComment(request.getComment() != null ? request.getComment().trim() : "");
        review.setCreatedAt(Instant.now());

        Review savedReview = reviewRepository.save(review);

        // Update product rating
        updateProductRating(productId);

        return savedReview;
    }

    @CacheEvict(value = "productById", key = "#productId")
    private void updateProductRating(String productId) {
        List<Review> reviews = reviewRepository.findByProductIdOrderByCreatedAtDesc(productId);
        
        if (reviews.isEmpty()) {
            return;
        }

        // Calculate average rating
        double averageRating = reviews.stream()
                .mapToInt(Review::getRating)
                .average()
                .orElse(0.0);

        // Update product - bypass cache by using repository directly
        Product product = productRepository.findById(productId).orElse(null);
        if (product != null) {
            product.setRating(Math.round(averageRating * 10.0) / 10.0); // Round to 1 decimal
            product.setReviewCount(reviews.size());
            product.setUpdatedAt(Instant.now());
            
            // Save and explicitly evict cache
            Product savedProduct = productRepository.save(product);
            
            // Publish cache invalidation event
            if ("ttl_invalidate".equals(cacheMode)) {
                try {
                    publishCacheInvalidation(productId, savedProduct.getVersion());
                } catch (Exception e) {
                    System.err.println("Warning: Failed to publish cache invalidation event for rating update: " + e.getMessage());
                }
            }
            
            System.out.println("Updated product " + productId + " rating to " + product.getRating() + 
                             " based on " + reviews.size() + " reviews. Cache evicted.");
        }
    }

    private void publishCacheInvalidation(String productId, Integer version) {
        CacheInvalidationEvent event = new CacheInvalidationEvent(
                "product",
                List.of(productId),
                version,
                Instant.now(),
                "rating_update"
        );

        kafkaTemplate.send("cache.invalidate", productId, event);
        System.out.println("Published cache invalidation event for product " + productId + " due to rating update");
    }

    public boolean hasUserReviewed(String productId, String userId) {
        return reviewRepository.existsByProductIdAndUserId(productId, userId);
    }
}