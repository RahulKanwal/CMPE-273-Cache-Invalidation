package com.eds.catalog.controller;

import com.eds.catalog.model.Product;
import com.eds.catalog.model.ProductUpdateRequest;
import com.eds.catalog.service.ProductService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/products")
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
    public ResponseEntity<List<Product>> getAllProducts() {
        return ResponseEntity.ok(productService.getAllProducts());
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

    @GetMapping("/{id}/version")
    public ResponseEntity<Integer> getProductVersion(@PathVariable String id) {
        Product product = productService.getProduct(id);
        if (product == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(product.getVersion());
    }
}

