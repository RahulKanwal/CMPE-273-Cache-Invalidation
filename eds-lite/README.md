# EDS-Lite: Kafka-Based Distributed Cache Invalidation Demo

A minimal microservices application demonstrating Kafka-based distributed cache invalidation with measurable performance metrics.

## Architecture

- **api-gateway** (8080): Spring Cloud Gateway routing requests
- **catalog-service** (8081): Product catalog with MongoDB storage and Redis caching
- **order-service** (8082): Order management with MongoDB

## Prerequisites

- Java 21
- Maven 3.8+
- Redis (local or Upstash)
- MongoDB (local or Atlas)
- Kafka (Redpanda local or Confluent Cloud)
- k6 (for load testing)
- Python 3.8+ (for metrics summarization)

## Quick Start

### 0. Setup Local Infrastructure (First Time Only)

```bash
# Install and setup Redis, MongoDB, and Kafka
./scripts/setup-local.sh

# For Kafka, choose one:
# Option A: Apache Kafka (native, no Docker) - RECOMMENDED
./scripts/setup-kafka.sh

# Option B: Redpanda (requires Docker on macOS)
# ./scripts/setup-local.sh  # Already includes Redpanda setup
```

### 1. Start Infrastructure

```bash
# Terminal 1: Start Kafka (choose one)
# Option A: Apache Kafka (no Docker) - RECOMMENDED
./scripts/start-kafka.sh

# Option B: Redpanda (requires Docker)
# ./scripts/start-redpanda.sh

# Option C: Use Confluent Cloud (no local setup)
# Just set environment variables (see Step 2)

# Terminal 2: Start Redis
./scripts/start-redis.sh

# Terminal 3: Start MongoDB
./scripts/start-mongo.sh

# Verify all services are running
./scripts/check-services.sh

# Terminal 4: Seed MongoDB with products
mongosh mongodb://localhost:27017/eds < scripts/seed-mongo.js
```

### 2. Configure Kafka (if using Confluent Cloud)

Set environment variables:
```bash
export KAFKA_BOOTSTRAP_SERVERS=your-bootstrap-servers
export KAFKA_SASL_JAAS_CONFIG=your-jaas-config
export KAFKA_SECURITY_PROTOCOL=SASL_SSL
```

Or edit `catalog-service/src/main/resources/application.yml` and `order-service/src/main/resources/application.yml`.

### 3. Run Services

```bash
# Terminal 5: Catalog Service
cd catalog-service
export CACHE_MODE=ttl_invalidate  # Options: none, ttl, ttl_invalidate
mvn spring-boot:run

# Terminal 6: Order Service
cd order-service
mvn spring-boot:run

# Terminal 7: API Gateway
cd api-gateway
mvn spring-boot:run
```

### 4. Test Cache Invalidation

```bash
# Update a product
curl -X POST http://localhost:8080/api/catalog/products/1 \
  -H "Content-Type: application/json" \
  -d '{"price": 99.99, "stock": 50}'

# Read the product (should be fresh)
curl http://localhost:8080/api/catalog/products/1
```

Check logs for `invalidations_sent` and `invalidations_received` metrics.

### 5. Test the System

**Option A: Quick Test (2 minutes)**
```bash
./scripts/quick-test.sh
```

**Option B: Full Scenario Comparison (30-45 minutes)**
```bash
./scripts/run-all-scenarios.sh
```

See [TESTING_GUIDE.md](TESTING_GUIDE.md) for detailed testing instructions.

## Cache Modes

- **none**: Disable caching entirely
- **ttl**: Enable caching with TTL, but no Kafka invalidation consumer
- **ttl_invalidate**: Enable caching + Kafka invalidation consumer (default)

## Metrics

Metrics are written to `/tmp/metrics/*.jsonl`:
- `catalog.jsonl`: Cache hits/misses, invalidations, stale reads, inconsistency windows
- `gateway.jsonl`: Request latencies
- `order.jsonl`: Order operations

## Expected Results

| Scenario | p95 (ms) | Hit Rate | Stale Rate | Inconsistency p95 (ms) |
|----------|----------|----------|------------|------------------------|
| A (none) | HIGH     | 0%       | 0%         | 0                      |
| B (ttl)  | LOW      | 85-95%   | >0%        | ≈ TTL (seconds)        |
| C (ttl+inv) | LOW   | 85-95%   | ~0%        | < 100                  |

## Project Structure

```
eds-lite/
├── api-gateway/          # Spring Cloud Gateway
├── catalog-service/      # Product catalog with cache invalidation
├── order-service/        # Order management
├── scripts/              # Infrastructure and test scripts
│   ├── start-redpanda.sh
│   ├── start-redis.sh
│   ├── start-mongo.sh
│   ├── seed-mongo.js
│   ├── run-k6-a.sh
│   ├── run-k6-b.sh
│   ├── run-k6-c.sh
│   └── summarize-metrics.py
└── ops/
    └── k6/
        └── load-mixed.js
```

## Testing Scripts

Two automated testing options are available:

### Quick Test (2 minutes)
Fast validation that cache invalidation is working:
```bash
./scripts/quick-test.sh
```

This script:
- Verifies all services are running
- Tests cache hit/miss behavior
- Updates a product and verifies invalidation
- Shows metrics summary

### Full Scenario Test (30-45 minutes)
Complete comparison of all three caching strategies:
```bash
./scripts/run-all-scenarios.sh
```

This script:
- Automatically runs Scenarios A, B, and C
- Switches cache modes between tests
- Runs k6 load tests for each scenario
- Generates comparison report in `/tmp/eds-results/`

See [TESTING_GUIDE.md](TESTING_GUIDE.md) for detailed instructions.

## Troubleshooting

- **Kafka connection issues**: Check `KAFKA_BOOTSTRAP_SERVERS` and security config
- **Redis connection**: Ensure Redis is running on localhost:6379
- **MongoDB connection**: Check `mongodb://localhost:27017/eds`
- **Metrics not appearing**: Ensure `/tmp/metrics/` directory exists and is writable
- **Services not starting**: Run `./scripts/check-services.sh` to diagnose

