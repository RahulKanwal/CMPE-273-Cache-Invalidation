package com.eds.catalog.controller;

import com.eds.catalog.model.Product;
import com.eds.catalog.model.ProductCreateRequest;
import com.eds.catalog.model.ProductUpdateRequest;
import com.eds.catalog.model.ProductSearchRequest;
import com.eds.catalog.model.ProductSearchResponse;
import com.eds.catalog.service.ProductService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/products")
@CrossOrigin(origins = "*")
public class ProductController {
    private final ProductService productService;

    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    @GetMapping("/{id}")
    public ResponseEntity<Product> getProduct(@PathVariable String id) {
        Product product = productService.getProductWithCacheMetrics(id);
        if (product == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(product);
    }

    @GetMapping
    public ResponseEntity<ProductSearchResponse> searchProducts(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String minPrice,
            @RequestParam(required = false) String maxPrice,
            @RequestParam(required = false) Boolean featured,
            @RequestParam(defaultValue = "name") String sortBy,
            @RequestParam(defaultValue = "asc") String sortDirection,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        ProductSearchRequest request = new ProductSearchRequest();
        request.setSearch(search);
        request.setCategory(category);
        if (minPrice != null) request.setMinPrice(new java.math.BigDecimal(minPrice));
        if (maxPrice != null) request.setMaxPrice(new java.math.BigDecimal(maxPrice));
        request.setFeatured(featured);
        request.setSortBy(sortBy);
        request.setSortDirection(sortDirection);
        request.setPage(page);
        request.setSize(size);
        
        return ResponseEntity.ok(productService.searchProducts(request));
    }

    @GetMapping("/categories")
    public ResponseEntity<List<String>> getCategories() {
        return ResponseEntity.ok(productService.getCategories());
    }

    @GetMapping("/featured")
    public ResponseEntity<List<Product>> getFeaturedProducts() {
        return ResponseEntity.ok(productService.getFeaturedProducts());
    }

    @PostMapping("/{id}")
    public ResponseEntity<?> updateProduct(
            @PathVariable String id,
            @RequestBody ProductUpdateRequest request) {
        System.out.println("=== UPDATE REQUEST RECEIVED ===");
        System.out.println("Product ID: " + id);
        System.out.println("Request object: " + request);
        System.out.println("Request is null: " + (request == null));
        
        try {
            if (request == null) {
                System.err.println("ERROR: Request body is null!");
                return ResponseEntity.badRequest().body("Request body is required");
            }
            
            System.out.println("Price: " + request.getPrice());
            System.out.println("Stock: " + request.getStock());
            System.out.println("Name: " + request.getName());
            
            Product updated = productService.updateProduct(id, request);
            System.out.println("Update successful! Product version: " + updated.getVersion());
            return ResponseEntity.ok(updated);
        } catch (RuntimeException e) {
            // Log the error for debugging
            System.err.println("=== UPDATE FAILED ===");
            System.err.println("Product ID: " + id);
            System.err.println("Error message: " + e.getMessage());
            System.err.println("Error class: " + e.getClass().getName());
            e.printStackTrace();
            
            // Return appropriate status code with error message
            if (e.getMessage() != null && e.getMessage().contains("not found")) {
                return ResponseEntity.notFound().build();
            }
            
            // Return 400 with error message for client to see
            String errorMsg = e.getMessage() != null ? e.getMessage() : "Unknown error";
            return ResponseEntity.badRequest().body("Error: " + errorMsg);
        } catch (Exception e) {
            System.err.println("=== UNEXPECTED ERROR ===");
            System.err.println("Product ID: " + id);
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(500).body("Internal server error: " + e.getMessage());
        }
    }

    @PostMapping
    public ResponseEntity<?> createProduct(@RequestBody ProductCreateRequest request) {
        System.out.println("=== CREATE REQUEST RECEIVED ===");
        System.out.println("Request object: " + request);
        
        try {
            if (request == null) {
                System.err.println("ERROR: Request body is null!");
                return ResponseEntity.badRequest().body("Request body is required");
            }
            
            if (request.getName() == null || request.getName().trim().isEmpty()) {
                return ResponseEntity.badRequest().body("Product name is required");
            }
            
            if (request.getPrice() == null || request.getPrice().compareTo(java.math.BigDecimal.ZERO) <= 0) {
                return ResponseEntity.badRequest().body("Valid price is required");
            }
            
            if (request.getStock() == null || request.getStock() < 0) {
                return ResponseEntity.badRequest().body("Valid stock quantity is required");
            }
            
            if (request.getCategory() == null || request.getCategory().trim().isEmpty()) {
                return ResponseEntity.badRequest().body("Category is required");
            }
            
            Product created = productService.createProduct(request);
            System.out.println("Create successful! Product ID: " + created.getId());
            return ResponseEntity.ok(created);
        } catch (RuntimeException e) {
            System.err.println("=== CREATE FAILED ===");
            System.err.println("Error message: " + e.getMessage());
            e.printStackTrace();
            
            String errorMsg = e.getMessage() != null ? e.getMessage() : "Unknown error";
            return ResponseEntity.badRequest().body("Error: " + errorMsg);
        } catch (Exception e) {
            System.err.println("=== UNEXPECTED ERROR ===");
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(500).body("Internal server error: " + e.getMessage());
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteProduct(@PathVariable String id) {
        System.out.println("=== DELETE REQUEST RECEIVED ===");
        System.out.println("Product ID: " + id);
        
        try {
            boolean deleted = productService.deleteProduct(id);
            if (deleted) {
                System.out.println("Delete successful! Product ID: " + id);
                return ResponseEntity.ok().build();
            } else {
                System.out.println("Product not found: " + id);
                return ResponseEntity.notFound().build();
            }
        } catch (RuntimeException e) {
            System.err.println("=== DELETE FAILED ===");
            System.err.println("Product ID: " + id);
            System.err.println("Error message: " + e.getMessage());
            e.printStackTrace();
            
            String errorMsg = e.getMessage() != null ? e.getMessage() : "Unknown error";
            return ResponseEntity.badRequest().body("Error: " + errorMsg);
        } catch (Exception e) {
            System.err.println("=== UNEXPECTED ERROR ===");
            System.err.println("Product ID: " + id);
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(500).body("Internal server error: " + e.getMessage());
        }
    }

    @GetMapping("/{id}/version")
    public ResponseEntity<Integer> getProductVersion(@PathVariable String id) {
        Product product = productService.getProduct(id);
        if (product == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(product.getVersion());
    }
}

