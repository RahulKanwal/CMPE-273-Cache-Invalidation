# Quick Start Guide

## Prerequisites

- Java 21
- Maven 3.8+
- Redis (local or Upstash)
- MongoDB (local or Atlas)  
- Kafka (Redpanda local or Confluent Cloud)
- k6 (for load testing)
- Python 3.8+ (for metrics)

## Step 0: Setup Infrastructure (First Time Only)

```bash
cd eds-lite

# Install Redis and MongoDB
./scripts/setup-local.sh

# For Kafka, choose one (no Docker required):
# Option A: Apache Kafka (native) - RECOMMENDED
./scripts/setup-kafka.sh

# Option B: Redpanda (requires Docker on macOS)
# ./scripts/setup-local.sh  # Already includes Redpanda
```

## Step 1: Start Infrastructure

```bash
# Terminal 1: Start Kafka (choose one)
# Option A: Apache Kafka (no Docker) - RECOMMENDED
./scripts/start-kafka.sh

# Option B: Redpanda (requires Docker)
# ./scripts/start-redpanda.sh

# Terminal 2: Start Redis
./scripts/start-redis.sh

# Terminal 3: Start MongoDB
./scripts/start-mongo.sh

# Verify all services are running
./scripts/check-services.sh

# Terminal 4: Seed MongoDB
mongosh mongodb://localhost:27017/eds < scripts/seed-mongo.js
# Or: node scripts/seed-mongo.js
```

## Step 2: Configure Services

### Option A: Use Local Services (Default)
No configuration needed - services use localhost defaults.

### Option B: Use Cloud Services

```bash
# For Confluent Cloud
export KAFKA_BOOTSTRAP_SERVERS=pkc-xxxxx.us-east-1.aws.confluent.cloud:9092
export KAFKA_SECURITY_PROTOCOL=SASL_SSL
export KAFKA_SASL_JAAS_CONFIG='org.apache.kafka.common.security.plain.PlainLoginModule required username="..." password="...";'

# For Upstash Redis
export REDIS_HOST=your-redis-host.upstash.io
export REDIS_PORT=6379

# For MongoDB Atlas
export MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/eds
```

## Step 3: Run Services

```bash
# Terminal 5: Catalog Service (choose cache mode)
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

## Step 4: Test the System

### Using the Demo Page

```bash
# Terminal 8: Start the demo frontend
./scripts/serve-demo.sh
```

Then open your browser and go to: **http://localhost:8000/demo.html**

The demo page lets you:
- Get products
- Update products (triggers cache invalidation)
- Create orders
- Run cache invalidation tests

### Using curl

```bash
# Get a product
curl http://localhost:8080/api/catalog/products/1

# Update a product (triggers cache invalidation)
curl -X POST http://localhost:8080/api/catalog/products/1 \
  -H "Content-Type: application/json" \
  -d '{"price": 99.99, "stock": 50}'

# Get product again (should be fresh)
curl http://localhost:8080/api/catalog/products/1

# Create an order
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "customer-123",
    "items": [
      {"productId": "1", "quantity": 2, "price": 10.00}
    ]
  }'
```

## Step 5: Run Load Tests

```bash
# Scenario A: No cache
cd scripts
export CACHE_MODE=none
# (restart catalog-service with CACHE_MODE=none)
./run-k6-a.sh

# Scenario B: TTL only
export CACHE_MODE=ttl
# (restart catalog-service with CACHE_MODE=ttl)
./run-k6-b.sh

# Scenario C: TTL + invalidation
export CACHE_MODE=ttl_invalidate
# (restart catalog-service with CACHE_MODE=ttl_invalidate)
./run-k6-c.sh
```

## Step 6: Analyze Metrics

```bash
# Summarize metrics from /tmp/metrics/*.jsonl
python3 scripts/summarize-metrics.py
```

## Expected Results

After running k6 tests and summarizing metrics, you should see:

| Scenario | p95 (ms) | Hit Rate | Stale Rate | Inconsistency p95 (ms) |
|----------|----------|----------|------------|------------------------|
| A (none) | HIGH     | 0%       | 0%         | 0                      |
| B (ttl)  | LOW      | 85-95%   | >0%        | ≈ TTL (300s)           |
| C (ttl+inv) | LOW   | 85-95%   | ~0%        | < 100                  |

## Troubleshooting

1. **Kafka connection errors**: Check `KAFKA_BOOTSTRAP_SERVERS` and security config
2. **Redis connection errors**: Ensure Redis is running or `REDIS_HOST` is set
3. **MongoDB connection errors**: Check `MONGODB_URI`
4. **No metrics**: Ensure `/tmp/metrics/` directory exists and is writable
5. **Cache not working**: Check `CACHE_MODE` environment variable

## Verification Checklist

- [ ] All infrastructure services running
- [ ] Products seeded in MongoDB
- [ ] All three services started successfully
- [ ] GET /api/catalog/products/1 returns product
- [ ] POST update triggers invalidation (check logs)
- [ ] Metrics appearing in /tmp/metrics/*.jsonl
- [ ] k6 tests complete successfully
- [ ] Metrics summary shows expected results

