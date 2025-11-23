#!/bin/bash

# EDS Marketplace: Start Cache Demo
# Starts the necessary services for the cache demo

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EDS Cache Demo Startup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to check if a service is running
check_service() {
    local port=$1
    local name=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $name is running on port $port"
        return 0
    else
        echo -e "${RED}✗${NC} $name is NOT running on port $port"
        return 1
    fi
}

echo "Checking required services for cache demo..."
echo ""

# Check infrastructure services
all_running=true

if ! check_service 9092 "Kafka"; then
    echo -e "${YELLOW}  Start with: ./scripts/start-kafka.sh${NC}"
    all_running=false
fi

if ! check_service 6379 "Redis"; then
    echo -e "${YELLOW}  Start with: ./scripts/start-redis.sh${NC}"
    all_running=false
fi

if ! check_service 27017 "MongoDB"; then
    echo -e "${YELLOW}  Start with: ./scripts/start-mongo.sh${NC}"
    all_running=false
fi

if ! check_service 8081 "Catalog Service"; then
    echo -e "${YELLOW}  Start with: cd catalog-service && mvn spring-boot:run${NC}"
    all_running=false
fi

if ! check_service 3000 "React UI"; then
    echo -e "${YELLOW}  Start with: cd marketplace-ui && npm start${NC}"
    all_running=false
fi

echo ""

if [ "$all_running" = true ]; then
    echo -e "${GREEN}🎉 All services are running!${NC}"
    echo ""
    echo -e "${BLUE}Cache Demo is ready:${NC}"
    echo -e "${BLUE}http://localhost:3000/cache-demo${NC}"
    echo ""
    echo "The demo allows you to:"
    echo "  • Switch between 3 cache scenarios"
    echo "  • Run interactive cache tests"
    echo "  • Visualize cache architecture"
    echo "  • See real-time performance metrics"
    echo "  • Monitor cache events and logs"
    echo ""
else
    echo -e "${RED}❌ Some services are missing!${NC}"
    echo ""
    echo "To start all required services:"
    echo ""
    echo "1. Infrastructure (in separate terminals):"
    echo -e "   ${YELLOW}./scripts/start-kafka.sh${NC}"
    echo -e "   ${YELLOW}./scripts/start-redis.sh${NC}"
    echo -e "   ${YELLOW}./scripts/start-mongo.sh${NC}"
    echo ""
    echo "2. Catalog Service:"
    echo -e "   ${YELLOW}cd catalog-service && mvn spring-boot:run${NC}"
    echo ""
    echo "3. React UI:"
    echo -e "   ${YELLOW}cd marketplace-ui && npm start${NC}"
    echo ""
    echo "Then visit: http://localhost:3000/cache-demo"
    echo ""
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Cache Demo Features:${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "🏗️  Architecture Visualization"
echo "   • Visual representation of cache components"
echo "   • Real-time data flow animation"
echo "   • Component interaction diagrams"
echo ""
echo "📊 Performance Analytics"
echo "   • Response time comparisons"
echo "   • Cache hit/miss ratios"
echo "   • Latency improvements visualization"
echo ""
echo "🔄 Interactive Testing"
echo "   • Test all 3 cache scenarios"
echo "   • Real-time cache behavior simulation"
echo "   • Stale data detection"
echo ""
echo "📈 Live Metrics"
echo "   • Cache hits/misses counter"
echo "   • Invalidation events tracking"
echo "   • Average response times"
echo ""
echo "📝 Event Logging"
echo "   • Real-time test execution logs"
echo "   • Cache event timeline"
echo "   • Detailed operation tracking"
echo ""

if [ "$all_running" = true ]; then
    echo -e "${GREEN}Ready to demo! 🚀${NC}"
else
    echo -e "${YELLOW}Start the missing services to begin! ⚡${NC}"
fi

echo ""