#!/bin/bash

# Quick port diagnosis script

echo "=== EDS-Lite Port Diagnosis ==="
echo ""

# Check each port and show what's using it
check_port() {
    local port=$1
    local service=$2
    
    echo "Port $port ($service):"
    if lsof -i :$port >/dev/null 2>&1; then
        echo "  ✓ In use by:"
        lsof -i :$port | grep -v COMMAND | while read line; do
            echo "    $line"
        done
    else
        echo "  ✗ Available"
    fi
    echo ""
}

check_port 8080 "API Gateway"
check_port 8081 "Catalog Service"
check_port 8082 "Order Service"
check_port 9092 "Kafka"
check_port 6379 "Redis"
check_port 27017 "MongoDB"

echo "=== Java Processes ==="
ps aux | grep java | grep -v grep | while read line; do
    echo "$line"
done

echo ""
echo "=== Maven Processes ==="
ps aux | grep mvn | grep -v grep | while read line; do
    echo "$line"
done

echo ""
echo "=== Quick Actions ==="
echo "To stop all services:     ./scripts/stop-all-services.sh"
echo "To manage ports:          ./scripts/manage-ports.sh"
echo "To start all services:    ./scripts/start-all-services.sh"
echo ""