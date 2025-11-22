#!/bin/bash

# EDS Marketplace Startup Script
# This script starts all required services for the marketplace

set -e

echo "🚀 Starting EDS Marketplace..."
echo "================================"

# Check if required tools are installed
command -v java >/dev/null 2>&1 || { echo "❌ Java is required but not installed. Aborting." >&2; exit 1; }
command -v mvn >/dev/null 2>&1 || { echo "❌ Maven is required but not installed. Aborting." >&2; exit 1; }
command -v node >/dev/null 2>&1 || { echo "❌ Node.js is required but not installed. Aborting." >&2; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "❌ npm is required but not installed. Aborting." >&2; exit 1; }

# Function to check if a port is in use
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo "⚠️  Port $1 is already in use. Please free it before starting."
        return 1
    fi
    return 0
}

# Check required ports
echo "🔍 Checking required ports..."
check_port 3000 || exit 1  # React frontend
check_port 8080 || exit 1  # API Gateway
check_port 8081 || exit 1  # Catalog Service
check_port 8082 || exit 1  # Order Service
check_port 8083 || exit 1  # User Service

echo "✅ All ports are available"

# Check if infrastructure is running
echo "🔍 Checking infrastructure services..."

# Check Redis
if ! redis-cli ping >/dev/null 2>&1; then
    echo "❌ Redis is not running. Please start Redis first:"
    echo "   ./scripts/start-redis.sh"
    exit 1
fi
echo "✅ Redis is running"

# Check MongoDB
if ! mongosh --eval "db.adminCommand('ping')" mongodb://localhost:27017/eds >/dev/null 2>&1; then
    echo "❌ MongoDB is not running. Please start MongoDB first:"
    echo "   ./scripts/start-mongo.sh"
    exit 1
fi
echo "✅ MongoDB is running"

# Check Kafka (optional check - services will start without it but with warnings)
if ! nc -z localhost 9092 >/dev/null 2>&1; then
    echo "⚠️  Kafka is not running. Cache invalidation will not work optimally."
    echo "   To start Kafka: ./scripts/start-kafka.sh"
else
    echo "✅ Kafka is running"
fi

# Create log directory
mkdir -p logs

echo ""
echo "🏗️  Building and starting services..."
echo "This may take a few minutes on first run..."

# Function to start a service in background
start_service() {
    local service_name=$1
    local service_dir=$2
    local port=$3
    local additional_args=$4
    
    echo "🔄 Starting $service_name..."
    cd "$service_dir"
    
    if [ "$service_name" = "marketplace-ui" ]; then
        # Install npm dependencies if needed
        if [ ! -d "node_modules" ]; then
            echo "📦 Installing npm dependencies for $service_name..."
            npm install
        fi
        npm start > "../logs/$service_name.log" 2>&1 &
    else
        # Java services
        if [ -n "$additional_args" ]; then
            eval "$additional_args mvn spring-boot:run > ../logs/$service_name.log 2>&1 &"
        else
            mvn spring-boot:run > "../logs/$service_name.log" 2>&1 &
        fi
    fi
    
    local pid=$!
    echo "$pid" > "../logs/$service_name.pid"
    echo "✅ $service_name started (PID: $pid, Port: $port)"
    cd - >/dev/null
}

# Start services in order
start_service "user-service" "user-service" "8083"
sleep 5

start_service "catalog-service" "catalog-service" "8081" "export CACHE_MODE=ttl_invalidate &&"
sleep 5

start_service "order-service" "order-service" "8082"
sleep 5

start_service "api-gateway" "api-gateway" "8080"
sleep 5

start_service "marketplace-ui" "marketplace-ui" "3000"

echo ""
echo "🎉 EDS Marketplace is starting up!"
echo "================================"
echo ""
echo "📱 Frontend:     http://localhost:3000"
echo "🔌 API Gateway:  http://localhost:8080"
echo "👤 User Service: http://localhost:8083"
echo "📦 Catalog:      http://localhost:8081"
echo "🛒 Orders:       http://localhost:8082"
echo ""
echo "📊 Demo Accounts:"
echo "   Admin: admin@marketplace.com / admin123"
echo "   Or register a new customer account"
echo ""
echo "📝 Logs are available in the logs/ directory"
echo "🛑 To stop all services: ./scripts/stop-marketplace.sh"
echo ""
echo "⏳ Services are starting... Please wait 30-60 seconds for full startup"
echo "   You can monitor progress with: tail -f logs/*.log"