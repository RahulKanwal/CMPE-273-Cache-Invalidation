#!/bin/bash

# EDS Marketplace: Quick Cache Test
# Tests cache invalidation on the currently running catalog service

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CATALOG_URL="http://localhost:8081"
TEST_PRODUCT_ID="1"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="quick-cache-test-$TIMESTAMP.txt"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EDS Quick Cache Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Initialize results file
cat > "$RESULTS_FILE" << EOF
EDS Marketplace Quick Cache Test Results
=======================================
Test Run: $(date)
Test ID: $TIMESTAMP

This test validates cache behavior on the currently running catalog service.

EOF

log_result() {
    echo "$1" | tee -a "$RESULTS_FILE"
}

# Check if catalog service is running
if ! lsof -Pi :8081 -sTCP:LISTEN -t >/dev/null 2>&1; then
    log_result "✗ Catalog service is NOT running on port 8081"
    log_result ""
    log_result "Please start the catalog service first:"
    log_result "  cd catalog-service && mvn spring-boot:run"
    log_result ""
    exit 1
fi

log_result "✓ Catalog service is running on port 8081"
log_result ""

# Test 1: First read (potential cache miss)
log_result "========================================="
log_result "Test 1: First Read"
log_result "========================================="
log_result "GET $CATALOG_URL/products/$TEST_PRODUCT_ID"

start_time=$(date +%s%N)
response1=$(curl -s "$CATALOG_URL/products/$TEST_PRODUCT_ID")
end_time=$(date +%s%N)
latency1=$(( (end_time - start_time) / 1000000 ))

if [ $? -eq 0 ]; then
    price1=$(echo "$response1" | jq -r '.price' 2>/dev/null || echo "")
    stock1=$(echo "$response1" | jq -r '.stock' 2>/dev/null || echo "")
    version1=$(echo "$response1" | jq -r '.version' 2>/dev/null || echo "")
    
    log_result "✓ Response received in ${latency1}ms"
    log_result "  Price: $price1"
    log_result "  Stock: $stock1"
    log_result "  Version: $version1"
else
    log_result "✗ Failed to get product"
    exit 1
fi

# Test 2: Second read (potential cache hit)
sleep 1
log_result ""
log_result "========================================="
log_result "Test 2: Second Read (Cache Hit Test)"
log_result "========================================="
log_result "GET $CATALOG_URL/products/$TEST_PRODUCT_ID"

start_time=$(date +%s%N)
response2=$(curl -s "$CATALOG_URL/products/$TEST_PRODUCT_ID")
end_time=$(date +%s%N)
latency2=$(( (end_time - start_time) / 1000000 ))

price2=$(echo "$response2" | jq -r '.price' 2>/dev/null || echo "")
version2=$(echo "$response2" | jq -r '.version' 2>/dev/null || echo "")

log_result "✓ Response received in ${latency2}ms"
log_result "  Price: $price2"
log_result "  Version: $version2"

# Analyze cache behavior
if [ $latency2 -lt $latency1 ]; then
    cache_speedup=$((latency1 - latency2))
    log_result "✓ Cache hit detected! ${cache_speedup}ms faster"
elif [ $latency2 -eq $latency1 ]; then
    log_result "⚠ Similar response times (${latency1}ms vs ${latency2}ms)"
else
    log_result "⚠ Second request was slower (${latency2}ms vs ${latency1}ms)"
fi

# Test 3: Update product
sleep 1
log_result ""
log_result "========================================="
log_result "Test 3: Update Product"
log_result "========================================="

new_price=$(echo "$price1 + 5.00" | bc 2>/dev/null || echo "199.99")
new_stock=$((stock1 + 10))

log_result "POST $CATALOG_URL/products/$TEST_PRODUCT_ID"
log_result "Updating: Price $price1 -> $new_price, Stock $stock1 -> $new_stock"

update_response=$(curl -s -X POST "$CATALOG_URL/products/$TEST_PRODUCT_ID" \
    -H "Content-Type: application/json" \
    -d "{\"price\": $new_price, \"stock\": $new_stock}")

if echo "$update_response" | jq . >/dev/null 2>&1; then
    update_price=$(echo "$update_response" | jq -r '.price' 2>/dev/null || echo "")
    update_stock=$(echo "$update_response" | jq -r '.stock' 2>/dev/null || echo "")
    update_version=$(echo "$update_response" | jq -r '.version' 2>/dev/null || echo "")
    
    log_result "✓ Update successful"
    log_result "  New Price: $update_price"
    log_result "  New Stock: $update_stock"
    log_result "  New Version: $update_version"
    
    if [ "$update_version" != "$version1" ]; then
        log_result "✓ Version incremented: $version1 -> $update_version"
    else
        log_result "⚠ Version not incremented"
    fi
else
    log_result "✗ Update failed: $update_response"
    exit 1
fi

# Test 4: Wait for cache invalidation
log_result ""
log_result "Waiting 3 seconds for potential cache invalidation..."
sleep 3

# Test 5: Read after update
log_result ""
log_result "========================================="
log_result "Test 4: Read After Update"
log_result "========================================="
log_result "GET $CATALOG_URL/products/$TEST_PRODUCT_ID"

start_time=$(date +%s%N)
response3=$(curl -s "$CATALOG_URL/products/$TEST_PRODUCT_ID")
end_time=$(date +%s%N)
latency3=$(( (end_time - start_time) / 1000000 ))

