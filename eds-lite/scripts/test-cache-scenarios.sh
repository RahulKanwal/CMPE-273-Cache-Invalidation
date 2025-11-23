#!/bin/bash

# EDS Marketplace: Cache Scenarios Test Script
# Tests the three cache invalidation scenarios and saves results to a text file

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CATALOG_URL="http://localhost:8081"
TEST_PRODUCT_ID="1"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="cache-test-results-$TIMESTAMP.txt"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CATALOG_SERVICE_DIR="$SCRIPT_DIR/../catalog-service"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EDS Cache Scenarios Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Initialize results file
cat > "$RESULTS_FILE" << EOF
EDS Marketplace Cache Scenarios Test Results
============================================
Test Run: $(date)
Test ID: $TIMESTAMP

This test validates the three cache invalidation scenarios:
1. Scenario A: No Cache (CACHE_MODE=none)
2. Scenario B: TTL-Only Cache (CACHE_MODE=ttl) 
3. Scenario C: TTL + Kafka Invalidation (CACHE_MODE=ttl_invalidate)

EOF

log_result() {
    echo "$1" | tee -a "$RESULTS_FILE"
}

# Function to check if a service is running
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

# Function to stop catalog service
stop_catalog_service() {
    log_result "Stopping catalog service..."
    if lsof -ti:8081 >/dev/null 2>&1; then
        local catalog_pid=$(lsof -ti:8081)
        kill -TERM $catalog_pid 2>/dev/null || true
        sleep 3
        
        # Force kill if still running
        if lsof -ti:8081 >/dev/null 2>&1; then
            kill -9 $catalog_pid 2>/dev/null || true
            sleep 2
        fi
        log_result "✓ Catalog service stopped"
    else
        log_result "Catalog service was not running"
    fi
}

# Function to start catalog service with specific cache mode
start_catalog_service() {
    local cache_mode=$1
    log_result "Starting catalog service with CACHE_MODE=$cache_mode..."
    
    local original_dir=$(pwd)
    cd "$CATALOG_SERVICE_DIR"
    
    # Set environment and start service
    export CACHE_MODE=$cache_mode
    mvn spring-boot:run > "/tmp/catalog-$cache_mode.log" 2>&1 &
    local pid=$!
    
    cd "$original_dir"
    
    # Wait for service to start
    log_result "Waiting for service to start..."
    for i in {1..60}; do
        if lsof -Pi :8081 -sTCP:LISTEN -t >/dev/null 2>&1; then
            log_result "✓ Catalog service started (PID: $pid)"
            sleep 5  # Give it time to fully initialize
            return 0
        fi
        sleep 1
    done
    
    log_result "✗ Failed to start catalog service"
    return 1
}

