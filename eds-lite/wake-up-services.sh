#!/bin/bash

# Quick script to wake up all Render services
# Run this whenever you get 502 errors

echo "================================================"
echo "Waking Up Render Services..."
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}This will take about 60 seconds...${NC}"
echo ""

# Wake up API Gateway
echo "1/4 Waking API Gateway..."
curl -s -m 60 https://api-gateway-lpnh.onrender.com/actuator/health > /dev/null 2>&1 &
PID1=$!

# Wake up Catalog Service (replace YOUR-ID with actual ID)
echo "2/4 Waking Catalog Service..."
echo -e "${YELLOW}⚠️  You need to replace YOUR-ID with your actual service ID${NC}"
curl -s -m 60 https://catalog-service-e2ry.onrender.com/actuator/health > /dev/null 2>&1 &
PID2=$!

# Wake up Order Service (replace YOUR-ID with actual ID)
echo "3/4 Waking Order Service..."
echo -e "${YELLOW}⚠️  You need to replace YOUR-ID with your actual service ID${NC}"
curl -s -m 60 https://user-service-1z5w.onrender.com/actuator/health > /dev/null 2>&1 &
PID3=$!

# Wake up User Service (replace YOUR-ID with actual ID)
echo "4/4 Waking User Service..."
echo -e "${YELLOW}⚠️  You need to replace YOUR-ID with your actual service ID${NC}"
curl -s -m 60 https://order-service-wfi0.onrender.com/actuator/health > /dev/null 2>&1 &
PID4=$!

echo ""
echo "Waiting for services to respond..."
echo ""

# Wait for all background processes
wait $PID1 2>/dev/null
echo -e "${GREEN}✓ API Gateway is awake${NC}"

# Uncomment these after adding your service URLs
wait $PID2 2>/dev/null
echo -e "${GREEN}✓ Catalog Service is awake${NC}"

wait $PID3 2>/dev/null
echo -e "${GREEN}✓ Order Service is awake${NC}"

wait $PID4 2>/dev/null
echo -e "${GREEN}✓ User Service is awake${NC}"

echo ""
echo "================================================"
echo -e "${GREEN}Services are waking up!${NC}"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Go to https://dashboard.render.com/"
echo "2. Copy the URLs for your 3 other services"
echo "3. Edit this script and replace YOUR-ID"
echo "4. Run it again to wake all services"
echo ""
echo "Or just wait 2-3 minutes and try your website again!"
echo ""
