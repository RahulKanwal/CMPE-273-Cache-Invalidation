#!/bin/bash

# EDS Marketplace Stop Script
# This script stops all marketplace services

echo "🛑 Stopping EDS Marketplace services..."
echo "======================================"

# Function to stop a service
stop_service() {
    local service_name=$1
    local pid_file="logs/$service_name.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p $pid > /dev/null 2>&1; then
            echo "🔄 Stopping $service_name (PID: $pid)..."
            kill $pid
            sleep 2
            
            # Force kill if still running
            if ps -p $pid > /dev/null 2>&1; then
                echo "⚠️  Force killing $service_name..."
                kill -9 $pid
            fi
            
            echo "✅ $service_name stopped"
        else
            echo "⚠️  $service_name was not running"
        fi
        rm -f "$pid_file"
    else
        echo "⚠️  No PID file found for $service_name"
    fi
}

# Stop services
stop_service "marketplace-ui"
stop_service "api-gateway"
stop_service "order-service"
stop_service "catalog-service"
stop_service "user-service"

# Also kill any remaining Java processes on our ports
echo "🔍 Checking for remaining processes..."

for port in 3000 8080 8081 8082 8083; do
    pid=$(lsof -ti:$port 2>/dev/null)
    if [ -n "$pid" ]; then
        echo "🔄 Killing process on port $port (PID: $pid)..."
        kill -9 $pid 2>/dev/null || true
    fi
done

echo ""
echo "✅ All EDS Marketplace services stopped"
echo ""
echo "💡 Infrastructure services (Redis, MongoDB, Kafka) are still running"
echo "   To stop them, use their respective stop scripts"