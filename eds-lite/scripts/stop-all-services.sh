#!/bin/bash

# Stop all EDS-Lite services cleanly

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Stopping All EDS-Lite Services${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to stop service on port
stop_service() {
    local port=$1
    local name=$2
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        local pid=$(lsof -ti:$port)
        echo -e "${YELLOW}Stopping $name (port $port, PID $pid)...${NC}"
        
        # Try graceful shutdown
        kill -TERM $pid 2>/dev/null || true
        sleep 2
        
        # Check if still running
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo -e "${YELLOW}Force killing $name...${NC}"
            kill -9 $pid 2>/dev/null || true
            sleep 1
        fi
        
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo -e "${RED}✗${NC} Failed to stop $name"
        else
            echo -e "${GREEN}✓${NC} $name stopped"
        fi
    else
        echo -e "${GREEN}✓${NC} $name was not running"
    fi
}

# Stop services in order (applications first, then infrastructure)
echo "Stopping application services..."
stop_service 8080 "API Gateway"
stop_service 8081 "Catalog Service"
stop_service 8082 "Order Service"

echo ""
echo "Stopping infrastructure services..."
stop_service 9092 "Kafka"
stop_service 6379 "Redis"
stop_service 27017 "MongoDB"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All services stopped!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "To start services again:"
echo "  ./scripts/start-all-services.sh"
echo ""
echo "Or manually:"
echo "  ./scripts/start-kafka.sh"
echo "  ./scripts/start-redis.sh"
echo "  ./scripts/start-mongo.sh"
echo "  cd api-gateway && mvn spring-boot:run"
echo "  cd order-service && mvn spring-boot:run"
echo "  cd catalog-service && export CACHE_MODE=ttl_invalidate && mvn spring-boot:run"
echo ""