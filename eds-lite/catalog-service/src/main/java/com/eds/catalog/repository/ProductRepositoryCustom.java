package com.eds.catalog.repository;

import com.eds.catalog.model.ProductSearchRequest;
import com.eds.catalog.model.ProductSearchResponse;

import java.util.List;

public interface ProductRepositoryCustom {
    ProductSearchResponse searchProducts(ProductSearchRequest request);
    List<String> findDistinctCategories();
}