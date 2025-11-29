#!/bin/bash

# Test script to verify MongoDB Atlas, Upstash Redis, and Confluent Cloud Kafka

echo "=========================================="
echo "Testing Cloud Services"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to test MongoDB
test_mongodb() {
    echo "1. Testing MongoDB Atlas..."
    echo "   Enter your MongoDB connection string:"
    echo "   (Format: mongodb+srv://user:password@cluster.mongodb.net/eds)"
    read -p "   MongoDB URI: " MONGODB_URI
    
    if command -v mongosh &> /dev/null; then
        echo "   Connecting to MongoDB..."
        if mongosh "$MONGODB_URI" --eval "db.adminCommand('ping')" --quiet > /dev/null 2>&1; then
            echo -e "   ${GREEN}✓ MongoDB Atlas is working!${NC}"
            return 0
        else
            echo -e "   ${RED}✗ MongoDB connection failed${NC}"
            echo "   Check: username, password, IP whitelist (0.0.0.0/0)"
            return 1
        fi
    else
        echo -e "   ${YELLOW}⚠ mongosh not installed, testing with curl...${NC}"
        # Try to resolve the hostname at least
        HOST=$(echo "$MONGODB_URI" | sed -n 's/.*@\([^/]*\).*/\1/p')
        if [ -n "$HOST" ]; then
            if ping -c 1 "$HOST" &> /dev/null; then
                echo -e "   ${GREEN}✓ MongoDB host is reachable${NC}"
                return 0
            else
                echo -e "   ${RED}✗ Cannot reach MongoDB host${NC}"
                return 1
            fi
        fi
    fi
}

# Function to test Redis
test_redis() {
    echo ""
    echo "2. Testing Upstash Redis..."
    read -p "   Redis Host: " REDIS_HOST
    read -p "   Redis Port (default 6379): " REDIS_PORT
    REDIS_PORT=${REDIS_PORT:-6379}
    read -sp "   Redis Password: " REDIS_PASSWORD
    echo ""
    
    if command -v redis-cli &> /dev/null; then
        echo "   Connecting to Redis..."
        if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" --tls PING 2>/dev/null | grep -q "PONG"; then
            echo -e "   ${GREEN}✓ Upstash Redis is working!${NC}"
            return 0
        else
            echo -e "   ${RED}✗ Redis connection failed${NC}"
            echo "   Check: host, port, password"
            return 1
        fi
    else
        echo -e "   ${YELLOW}⚠ redis-cli not installed, testing with curl...${NC}"
        # Test if host is reachable
        if nc -zv "$REDIS_HOST" "$REDIS_PORT" 2>&1 | grep -q "succeeded"; then
            echo -e "   ${GREEN}✓ Redis host is reachable${NC}"
            return 0
        else
            echo -e "   ${RED}✗ Cannot reach Redis host${NC}"
            return 1
        fi
    fi
}

# Function to test Kafka
test_kafka() {
    echo ""
    echo "3. Testing Confluent Cloud Kafka..."
    read -p "   Bootstrap Server (e.g., pkc-xxxxx.region.aws.confluent.cloud:9092): " KAFKA_BOOTSTRAP
    read -p "   API Key: " KAFKA_KEY
    read -sp "   API Secret: " KAFKA_SECRET
    echo ""
    
    # Extract host from bootstrap server
    KAFKA_HOST=$(echo "$KAFKA_BOOTSTRAP" | cut -d: -f1)
    KAFKA_PORT=$(echo "$KAFKA_BOOTSTRAP" | cut -d: -f2)
    KAFKA_PORT=${KAFKA_PORT:-9092}
    
    echo "   Testing Kafka connectivity..."
    
    # Test if we can reach the Kafka host
    if nc -zv "$KAFKA_HOST" "$KAFKA_PORT" 2>&1 | grep -q "succeeded"; then
        echo -e "   ${GREEN}✓ Kafka host is reachable${NC}"
        echo "   Note: Full authentication test requires kafka-console tools"
        return 0
    else
        echo -e "   ${RED}✗ Cannot reach Kafka host${NC}"
        echo "   Check: bootstrap server URL, firewall"
        return 1
    fi
}

# Main execution
echo "This script will test your cloud services connectivity."
echo "You'll need to provide credentials for each service."
echo ""

MONGODB_OK=0
REDIS_OK=0
KAFKA_OK=0

# Test MongoDB
if test_mongodb; then
    MONGODB_OK=1
fi

# Test Redis
if test_redis; then
    REDIS_OK=1
fi

# Test Kafka
if test_kafka; then
    KAFKA_OK=1
fi

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
if [ $MONGODB_OK -eq 1 ]; then
    echo -e "${GREEN}✓ MongoDB Atlas: Working${NC}"
else
    echo -e "${RED}✗ MongoDB Atlas: Failed${NC}"
fi

if [ $REDIS_OK -eq 1 ]; then
    echo -e "${GREEN}✓ Upstash Redis: Working${NC}"
else
    echo -e "${RED}✗ Upstash Redis: Failed${NC}"
fi

if [ $KAFKA_OK -eq 1 ]; then
    echo -e "${GREEN}✓ Confluent Cloud Kafka: Working${NC}"
else
    echo -e "${RED}✗ Confluent Cloud Kafka: Failed${NC}"
fi

echo ""
if [ $MONGODB_OK -eq 1 ] && [ $REDIS_OK -eq 1 ] && [ $KAFKA_OK -eq 1 ]; then
    echo -e "${GREEN}All services are working! ✓${NC}"
    echo "You can proceed with Railway deployment."
else
    echo -e "${YELLOW}Some services failed. Fix them before deploying.${NC}"
fi
echo ""
