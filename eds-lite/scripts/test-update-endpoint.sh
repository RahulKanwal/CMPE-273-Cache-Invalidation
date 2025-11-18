#!/bin/bash

# Test script to verify the update endpoint is working

echo "Testing Update Endpoint..."
echo ""

echo "1. Testing direct service (port 8081):"
curl -X POST http://localhost:8081/products/1 \
  -H "Content-Type: application/json" \
  -d '{"price": 99.99, "stock": 50}' \
  -w "\nHTTP Status: %{http_code}\n" \
  2>&1 | tail -5

echo ""
echo "2. Testing through gateway (port 8080):"
curl -X POST http://localhost:8080/api/catalog/products/1 \
  -H "Content-Type: application/json" \
  -d '{"price": 99.99, "stock": 50}' \
  -w "\nHTTP Status: %{http_code}\n" \
  2>&1 | tail -5

echo ""
echo "3. Testing with OPTIONS (preflight):"
curl -X OPTIONS http://localhost:8080/api/catalog/products/1 \
  -H "Origin: http://localhost:8000" \
  -H "Access-Control-Request-Method: POST" \
  -w "\nHTTP Status: %{http_code}\n" \
  2>&1 | grep -E "(HTTP|Access-Control)" | head -5

echo ""
echo "Done!"


