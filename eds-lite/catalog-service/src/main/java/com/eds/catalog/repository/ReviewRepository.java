package com.eds.catalog.repository;

import com.eds.catalog.model.Review;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReviewRepository extends MongoRepository<Review, String> {
    List<Review> findByProductIdOrderByCreatedAtDesc(String productId);
    boolean existsByProductIdAndUserId(String productId, String userId);
    long countByProductId(String productId);
}