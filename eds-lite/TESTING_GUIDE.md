# Testing Guide

This guide explains how to test the EDS-Lite cache invalidation system.

## Two Testing Options

### Option 1: Quick Test (5 minutes) ⚡
Fast validation that cache invalidation is working.

### Option 2: Full Scenario Test (30-45 minutes) 📊
Complete comparison of all three caching strategies with load testing.

---

## Prerequisites

Before running any tests, ensure all services are running:

```bash
# Terminal 1: Kafka
./scripts/start-kafka.sh

# Terminal 2: Redis
./scripts/start-redis.sh

# Terminal 3: MongoDB
./scripts/start-mongo.sh

# Terminal 4: API Gateway
cd api-gateway
mvn spring-boot:run

# Terminal 5: Order Service
cd order-service
mvn spring-boot:run

# Terminal 6: Catalog Service
cd catalog-service
export CACHE_MODE=ttl_invalidate
mvn spring-boot:run
```

Verify all services are running:
```bash
./scripts/check-services.sh
```

---

## Option 1: Quick Test ⚡

**What it does:**
- Tests basic cache hit/miss behavior
- Updates a product and verifies cache invalidation
- Checks that fresh data is retrieved after update
- Takes ~2 minutes

**How to run:**
```bash
cd eds-lite/scripts
./quick-test.sh
```

**Expected output:**
```
✓ API Gateway is running
✓ Catalog Service is running
✓ Redis is running
✓ MongoDB is running
✓ Kafka is running

Test 1: First Read (Cache Miss)
✓ Product retrieved

Test 2: Second Read (Cache Hit)
✓ Product retrieved from cache

Test 3: Update Product (Triggers Cache Invalidation)
✓ Product updated

Test 4: Read After Update (Should Get Fresh Data)
✓ Fresh data retrieved! Price=199.99, Stock=999
✓ Cache invalidation worked!

Test 5: Check Metrics
Metrics Summary:
  Cache Hits: 15
  Cache Misses: 3
  Invalidations Sent: 1

✓ Cache invalidation is working correctly! 🎉
```

**What to look for in logs:**
In the catalog-service terminal, you should see:
```
invalidations_sent: 1
Cache cleared for product 1
invalidations_received: 1
```

---

## Option 2: Full Scenario Test 📊

**What it does:**
- Runs all three scenarios (A, B, C) with k6 load testing
- Automatically switches between cache modes
- Generates performance comparison report
- Takes ~30-45 minutes

**How to run:**
```bash
cd eds-lite/scripts
./run-all-scenarios.sh
```

**What happens:**

### Scenario A: No Cache (CACHE_MODE=none)
1. Stops catalog-service
2. Starts with `CACHE_MODE=none`
3. Runs k6 load test (90% reads, 10% writes)
4. Backs up metrics
5. Expected: High latency, 0% cache hit rate

### Scenario B: TTL-Only Cache (CACHE_MODE=ttl)
1. Stops catalog-service
2. Starts with `CACHE_MODE=ttl`
3. Runs k6 load test
4. Backs up metrics
5. Expected: Low latency, 85-95% hit rate, stale reads present

### Scenario C: TTL + Kafka Invalidation (CACHE_MODE=ttl_invalidate)
1. Stops catalog-service
2. Starts with `CACHE_MODE=ttl_invalidate`
3. Runs k6 load test
4. Backs up metrics
5. Expected: Low latency, 85-95% hit rate, minimal stale reads

**Results location:**
```
/tmp/eds-results/YYYYMMDD_HHMMSS/
├── scenario-A-metrics/
├── scenario-B-metrics/
├── scenario-C-metrics/
└── RESULTS_SUMMARY.txt
```

**View results:**
```bash
# Find the latest results
ls -lt /tmp/eds-results/

# View summary
cat /tmp/eds-results/YYYYMMDD_HHMMSS/RESULTS_SUMMARY.txt
```

**Expected comparison:**

