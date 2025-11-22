package com.eds.catalog.model;

import java.util.List;

public class ProductSearchResponse {
    private List<Product> products;
    private long totalElements;
    private int totalPages;
    private int currentPage;
    private int size;

    public ProductSearchResponse(List<Product> products, long totalElements, int totalPages, int currentPage, int size) {
        this.products = products;
        this.totalElements = totalElements;
        this.totalPages = totalPages;
        this.currentPage = currentPage;
        this.size = size;
    }

    // Getters and setters
    public List<Product> getProducts() { return products; }
    public void setProducts(List<Product> products) { this.products = products; }

    public long getTotalElements() { return totalElements; }
    public void setTotalElements(long totalElements) { this.totalElements = totalElements; }

    public int getTotalPages() { return totalPages; }
    public void setTotalPages(int totalPages) { this.totalPages = totalPages; }

    public int getCurrentPage() { return currentPage; }
    public void setCurrentPage(int currentPage) { this.currentPage = currentPage; }

    public int getSize() { return size; }
    public void setSize(int size) { this.size = size; }
}