#!/bin/bash
# Start catalog-service (same simple pattern as api-gateway and order-service)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CATALOG_DIR="$PROJECT_ROOT/catalog-service"

# Stop any existing instance on port 8081
echo "Checking for existing catalog-service instances..."
if lsof -ti:8081 >/dev/null 2>&1; then
    echo "Stopping existing process on port 8081..."
    lsof -ti:8081 | xargs kill -9 2>/dev/null
    sleep 2
fi

# Kill any catalog-service Java processes
pkill -f "CatalogServiceApplication" 2>/dev/null
sleep 1

# Navigate to catalog-service directory
cd "$CATALOG_DIR" || {
    echo "Error: Could not find catalog-service directory"
    exit 1
}

# Set cache mode (default to ttl_invalidate)
export CACHE_MODE=${CACHE_MODE:-ttl_invalidate}

echo "=========================================="
echo "Starting catalog-service"
echo "  Port: 8081"
echo "  Cache Mode: $CACHE_MODE"
echo "=========================================="
echo ""

# Start the service (exactly like api-gateway and order-service)
mvn spring-boot:run

