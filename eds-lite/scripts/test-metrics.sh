#!/bin/bash

# Test if metrics are being generated

echo "=== Testing Metrics Generation ==="
echo ""

# Clear metrics directory
rm -rf /tmp/metrics
mkdir -p /tmp/metrics
echo "✓ Cleared /tmp/metrics directory"

# Make a few API calls to generate metrics
echo ""
echo "Making API calls to generate metrics..."

for i in {1..5}; do
    echo "  Request $i: GET /api/catalog/products/$i"
    curl -s "http://localhost:8080/api/catalog/products/$i" > /dev/null
    sleep 1
done

echo ""
echo "Making update requests..."
for i in {1..2}; do
    echo "  Update $i: POST /api/catalog/products/$i"
    curl -s -X POST "http://localhost:8080/api/catalog/products/$i" \
        -H "Content-Type: application/json" \
        -d '{"price": 99.99, "stock": 50}' > /dev/null
    sleep 1
done

echo ""
echo "Waiting 10 seconds for metrics to be written..."
sleep 10

echo ""
echo "=== Checking for metrics files ==="
ls -la /tmp/metrics/

echo ""
echo "=== If catalog.jsonl exists, show content ==="
if [ -f /tmp/metrics/catalog.jsonl ]; then
    echo "Found catalog.jsonl! Content:"
    cat /tmp/metrics/catalog.jsonl
else
    echo "❌ No catalog.jsonl found"
    echo ""
    echo "Possible issues:"
    echo "1. MetricsWriter not working"
    echo "2. Permissions issue with /tmp/metrics"
    echo "3. Service not configured to write metrics"
fi

echo ""
echo "=== Checking /tmp/metrics permissions ==="
ls -ld /tmp/metrics