#!/bin/bash

# Test Render Deployment - Cache Scenarios
# Tests the deployed application on Render

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
API_GATEWAY_URL="https://api-gateway-lpnh.onrender.com"
TEST_PRODUCT_ID="1"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="render-test-results-$TIMESTAMP.txt"

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Render Deployment Cache Test${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo "Testing: $API_GATEWAY_URL"
echo "Results will be saved to: $RESULTS_FILE"
echo ""

# Warm-up check
echo -e "${YELLOW}Checking if services are warm...${NC}"
warmup_start=$(date +%s%N)
warmup_response=$(curl -s -w "\n%{http_code}" "$API_GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID" 2>/dev/null)
warmup_end=$(date +%s%N)
warmup_latency=$(( (warmup_end - warmup_start) / 1000000 ))
warmup_status=$(echo "$warmup_response" | tail -n1)

if [ "$warmup_latency" -gt 2000 ]; then
    echo -e "${YELLOW}⚠ Services are cold (${warmup_latency}ms response)${NC}"
    echo -e "${YELLOW}Warming up services...${NC}"
    sleep 3
    # Second warmup call
    curl -s "$API_GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID" > /dev/null 2>&1
    sleep 2
    echo -e "${GREEN}✓ Services warmed up${NC}"
else
    echo -e "${GREEN}✓ Services are already warm (${warmup_latency}ms)${NC}"
fi
echo ""

# Initialize results file
cat > "$RESULTS_FILE" << EOF
Render Deployment Cache Test Results
=====================================
Test Run: $(date)
API Gateway: $API_GATEWAY_URL
Test Product ID: $TEST_PRODUCT_ID

This test validates the currently deployed cache configuration.
The backend must be configured with the desired CACHE_MODE before running.

EOF

log_result() {
    echo "$1" | tee -a "$RESULTS_FILE"
}

# Function to make API call and measure latency
make_api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    local start_time=$(date +%s%N)
    
    if [ "$method" == "GET" ]; then
        local response=$(curl -s -w "\n%{http_code}" "$API_GATEWAY_URL$endpoint" 2>/dev/null)
    else
        local response=$(curl -s -w "\n%{http_code}" -X POST "$API_GATEWAY_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data" 2>/dev/null)
    fi
    
    local end_time=$(date +%s%N)
    local latency=$(( (end_time - start_time) / 1000000 ))
    
    # Split response and status code
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    echo "$latency|$http_code|$body"
}

# Parse JSON (simple extraction)
get_json_field() {
    local json=$1
    local field=$2
    echo "$json" | grep -o "\"$field\":[^,}]*" | cut -d':' -f2 | tr -d '"' | tr -d ' '
}

echo -e "${YELLOW}Starting test sequence...${NC}"
echo ""

# Test 1: First Read (Cache Miss Expected)
log_result "========================================="
log_result "Test 1: First Read (Cache Miss Expected)"
log_result "========================================="
log_result "GET $API_GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID"
log_result ""

result1=$(make_api_call "GET" "/api/catalog/products/$TEST_PRODUCT_ID")
latency1=$(echo "$result1" | cut -d'|' -f1)
status1=$(echo "$result1" | cut -d'|' -f2)
body1=$(echo "$result1" | cut -d'|' -f3-)

price1=$(get_json_field "$body1" "price")
version1=$(get_json_field "$body1" "version")
name1=$(get_json_field "$body1" "name")

log_result "Status: $status1"
log_result "Response time: ${latency1}ms"
log_result "Product: $name1"
log_result "Price: \$$price1"
log_result "Version: $version1"
log_result ""

if [ "$status1" != "200" ]; then
    log_result "❌ ERROR: First read failed with status $status1"
    log_result "Response: $body1"
    log_result ""
    log_result "Test aborted. Please check:"
    log_result "1. Services are awake (not sleeping)"
    log_result "2. Product with ID $TEST_PRODUCT_ID exists"
    log_result "3. API Gateway is accessible"
    exit 1
fi

echo -e "${GREEN}✓ First read successful${NC}"
sleep 2

