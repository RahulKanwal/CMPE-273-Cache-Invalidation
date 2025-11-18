#!/bin/bash

# Start Apache Kafka (native, no Docker)
# This is an alternative to Redpanda that doesn't require Docker

set -e

echo "Starting Apache Kafka..."

# Check if Kafka is installed
KAFKA_HOME=""
KAFKA_BIN_DIR=""

if [ -n "$KAFKA_HOME" ] && [ -d "$KAFKA_HOME" ]; then
    # Use environment variable if set
    KAFKA_HOME="$KAFKA_HOME"
    if [ -d "$KAFKA_HOME/bin" ]; then
        KAFKA_BIN_DIR="$KAFKA_HOME/bin"
    elif [ -d "$KAFKA_HOME/libexec/bin" ]; then
        KAFKA_BIN_DIR="$KAFKA_HOME/libexec/bin"
    fi
elif command -v brew &> /dev/null && [ -d "$(brew --prefix kafka 2>/dev/null)" ]; then
    # Homebrew installation - check both standard and libexec locations
    BREW_KAFKA="$(brew --prefix kafka)"
    if [ -f "$BREW_KAFKA/libexec/bin/kafka-server-start.sh" ]; then
        # Homebrew uses libexec/bin
        KAFKA_HOME="$BREW_KAFKA"
        KAFKA_BIN_DIR="$BREW_KAFKA/libexec/bin"
    elif [ -f "$BREW_KAFKA/bin/kafka-server-start.sh" ]; then
        # Standard installation
        KAFKA_HOME="$BREW_KAFKA"
        KAFKA_BIN_DIR="$BREW_KAFKA/bin"
    fi
elif [ -d "/opt/homebrew/opt/kafka" ]; then
    # Homebrew on Apple Silicon
    if [ -f "/opt/homebrew/opt/kafka/libexec/bin/kafka-server-start.sh" ]; then
        KAFKA_HOME="/opt/homebrew/opt/kafka"
        KAFKA_BIN_DIR="/opt/homebrew/opt/kafka/libexec/bin"
    elif [ -f "/opt/homebrew/opt/kafka/bin/kafka-server-start.sh" ]; then
        KAFKA_HOME="/opt/homebrew/opt/kafka"
        KAFKA_BIN_DIR="/opt/homebrew/opt/kafka/bin"
    fi
elif [ -d "/usr/local/opt/kafka" ]; then
    # Homebrew on Intel Mac
    if [ -f "/usr/local/opt/kafka/libexec/bin/kafka-server-start.sh" ]; then
        KAFKA_HOME="/usr/local/opt/kafka"
        KAFKA_BIN_DIR="/usr/local/opt/kafka/libexec/bin"
    elif [ -f "/usr/local/opt/kafka/bin/kafka-server-start.sh" ]; then
        KAFKA_HOME="/usr/local/opt/kafka"
        KAFKA_BIN_DIR="/usr/local/opt/kafka/bin"
    fi
elif [ -d "/opt/kafka" ] && [ -f "/opt/kafka/bin/kafka-server-start.sh" ]; then
    KAFKA_HOME="/opt/kafka"
    KAFKA_BIN_DIR="/opt/kafka/bin"
elif [ -d "/usr/local/kafka" ] && [ -f "/usr/local/kafka/bin/kafka-server-start.sh" ]; then
    KAFKA_HOME="/usr/local/kafka"
    KAFKA_BIN_DIR="/usr/local/kafka/bin"
elif [ -d "$HOME/kafka" ] && [ -f "$HOME/kafka/bin/kafka-server-start.sh" ]; then
    KAFKA_HOME="$HOME/kafka"
    KAFKA_BIN_DIR="$HOME/kafka/bin"
fi

if [ -z "$KAFKA_BIN_DIR" ] || [ ! -f "$KAFKA_BIN_DIR/kafka-server-start.sh" ]; then
    echo "❌ Kafka not found!"
    echo ""
    echo "Please install Apache Kafka:"
    echo ""
    echo "Option 1: Download and extract Kafka"
    echo "  wget https://downloads.apache.org/kafka/2.13-3.6.1/kafka_2.13-3.6.1.tgz"
    echo "  tar -xzf kafka_2.13-3.6.1.tgz"
    echo "  mv kafka_2.13-3.6.1 ~/kafka"
    echo "  export KAFKA_HOME=~/kafka"
    echo ""
    echo "Option 2: Use Homebrew (macOS)"
    echo "  brew install kafka"
    echo ""
    echo "Option 3: Use Confluent Cloud (cloud, no local setup)"
    echo "  export KAFKA_BOOTSTRAP_SERVERS=your-bootstrap-servers"
    echo "  export KAFKA_SECURITY_PROTOCOL=SASL_SSL"
    echo "  export KAFKA_SASL_JAAS_CONFIG='...'"
    echo ""
    exit 1