| Metric | Scenario A (No Cache) | Scenario B (TTL) | Scenario C (TTL+Inv) |
|--------|----------------------|------------------|---------------------|
| p95 Latency | 50-100ms | 5-10ms | 5-10ms |
| Cache Hit Rate | 0% | 85-95% | 85-95% |
| Stale Read Rate | 0% | >5% | <1% |
| Inconsistency Window | N/A | ~300s (TTL) | <100ms |

---

## Manual Testing with curl

If you prefer manual testing:

### 1. Get a product (cache miss)
```bash
curl http://localhost:8080/api/catalog/products/1
```

### 2. Get again (cache hit)
```bash
curl http://localhost:8080/api/catalog/products/1
```

### 3. Update the product
```bash
curl -X POST http://localhost:8080/api/catalog/products/1 \
  -H "Content-Type: application/json" \
  -d '{"price": 99.99, "stock": 50}'
```

### 4. Get again (fresh data)
```bash
curl http://localhost:8080/api/catalog/products/1
```

### 5. Check metrics
```bash
cat /tmp/metrics/catalog.jsonl | tail -20
```

---

## Testing with Demo UI

Start the demo page:
```bash
./scripts/serve-demo.sh
```

Open browser: http://localhost:8000/demo.html

**Features:**
- Get Product: Test cache hits/misses
- Update Product: Trigger cache invalidation
- Create Order: Test order service
- Run Cache Test: Automated test sequence

---

## Troubleshooting

### Services not starting
```bash
# Check what's running
./scripts/check-services.sh

# Check specific port
lsof -i :8081

# Kill stuck process
lsof -ti:8081 | xargs kill -9
```

### No metrics appearing
```bash
# Check metrics directory
ls -la /tmp/metrics/

# Create if missing
mkdir -p /tmp/metrics
chmod 777 /tmp/metrics
```

### k6 not found
```bash
# macOS
brew install k6

# Linux
sudo apt-get install k6
```

### Python not found
```bash
# macOS
brew install python3

# Linux
sudo apt-get install python3
```

### Catalog service won't start
```bash
# Check logs
tail -f /tmp/catalog-*.log

# Rebuild
cd catalog-service
mvn clean package -DskipTests
```

---

## Understanding the Results

### Cache Hit Rate
- **Good:** 85-95% (most reads served from cache)
- **Bad:** <50% (cache not effective)

### Stale Read Rate
- **Scenario A (no cache):** 0% (always fresh, but slow)
- **Scenario B (TTL only):** 5-20% (stale until TTL expires)
- **Scenario C (TTL+invalidation):** <1% (near-zero stale reads)

### Inconsistency Window
- **Time between update and cache invalidation**
- **Scenario B:** ~300 seconds (TTL duration)
- **Scenario C:** <100 milliseconds (Kafka propagation)

### p95 Latency
- **Scenario A:** 50-100ms (every read hits MongoDB)
- **Scenario B & C:** 5-10ms (most reads from Redis)

---

## What Success Looks Like

**Quick Test:**
```
✓ Cache hit on second read
✓ Update triggers invalidation
✓ Fresh data after update
✓ Metrics show invalidations_sent > 0
```

**Full Scenario Test:**
```
Scenario C shows:
✓ Low latency (similar to Scenario B)
✓ High cache hit rate (85-95%)
✓ Near-zero stale reads (<1%)
✓ Fast invalidation (<100ms)
```

**This proves Kafka-based invalidation gives you:**
- **Speed of caching** (low latency)
- **Freshness of no-cache** (minimal stale reads)
- **Best of both worlds!** 🎉

---

## Next Steps

After successful testing:

1. **Review metrics:** Understand the performance characteristics
2. **Experiment:** Try different TTL values, cache sizes
3. **Scale:** Run multiple catalog-service instances to see distributed invalidation
4. **Customize:** Modify k6 scripts for your workload patterns

---

## Quick Reference

```bash
# Quick validation (2 minutes)
./scripts/quick-test.sh

# Full comparison (30-45 minutes)
./scripts/run-all-scenarios.sh

# Manual test
./scripts/test-apis.sh

# Check services
./scripts/check-services.sh

# View metrics
cat /tmp/metrics/catalog.jsonl | tail -20

# Analyze metrics
python3 scripts/summarize-metrics.py
```
