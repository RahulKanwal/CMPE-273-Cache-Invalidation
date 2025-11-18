#!/bin/bash

# Script to stop the catalog service running on port 8081

echo "Stopping catalog service on port 8081..."

PID=$(lsof -ti:8081)

if [ -z "$PID" ]; then
    echo "No process found on port 8081"
    exit 0
fi

echo "Found process $PID on port 8081"
kill -9 $PID 2>/dev/null

sleep 1

# Verify it's stopped
if lsof -ti:8081 > /dev/null 2>&1; then
    echo "Warning: Process may still be running. Trying again..."
    lsof -ti:8081 | xargs kill -9 2>/dev/null
    sleep 1
fi

if lsof -ti:8081 > /dev/null 2>&1; then
    echo "Error: Could not stop process on port 8081"
    exit 1
else
    echo "✓ Catalog service stopped successfully"
    exit 0
fi