fi

echo "Kafka installation found at: $KAFKA_HOME"
echo "Kafka bin directory: $KAFKA_BIN_DIR"

# Create log directories
mkdir -p /tmp/kafka-logs
mkdir -p /tmp/zookeeper-data

# Find config directory
KAFKA_CONFIG_DIR=""
if [ -d "$KAFKA_HOME/config" ]; then
    KAFKA_CONFIG_DIR="$KAFKA_HOME/config"
elif [ -d "/opt/homebrew/etc/kafka" ]; then
    KAFKA_CONFIG_DIR="/opt/homebrew/etc/kafka"
elif [ -d "/usr/local/etc/kafka" ]; then
    KAFKA_CONFIG_DIR="/usr/local/etc/kafka"
fi

# Start Zookeeper (if needed for Kafka < 3.0)
if [ -f "$KAFKA_BIN_DIR/zookeeper-server-start.sh" ]; then
    if ! pgrep -f "zookeeper" > /dev/null; then
        echo "Starting Zookeeper..."
        if [ -n "$KAFKA_CONFIG_DIR" ] && [ -f "$KAFKA_CONFIG_DIR/zookeeper.properties" ]; then
            $KAFKA_BIN_DIR/zookeeper-server-start.sh $KAFKA_CONFIG_DIR/zookeeper.properties > /tmp/zookeeper.log 2>&1 &
        else
            $KAFKA_BIN_DIR/zookeeper-server-start.sh $KAFKA_HOME/libexec/config/zookeeper.properties > /tmp/zookeeper.log 2>&1 &
        fi
        sleep 5
        echo "✓ Zookeeper started"
    else
        echo "✓ Zookeeper is already running"
    fi
fi

# Start Kafka
if pgrep -f "kafka.Kafka" > /dev/null; then
    echo "✓ Kafka is already running on localhost:9092"
else
    echo "Starting Kafka on localhost:9092..."
    
    # Find server.properties
    KAFKA_CONFIG=""
    if [ -n "$KAFKA_CONFIG_DIR" ] && [ -f "$KAFKA_CONFIG_DIR/server.properties" ]; then
        KAFKA_CONFIG="$KAFKA_CONFIG_DIR/server.properties"
    elif [ -f "$KAFKA_HOME/libexec/config/server.properties" ]; then
        KAFKA_CONFIG="$KAFKA_HOME/libexec/config/server.properties"
    elif [ -f "$KAFKA_HOME/config/server.properties" ]; then
        KAFKA_CONFIG="$KAFKA_HOME/config/server.properties"
    fi
    
    if [ -z "$KAFKA_CONFIG" ] || [ ! -f "$KAFKA_CONFIG" ]; then
        echo "❌ Kafka config not found. Tried:"
        echo "   $KAFKA_CONFIG_DIR/server.properties"
        echo "   $KAFKA_HOME/libexec/config/server.properties"
        echo "   $KAFKA_HOME/config/server.properties"
        exit 1
    fi
    
    echo "Using config: $KAFKA_CONFIG"
    
    # Start Kafka
    $KAFKA_BIN_DIR/kafka-server-start.sh $KAFKA_CONFIG > /tmp/kafka.log 2>&1 &
    
    echo "Waiting for Kafka to start..."
    sleep 10
    
    # Wait for Kafka to be ready
    echo "Waiting for Kafka to be ready..."
    for i in {1..30}; do
        if $KAFKA_BIN_DIR/kafka-broker-api-versions.sh --bootstrap-server localhost:9092 > /dev/null 2>&1; then
            echo "✓ Kafka is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "⚠ Kafka may still be starting. Continuing anyway..."
        fi
        sleep 1
    done
fi

# Create topics
echo "Creating topics..."
$KAFKA_BIN_DIR/kafka-topics.sh --create --bootstrap-server localhost:9092 \
    --topic cache.invalidate --partitions 1 --replication-factor 1 2>/dev/null || \
    echo "  Topic cache.invalidate already exists"

$KAFKA_BIN_DIR/kafka-topics.sh --create --bootstrap-server localhost:9092 \
    --topic order.events --partitions 1 --replication-factor 1 2>/dev/null || \
    echo "  Topic order.events already exists"

echo ""
echo "✓ Kafka started successfully"
echo "Bootstrap servers: PLAINTEXT://localhost:9092"
echo ""
echo "To stop Kafka:"
echo "  $KAFKA_BIN_DIR/kafka-server-stop.sh"
if [ -f "$KAFKA_BIN_DIR/zookeeper-server-stop.sh" ]; then
    echo "  $KAFKA_BIN_DIR/zookeeper-server-stop.sh"
fi

