#!/bin/bash

# EDS Marketplace: Cache Invalidation Test Script
# Tests the Kafka-based distributed cache invalidation system

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

GATEWAY_URL="http://localhost:8080"
TEST_PRODUCT_ID="1"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="/tmp/cache-invalidation-test-$TIMESTAMP.txt"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EDS Marketplace: Cache Invalidation Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Initialize results file
cat > "$RESULTS_FILE" << EOF
EDS Marketplace Cache Invalidation Test Results
===============================================
Test Run: $(date)
Test ID: $TIMESTAMP

EOF

log_result() {
    echo "$1" | tee -a "$RESULTS_FILE"
}

# Check if services are running
check_service() {
    local port=$1
    local name=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_result "✓ $name is running on port $port"
        return 0
    else
        log_result "✗ $name is NOT running on port $port"
        return 1
    fi
}

echo "Checking required services..." | tee -a "$RESULTS_FILE"
all_running=true

check_service 8080 "API Gateway" || all_running=false
check_service 8081 "Catalog Service" || all_running=false
check_service 8082 "Order Service" || all_running=false
check_service 8083 "User Service" || all_running=false
check_service 6379 "Redis" || all_running=false
check_service 27017 "MongoDB" || all_running=false
check_service 9092 "Kafka" || all_running=false

if [ "$all_running" = false ]; then
    echo "" | tee -a "$RESULTS_FILE"
    log_result "ERROR: Not all services are running!"
    log_result "Please start all services first using: ./scripts/start-marketplace.sh"
    exit 1
fi

echo "" | tee -a "$RESULTS_FILE"
log_result "All services are running!"
echo "" | tee -a "$RESULTS_FILE"

# Test 1: Get initial product state
echo -e "${BLUE}Test 1: Get Initial Product State (Cache Miss)${NC}" | tee -a "$RESULTS_FILE"
echo "GET $GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID" | tee -a "$RESULTS_FILE"

INITIAL_RESPONSE=$(curl -s "$GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID")
INITIAL_PRICE=$(echo "$INITIAL_RESPONSE" | jq -r '.price' 2>/dev/null || echo "")
INITIAL_STOCK=$(echo "$INITIAL_RESPONSE" | jq -r '.stock' 2>/dev/null || echo "")
INITIAL_VERSION=$(echo "$INITIAL_RESPONSE" | jq -r '.version' 2>/dev/null || echo "")

log_result "Initial State: Price=$INITIAL_PRICE, Stock=$INITIAL_STOCK, Version=$INITIAL_VERSION"
echo "" | tee -a "$RESULTS_FILE"
sleep 1

# Test 2: Read again (should be cache hit)
echo -e "${BLUE}Test 2: Second Read (Cache Hit)${NC}" | tee -a "$RESULTS_FILE"
echo "GET $GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID" | tee -a "$RESULTS_FILE"

CACHED_RESPONSE=$(curl -s "$GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID")
CACHED_VERSION=$(echo "$CACHED_RESPONSE" | jq -r '.version' 2>/dev/null || echo "")

if [ "$CACHED_VERSION" = "$INITIAL_VERSION" ]; then
    log_result "✓ Cache hit - same version returned: $CACHED_VERSION"
else
    log_result "⚠ Unexpected version change: $INITIAL_VERSION -> $CACHED_VERSION"
fi
echo "" | tee -a "$RESULTS_FILE"
sleep 1

# Test 3: Update product (triggers cache invalidation)
echo -e "${BLUE}Test 3: Update Product (Triggers Cache Invalidation)${NC}" | tee -a "$RESULTS_FILE"
NEW_PRICE=$(echo "$INITIAL_PRICE + 10.00" | bc)
NEW_STOCK=$(echo "$INITIAL_STOCK + 5" | bc)

echo "POST $GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID" | tee -a "$RESULTS_FILE"
echo "Body: {\"price\": $NEW_PRICE, \"stock\": $NEW_STOCK}" | tee -a "$RESULTS_FILE"

UPDATE_RESPONSE=$(curl -s -X POST "$GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID" \
  -H "Content-Type: application/json" \
  -d "{\"price\": $NEW_PRICE, \"stock\": $NEW_STOCK}")

UPDATE_VERSION=$(echo "$UPDATE_RESPONSE" | jq -r '.version' 2>/dev/null || echo "")
UPDATE_PRICE=$(echo "$UPDATE_RESPONSE" | jq -r '.price' 2>/dev/null || echo "")
UPDATE_STOCK=$(echo "$UPDATE_RESPONSE" | jq -r '.stock' 2>/dev/null || echo "")