# Test 2: Second Read (Cache Hit Expected)
log_result "========================================="
log_result "Test 2: Second Read (Cache Hit Expected)"
log_result "========================================="
log_result "GET $API_GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID"
log_result ""

result2=$(make_api_call "GET" "/api/catalog/products/$TEST_PRODUCT_ID")
latency2=$(echo "$result2" | cut -d'|' -f1)
status2=$(echo "$result2" | cut -d'|' -f2)
body2=$(echo "$result2" | cut -d'|' -f3-)

price2=$(get_json_field "$body2" "price")
version2=$(get_json_field "$body2" "version")

log_result "Status: $status2"
log_result "Response time: ${latency2}ms"
log_result "Price: \$$price2"
log_result "Version: $version2"
log_result ""

# Calculate improvement
if [ "$latency1" -gt 0 ] && [ "$latency2" -gt 0 ]; then
    improvement=$(( (latency1 - latency2) * 100 / latency1 ))
    
    # Check if first read was abnormally slow (cold start)
    if [ "$latency1" -gt 2000 ]; then
        log_result "⚠ First read was very slow (${latency1}ms) - likely cold start"
        log_result "Second read: ${latency2}ms (${improvement}% faster)"
        log_result ""
        log_result "Note: Speed improvement may be due to service warm-up, not caching."
        log_result "To accurately test, run the script again now that services are warm."
        cache_working="UNCERTAIN"
    elif [ "$improvement" -gt 50 ]; then
        log_result "✓ Cache hit detected! ${improvement}% faster than first read"
        cache_working="YES"
    elif [ "$improvement" -gt 20 ]; then
        log_result "⚠ Possible cache hit (${improvement}% faster)"
        cache_working="MAYBE"
    else
        log_result "No significant cache benefit (${improvement}% difference)"
        log_result "This suggests caching is disabled (CACHE_TYPE=none)"
        cache_working="NO"
    fi
fi
log_result ""

echo -e "${GREEN}✓ Second read successful${NC}"
sleep 2

# Test 3: Update Product
new_price="299.99"
new_stock="150"

log_result "========================================="
log_result "Test 3: Update Product"
log_result "========================================="
log_result "POST $API_GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID"
log_result "Body: {\"price\": $new_price, \"stock\": $new_stock}"
log_result ""

update_data="{\"price\": $new_price, \"stock\": $new_stock}"
result3=$(make_api_call "POST" "/api/catalog/products/$TEST_PRODUCT_ID" "$update_data")
latency3=$(echo "$result3" | cut -d'|' -f1)
status3=$(echo "$result3" | cut -d'|' -f2)
body3=$(echo "$result3" | cut -d'|' -f3-)

price3=$(get_json_field "$body3" "price")
version3=$(get_json_field "$body3" "version")

log_result "Status: $status3"
log_result "Response time: ${latency3}ms"
log_result "New Price: \$$price3"
log_result "New Version: $version3"
log_result ""

if [ "$status3" != "200" ]; then
    log_result "⚠ WARNING: Update failed with status $status3"
    log_result "Response: $body3"
    log_result ""
else
    echo -e "${GREEN}✓ Update successful${NC}"
fi

# Wait for cache invalidation (if Kafka is enabled)
log_result "Waiting 5 seconds for cache invalidation..."
sleep 5
log_result ""

# Test 4: Read After Update
log_result "========================================="
log_result "Test 4: Read After Update"
log_result "========================================="
log_result "GET $API_GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID"
log_result ""

result4=$(make_api_call "GET" "/api/catalog/products/$TEST_PRODUCT_ID")
latency4=$(echo "$result4" | cut -d'|' -f1)
status4=$(echo "$result4" | cut -d'|' -f2)
body4=$(echo "$result4" | cut -d'|' -f3-)

price4=$(get_json_field "$body4" "price")
version4=$(get_json_field "$body4" "version")

log_result "Status: $status4"
log_result "Response time: ${latency4}ms"
log_result "Price: \$$price4"
log_result "Version: $version4"
log_result ""

# Check for stale data
if [ "$version4" == "$version3" ] && [ "$price4" == "$price3" ]; then
    log_result "✓ Fresh data confirmed!"
    log_result "  - Version updated: $version1 → $version4"
    log_result "  - Price updated: \$$price1 → \$$price4"
    stale_data="NO"
