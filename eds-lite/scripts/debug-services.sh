#!/bin/bash

# Debug script to see what's happening with services

echo "=== CURRENT PROCESSES ==="
echo "Java processes:"
ps aux | grep java | grep -v grep

echo ""
echo "Maven processes:"
ps aux | grep mvn | grep -v grep

echo ""
echo "=== PORT USAGE ==="
echo "Port 8080 (API Gateway):"
lsof -i :8080 || echo "Nothing on port 8080"

echo ""
echo "Port 8081 (Catalog Service):"
lsof -i :8081 || echo "Nothing on port 8081"

echo ""
echo "Port 8082 (Order Service):"
lsof -i :8082 || echo "Nothing on port 8082"

echo ""
echo "=== TESTING CONNECTIVITY ==="
echo "Testing API Gateway:"
curl -s -I http://localhost:8080/api/catalog/products/1 | head -1 || echo "API Gateway not responding"

echo ""
echo "Testing Catalog Service directly:"
curl -s -I http://localhost:8081/products/1 | head -1 || echo "Catalog Service not responding"

echo ""
echo "=== LOG FILES ==="
echo "Recent API Gateway logs:"
if [ -f /tmp/api-gateway.log ]; then
    tail -5 /tmp/api-gateway.log
else
    echo "No API Gateway log found"
fi

echo ""
echo "Recent Catalog Service logs:"
if [ -f /tmp/catalog-ttl_invalidate.log ]; then
    tail -5 /tmp/catalog-ttl_invalidate.log
else
    echo "No Catalog Service log found"
fi