#!/bin/bash

# Quick Manual Cache Test
# Tests the currently running catalog-service configuration

CATALOG_URL="http://localhost:8081"
TEST_PRODUCT_ID="1"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="manual-test-results-$TIMESTAMP.txt"

echo "========================================="
echo "Quick Manual Cache Test"
echo "========================================="
echo ""
echo "Testing catalog service at: $CATALOG_URL"
echo "Results will be saved to: $RESULTS_FILE"
echo ""

# Initialize results file
cat > "$RESULTS_FILE" << EOF
Quick Manual Cache Test Results
================================
Test Run: $(date)
Catalog URL: $CATALOG_URL
Test Product ID: $TEST_PRODUCT_ID

EOF

log_result() {
    echo "$1" | tee -a "$RESULTS_FILE"
}

# Test 1: First Read
log_result "Test 1: First Read (Cache Miss Expected)"
log_result "GET $CATALOG_URL/products/$TEST_PRODUCT_ID"
start_time=$(date +%s%N)
response1=$(curl -s "$CATALOG_URL/products/$TEST_PRODUCT_ID")
end_time=$(date +%s%N)
latency1=$(( (end_time - start_time) / 1000000 ))

price1=$(echo "$response1" | python3 -c "import sys, json; print(json.load(sys.stdin).get('price', 'N/A'))" 2>/dev/null || echo "N/A")
version1=$(echo "$response1" | python3 -c "import sys, json; print(json.load(sys.stdin).get('version', 'N/A'))" 2>/dev/null || echo "N/A")

log_result "Response time: ${latency1}ms"
log_result "Price: $price1, Version: $version1"
log_result ""

# Wait a bit
sleep 2

# Test 2: Second Read
log_result "Test 2: Second Read (Cache Hit Expected if caching enabled)"
log_result "GET $CATALOG_URL/products/$TEST_PRODUCT_ID"
start_time=$(date +%s%N)
response2=$(curl -s "$CATALOG_URL/products/$TEST_PRODUCT_ID")
end_time=$(date +%s%N)
latency2=$(( (end_time - start_time) / 1000000 ))

price2=$(echo "$response2" | python3 -c "import sys, json; print(json.load(sys.stdin).get('price', 'N/A'))" 2>/dev/null || echo "N/A")
version2=$(echo "$response2" | python3 -c "import sys, json; print(json.load(sys.stdin).get('version', 'N/A'))" 2>/dev/null || echo "N/A")

log_result "Response time: ${latency2}ms"
log_result "Price: $price2, Version: $version2"

# Calculate improvement
if [ "$latency1" -gt 0 ]; then
    improvement=$(( (latency1 - latency2) * 100 / latency1 ))
    if [ "$improvement" -gt 50 ]; then
        log_result "✓ Cache hit detected! ${improvement}% faster"
    else
        log_result "No significant cache benefit (${improvement}% difference)"
    fi
fi
log_result ""

# Wait a bit
sleep 2

# Test 3: Update Product
new_price="199.99"
new_stock="75"
log_result "Test 3: Update Product"
log_result "POST $CATALOG_URL/products/$TEST_PRODUCT_ID"
log_result "Body: {\"price\": $new_price, \"stock\": $new_stock}"

start_time=$(date +%s%N)
response3=$(curl -s -X POST "$CATALOG_URL/products/$TEST_PRODUCT_ID" \
  -H "Content-Type: application/json" \
  -d "{\"price\": $new_price, \"stock\": $new_stock}")
end_time=$(date +%s%N)
latency3=$(( (end_time - start_time) / 1000000 ))

price3=$(echo "$response3" | python3 -c "import sys, json; print(json.load(sys.stdin).get('price', 'N/A'))" 2>/dev/null || echo "N/A")
version3=$(echo "$response3" | python3 -c "import sys, json; print(json.load(sys.stdin).get('version', 'N/A'))" 2>/dev/null || echo "N/A")

log_result "Response time: ${latency3}ms"
log_result "New Price: $price3, New Version: $version3"
log_result ""

# Wait for cache invalidation
sleep 3

# Test 4: Read After Update
log_result "Test 4: Read After Update (Checking for fresh data)"
log_result "GET $CATALOG_URL/products/$TEST_PRODUCT_ID"

start_time=$(date +%s%N)
response4=$(curl -s "$CATALOG_URL/products/$TEST_PRODUCT_ID")
end_time=$(date +%s%N)
latency4=$(( (end_time - start_time) / 1000000 ))

price4=$(echo "$response4" | python3 -c "import sys, json; print(json.load(sys.stdin).get('price', 'N/A'))" 2>/dev/null || echo "N/A")
version4=$(echo "$response4" | python3 -c "import sys, json; print(json.load(sys.stdin).get('version', 'N/A'))" 2>/dev/null || echo "N/A")

log_result "Response time: ${latency4}ms"
log_result "Price: $price4, Version: $version4"

if [ "$version4" == "$version3" ] && [ "$price4" == "$price3" ]; then
    log_result "✓ Fresh data confirmed (version and price updated)"
elif [ "$version4" == "$version1" ]; then
    log_result "⚠ STALE DATA detected (still showing old version)"
else
    log_result "? Data state unclear"
fi
log_result ""

# Summary
log_result "========================================="
log_result "SUMMARY"
log_result "========================================="
log_result "First read:        ${latency1}ms"
log_result "Second read:       ${latency2}ms"
log_result "Update:            ${latency3}ms"
log_result "Post-update read:  ${latency4}ms"
log_result ""

if [ "$latency2" -lt "$((latency1 / 2))" ]; then
    log_result "Cache Status: ENABLED (second read was significantly faster)"
else
    log_result "Cache Status: DISABLED or NOT EFFECTIVE"
fi

if [ "$version4" == "$version3" ]; then
    log_result "Data Consistency: GOOD (fresh data after update)"
else
    log_result "Data Consistency: STALE (old data after update)"
fi

log_result ""
log_result "Test completed at: $(date)"
log_result "Results saved to: $RESULTS_FILE"

echo ""
echo "========================================="
echo "Test Complete!"
echo "========================================="
echo ""
echo "Results saved to: $RESULTS_FILE"
echo ""
echo "To view results:"
echo "  cat $RESULTS_FILE"
echo ""