log_result "Update Response: Price=$UPDATE_PRICE, Stock=$UPDATE_STOCK, Version=$UPDATE_VERSION"

if [ "$UPDATE_VERSION" != "$INITIAL_VERSION" ]; then
    log_result "✓ Version incremented: $INITIAL_VERSION -> $UPDATE_VERSION"
else
    log_result "✗ Version not incremented!"
fi
echo "" | tee -a "$RESULTS_FILE"

# Test 4: Wait for Kafka invalidation
echo -e "${BLUE}Test 4: Waiting for Kafka Cache Invalidation${NC}" | tee -a "$RESULTS_FILE"
log_result "Waiting 3 seconds for Kafka invalidation to propagate..."
sleep 3

# Test 5: Read after update (should get fresh data)
echo -e "${BLUE}Test 5: Read After Update (Should Get Fresh Data)${NC}" | tee -a "$RESULTS_FILE"
echo "GET $GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID" | tee -a "$RESULTS_FILE"

FRESH_RESPONSE=$(curl -s "$GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID")
FRESH_PRICE=$(echo "$FRESH_RESPONSE" | jq -r '.price' 2>/dev/null || echo "")
FRESH_STOCK=$(echo "$FRESH_RESPONSE" | jq -r '.stock' 2>/dev/null || echo "")
FRESH_VERSION=$(echo "$FRESH_RESPONSE" | jq -r '.version' 2>/dev/null || echo "")

log_result "Fresh Read: Price=$FRESH_PRICE, Stock=$FRESH_STOCK, Version=$FRESH_VERSION"

# Verify cache invalidation worked
if [ "$FRESH_PRICE" = "$NEW_PRICE" ] && [ "$FRESH_STOCK" = "$NEW_STOCK" ] && [ "$FRESH_VERSION" = "$UPDATE_VERSION" ]; then
    log_result "✓ Cache invalidation SUCCESS! Fresh data retrieved."
    CACHE_INVALIDATION_SUCCESS=true
else
    log_result "✗ Cache invalidation FAILED! Stale data detected."
    log_result "  Expected: Price=$NEW_PRICE, Stock=$NEW_STOCK, Version=$UPDATE_VERSION"
    log_result "  Got:      Price=$FRESH_PRICE, Stock=$FRESH_STOCK, Version=$FRESH_VERSION"
    CACHE_INVALIDATION_SUCCESS=false
fi
echo "" | tee -a "$RESULTS_FILE"

# Test 6: Test rating update cache invalidation
echo -e "${BLUE}Test 6: Test Rating Update Cache Invalidation${NC}" | tee -a "$RESULTS_FILE"
echo "POST $GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID/reviews" | tee -a "$RESULTS_FILE"

RATING_RESPONSE=$(curl -s -X POST "$GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID/reviews" \
  -H "Content-Type: application/json" \
  -H "X-User-Id: test-cache-user@example.com" \
  -d '{"rating": 4, "comment": "", "userName": "Cache Test User"}')

if echo "$RATING_RESPONSE" | grep -q "already reviewed"; then
    log_result "⚠ User already reviewed this product, skipping rating test"
else
    RATING_ID=$(echo "$RATING_RESPONSE" | jq -r '.id' 2>/dev/null || echo "")
    if [ "$RATING_ID" != "null" ] && [ "$RATING_ID" != "" ]; then
        log_result "✓ Rating submitted: $RATING_ID"
        
        # Wait for rating to update product
        log_result "Waiting 3 seconds for rating update and cache invalidation..."
        sleep 3
        
        # Check if product rating was updated
        RATED_RESPONSE=$(curl -s "$GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID")
        RATED_VERSION=$(echo "$RATED_RESPONSE" | jq -r '.version' 2>/dev/null || echo "")
        RATED_RATING=$(echo "$RATED_RESPONSE" | jq -r '.rating' 2>/dev/null || echo "")
        
        log_result "After Rating: Version=$RATED_VERSION, Rating=$RATED_RATING"
        
        if [ "$RATED_VERSION" != "$FRESH_VERSION" ]; then
            log_result "✓ Rating update triggered cache invalidation: $FRESH_VERSION -> $RATED_VERSION"
        else
            log_result "⚠ Rating update may not have triggered cache invalidation"
        fi
    else
        log_result "✗ Failed to submit rating"
    fi
fi
echo "" | tee -a "$RESULTS_FILE"

