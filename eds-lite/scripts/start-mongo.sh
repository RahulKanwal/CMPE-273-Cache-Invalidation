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
    
    # Try to start with brew services (macOS)
    if command -v brew &> /dev/null && brew services list | grep -q mongodb-community; then
        echo "Using brew services to start MongoDB..."
        brew services start mongodb-community
        sleep 3
        
        # Verify it started
        if lsof -Pi :27017 -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo "✓ MongoDB started successfully with brew services"
        else
            echo "❌ Failed to start MongoDB with brew services"
            exit 1
        fi
    else
        # Fallback: manual start
        echo "Starting MongoDB manually..."
        mkdir -p /tmp/mongodb-data
        
        if mongod --dbpath /tmp/mongodb-data --port 27017 --fork --logpath /tmp/mongodb.log 2>/dev/null; then
            sleep 3
            echo "✓ MongoDB started successfully"
        else
            # Last resort: background start
            mongod --dbpath /tmp/mongodb-data --port 27017 > /tmp/mongodb.log 2>&1 &
            sleep 3
            
            if lsof -Pi :27017 -sTCP:LISTEN -t >/dev/null 2>&1; then
                echo "✓ MongoDB started successfully"
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

