#!/bin/bash

# Manual scenario runner - you manage the services, script just runs tests
# This avoids the service management issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EDS-Lite: Manual Scenario Test Runner${NC}"
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

# Function to test API connectivity
test_connectivity() {
    echo -e "${YELLOW}Testing API connectivity...${NC}"
    if curl -s -f "http://localhost:8080/api/catalog/products/1" > /dev/null; then
        echo -e "${GREEN}✓${NC} API Gateway responding"
        return 0
    else
        echo -e "${RED}✗${NC} API Gateway not responding"
        return 1
    fi
}

# Function to run k6 test
run_k6_test() {
    local scenario=$1
    local script_name=$2
    
    echo -e "${YELLOW}Running k6 test for Scenario $scenario...${NC}"
    
    local script="$SCRIPT_DIR/$script_name"
    
    if [ ! -f "$script" ]; then
        echo -e "${RED}✗${NC} k6 script not found: $script"
        return 1
    fi
    
    cd "$SCRIPT_DIR"
    bash "$script_name"
    
    echo -e "${GREEN}✓${NC} k6 test completed for Scenario $scenario"
}

# Function to backup metrics
backup_metrics() {
    local scenario=$1
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local results_dir="/tmp/eds-results/$timestamp"
    
    echo -e "${YELLOW}Backing up metrics for Scenario $scenario...${NC}"
    
    mkdir -p "$results_dir"
    
    if [ -d "/tmp/metrics" ]; then
        cp -r "/tmp/metrics" "$results_dir/scenario-$scenario-metrics"
        echo -e "${GREEN}✓${NC} Metrics backed up to $results_dir/scenario-$scenario-metrics"
    else
        echo -e "${YELLOW}⚠${NC} No metrics directory found"
    fi
}

# Check prerequisites
echo "Checking all required services..."
all_services_running=true

check_service 8080 "API Gateway" || all_services_running=false
check_service 8081 "Catalog Service" || all_services_running=false
check_service 8082 "Order Service" || all_services_running=false
check_service 9092 "Kafka" || all_services_running=false
check_service 6379 "Redis" || all_services_running=false
check_service 27017 "MongoDB" || all_services_running=false

if [ "$all_services_running" = false ]; then
    echo ""
    echo -e "${RED}ERROR: Not all required services are running!${NC}"
    echo ""
    echo "Please start the missing services and try again."
    exit 1
fi

test_connectivity || exit 1

echo ""
echo -e "${GREEN}✓ All services are running and responding!${NC}"
echo ""

# Instructions for manual scenario testing
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Manual Scenario Testing Instructions${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "This script will run k6 tests for each scenario."
echo "You need to manually restart the catalog-service with different CACHE_MODE values."
echo ""
echo "Press Enter to continue, or Ctrl+C to cancel..."
read

# Scenario A
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Scenario A: No Cache${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}MANUAL STEP REQUIRED:${NC}"
echo "1. Stop catalog-service (Ctrl+C in its terminal)"
echo "2. Start with: cd catalog-service && export CACHE_MODE=none && mvn spring-boot:run"
echo "3. Wait for it to start (look for 'Started CatalogServiceApplication')"
echo ""
echo "Press Enter when catalog-service is running with CACHE_MODE=none..."
read

# Clear metrics and run test
rm -rf /tmp/metrics && mkdir -p /tmp/metrics
test_connectivity && run_k6_test "A" "run-k6-a.sh"
backup_metrics "A"

# Scenario B
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Scenario B: TTL Only${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}MANUAL STEP REQUIRED:${NC}"
echo "1. Stop catalog-service (Ctrl+C in its terminal)"
echo "2. Start with: cd catalog-service && export CACHE_MODE=ttl && mvn spring-boot:run"
echo "3. Wait for it to start (look for 'Started CatalogServiceApplication')"
echo ""
echo "Press Enter when catalog-service is running with CACHE_MODE=ttl..."
read

# Clear metrics and run test
rm -rf /tmp/metrics && mkdir -p /tmp/metrics
test_connectivity && run_k6_test "B" "run-k6-b.sh"
backup_metrics "B"

# Scenario C
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Scenario C: TTL + Invalidation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}MANUAL STEP REQUIRED:${NC}"
echo "1. Stop catalog-service (Ctrl+C in its terminal)"
echo "2. Start with: cd catalog-service && export CACHE_MODE=ttl_invalidate && mvn spring-boot:run"
echo "3. Wait for it to start (look for 'Started CatalogServiceApplication')"
echo ""
echo "Press Enter when catalog-service is running with CACHE_MODE=ttl_invalidate..."
read

# Clear metrics and run test
rm -rf /tmp/metrics && mkdir -p /tmp/metrics
test_connectivity && run_k6_test "C" "run-k6-c.sh"
backup_metrics "C"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All scenarios completed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Results saved to /tmp/eds-results/"
echo ""
echo "To analyze the final scenario results:"
echo "  python3 scripts/summarize-metrics.py"
echo ""