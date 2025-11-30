#!/bin/bash

# Keep Render Services Awake Script
# This script pings all your Render services to prevent them from sleeping
# Run this manually or set up a cron job to run it every 10 minutes

echo "================================================"
echo "Keep Render Services Awake"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to ping a service
ping_service() {
    local service_name=$1
    local url=$2
    
    echo -n "Pinging ${service_name}... "
    
    if curl -s -f -m 30 "${url}" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Success${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed${NC}"
        return 1
    fi
}

# Ping all services
echo "Starting health checks..."
echo ""

ping_service "API Gateway" "https://api-gateway-lpnh.onrender.com/actuator/health"
sleep 2

ping_service "Catalog Service" "https://catalog-service-YOUR-ID.onrender.com/actuator/health"
sleep 2

ping_service "Order Service" "https://order-service-YOUR-ID.onrender.com/actuator/health"
sleep 2

ping_service "User Service" "https://user-service-YOUR-ID.onrender.com/actuator/health"

echo ""
echo "================================================"
echo -e "${GREEN}All services pinged!${NC}"
echo "================================================"
echo ""
echo "To run this automatically, add to your crontab:"
echo -e "${YELLOW}*/10 * * * * /path/to/keep-services-awake.sh${NC}"
echo ""