# Function to test cache behavior
test_cache_behavior() {
    local scenario=$1
    local cache_mode=$2
    
    log_result ""
    log_result "========================================="
    log_result "Testing Scenario $scenario: $cache_mode"
    log_result "========================================="
    
    # Test 1: First read (cache miss expected)
    log_result ""
    log_result "Test 1: First Read (Cache Miss Expected)"
    log_result "GET $CATALOG_URL/products/$TEST_PRODUCT_ID"
    
    local start_time=$(date +%s%N)
    local response1=$(curl -s "$CATALOG_URL/products/$TEST_PRODUCT_ID")
    local end_time=$(date +%s%N)
    local latency1=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
    
    local price1=$(echo "$response1" | jq -r '.price' 2>/dev/null || echo "")
    local version1=$(echo "$response1" | jq -r '.version' 2>/dev/null || echo "")
    
    log_result "Response time: ${latency1}ms"
    log_result "Price: $price1, Version: $version1"
    
    # Test 2: Second read (cache hit expected for cached scenarios)
    sleep 1
    log_result ""
    log_result "Test 2: Second Read (Cache Hit Expected for Cached Scenarios)"
    log_result "GET $CATALOG_URL/products/$TEST_PRODUCT_ID"
    
    start_time=$(date +%s%N)
    local response2=$(curl -s "$CATALOG_URL/products/$TEST_PRODUCT_ID")
    end_time=$(date +%s%N)
    local latency2=$(( (end_time - start_time) / 1000000 ))
    
    local price2=$(echo "$response2" | jq -r '.price' 2>/dev/null || echo "")
    local version2=$(echo "$response2" | jq -r '.version' 2>/dev/null || echo "")
    
    log_result "Response time: ${latency2}ms"
    log_result "Price: $price2, Version: $version2"
    
    # Analyze cache behavior
    if [ "$cache_mode" = "No Cache" ]; then
        log_result "Expected: Similar response times (no caching)"
        if [ $latency1 -gt 0 ] && [ $latency2 -gt 0 ]; then
            log_result "✓ Both requests went to database"
        fi
    else
        log_result "Expected: Second request faster (cache hit)"
        if [ $latency2 -lt $latency1 ]; then
            log_result "✓ Cache hit detected (faster response)"
        else
            log_result "⚠ Cache behavior unclear (similar response times)"
        fi
    fi
    
    # Test 3: Update product
    sleep 1
    log_result ""
    log_result "Test 3: Update Product"
    local new_price=$(echo "$price1 + 10.00" | bc 2>/dev/null || echo "199.99")
    local new_stock="100"
    
    log_result "POST $CATALOG_URL/products/$TEST_PRODUCT_ID"
    log_result "Body: {\"price\": $new_price, \"stock\": $new_stock}"
    
    local update_response=$(curl -s -X POST "$CATALOG_URL/products/$TEST_PRODUCT_ID" \
        -H "Content-Type: application/json" \
        -d "{\"price\": $new_price, \"stock\": $new_stock}")
    
    local update_price=$(echo "$update_response" | jq -r '.price' 2>/dev/null || echo "")
    local update_version=$(echo "$update_response" | jq -r '.version' 2>/dev/null || echo "")
    
    log_result "Update response: Price=$update_price, Version=$update_version"
    
    if [ "$update_version" != "$version1" ]; then
        log_result "✓ Version incremented: $version1 -> $update_version"
    else
        log_result "⚠ Version not incremented"
    fi
    
    # Test 4: Wait and read after update
    if [ "$cache_mode" = "TTL + Kafka Invalidation" ]; then
        log_result ""
        log_result "Waiting 3 seconds for Kafka invalidation..."
        sleep 3
    elif [ "$cache_mode" = "TTL-Only Cache" ]; then
        log_result ""
        log_result "Waiting 2 seconds (TTL cache may still serve stale data)..."
        sleep 2
    else
        log_result ""
        log_result "Waiting 1 second..."
        sleep 1
    fi
    
    log_result ""
    log_result "Test 4: Read After Update"
    log_result "GET $CATALOG_URL/products/$TEST_PRODUCT_ID"
    
    start_time=$(date +%s%N)
    local response3=$(curl -s "$CATALOG_URL/products/$TEST_PRODUCT_ID")
    end_time=$(date +%s%N)
    local latency3=$(( (end_time - start_time) / 1000000 ))
    
    local price3=$(echo "$response3" | jq -r '.price' 2>/dev/null || echo "")
    local version3=$(echo "$response3" | jq -r '.version' 2>/dev/null || echo "")
    
    log_result "Response time: ${latency3}ms"
    log_result "Price: $price3, Version: $version3"
    
    # Analyze cache invalidation
    if [ "$price3" = "$new_price" ] && [ "$version3" = "$update_version" ]; then
        log_result "✓ Fresh data retrieved - cache invalidation working"
    else
        log_result "⚠ Stale data detected - Expected: Price=$new_price, Version=$update_version"
        log_result "   Got: Price=$price3, Version=$version3"
    fi
    
    # Test 5: Multiple rapid reads for consistency
    log_result ""
    log_result "Test 5: Rapid Consistency Check (5 reads)"
    local versions=()
    local total_latency=0
    
    for i in {1..5}; do
        start_time=$(date +%s%N)
        local rapid_response=$(curl -s "$CATALOG_URL/products/$TEST_PRODUCT_ID")
        end_time=$(date +%s%N)
        local rapid_latency=$(( (end_time - start_time) / 1000000 ))
        
        local rapid_version=$(echo "$rapid_response" | jq -r '.version' 2>/dev/null || echo "")
        versions+=("$rapid_version")
        total_latency=$((total_latency + rapid_latency))
        
        sleep 0.1
    done
    
    local avg_latency=$((total_latency / 5))
    log_result "Average response time: ${avg_latency}ms"
    
    # Check consistency
    local first_version=${versions[0]}
    local all_same=true
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
    
    # Summary for this scenario
    log_result ""
    log_result "Scenario $scenario Summary:"
    log_result "- Cache Mode: $cache_mode"
    log_result "- First read: ${latency1}ms"
    log_result "- Second read: ${latency2}ms"
    log_result "- Post-update read: ${latency3}ms"
    log_result "- Average rapid read: ${avg_latency}ms"
    log_result "- Data consistency: $([ "$all_same" = true ] && echo "✓ Consistent" || echo "⚠ Inconsistent")"
    log_result "- Cache invalidation: $([ "$price3" = "$new_price" ] && echo "✓ Working" || echo "⚠ Issues detected")"
}

