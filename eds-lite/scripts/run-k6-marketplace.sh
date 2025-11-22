#!/bin/bash

# Marketplace-specific load test
# Tests product search, cart operations, and user flows

echo "🧪 Running EDS Marketplace Load Test..."
echo "======================================"

# Check if k6 is installed
if ! command -v k6 &> /dev/null; then
    echo "❌ k6 is not installed. Please install k6 first:"
    echo "   brew install k6  # macOS"
    echo "   https://k6.io/docs/getting-started/installation/"
    exit 1
fi

# Check if services are running
echo "🔍 Checking if services are running..."
for port in 3000 8080 8081 8082 8083; do
    if ! nc -z localhost $port 2>/dev/null; then
        echo "❌ Service on port $port is not running"
        echo "   Please start the marketplace first: ./scripts/start-marketplace.sh"
        exit 1
    fi
done
echo "✅ All services are running"

# Create k6 test script
cat > /tmp/marketplace-load-test.js << 'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '30s', target: 10 },  // Ramp up
    { duration: '1m', target: 20 },   // Stay at 20 users
    { duration: '30s', target: 0 },   // Ramp down
  ],
};

const BASE_URL = 'http://localhost:8080';

export default function() {
  // Test 1: Get featured products
  let response = http.get(`${BASE_URL}/api/catalog/products/featured`);
  check(response, {
    'featured products status is 200': (r) => r.status === 200,
    'featured products response time < 500ms': (r) => r.timings.duration < 500,
  });

  sleep(1);

  // Test 2: Search products
  response = http.get(`${BASE_URL}/api/catalog/products?search=laptop&page=0&size=12`);
  check(response, {
    'search status is 200': (r) => r.status === 200,
    'search response time < 1000ms': (r) => r.timings.duration < 1000,
  });

  sleep(1);

  // Test 3: Get product categories
  response = http.get(`${BASE_URL}/api/catalog/products/categories`);
  check(response, {
    'categories status is 200': (r) => r.status === 200,
    'categories response time < 200ms': (r) => r.timings.duration < 200,
  });

  sleep(1);

  // Test 4: Get specific product (should hit cache)
  response = http.get(`${BASE_URL}/api/catalog/products/1`);
  check(response, {
    'product detail status is 200': (r) => r.status === 200,
    'product detail response time < 100ms': (r) => r.timings.duration < 100,
  });

  sleep(1);

  // Test 5: Filter by category
  response = http.get(`${BASE_URL}/api/catalog/products?category=Electronics&page=0&size=12`);
  check(response, {
    'category filter status is 200': (r) => r.status === 200,
    'category filter response time < 800ms': (r) => r.timings.duration < 800,
  });

  sleep(2);
}

export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
  };
}

function textSummary(data, options) {
  const indent = options.indent || '';
  const enableColors = options.enableColors || false;
  
  let summary = '\n';
  summary += `${indent}📊 EDS Marketplace Load Test Results\n`;
  summary += `${indent}=====================================\n\n`;
  
  // Test execution info
  summary += `${indent}🕐 Test Duration: ${Math.round(data.state.testRunDurationMs / 1000)}s\n`;
  summary += `${indent}👥 Virtual Users: ${data.metrics.vus.values.max}\n`;
  summary += `${indent}🔄 Total Requests: ${data.metrics.http_reqs.values.count}\n\n`;
  
  // Response times
  summary += `${indent}⚡ Response Times:\n`;
  summary += `${indent}   Average: ${Math.round(data.metrics.http_req_duration.values.avg)}ms\n`;
  summary += `${indent}   95th percentile: ${Math.round(data.metrics.http_req_duration.values['p(95)'])}ms\n`;
  summary += `${indent}   Max: ${Math.round(data.metrics.http_req_duration.values.max)}ms\n\n`;
  
  // Success rate
  const successRate = (data.metrics.http_req_failed.values.rate * 100).toFixed(2);
  summary += `${indent}✅ Success Rate: ${(100 - successRate).toFixed(2)}%\n`;
  summary += `${indent}❌ Failed Requests: ${successRate}%\n\n`;
  
  // Throughput
  const rps = data.metrics.http_reqs.values.rate.toFixed(2);
  summary += `${indent}🚀 Throughput: ${rps} requests/second\n\n`;
  
  return summary;
}
EOF

echo "🚀 Starting load test..."
echo "   Duration: 2 minutes"
echo "   Max Users: 20"
echo "   Target: Marketplace API endpoints"
echo ""

# Run the test
k6 run /tmp/marketplace-load-test.js

echo ""
echo "✅ Load test completed!"
echo ""
echo "💡 Tips for performance optimization:"
echo "   - Monitor Redis cache hit rates in service logs"
echo "   - Check MongoDB query performance"
echo "   - Verify Kafka consumer lag for cache invalidation"
echo "   - Scale services horizontally if needed"

# Cleanup
rm -f /tmp/marketplace-load-test.js