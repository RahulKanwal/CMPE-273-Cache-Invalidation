#!/bin/bash

# Fix MongoDB connection issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}MongoDB Connection Fix${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if MongoDB is installed
if ! command -v mongod &> /dev/null; then
    echo -e "${RED}✗${NC} MongoDB not installed"
    echo ""
    echo "Install with:"
    echo "  brew tap mongodb/brew"
    echo "  brew install mongodb-community"
    exit 1
fi

echo -e "${GREEN}✓${NC} MongoDB is installed"

# Check if MongoDB is running
if lsof -Pi :27017 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} MongoDB is running on port 27017"
else
    echo -e "${YELLOW}⚠${NC} MongoDB is not running, starting it..."
    
    # Start MongoDB with brew services
    if command -v brew &> /dev/null; then
        brew services start mongodb-community
        sleep 3
        
        if lsof -Pi :27017 -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} MongoDB started successfully"
        else
            echo -e "${RED}✗${NC} Failed to start MongoDB with brew services"
            exit 1
        fi
    else
        echo -e "${RED}✗${NC} Homebrew not found, cannot start MongoDB"
        exit 1
    fi
fi

# Test connection
echo -e "${YELLOW}Testing MongoDB connection...${NC}"
if mongosh mongodb://localhost:27017/eds --eval "db.runCommand({ping: 1})" --quiet >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} MongoDB connection successful"
else
    echo -e "${RED}✗${NC} MongoDB connection failed"
    exit 1
fi

# Check if database is seeded
echo -e "${YELLOW}Checking database...${NC}"
PRODUCT_COUNT=$(mongosh mongodb://localhost:27017/eds --eval "db.products.countDocuments()" --quiet 2>/dev/null | tail -1)

if [ "$PRODUCT_COUNT" -gt 0 ] 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Database has $PRODUCT_COUNT products"
else
    echo -e "${YELLOW}⚠${NC} Database is empty, seeding..."
    mongosh mongodb://localhost:27017/eds < seed-mongo.js >/dev/null
    echo -e "${GREEN}✓${NC} Database seeded with 2000 products"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}MongoDB is ready!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Connection string: mongodb://localhost:27017/eds"
echo "Products in database: $(mongosh mongodb://localhost:27017/eds --eval "db.products.countDocuments()" --quiet 2>/dev/null | tail -1)"
echo ""
echo "Test with:"
echo "  mongosh mongodb://localhost:27017/eds"
echo "  curl http://localhost:8080/api/catalog/products/1"
echo ""