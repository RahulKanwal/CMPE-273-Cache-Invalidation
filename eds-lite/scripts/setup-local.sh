#!/bin/bash

# Setup script for local infrastructure (Redis, MongoDB, Kafka/Redpanda)
# This script installs and configures all required services for local development

set -e

echo "=========================================="
echo "EDS-Lite Local Infrastructure Setup"
echo "=========================================="
echo ""

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    echo "Detected: macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    echo "Detected: Linux"
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

echo ""

# Check for Homebrew (macOS) or apt (Linux)
if [[ "$OS" == "macos" ]]; then
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    INSTALL_CMD="brew install"
elif [[ "$OS" == "linux" ]]; then
    if command -v apt-get &> /dev/null; then
        INSTALL_CMD="sudo apt-get install -y"
        UPDATE_CMD="sudo apt-get update"
    elif command -v yum &> /dev/null; then
        INSTALL_CMD="sudo yum install -y"
        UPDATE_CMD="sudo yum update -y"
    else
        echo "No package manager found (apt-get or yum)"
        exit 1
    fi
fi

# Install Redis
echo ""
echo "--- Installing Redis ---"
if command -v redis-server &> /dev/null; then
    echo "✓ Redis is already installed"
else
    echo "Installing Redis..."
    if [[ "$OS" == "macos" ]]; then
        $INSTALL_CMD redis
    else
        $UPDATE_CMD
        $INSTALL_CMD redis-server
    fi
    echo "✓ Redis installed"
fi

# Install MongoDB
echo ""
echo "--- Installing MongoDB ---"
if command -v mongod &> /dev/null; then
    echo "✓ MongoDB is already installed"
else
    echo "Installing MongoDB..."
    if [[ "$OS" == "macos" ]]; then
        brew tap mongodb/brew
        $INSTALL_CMD mongodb-community
    else
        # For Linux, we'll use the official MongoDB installation
        echo "For Linux, please install MongoDB manually:"
        echo "  See: https://www.mongodb.com/docs/manual/installation/"
        echo ""
        echo "Or use MongoDB Atlas (cloud): https://www.mongodb.com/cloud/atlas"
        read -p "Press Enter to continue (or Ctrl+C to install MongoDB manually)..."
    fi
    echo "✓ MongoDB installation attempted"
fi

# Install Redpanda (Kafka-compatible)
echo ""
echo "--- Installing Redpanda (Kafka) ---"
if command -v rpk &> /dev/null; then
    echo "✓ Redpanda is already installed"
else
    echo "Installing Redpanda..."
    if [[ "$OS" == "macos" ]]; then
        brew tap redpanda-data/tap
        $INSTALL_CMD redpanda
    else
        echo "For Linux, installing Redpanda..."
        if command -v curl &> /dev/null; then
            curl -1sLf 'https://packages.vectorized.io/nzc4ZYQK3WRGd9sy/redpanda/cfg/setup/bash.deb.sh' | sudo bash
            sudo apt-get install -y redpanda
        else
            echo "curl not found. Please install curl first: sudo apt-get install curl"
            echo "Then run this script again or install Redpanda manually"
        fi
    fi
    if command -v rpk &> /dev/null; then
        echo "✓ Redpanda CLI installed"
    else
        echo "⚠ Redpanda CLI installation may have failed. You may need to install manually."
    fi
fi

# Check for Docker (needed for rpk container on macOS)
if [[ "$OS" == "macos" ]]; then
    echo ""
    echo "Note: On macOS, Redpanda uses Docker via 'rpk container start'."
    if ! command -v docker &> /dev/null; then
        echo "⚠ Docker not found. You have two options:"
        echo "  1. Install Docker Desktop: https://www.docker.com/products/docker-desktop"
        echo "  2. Use Confluent Cloud (cloud Kafka) - see README for setup"
    else
        echo "✓ Docker is available (needed for rpk container)"
    fi
fi

# Create necessary directories
echo ""
echo "--- Creating directories ---"
mkdir -p /tmp/mongodb-data
mkdir -p /tmp/metrics
echo "✓ Directories created"

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Start Redis:     ./scripts/start-redis.sh"
echo "2. Start MongoDB:   ./scripts/start-mongo.sh"
echo "3. Start Redpanda:  ./scripts/start-redpanda.sh"
echo "4. Seed MongoDB:    mongosh mongodb://localhost:27017/eds < scripts/seed-mongo.js"
echo ""