price3=$(echo "$response3" | jq -r '.price' 2>/dev/null || echo "")
stock3=$(echo "$response3" | jq -r '.stock' 2>/dev/null || echo "")
version3=$(echo "$response3" | jq -r '.version' 2>/dev/null || echo "")

log_result "✓ Response received in ${latency3}ms"
log_result "  Price: $price3"
log_result "  Stock: $stock3"
log_result "  Version: $version3"

# Analyze cache invalidation
if [ "$price3" = "$new_price" ] && [ "$stock3" = "$new_stock" ] && [ "$version3" = "$update_version" ]; then
    log_result "✓ Fresh data retrieved - cache invalidation working!"
else
    log_result "⚠ Data mismatch detected:"
    log_result "  Expected: Price=$new_price, Stock=$new_stock, Version=$update_version"
    log_result "  Got:      Price=$price3, Stock=$stock3, Version=$version3"
    
    if [ "$version3" = "$version1" ]; then
        log_result "⚠ Stale data from cache - invalidation may not be working"
    fi
fi

# Test 6: Multiple rapid reads
log_result ""
log_result "========================================="
log_result "Test 5: Rapid Reads (Consistency Check)"
log_result "========================================="

log_result "Performing 5 rapid reads..."
versions=()
total_latency=0

for i in {1..5}; do
    start_time=$(date +%s%N)
    rapid_response=$(curl -s "$CATALOG_URL/products/$TEST_PRODUCT_ID")
    end_time=$(date +%s%N)
    rapid_latency=$(( (end_time - start_time) / 1000000 ))
    
    rapid_version=$(echo "$rapid_response" | jq -r '.version' 2>/dev/null || echo "")
    versions+=("$rapid_version")
    total_latency=$((total_latency + rapid_latency))
    
    sleep 0.1
done

avg_latency=$((total_latency / 5))
log_result "Average response time: ${avg_latency}ms"

# Check consistency
first_version=${versions[0]}
all_same=true
for version in "${versions[@]}"; do
    if [ "$version" != "$first_version" ]; then
        all_same=false
        break
    fi
done

if [ "$all_same" = true ]; then
    log_result "✓ Consistency: All reads returned version $first_version"
else
    log_result "⚠ Inconsistency detected: ${versions[*]}"
fi

# Test 7: Add a review to test review-based cache invalidation
log_result ""
log_result "========================================="
log_result "Test 6: Review-Based Cache Invalidation"
log_result "========================================="

log_result "POST $CATALOG_URL/products/$TEST_PRODUCT_ID/reviews"
review_response=$(curl -s -X POST "$CATALOG_URL/products/$TEST_PRODUCT_ID/reviews" \
    -H "Content-Type: application/json" \
    -H "X-User-Id: cache-test-user-$TIMESTAMP@example.com" \
    -d '{"rating": 4, "comment": "Cache test review", "userName": "Cache Test User"}')

if echo "$review_response" | grep -q "already reviewed"; then
    log_result "⚠ User already reviewed this product, skipping review test"
elif echo "$review_response" | jq . >/dev/null 2>&1; then
    review_id=$(echo "$review_response" | jq -r '.id' 2>/dev/null || echo "")
    log_result "✓ Review added: $review_id"
    
    log_result "Waiting 3 seconds for review-based cache invalidation..."
    sleep 3
    
    # Check if product was updated
    final_response=$(curl -s "$CATALOG_URL/products/$TEST_PRODUCT_ID")
    final_version=$(echo "$final_response" | jq -r '.version' 2>/dev/null || echo "")
    final_rating=$(echo "$final_response" | jq -r '.rating' 2>/dev/null || echo "")
    
    log_result "After review: Version=$final_version, Rating=$final_rating"
    
    if [ "$final_version" != "$version3" ]; then
        log_result "✓ Review triggered cache invalidation: $version3 -> $final_version"
    else
        log_result "⚠ Review may not have triggered cache invalidation"
    fi
else
    log_result "⚠ Review submission failed or returned unexpected response"
    log_result "Response: $review_response"
fi

# Final summary
log_result ""
log_result ""
log_result "========================================="
log_result "QUICK CACHE TEST SUMMARY"
log_result "========================================="
log_result ""
log_result "Performance:"
log_result "- First read:     ${latency1}ms"
log_result "- Second read:    ${latency2}ms"
log_result "- Post-update:    ${latency3}ms"
log_result "- Average rapid:  ${avg_latency}ms"
log_result ""
log_result "Cache Behavior:"
if [ $latency2 -lt $latency1 ]; then
    log_result "- Cache hits:     ✓ Detected (faster subsequent reads)"
else
    log_result "- Cache hits:     ⚠ Not clearly detected"
fi

if [ "$price3" = "$new_price" ] && [ "$version3" = "$update_version" ]; then
    log_result "- Invalidation:   ✓ Working (fresh data after update)"
else
    log_result "- Invalidation:   ⚠ Issues detected (stale data)"
fi

if [ "$all_same" = true ]; then
    log_result "- Consistency:    ✓ All reads consistent"
else
    log_result "- Consistency:    ⚠ Inconsistencies detected"
fi

log_result ""
log_result "Test completed at: $(date)"
log_result "Results saved to: $RESULTS_FILE"
log_result ""

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Quick Cache Test Completed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Results saved to: $RESULTS_FILE"
echo ""
echo "To view full results:"
echo "  cat $RESULTS_FILE"
echo ""
echo "To view just the summary:"
echo "  tail -20 $RESULTS_FILE"
echo ""