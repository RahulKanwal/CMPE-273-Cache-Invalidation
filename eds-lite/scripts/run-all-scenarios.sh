#!/bin/bash

# EDS-Lite: Automated Test Runner for All Three Scenarios
# This script runs Scenarios A, B, and C and generates a comparison report

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CATALOG_SERVICE_DIR="$SCRIPT_DIR/../catalog-service"
CATALOG_SERVICE_PORT=8081
METRICS_DIR="/tmp/metrics"
RESULTS_DIR="/tmp/eds-results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EDS-Lite: Automated Scenario Test Runner${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print section headers
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

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
        # Get the PID of the process on port 8081
        local catalog_pid=$(lsof -ti:$CATALOG_SERVICE_PORT)
        echo "Stopping catalog service (PID: $catalog_pid)"
        
        # Kill only the specific process, not all Java processes
        kill -TERM $catalog_pid 2>/dev/null || true
        sleep 2
        
        # If still running, force kill
        if lsof -ti:$CATALOG_SERVICE_PORT >/dev/null 2>&1; then
            kill -9 $catalog_pid 2>/dev/null || true
            sleep 2
        fi
        
        echo -e "${GREEN}✓${NC} Catalog service stopped"
    else
        echo -e "${YELLOW}Catalog service was not running${NC}"
    fi
}

# Function to start catalog service with specific cache mode
start_catalog_service() {
    local cache_mode=$1
    echo -e "${YELLOW}Starting catalog-service with CACHE_MODE=$cache_mode...${NC}"
    
    # Save current directory
    local original_dir=$(pwd)
    
    cd "$CATALOG_SERVICE_DIR"
    export CACHE_MODE=$cache_mode
    
    # Start in background and redirect output to log
    mvn spring-boot:run > /tmp/catalog-$cache_mode.log 2>&1 &
    local pid=$!
    
    # Return to original directory
    cd "$original_dir"
    
    # Wait for service to start (check for up to 60 seconds)
    echo -e "${YELLOW}Waiting for service to start...${NC}"
    for i in {1..60}; do
        if lsof -Pi :$CATALOG_SERVICE_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Catalog service started (PID: $pid)"
            sleep 5  # Give it a few more seconds to fully initialize
            return 0
        fi
        sleep 1
    done
    
    echo -e "${RED}✗${NC} Failed to start catalog service"
    return 1
}

# Function to run k6 test
run_k6_test() {
    local scenario=$1
    local script_name=$2
    
    echo -e "${YELLOW}Running k6 test for Scenario $scenario...${NC}"
    
    local script="$SCRIPT_DIR/$script_name"
    
    if [ ! -f "$script" ]; then
        echo -e "${RED}✗${NC} k6 script not found: $script"
        echo -e "${YELLOW}⚠${NC} Skipping k6 test for Scenario $scenario"
        return 0
    fi
    
    # Verify all services are still running before k6 test
    echo -e "${YELLOW}Verifying services are ready...${NC}"
    if ! check_service 8080 "API Gateway"; then
        echo -e "${RED}✗${NC} API Gateway not running - k6 test will fail"
        echo -e "${YELLOW}Please restart API Gateway: cd api-gateway && mvn spring-boot:run${NC}"
        return 1
    fi
    
    if ! check_service 8081 "Catalog Service"; then
        echo -e "${RED}✗${NC} Catalog Service not running - k6 test will fail"
        return 1
    fi
    
    if ! check_service 8082 "Order Service"; then
        echo -e "${RED}✗${NC} Order Service not running - k6 test will fail"
        echo -e "${YELLOW}Please restart Order Service: cd order-service && mvn spring-boot:run${NC}"
        return 1
    fi
    
    # Test API Gateway connectivity
    echo -e "${YELLOW}Testing API Gateway connectivity...${NC}"
    if curl -s -f "http://localhost:8080/api/catalog/products/1" > /dev/null; then
        echo -e "${GREEN}✓${NC} API Gateway responding"
    else
        echo -e "${RED}✗${NC} API Gateway not responding - k6 test will fail"
        echo "Try: curl http://localhost:8080/api/catalog/products/1"
        return 1
    fi
    
    # Run k6 test
    cd "$SCRIPT_DIR"
    bash "$script_name"
    
    echo -e "${GREEN}✓${NC} k6 test completed for Scenario $scenario"
}

# Function to backup metrics
backup_metrics() {
    local scenario=$1
    echo -e "${YELLOW}Backing up metrics for Scenario $scenario...${NC}"
    
    mkdir -p "$RESULTS_DIR/$TIMESTAMP"
    
    if [ -d "$METRICS_DIR" ]; then
        cp -r "$METRICS_DIR" "$RESULTS_DIR/$TIMESTAMP/scenario-$scenario-metrics"
        echo -e "${GREEN}✓${NC} Metrics backed up to $RESULTS_DIR/$TIMESTAMP/scenario-$scenario-metrics"
    else
        echo -e "${YELLOW}⚠${NC} No metrics directory found"
    fi
}

# Function to clear metrics
clear_metrics() {
    echo -e "${YELLOW}Clearing old metrics...${NC}"
    rm -rf "$METRICS_DIR"
    mkdir -p "$METRICS_DIR"
    echo -e "${GREEN}✓${NC} Metrics cleared"
}