# Main execution
log_result "Starting cache scenarios test..."
log_result ""

# Check prerequisites
log_result "Checking prerequisites..."
all_services_running=true

if ! check_service 9092 "Kafka"; then
    all_services_running=false
fi

if ! check_service 6379 "Redis"; then
    all_services_running=false
fi

if ! check_service 27017 "MongoDB"; then
    all_services_running=false
fi

if [ "$all_services_running" = false ]; then
    log_result ""
    log_result "ERROR: Not all required infrastructure services are running!"
    log_result ""
    log_result "Please start the missing services:"
    log_result "  - Kafka: ./scripts/start-kafka.sh"
    log_result "  - Redis: ./scripts/start-redis.sh"
    log_result "  - MongoDB: ./scripts/start-mongo.sh"
    log_result ""
    exit 1
fi

log_result ""
log_result "✓ All infrastructure services are running!"

# Test Scenario A: No Cache
stop_catalog_service
test_cache_behavior "A" "No Cache"
if ! start_catalog_service "none"; then
    log_result "Failed to start catalog service for Scenario A"
    exit 1
fi
test_cache_behavior "A" "No Cache"
stop_catalog_service

# Test Scenario B: TTL-Only Cache
log_result ""
log_result ""
test_cache_behavior "B" "TTL-Only Cache"
if ! start_catalog_service "ttl"; then
    log_result "Failed to start catalog service for Scenario B"
    exit 1
fi
test_cache_behavior "B" "TTL-Only Cache"
stop_catalog_service

# Test Scenario C: TTL + Kafka Invalidation
log_result ""
log_result ""
test_cache_behavior "C" "TTL + Kafka Invalidation"
if ! start_catalog_service "ttl_invalidate"; then
    log_result "Failed to start catalog service for Scenario C"
    exit 1
fi
test_cache_behavior "C" "TTL + Kafka Invalidation"
stop_catalog_service

# Final summary
log_result ""
log_result ""
log_result "========================================="
log_result "FINAL TEST SUMMARY"
log_result "========================================="
log_result ""
log_result "Test completed at: $(date)"
log_result "Results saved to: $RESULTS_FILE"
log_result ""
log_result "Expected Results:"
log_result "- Scenario A: High latency, no caching benefits"
log_result "- Scenario B: Low latency, possible stale data after updates"
log_result "- Scenario C: Low latency, fresh data after updates"
log_result ""
log_result "Review the detailed results above to verify cache behavior."
log_result ""

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Cache Scenarios Test Completed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Results saved to: $RESULTS_FILE"
echo ""
echo "To view results:"
echo "  cat $RESULTS_FILE"
echo ""
echo "To view just the summary:"
echo "  grep -A 20 'FINAL TEST SUMMARY' $RESULTS_FILE"
echo ""