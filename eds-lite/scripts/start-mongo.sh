#!/bin/bash

# Start MongoDB
# Run ./scripts/setup-local.sh first to install MongoDB

set -e

echo "Starting MongoDB..."

# Check if MongoDB is installed
if ! command -v mongod &> /dev/null; then
    echo "❌ MongoDB not found!"
    echo ""
    echo "Please run the setup script first:"
    echo "  ./scripts/setup-local.sh"
    echo ""
    echo "Or install manually:"
    echo "  macOS: brew tap mongodb/brew && brew install mongodb-community"
    echo "  Linux: See https://www.mongodb.com/docs/manual/installation/"
    echo ""
    echo "Or use MongoDB Atlas (cloud): https://www.mongodb.com/cloud/atlas"
    echo "Then set: export MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/eds"
    exit 1
fi

# Check if already running
if lsof -Pi :27017 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "✓ MongoDB is already running on localhost:27017"
else
    echo "Starting MongoDB on localhost:27017..."
    
    # Start MongoDB manually (more reliable than brew services)
    echo "Starting MongoDB manually..."
    mkdir -p /tmp/mongodb-data
    
    # Try fork mode first
    if mongod --dbpath /tmp/mongodb-data --port 27017 --fork --logpath /tmp/mongodb.log 2>/dev/null; then
        sleep 3
        echo "✓ MongoDB started successfully with fork mode"
    else
        # Fallback: background start
        echo "Fork mode failed, trying background start..."
        mongod --dbpath /tmp/mongodb-data --port 27017 > /tmp/mongodb.log 2>&1 &
        sleep 3
        
        if lsof -Pi :27017 -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo "✓ MongoDB started successfully in background"
        else
            # Last resort: try brew services (may have launchctl issues)
            if command -v brew &> /dev/null && brew services list | grep -q mongodb-community; then
                echo "Trying brew services as last resort..."
                brew services start mongodb-community 2>/dev/null || true
                sleep 3
                
                if lsof -Pi :27017 -sTCP:LISTEN -t >/dev/null 2>&1; then
                    echo "✓ MongoDB started with brew services"
                else
                    echo "❌ Failed to start MongoDB. Check /tmp/mongodb.log for errors"
                    echo "You may need to run: brew services stop mongodb-community && brew services start mongodb-community"
                    exit 1
                fi
            else
                echo "❌ Failed to start MongoDB. Check /tmp/mongodb.log for errors"
                exit 1
            fi
        fi
    fi
fi

echo ""
echo "MongoDB is running on mongodb://localhost:27017/eds"
echo "To use MongoDB Atlas instead, set:"
echo "  export MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/eds"

