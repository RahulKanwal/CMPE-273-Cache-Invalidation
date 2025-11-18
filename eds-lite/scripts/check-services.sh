#!/bin/bash

# Check if all required services are running

echo "=========================================="
echo "Checking Infrastructure Services"
echo "=========================================="
echo ""

# Check Redis
echo -n "Redis: "
if pgrep -f "redis-server" > /dev/null; then
    echo "✓ Running on localhost:6379"
else
    echo "✗ Not running (run: ./scripts/start-redis.sh)"
fi

# Check MongoDB
echo -n "MongoDB: "
if pgrep -f "mongod" > /dev/null; then
    echo "✓ Running on localhost:27017"
else
    echo "✗ Not running (run: ./scripts/start-mongo.sh)"
fi

# Check Redpanda
echo -n "Redpanda (Kafka): "
if pgrep -f "redpanda" > /dev/null; then
    echo "✓ Running on localhost:9092"
else
    echo "✗ Not running (run: ./scripts/start-redpanda.sh)"
fi

echo ""
echo "=========================================="

# Test connections
echo ""
echo "Testing connections..."

# Test Redis
if command -v redis-cli &> /dev/null; then
    if redis-cli -p 6379 ping > /dev/null 2>&1; then
        echo "✓ Redis connection: OK"
    else
        echo "✗ Redis connection: FAILED"
    fi
fi

# Test MongoDB
if command -v mongosh &> /dev/null || command -v mongo &> /dev/null; then
    MONGO_CMD="mongosh"
    if ! command -v mongosh &> /dev/null; then
        MONGO_CMD="mongo"
    fi
    if $MONGO_CMD --eval "db.adminCommand('ping')" --quiet > /dev/null 2>&1; then
        echo "✓ MongoDB connection: OK"
    else
        echo "✗ MongoDB connection: FAILED"
    fi
fi

# Test Kafka/Redpanda
if command -v rpk &> /dev/null; then
    if rpk cluster info --brokers localhost:9092 > /dev/null 2>&1; then
        echo "✓ Redpanda connection: OK"
    else
        echo "✗ Redpanda connection: FAILED"
    fi
fi

echo ""

