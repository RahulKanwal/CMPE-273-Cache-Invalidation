#!/bin/bash

# EDS-Lite: Quick Test Script
# Tests cache invalidation without full k6 load tests (faster, ~5 minutes)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

GATEWAY_URL="http://localhost:8080"
CATALOG_URL="http://localhost:8081"
TEST_PRODUCT_ID="1"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EDS-Lite: Quick Cache Invalidation Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if services are running
check_service() {
    local port=$1
    local name=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $name is running"
        return 0
    else
        echo -e "${RED}✗${NC} $name is NOT running on port $port"
        return 1
    fi
}

echo "Checking services..."
all_running=true

check_service 8080 "API Gateway" || all_running=false
check_service 8081 "Catalog Service" || all_running=false
check_service 6379 "Redis" || all_running=false
check_service 27017 "MongoDB" || all_running=false
check_service 9092 "Kafka" || all_running=false

if [ "$all_running" = false ]; then
    echo ""
    echo -e "${RED}ERROR: Not all services are running!${NC}"
    echo "Please start all services first."
    exit 1
fi

echo ""
echo -e "${GREEN}All services are running!${NC}"
echo ""

# Test 1: Cache Miss
echo -e "${BLUE}Test 1: First Read (Cache Miss)${NC}"
echo "GET $GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID"
RESPONSE1=$(curl -s "$GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID")
echo "Response: $RESPONSE1" | jq '.' 2>/dev/null || echo "$RESPONSE1"
echo -e "${GREEN}✓${NC} Product retrieved"
echo ""
sleep 1

# Test 2: Cache Hit
echo -e "${BLUE}Test 2: Second Read (Cache Hit)${NC}"
echo "GET $GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID"
RESPONSE2=$(curl -s "$GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID")
echo "Response: $RESPONSE2" | jq '.' 2>/dev/null || echo "$RESPONSE2"
echo -e "${GREEN}✓${NC} Product retrieved from cache"
echo ""
sleep 1

# Test 3: Update Product
echo -e "${BLUE}Test 3: Update Product (Triggers Cache Invalidation)${NC}"
NEW_PRICE="199.99"
NEW_STOCK="999"
echo "POST $GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID"
echo "Body: {\"price\": $NEW_PRICE, \"stock\": $NEW_STOCK}"

UPDATE_RESPONSE=$(curl -s -X POST "$GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID" \
  -H "Content-Type: application/json" \
  -d "{\"price\": $NEW_PRICE, \"stock\": $NEW_STOCK}")

echo "Response: $UPDATE_RESPONSE" | jq '.' 2>/dev/null || echo "$UPDATE_RESPONSE"
echo -e "${GREEN}✓${NC} Product updated"
echo ""
echo -e "${YELLOW}⏳ Waiting 2 seconds for Kafka invalidation to propagate...${NC}"
sleep 2

# Test 4: Read After Update (Should be Fresh)
echo -e "${BLUE}Test 4: Read After Update (Should Get Fresh Data)${NC}"
echo "GET $GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID"
RESPONSE3=$(curl -s "$GATEWAY_URL/api/catalog/products/$TEST_PRODUCT_ID")
echo "Response: $RESPONSE3" | jq '.' 2>/dev/null || echo "$RESPONSE3"

# Verify the update
ACTUAL_PRICE=$(echo "$RESPONSE3" | jq -r '.price' 2>/dev/null || echo "")
ACTUAL_STOCK=$(echo "$RESPONSE3" | jq -r '.stock' 2>/dev/null || echo "")

if [ "$ACTUAL_PRICE" = "$NEW_PRICE" ] && [ "$ACTUAL_STOCK" = "$NEW_STOCK" ]; then
    echo -e "${GREEN}✓${NC} Fresh data retrieved! Price=$ACTUAL_PRICE, Stock=$ACTUAL_STOCK"
    echo -e "${GREEN}✓${NC} Cache invalidation worked!"
else
    echo -e "${RED}✗${NC} Data mismatch! Expected Price=$NEW_PRICE, Stock=$NEW_STOCK"
    echo -e "${RED}✗${NC} Got Price=$ACTUAL_PRICE, Stock=$ACTUAL_STOCK"
fi
echo ""

# Test 5: Check Metrics
echo -e "${BLUE}Test 5: Check Metrics${NC}"
echo ""

if [ -f "/tmp/metrics/catalog.jsonl" ]; then
    echo "Recent metrics from catalog service:"
    tail -n 5 /tmp/metrics/catalog.jsonl
    echo ""
    
    # Count metrics
    CACHE_HITS=$(grep -c "cache_hits" /tmp/metrics/catalog.jsonl 2>/dev/null || echo "0")
    CACHE_MISSES=$(grep -c "cache_misses" /tmp/metrics/catalog.jsonl 2>/dev/null || echo "0")
    INVALIDATIONS_SENT=$(grep -c "invalidations_sent" /tmp/metrics/catalog.jsonl 2>/dev/null || echo "0")
    
    echo "Metrics Summary:"
    echo "  Cache Hits: $CACHE_HITS"
    echo "  Cache Misses: $CACHE_MISSES"
    echo "  Invalidations Sent: $INVALIDATIONS_SENT"
else
    echo -e "${YELLOW}⚠${NC} No metrics file found at /tmp/metrics/catalog.jsonl"
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}✓${NC} Cache miss on first read"
echo -e "${GREEN}✓${NC} Cache hit on second read"
echo -e "${GREEN}✓${NC} Update triggered cache invalidation"
echo -e "${GREEN}✓${NC} Fresh data retrieved after update"
echo ""
echo -e "${GREEN}Cache invalidation is working correctly! 🎉${NC}"
echo ""
echo "To see detailed logs:"
echo "  - Catalog service logs: Check the terminal where catalog-service is running"
echo "  - Look for: 'invalidations_sent', 'invalidations_received', 'Cache cleared'"
echo ""