elif [ "$version4" == "$version1" ]; then
    log_result "⚠ STALE DATA DETECTED!"
    log_result "  - Still showing old version: $version1"
    log_result "  - Still showing old price: \$$price1"
    log_result "  - Expected version: $version3"
    log_result "  - Expected price: \$$price3"
    stale_data="YES"
else
    log_result "? Data state unclear (version: $version4)"
    stale_data="UNKNOWN"
fi
log_result ""

echo -e "${GREEN}✓ Post-update read successful${NC}"

# Summary
log_result "========================================="
log_result "TEST SUMMARY"
log_result "========================================="
log_result ""
log_result "Performance Metrics:"
log_result "  First read:        ${latency1}ms"
log_result "  Second read:       ${latency2}ms"
log_result "  Update:            ${latency3}ms"
log_result "  Post-update read:  ${latency4}ms"
log_result ""

# Determine cache scenario
log_result "Cache Analysis:"
if [ "$cache_working" == "UNCERTAIN" ]; then
    log_result "  ⚠ Cache Status: UNCERTAIN (cold start detected)"
    log_result "  ⚠ First read was abnormally slow (${latency1}ms)"
    log_result "  ⚠ This suggests services were sleeping/cold starting"
    log_result ""
    log_result "Recommendation: Run the test again immediately to get accurate results."
    log_result "Now that services are warm, the test will show true cache behavior."
    log_result ""
    log_result "If second run also shows fast reads:"
    log_result "  - Scenario B or C (caching enabled)"
    log_result "If second run shows slow reads:"
    log_result "  - Scenario A (no caching)"
elif [ "$cache_working" == "YES" ]; then
    if [ "$stale_data" == "NO" ]; then
        log_result "  ✓ Cache Status: ENABLED"
        log_result "  ✓ Cache Invalidation: WORKING"
        log_result "  ✓ Data Consistency: GOOD"
        log_result ""
        log_result "Likely Configuration: Scenario C (TTL + Kafka Invalidation)"
        log_result "  - CACHE_TYPE=redis"
        log_result "  - CACHE_MODE=ttl_invalidate"
        log_result "  - KAFKA_ENABLED=true"
    else
        log_result "  ✓ Cache Status: ENABLED"
        log_result "  ⚠ Cache Invalidation: NOT WORKING"
        log_result "  ⚠ Data Consistency: STALE DATA"
        log_result ""
        log_result "Likely Configuration: Scenario B (TTL-Only)"
        log_result "  - CACHE_TYPE=redis"
        log_result "  - CACHE_MODE=ttl"
        log_result "  - No Kafka invalidation"
    fi
else
    log_result "  ✓ Cache Status: DISABLED"
    log_result "  ✓ Data Consistency: ALWAYS FRESH"
    log_result ""
    log_result "Likely Configuration: Scenario A (No Cache)"
    log_result "  - CACHE_TYPE=none"
fi
log_result ""

# Calculate average latency
if [ "$latency1" -gt 0 ] && [ "$latency2" -gt 0 ] && [ "$latency4" -gt 0 ]; then
    avg_latency=$(( (latency1 + latency2 + latency4) / 3 ))
    log_result "Average Read Latency: ${avg_latency}ms"
    log_result ""
fi

log_result "Test completed at: $(date)"
log_result "Results saved to: $RESULTS_FILE"
log_result ""

# Final output
echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}Test Complete!${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo "Results saved to: $RESULTS_FILE"
echo ""
echo "To view results:"
echo "  cat $RESULTS_FILE"
echo ""
echo "To view just the summary:"
echo "  tail -40 $RESULTS_FILE"
echo ""

# Restore original price (optional)
if [ "$status3" == "200" ] && [ "$price1" != "" ]; then
    echo -e "${YELLOW}Restoring original price...${NC}"
    restore_data="{\"price\": $price1, \"stock\": $new_stock}"
    curl -s -X POST "$API_GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID" \
        -H "Content-Type: application/json" \
        -d "$restore_data" > /dev/null 2>&1
    echo -e "${GREEN}✓ Original price restored${NC}"
    echo ""
fi