# Main execution
print_header "Step 1: Pre-flight Checks"

# Check if infrastructure is running
echo "Checking infrastructure services..."
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

if ! check_service 8080 "API Gateway"; then
    all_services_running=false
fi

if ! check_service 8082 "Order Service"; then
    all_services_running=false
fi

if [ "$all_services_running" = false ]; then
    echo ""
    echo -e "${RED}ERROR: Not all required services are running!${NC}"
    echo ""
    echo "The automated test requires ALL services to be running:"
    echo ""
    echo "Infrastructure services:"
    echo "  1. ./scripts/start-kafka.sh"
    echo "  2. ./scripts/start-redis.sh"
    echo "  3. ./scripts/start-mongo.sh"
    echo ""
    echo "Application services (start in separate terminals):"
    echo "  4. cd api-gateway && mvn spring-boot:run"
    echo "  5. cd order-service && mvn spring-boot:run"
    echo ""
    echo "The catalog-service will be managed automatically by this script."
    echo ""
    echo -e "${YELLOW}TIP: Use the quick-test.sh instead if you want to test manually.${NC}"
    echo ""
    exit 1
fi

echo ""
echo -e "${GREEN}✓ All infrastructure services are running!${NC}"

# Create results directory
mkdir -p "$RESULTS_DIR/$TIMESTAMP"

print_header "Step 2: Running Scenario A (No Cache)"
clear_metrics
stop_catalog_service
start_catalog_service "none"
sleep 10  # Extra time for warmup
run_k6_test "A" "run-k6-a.sh"
backup_metrics "A"
stop_catalog_service

print_header "Step 3: Running Scenario B (TTL Only)"
clear_metrics
start_catalog_service "ttl"
sleep 10  # Extra time for warmup
run_k6_test "B" "run-k6-b.sh"
backup_metrics "B"
stop_catalog_service

print_header "Step 4: Running Scenario C (TTL + Invalidation)"
clear_metrics
start_catalog_service "ttl_invalidate"
sleep 10  # Extra time for warmup
run_k6_test "C" "run-k6-c.sh"
backup_metrics "C"
stop_catalog_service

print_header "Step 5: Generating Results Summary"

# Create a summary report
REPORT_FILE="$RESULTS_DIR/$TIMESTAMP/RESULTS_SUMMARY.txt"

cat > "$REPORT_FILE" << EOF
========================================
EDS-Lite Test Results Summary
========================================
Test Run: $TIMESTAMP

SCENARIO A: No Cache (CACHE_MODE=none)
--------------------------------------
- All reads hit MongoDB directly
- Expected: High latency, 0% cache hit rate, 0% stale reads

SCENARIO B: TTL-Only Cache (CACHE_MODE=ttl)
--------------------------------------------
- Cache enabled with TTL, no Kafka invalidation
- Expected: Low latency, 85-95% hit rate, >0% stale reads

SCENARIO C: TTL + Kafka Invalidation (CACHE_MODE=ttl_invalidate)
-----------------------------------------------------------------
- Cache enabled with Kafka-based invalidation
- Expected: Low latency, 85-95% hit rate, <1% stale reads, <100ms inconsistency

========================================
Detailed Metrics
========================================

EOF

# Try to run Python summarizer if available
cd "$SCRIPT_DIR"
if command -v python3 &> /dev/null; then
    echo "Running metrics analysis..."
    
    for scenario in A B C; do
        echo "" >> "$REPORT_FILE"
        echo "--- Scenario $scenario ---" >> "$REPORT_FILE"
        
        SCENARIO_METRICS="$RESULTS_DIR/$TIMESTAMP/scenario-$scenario-metrics"
        if [ -d "$SCENARIO_METRICS" ]; then
            # Copy metrics to temp location for analysis
            rm -rf "$METRICS_DIR"
            cp -r "$SCENARIO_METRICS" "$METRICS_DIR"
            
            # Run summarizer and append to report
            python3 summarize-metrics.py >> "$REPORT_FILE" 2>&1 || echo "Error analyzing Scenario $scenario" >> "$REPORT_FILE"
        else
            echo "No metrics found for Scenario $scenario" >> "$REPORT_FILE"
        fi
    done
else
    echo "Python3 not found. Skipping automated analysis." >> "$REPORT_FILE"
    echo "Please run 'python3 scripts/summarize-metrics.py' manually on each scenario's metrics." >> "$REPORT_FILE"
fi

print_header "Test Completion"

echo -e "${GREEN}✓ All scenarios completed successfully!${NC}"
echo ""
echo "Results saved to: $RESULTS_DIR/$TIMESTAMP"
echo ""
echo "Files generated:"
echo "  - scenario-A-metrics/  (No cache)"
echo "  - scenario-B-metrics/  (TTL only)"
echo "  - scenario-C-metrics/  (TTL + Invalidation)"
echo "  - RESULTS_SUMMARY.txt  (Summary report)"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}View Results:${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "cat $REPORT_FILE"
echo ""

# Display the summary
if [ -f "$REPORT_FILE" ]; then
    echo -e "${YELLOW}Quick Summary:${NC}"
    echo ""
    cat "$REPORT_FILE"
fi

echo ""
echo -e "${GREEN}Done! 🎉${NC}"
echo ""
