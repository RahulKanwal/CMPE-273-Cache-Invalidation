package com.eds.catalog.repository;

import com.eds.catalog.model.Product;
import com.eds.catalog.model.ProductSearchRequest;
import com.eds.catalog.model.ProductSearchResponse;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProductRepository extends MongoRepository<Product, String>, ProductRepositoryCustom {
    
    @Query(value = "{}", fields = "{ 'category' : 1 }")
    List<Product> findAllCategories();
    
    List<Product> findByFeaturedTrue();
    
    List<Product> findByCategoryIgnoreCase(String category);
}

