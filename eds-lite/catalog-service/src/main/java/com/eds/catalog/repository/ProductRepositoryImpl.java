package com.eds.catalog.repository;

import com.eds.catalog.model.Product;
import com.eds.catalog.model.ProductSearchRequest;
import com.eds.catalog.model.ProductSearchResponse;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;

@Repository
public class ProductRepositoryImpl implements ProductRepositoryCustom {
    
    private final MongoTemplate mongoTemplate;

    public ProductRepositoryImpl(MongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
    }

    @Override
    public List<String> findDistinctCategories() {
        return mongoTemplate.findDistinct("category", Product.class, String.class);
    }

    @Override
    public ProductSearchResponse searchProducts(ProductSearchRequest request) {
        Query query = new Query();
        List<Criteria> criteria = new ArrayList<>();

        // Text search
        if (request.getSearch() != null && !request.getSearch().trim().isEmpty()) {
            Criteria searchCriteria = new Criteria().orOperator(
                Criteria.where("name").regex(request.getSearch(), "i"),
                Criteria.where("description").regex(request.getSearch(), "i"),
                Criteria.where("tags").regex(request.getSearch(), "i")
            );
            criteria.add(searchCriteria);
        }

        // Category filter
        if (request.getCategory() != null && !request.getCategory().trim().isEmpty()) {
            criteria.add(Criteria.where("category").regex(request.getCategory(), "i"));
        }

        // Price range filter
        if (request.getMinPrice() != null) {
            criteria.add(Criteria.where("price").gte(request.getMinPrice()));
        }
        if (request.getMaxPrice() != null) {
            criteria.add(Criteria.where("price").lte(request.getMaxPrice()));
        }

        // Featured filter
        if (request.getFeatured() != null) {
            criteria.add(Criteria.where("featured").is(request.getFeatured()));
        }

        // Combine all criteria
        if (!criteria.isEmpty()) {
            query.addCriteria(new Criteria().andOperator(criteria.toArray(new Criteria[0])));
        }

        // Count total results
        long totalElements = mongoTemplate.count(query, Product.class);

        // Add sorting
        Sort sort = Sort.by(
            "desc".equalsIgnoreCase(request.getSortDirection()) ? 
                Sort.Direction.DESC : Sort.Direction.ASC,
            request.getSortBy()
        );
        query.with(sort);

        // Add pagination
        Pageable pageable = PageRequest.of(request.getPage(), request.getSize());
        query.with(pageable);

        // Execute query
        List<Product> products = mongoTemplate.find(query, Product.class);

        // Calculate pagination info
        int totalPages = (int) Math.ceil((double) totalElements / request.getSize());

        return new ProductSearchResponse(
            products,
            totalElements,
            totalPages,
            request.getPage(),
            request.getSize()
        );
    }
}