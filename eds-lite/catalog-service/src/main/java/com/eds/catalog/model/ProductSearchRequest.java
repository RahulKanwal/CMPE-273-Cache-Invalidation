package com.eds.catalog.model;

import java.math.BigDecimal;

public class ProductSearchRequest {
    private String search;
    private String category;
    private BigDecimal minPrice;
    private BigDecimal maxPrice;
    private Boolean featured;
    private String sortBy = "name";
    private String sortDirection = "asc";
    private int page = 0;
    private int size = 20;

    // Getters and setters
    public String getSearch() { return search; }
    public void setSearch(String search) { this.search = search; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public BigDecimal getMinPrice() { return minPrice; }
    public void setMinPrice(BigDecimal minPrice) { this.minPrice = minPrice; }

    public BigDecimal getMaxPrice() { return maxPrice; }
    public void setMaxPrice(BigDecimal maxPrice) { this.maxPrice = maxPrice; }

    public Boolean getFeatured() { return featured; }
    public void setFeatured(Boolean featured) { this.featured = featured; }

    public String getSortBy() { return sortBy; }
    public void setSortBy(String sortBy) { this.sortBy = sortBy; }

    public String getSortDirection() { return sortDirection; }
    public void setSortDirection(String sortDirection) { this.sortDirection = sortDirection; }

    public int getPage() { return page; }
    public void setPage(int page) { this.page = page; }

    public int getSize() { return size; }
    public void setSize(int size) { this.size = size; }
}