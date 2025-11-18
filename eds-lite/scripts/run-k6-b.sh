#!/bin/bash

# Scenario B: TTL only (no invalidation consumer)
# Set CACHE_MODE=ttl in catalog-service before running

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
K6_SCRIPT="$SCRIPT_DIR/../ops/k6/load-mixed.js"

echo "Running k6 load test - Scenario B: TTL Only"
echo "Make sure catalog-service is running with CACHE_MODE=ttl"
echo ""

BASE_URL=${BASE_URL:-http://localhost:8080}

# Copy k6 script to /tmp to avoid path issues with spaces in directory names
cp "$K6_SCRIPT" /tmp/load-mixed.js
cd /tmp
k6 run --env BASE_URL="$BASE_URL" load-mixed.js

echo ""
echo "Test complete. Check /tmp/metrics/catalog.jsonl for metrics."

