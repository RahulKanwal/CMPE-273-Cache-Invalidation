#!/bin/bash

# Simple scenario test without k6 - just switches cache modes and tests basic functionality

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CATALOG_SERVICE_DIR="$SCRIPT_DIR/../catalog-service"
CATALOG_SERVICE_PORT=8081

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EDS-Lite: Simple Scenario Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to check if a service is running
check_service() {
    local port=$1
    local service_name=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $service_name is running on port $port"
        return 0
    else
        echo -e "${RED}✗${NC} $service_name is NOT running on port $port"
        return 1
    fi
}

# Function to stop catalog service
stop_catalog_service() {
    echo -e "${YELLOW}Stopping catalog-service...${NC}"
    if lsof -ti:$CATALOG_SERVICE_PORT >/dev/null 2>&1; then
        lsof -ti:$CATALOG_SERVICE_PORT | xargs kill -9 2>/dev/null || true
        sleep 3
        echo -e "${GREEN}✓${NC} Catalog service stopped"
    else
        echo -e "${YELLOW}Catalog service was not running${NC}"
    fi
}

# Function to start catalog service
start_catalog_service() {
    local cache_mode=$1
    echo -e "${YELLOW}Starting catalog-service with CACHE_MODE=$cache_mode...${NC}"
    
    local original_dir=$(pwd)
    cd "$CATALOG_SERVICE_DIR"
    export CACHE_MODE=$cache_mode
    
    mvn spring-boot:run > /tmp/catalog-$cache_mode.log 2>&1 &
    local pid=$!
    cd "$original_dir"
    
    echo -e "${YELLOW}Waiting for service to start...${NC}"
    for i in {1..60}; do
        if lsof -Pi :$CATALOG_SERVICE_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Catalog service started (PID: $pid)"
            sleep 5
            return 0
        fi
        sleep 1
    done
    
    echo -e "${RED}✗${NC} Failed to start catalog service"
    return 1
}

# Function to test API
test_api() {
    local scenario=$1
    echo -e "${YELLOW}Testing API for Scenario $scenario...${NC}"
    
    # Test GET
    echo "Testing GET /api/catalog/products/1"
    if curl -s -f "http://localhost:8080/api/catalog/products/1" > /dev/null; then
        echo -e "${GREEN}✓${NC} GET request successful"
    else
        echo -e "${RED}✗${NC} GET request failed"
        return 1
    fi
    
    # Test POST (update)
    echo "Testing POST /api/catalog/products/1"
    if curl -s -f -X POST "http://localhost:8080/api/catalog/products/1" \
        -H "Content-Type: application/json" \
        -d '{"price": 99.99, "stock": 50}' > /dev/null; then
        echo -e "${GREEN}✓${NC} POST request successful"
    else
        echo -e "${RED}✗${NC} POST request failed"
        return 1
    fi
    
    echo -e "${GREEN}✓${NC} API tests passed for Scenario $scenario"
}

# Check prerequisites
echo "Checking prerequisites..."
all_services_running=true

if ! check_service 8080 "API Gateway"; then
    all_services_running=false
fi

if ! check_service 8082 "Order Service"; then
    all_services_running=false
fi

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
    echo ""
    echo -e "${RED}ERROR: Not all required services are running!${NC}"
    echo ""
    echo "Please start the missing services first."
    exit 1
fi

echo ""
echo -e "${GREEN}✓ All prerequisite services are running!${NC}"

# Clear old metrics
rm -rf /tmp/metrics
mkdir -p /tmp/metrics

# Test Scenario A
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Scenario A: No Cache${NC}"
echo -e "${BLUE}========================================${NC}"
stop_catalog_service
start_catalog_service "none"
test_api "A"
echo "Scenario A metrics will be in /tmp/metrics/catalog.jsonl"
echo "Let it run for 30 seconds to collect metrics..."
sleep 30

# Test Scenario B
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Scenario B: TTL Only${NC}"
echo -e "${BLUE}========================================${NC}"
stop_catalog_service
rm -rf /tmp/metrics && mkdir -p /tmp/metrics
start_catalog_service "ttl"
test_api "B"
echo "Scenario B metrics will be in /tmp/metrics/catalog.jsonl"
echo "Let it run for 30 seconds to collect metrics..."
sleep 30

# Test Scenario C
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Scenario C: TTL + Invalidation${NC}"
echo -e "${BLUE}========================================${NC}"
stop_catalog_service
rm -rf /tmp/metrics && mkdir -p /tmp/metrics
start_catalog_service "ttl_invalidate"
test_api "C"
echo "Scenario C metrics will be in /tmp/metrics/catalog.jsonl"
echo "Let it run for 30 seconds to collect metrics..."
sleep 30

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All scenarios tested successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "To analyze metrics from the last scenario (C):"
echo "  python3 scripts/summarize-metrics.py"
echo ""
echo "To see raw metrics:"
echo "  cat /tmp/metrics/catalog.jsonl | tail -20"
echo ""