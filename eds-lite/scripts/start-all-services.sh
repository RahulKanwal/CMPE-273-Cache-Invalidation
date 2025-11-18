#!/bin/bash

# Start all services required for EDS-Lite testing
# This script starts infrastructure + application services

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Starting All EDS-Lite Services${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to check if service is running
is_running() {
    local port=$1
    lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1
}

# Function to wait for service
wait_for_service() {
    local port=$1
    local name=$2
    local max_wait=${3:-60}
    
    echo -e "${YELLOW}Waiting for $name to start on port $port...${NC}"
    for i in $(seq 1 $max_wait); do
        if is_running $port; then
            echo -e "${GREEN}✓${NC} $name is running on port $port"
            return 0
        fi
        sleep 1
    done
    echo -e "${RED}✗${NC} $name failed to start on port $port"
    return 1
}

# Start infrastructure services
echo -e "${BLUE}Step 1: Starting Infrastructure Services${NC}"
echo ""

if is_running 9092; then
    echo -e "${GREEN}✓${NC} Kafka already running"
else
    echo -e "${YELLOW}Starting Kafka...${NC}"
    "$SCRIPT_DIR/start-kafka.sh" &
    wait_for_service 9092 "Kafka" 30
fi

if is_running 6379; then
    echo -e "${GREEN}✓${NC} Redis already running"
else
    echo -e "${YELLOW}Starting Redis...${NC}"
    "$SCRIPT_DIR/start-redis.sh" &
    wait_for_service 6379 "Redis" 15
fi

if is_running 27017; then
    echo -e "${GREEN}✓${NC} MongoDB already running"
else
    echo -e "${YELLOW}Starting MongoDB...${NC}"
    "$SCRIPT_DIR/start-mongo.sh" &
    wait_for_service 27017 "MongoDB" 15
fi

echo ""
echo -e "${BLUE}Step 2: Starting Application Services${NC}"
echo ""

# Start API Gateway
if is_running 8080; then
    echo -e "${GREEN}✓${NC} API Gateway already running"
else
    echo -e "${YELLOW}Starting API Gateway...${NC}"
    cd "$SCRIPT_DIR/../api-gateway"
    mvn spring-boot:run > /tmp/api-gateway.log 2>&1 &
    cd "$SCRIPT_DIR"
    wait_for_service 8080 "API Gateway" 60
fi

# Start Order Service
if is_running 8082; then
    echo -e "${GREEN}✓${NC} Order Service already running"
else
    echo -e "${YELLOW}Starting Order Service...${NC}"
    cd "$SCRIPT_DIR/../order-service"
    mvn spring-boot:run > /tmp/order-service.log 2>&1 &
    cd "$SCRIPT_DIR"
    wait_for_service 8082 "Order Service" 60
fi

# Start Catalog Service (default mode)
if is_running 8081; then
    echo -e "${GREEN}✓${NC} Catalog Service already running"
else
    echo -e "${YELLOW}Starting Catalog Service (ttl_invalidate mode)...${NC}"
    cd "$SCRIPT_DIR/../catalog-service"
    export CACHE_MODE=ttl_invalidate
    mvn spring-boot:run > /tmp/catalog-service.log 2>&1 &
    cd "$SCRIPT_DIR"
    wait_for_service 8081 "Catalog Service" 60
fi

echo ""
echo -e "${BLUE}Step 3: Verifying System Health${NC}"
echo ""

# Test API connectivity
echo -e "${YELLOW}Testing API Gateway...${NC}"
sleep 5  # Give services a moment to fully initialize

if curl -s -f "http://localhost:8080/api/catalog/products/1" > /dev/null; then
    echo -e "${GREEN}✓${NC} API Gateway responding correctly"
else
    echo -e "${RED}✗${NC} API Gateway not responding"
    echo "Check logs: tail -f /tmp/api-gateway.log"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All Services Started Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Services running:"
echo "  - Kafka:          http://localhost:9092"
echo "  - Redis:          localhost:6379"
echo "  - MongoDB:        mongodb://localhost:27017"
echo "  - API Gateway:    http://localhost:8080"
echo "  - Catalog Service: http://localhost:8081"
echo "  - Order Service:   http://localhost:8082"
echo ""
echo "Logs available at:"
echo "  - API Gateway:     /tmp/api-gateway.log"
echo "  - Catalog Service: /tmp/catalog-service.log"
echo "  - Order Service:   /tmp/order-service.log"
echo ""
echo "Next steps:"
echo "  1. Seed database:    mongosh mongodb://localhost:27017/eds < scripts/seed-mongo.js"
echo "  2. Quick test:       ./scripts/quick-test.sh"
echo "  3. Full scenarios:   ./scripts/run-all-scenarios.sh"
echo ""