#!/bin/bash

# Complete marketplace setup script
# Sets up database and creates admin user properly

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EDS Marketplace Complete Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if user service is running
if ! lsof -Pi :8083 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${RED}❌ User service is not running on port 8083${NC}"
    echo -e "${YELLOW}Please start the user service first:${NC}"
    echo "   cd user-service && mvn spring-boot:run"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ User service is running${NC}"

# 1. Seed products
echo ""
echo -e "${BLUE}Step 1: Seeding marketplace products...${NC}"
mongosh mongodb://localhost:27017/eds < scripts/seed-marketplace.js

# 2. Create admin user properly
echo ""
echo -e "${BLUE}Step 2: Creating admin user...${NC}"
./scripts/create-admin-properly.sh

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Marketplace setup completed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "🎯 You can now:"
echo "  • Access frontend: http://localhost:3000"
echo "  • Login as admin: admin@marketplace.com / admin123"
echo "  • Register new customers through the UI"
echo ""