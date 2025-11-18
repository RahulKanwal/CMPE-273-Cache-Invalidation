#!/bin/bash

# Verify all endpoints are working

echo "=========================================="
echo "Endpoint Verification"
echo "=========================================="
echo ""

echo "1. Testing GET /products/1 (should work):"
RESPONSE=$(curl -s http://localhost:8081/products/1)
if [ $? -eq 0 ] && [ -n "$RESPONSE" ]; then
    echo "✓ GET /products/1: OK"
    echo "$RESPONSE" | head -1
else
    echo "✗ GET /products/1: FAILED"
fi
echo ""

echo "2. Testing POST /products/1/update (should work after restart):"
RESPONSE=$(curl -s -X POST http://localhost:8081/products/1/update \
  -H "Content-Type: application/json" \
  -d '{"price": 99.99, "stock": 50}' \
  -w "\nHTTP_CODE:%{http_code}")
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ POST /products/1/update: OK"
    echo "$BODY" | head -1
elif [ "$HTTP_CODE" = "404" ]; then
    echo "✗ POST /products/1/update: 404 - Service needs restart!"
    echo "   The endpoint exists in code but service is running old version"
else
    echo "✗ POST /products/1/update: HTTP $HTTP_CODE"
    echo "$BODY"
fi
echo ""

echo "3. Testing through gateway:"
RESPONSE=$(curl -s -X POST http://localhost:8080/api/catalog/products/1/update \
  -H "Content-Type: application/json" \
  -d '{"price": 99.99, "stock": 50}' \
  -w "\nHTTP_CODE:%{http_code}")
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Gateway POST /api/catalog/products/1/update: OK"
    echo "$BODY" | head -1
else
    echo "✗ Gateway POST /api/catalog/products/1/update: HTTP $HTTP_CODE"
    if [ "$HTTP_CODE" = "404" ]; then
        echo "   Check:"
        echo "   1. Is catalog-service restarted with new code?"
        echo "   2. Is gateway restarted?"
    fi
fi
echo ""

echo "=========================================="


