#!/bin/bash

# Start Redpanda (Kafka-compatible)
# Run ./scripts/setup-local.sh first to install Redpanda

set -e

echo "Starting Redpanda..."

# Check if redpanda is installed
if ! command -v rpk &> /dev/null; then
    echo "❌ Redpanda not found!"
    echo ""
    echo "Please run the setup script first:"
    echo "  ./scripts/setup-local.sh"
    echo ""
    echo "Or install manually:"
    echo "  macOS: brew tap redpanda-data/tap && brew install redpanda"
    echo "  Linux: See https://docs.redpanda.com/getting-started/quick-start"
    exit 1
fi

# Check if Redpanda is already running
if rpk cluster info --brokers localhost:9092 > /dev/null 2>&1; then
    echo "✓ Redpanda is already running on localhost:9092"
else
    echo "Starting Redpanda on localhost:9092..."
    
    # Check if Docker is available (for rpk container)
    if command -v docker &> /dev/null && docker info > /dev/null 2>&1; then
        echo "Using rpk container start (requires Docker)..."
        # Start Redpanda using container mode
        rpk container start \
            --kafka-ports 9092 \
            --console-port 8080 \
            --nodes 1 > /tmp/redpanda.log 2>&1 || {
            echo "⚠ Container start failed, checking if already running..."
        }
        
        echo "Waiting for Redpanda to start..."
        sleep 10
        
        # Wait for Redpanda to be ready
        for i in {1..30}; do
            if rpk cluster info --brokers localhost:9092 > /dev/null 2>&1; then
                break
            fi
            sleep 1
        done
    else
        # Try to find redpanda binary (native installation)
        REDPANDA_BIN=""
        if command -v redpanda &> /dev/null; then
            REDPANDA_BIN="redpanda"
        elif [ -f "/opt/homebrew/bin/redpanda" ]; then
            REDPANDA_BIN="/opt/homebrew/bin/redpanda"
        elif [ -f "/usr/local/bin/redpanda" ]; then
            REDPANDA_BIN="/usr/local/bin/redpanda"
        fi
        
        if [ -n "$REDPANDA_BIN" ]; then
            echo "Using native Redpanda installation..."
            mkdir -p /tmp/redpanda-data
            
            $REDPANDA_BIN start \
                --smp 1 \
                --memory 1G \
                --node-id 0 \
                --kafka-addr 0.0.0.0:9092 \
                --advertise-kafka-addr localhost:9092 \
                --rpc-addr 127.0.0.1:33145 \
                --advertise-rpc-addr 127.0.0.1:33145 \
                --data-directory /tmp/redpanda-data \
                --mode dev-container \
                --default-log-level=info > /tmp/redpanda.log 2>&1 &
            
            echo "Waiting for Redpanda to start..."
            sleep 8
        else
            echo "❌ Redpanda binary not found and Docker is not available."
            echo ""
            echo "Options:"
            echo "1. Use Apache Kafka (native, no Docker):"
            echo "   ./scripts/setup-kafka.sh"
            echo "   ./scripts/start-kafka.sh"
            echo ""
            echo "2. Use Confluent Cloud (cloud Kafka, no local setup):"
            echo "   export KAFKA_BOOTSTRAP_SERVERS=your-bootstrap-servers"
            echo "   export KAFKA_SECURITY_PROTOCOL=SASL_SSL"
            echo "   export KAFKA_SASL_JAAS_CONFIG='...'"
            echo ""
            echo "3. Install Docker and use: rpk container start"
            echo ""
            exit 1
        fi
    fi
    
    # Wait for Redpanda to be ready
    echo "Waiting for Redpanda to be ready..."
    for i in {1..30}; do
        if rpk cluster info --brokers localhost:9092 > /dev/null 2>&1; then
            echo "✓ Redpanda is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "⚠ Redpanda may still be starting. Continuing anyway..."
        fi
        sleep 1
    done
    
    # Create topics
    echo "Creating topics..."
    rpk topic create cache.invalidate --brokers localhost:9092 2>/dev/null || echo "  Topic cache.invalidate already exists"
    rpk topic create order.events --brokers localhost:9092 2>/dev/null || echo "  Topic order.events already exists"
    
    # Final verification
    if rpk cluster info --brokers localhost:9092 > /dev/null 2>&1; then
        echo "✓ Redpanda started successfully"
        echo "Bootstrap servers: PLAINTEXT://localhost:9092"
    else
        echo "⚠ Redpanda may not be fully ready yet, but topics were created."
        echo "  You can check status with: rpk cluster info --brokers localhost:9092"
    fi
fi

echo ""
echo "To use Confluent Cloud instead, set:"
echo "  export KAFKA_BOOTSTRAP_SERVERS=your-bootstrap-servers"
echo "  export KAFKA_SECURITY_PROTOCOL=SASL_SSL"
echo "  export KAFKA_SASL_JAAS_CONFIG='org.apache.kafka.common.security.plain.PlainLoginModule required username=\"...\" password=\"...\";'"

