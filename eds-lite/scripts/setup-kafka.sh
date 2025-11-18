#!/bin/bash

# Setup Apache Kafka (native installation, no Docker)

set -e

echo "=========================================="
echo "Apache Kafka Setup (No Docker)"
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

# Install Kafka
if [[ "$OS" == "macos" ]]; then
    if command -v brew &> /dev/null; then
        echo "Installing Kafka via Homebrew..."
        brew install kafka
        echo "✓ Kafka installed via Homebrew"
        echo ""
        echo "Kafka is typically installed at: /opt/homebrew/opt/kafka"
        echo "Or: /usr/local/opt/kafka"
        echo ""
        echo "To find Kafka location, run:"
        echo "  brew --prefix kafka"
    else
        echo "Homebrew not found. Please install Kafka manually:"
        echo "  1. Download: https://kafka.apache.org/downloads"
        echo "  2. Extract to ~/kafka"
        echo "  3. Set KAFKA_HOME=~/kafka"
    fi
else
    echo "For Linux, please install Kafka manually:"
    echo ""
    echo "Option 1: Download binary"
    echo "  wget https://downloads.apache.org/kafka/2.13-3.6.1/kafka_2.13-3.6.1.tgz"
    echo "  tar -xzf kafka_2.13-3.6.1.tgz"
    echo "  sudo mv kafka_2.13-3.6.1 /opt/kafka"
    echo ""
    echo "Option 2: Use package manager (if available)"
    echo "  sudo apt-get install kafka  # May not be available"
    echo ""
    echo "After installation, set:"
    echo "  export KAFKA_HOME=/opt/kafka"
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Start Kafka: ./scripts/start-kafka.sh"
echo ""
echo "Note: Make sure KAFKA_HOME is set if Kafka is not in standard location"
echo ""

