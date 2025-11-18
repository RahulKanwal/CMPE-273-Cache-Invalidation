#!/bin/bash

# EDS-Lite: Start All Infrastructure Services
# This script starts Kafka, Redis, and MongoDB in the background

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Starting EDS-Lite Infrastructure${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to check if service is already running
is_running() {
    local port=$1
    lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1
}

# Start Kafka
echo -e "${YELLOW}Starting Kafka...${NC}"
if is_running 9092; then
    echo -e "${GREEN}✓${NC} Kafka is already running on port 9092"
else
    if [ -f "$SCRIPT_DIR/start-kafka.sh" ]; then
        "$SCRIPT_DIR/start-kafka.sh" &
        echo -e "${GREEN}✓${NC} Kafka starting in background"
    else
        echo -e "${RED}✗${NC} start-kafka.sh not found"
    fi
fi
echo ""

# Start Redis
echo -e "${YELLOW}Starting Redis...${NC}"
if is_running 6379; then
    echo -e "${GREEN}✓${NC} Redis is already running on port 6379"
else
    if [ -f "$SCRIPT_DIR/start-redis.sh" ]; then
        "$SCRIPT_DIR/start-redis.sh" &
        echo -e "${GREEN}✓${NC} Redis starting in background"
    else
        echo -e "${RED}✗${NC} start-redis.sh not found"
    fi
fi
echo ""

# Start MongoDB
echo -e "${YELLOW}Starting MongoDB...${NC}"
if is_running 27017; then
    echo -e "${GREEN}✓${NC} MongoDB is already running on port 27017"
else
    if [ -f "$SCRIPT_DIR/start-mongo.sh" ]; then
        "$SCRIPT_DIR/start-mongo.sh" &
        echo -e "${GREEN}✓${NC} MongoDB starting in background"
    else
        echo -e "${RED}✗${NC} start-mongo.sh not found"
    fi
fi
echo ""

# Wait for services to start
echo -e "${YELLOW}Waiting for services to start (15 seconds)...${NC}"
sleep 15

# Check status
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Service Status${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

"$SCRIPT_DIR/check-services.sh"

echo ""
echo -e "${GREEN}Infrastructure startup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Seed MongoDB: mongosh mongodb://localhost:27017/eds < scripts/seed-mongo.js"
echo "  2. Start services:"
echo "     - cd api-gateway && mvn spring-boot:run"
echo "     - cd order-service && mvn spring-boot:run"
echo "     - cd catalog-service && export CACHE_MODE=ttl_invalidate && mvn spring-boot:run"
echo "  3. Run tests: ./scripts/quick-test.sh"
echo ""
