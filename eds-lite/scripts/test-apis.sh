#!/bin/bash

# Test script for EDS-Lite APIs
# Make sure all services are running before executing this script

API_BASE="http://localhost:8080"

echo "=========================================="
echo "Testing EDS-Lite APIs"
echo "=========================================="
echo ""

# Test 1: Get a product
echo "1. Testing GET /api/catalog/products/1"
echo "----------------------------------------"
curl -s "$API_BASE/api/catalog/products/1" | jq '.' || curl -s "$API_BASE/api/catalog/products/1"
echo ""
echo ""

# Test 2: Get another product
echo "2. Testing GET /api/catalog/products/100"
echo "----------------------------------------"
curl -s "$API_BASE/api/catalog/products/100" | jq '.' || curl -s "$API_BASE/api/catalog/products/100"
echo ""
echo ""

# Test 3: Update a product (triggers cache invalidation)
echo "3. Testing POST /api/catalog/products/1 (Update - triggers cache invalidation)"
echo "----------------------------------------"
curl -s -X POST "$API_BASE/api/catalog/products/1" \
  -H "Content-Type: application/json" \
  -d '{
    "price": 99.99,
    "stock": 50
  }' | jq '.' || curl -s -X POST "$API_BASE/api/catalog/products/1" \
  -H "Content-Type: application/json" \
  -d '{"price": 99.99, "stock": 50}'
echo ""
echo ""

# Test 4: Get the updated product (should be fresh)
echo "4. Testing GET /api/catalog/products/1 (After update - should be fresh)"
echo "----------------------------------------"
curl -s "$API_BASE/api/catalog/products/1" | jq '.' || curl -s "$API_BASE/api/catalog/products/1"
echo ""
echo ""

# Test 5: Create an order
echo "5. Testing POST /api/orders (Create order)"
echo "----------------------------------------"
curl -s -X POST "$API_BASE/api/orders" \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "customer-123",
    "items": [
      {"productId": "1", "quantity": 2, "price": 99.99},
      {"productId": "2", "quantity": 1, "price": 50.00}
    ]
  }' | jq '.' || curl -s -X POST "$API_BASE/api/orders" \
  -H "Content-Type: application/json" \
  -d '{"customerId": "customer-123", "items": [{"productId": "1", "quantity": 2, "price": 99.99}]}'
echo ""
echo ""

# Test 6: Get product version
echo "6. Testing GET /api/catalog/products/1/version"
echo "----------------------------------------"
curl -s "$API_BASE/api/catalog/products/1/version"
echo ""
echo ""

echo "=========================================="
echo "API Tests Complete!"
echo "=========================================="
echo ""
echo "Check the service logs for:"
echo "  - Cache hits/misses"
echo "  - Cache invalidation events"
echo "  - Metrics in /tmp/metrics/catalog.jsonl"
echo ""


