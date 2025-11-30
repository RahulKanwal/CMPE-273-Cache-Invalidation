package com.eds.catalog.controller;

import com.eds.catalog.model.Review;
import com.eds.catalog.model.ReviewRequest;
import com.eds.catalog.service.ReviewService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/products/{productId}/reviews")
public class ReviewController {
    
    private final ReviewService reviewService;

    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @GetMapping
    public ResponseEntity<List<Review>> getProductReviews(@PathVariable String productId) {
        try {
            List<Review> reviews = reviewService.getProductReviews(productId);
            return ResponseEntity.ok(reviews);
        } catch (Exception e) {
            System.err.println("Error fetching reviews for product " + productId + ": " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    @PostMapping
    public ResponseEntity<?> addReview(
            @PathVariable String productId,
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @RequestBody ReviewRequest request) {
        
        System.out.println("=== ADD REVIEW REQUEST ===");
        System.out.println("Product ID: " + productId);
        System.out.println("User ID: " + userId);
        System.out.println("Rating: " + request.getRating());
        System.out.println("Comment: " + request.getComment());
        
        try {
            if (userId == null || userId.trim().isEmpty()) {
                return ResponseEntity.badRequest().body("User authentication required");
            }

            if (request.getRating() == null || request.getRating() < 1 || request.getRating() > 5) {
                return ResponseEntity.badRequest().body("Rating must be between 1 and 5 stars");
            }

            Review review = reviewService.addReview(productId, userId, request);
            System.out.println("Review added successfully: " + review.getId());
            return ResponseEntity.ok(review);
            
        } catch (RuntimeException e) {
            System.err.println("Review error: " + e.getMessage());
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            System.err.println("Unexpected error adding review: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError().body("Failed to add review");
        }
    }

    @GetMapping("/user-reviewed")
    public ResponseEntity<Boolean> hasUserReviewed(
            @PathVariable String productId,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        
        if (userId == null || userId.trim().isEmpty()) {
            return ResponseEntity.ok(false);
        }

        try {
            boolean hasReviewed = reviewService.hasUserReviewed(productId, userId);
            return ResponseEntity.ok(hasReviewed);
        } catch (Exception e) {
            System.err.println("Error checking user review status: " + e.getMessage());
            return ResponseEntity.ok(false);
        }
    }
}