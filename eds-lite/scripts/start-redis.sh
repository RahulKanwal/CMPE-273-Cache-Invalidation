#!/bin/bash

# Start Redis
# Run ./scripts/setup-local.sh first to install Redis

set -e

echo "Starting Redis..."

if ! command -v redis-server &> /dev/null; then
    echo "❌ Redis not found!"
    echo ""
    echo "Please run the setup script first:"
    echo "  ./scripts/setup-local.sh"
    echo ""
    echo "Or install manually:"
    echo "  macOS: brew install redis"
    echo "  Linux: sudo apt-get install redis-server"
    exit 1
fi

if pgrep -f "redis-server" > /dev/null; then
    echo "✓ Redis is already running on localhost:6379"
else
    echo "Starting Redis on localhost:6379..."
    
    # Try to start Redis
    if redis-server --port 6379 --daemonize yes 2>/dev/null; then
        sleep 2
        echo "✓ Redis started successfully"
    else
        # Fallback: start in background without daemonize flag
        redis-server --port 6379 > /tmp/redis.log 2>&1 &
        sleep 2
        
        # Verify it's running
        if pgrep -f "redis-server" > /dev/null; then
            echo "✓ Redis started successfully"
        else
            echo "❌ Failed to start Redis. Check /tmp/redis.log for errors"
            exit 1
        fi
    fi
fi

echo ""
echo "Redis is running on localhost:6379"
echo "To use Upstash instead, set:"
echo "  export REDIS_HOST=your-redis-host"
echo "  export REDIS_PORT=your-redis-port"