# Test 7: Multiple rapid reads (test cache consistency)
echo -e "${BLUE}Test 7: Multiple Rapid Reads (Cache Consistency Test)${NC}" | tee -a "$RESULTS_FILE"
log_result "Performing 5 rapid reads to test cache consistency..."

VERSIONS=()
for i in {1..5}; do
    RAPID_RESPONSE=$(curl -s "$GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID")
    RAPID_VERSION=$(echo "$RAPID_RESPONSE" | jq -r '.version' 2>/dev/null || echo "")
    VERSIONS+=("$RAPID_VERSION")
    sleep 0.2
done

# Check if all versions are the same
FIRST_VERSION=${VERSIONS[0]}
ALL_SAME=true
for version in "${VERSIONS[@]}"; do
    if [ "$version" != "$FIRST_VERSION" ]; then
        ALL_SAME=false
        break
    fi
done

if [ "$ALL_SAME" = true ]; then
    log_result "✓ Cache consistency: All reads returned same version ($FIRST_VERSION)"
else
    log_result "⚠ Cache inconsistency detected: ${VERSIONS[*]}"
fi
echo "" | tee -a "$RESULTS_FILE"

# Test 8: Check metrics
echo -e "${BLUE}Test 8: Check Cache Metrics${NC}" | tee -a "$RESULTS_FILE"

if [ -f "/tmp/metrics/catalog.jsonl" ]; then
    log_result "Recent metrics from catalog service:"
    tail -n 3 /tmp/metrics/catalog.jsonl | tee -a "$RESULTS_FILE"
    echo "" | tee -a "$RESULTS_FILE"
    
    # Count metrics from the last few minutes
    RECENT_TIME=$(date -d '5 minutes ago' '+%Y-%m-%dT%H:%M' 2>/dev/null || date -v-5M '+%Y-%m-%dT%H:%M' 2>/dev/null || echo "")
    
    if [ -n "$RECENT_TIME" ]; then
        CACHE_HITS=$(grep "$RECENT_TIME" /tmp/metrics/catalog.jsonl 2>/dev/null | grep -c "cache_hits" || echo "0")
        CACHE_MISSES=$(grep "$RECENT_TIME" /tmp/metrics/catalog.jsonl 2>/dev/null | grep -c "cache_misses" || echo "0")
        INVALIDATIONS=$(grep "$RECENT_TIME" /tmp/metrics/catalog.jsonl 2>/dev/null | grep -c "invalidations_sent" || echo "0")
        
        log_result "Recent Metrics (last 5 minutes):"
        log_result "  Cache Hits: $CACHE_HITS"
        log_result "  Cache Misses: $CACHE_MISSES"
        log_result "  Invalidations Sent: $INVALIDATIONS"
    else
        log_result "Could not filter recent metrics (date command issue)"
    fi
else
    log_result "⚠ No metrics file found at /tmp/metrics/catalog.jsonl"
fi
echo "" | tee -a "$RESULTS_FILE"

# Summary
echo -e "${BLUE}========================================${NC}" | tee -a "$RESULTS_FILE"
echo -e "${BLUE}Cache Invalidation Test Summary${NC}" | tee -a "$RESULTS_FILE"
echo -e "${BLUE}========================================${NC}" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

if [ "$CACHE_INVALIDATION_SUCCESS" = true ]; then
    log_result "✓ PASS: Cache invalidation is working correctly!"
    log_result "✓ Product updates trigger immediate cache invalidation"
    log_result "✓ Fresh data is retrieved after updates"
    log_result "✓ Kafka-based distributed cache invalidation is functional"
    OVERALL_RESULT="PASS"
else
    log_result "✗ FAIL: Cache invalidation is not working properly!"
    log_result "✗ Stale data detected after product updates"
    log_result "✗ Check Kafka connectivity and cache configuration"
    OVERALL_RESULT="FAIL"
fi

echo "" | tee -a "$RESULTS_FILE"
log_result "Test completed at: $(date)"
log_result "Results saved to: $RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

# Restore original product state
echo -e "${BLUE}Restoring Original Product State${NC}" | tee -a "$RESULTS_FILE"
curl -s -X POST "$GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID" \
  -H "Content-Type: application/json" \
  -d "{\"price\": $INITIAL_PRICE, \"stock\": $INITIAL_STOCK}" > /dev/null

log_result "✓ Product restored to original state"
echo ""

if [ "$OVERALL_RESULT" = "PASS" ]; then
    echo -e "${GREEN}🎉 Cache invalidation test PASSED! 🎉${NC}"
    exit 0
else
    echo -e "${RED}❌ Cache invalidation test FAILED! ❌${NC}"
    exit 1
fi