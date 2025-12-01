# How to Test Cache Scenarios Locally (with Text Results)

This guide shows you how to test all 3 cache scenarios locally and get results in a text file.

---

## ✅ Yes! You Can Test Locally with Existing Scripts

There are **2 test scripts** that generate text results:

1. **`test-cache-scenarios.sh`** - Full test of all 3 scenarios (15-20 minutes)
2. **`quick-cache-test.sh`** - Quick test of current scenario (2 minutes)

---

## Prerequisites

### Required Services Running:

```bash
# Terminal 1: MongoDB
./scripts/start-mongo.sh

# Terminal 2: Redis
./scripts/start-redis.sh

# Terminal 3: Kafka (for Scenario C)
./scripts/start-kafka.sh
```

### Seed Database:

```bash
mongosh mongodb://localhost:27017/eds < scripts/seed-marketplace.js
```

---

## Option 1: Full Test (All 3 Scenarios)

### What It Does:

- Tests Scenario A (No Cache)
- Tests Scenario B (TTL-Only)
- Tests Scenario C (TTL + Kafka)
- Automatically starts/stops catalog-service with different configs
- Generates comprehensive text report

### Run the Test:

```bash
cd eds-lite/scripts
./test-cache-scenarios.sh
```

### What Happens:

```
1. Checks infrastructure (MongoDB, Redis, Kafka)
2. Tests Scenario A:
   - Stops catalog-service
   - Starts with CACHE_MODE=none
   - Runs tests (read → read → update → read)
   - Records latencies and results
   - Stops service
3. Tests Scenario B:
   - Starts with CACHE_MODE=ttl
   - Runs tests
   - Records results
   - Stops service
4. Tests Scenario C:
   - Starts with CACHE_MODE=ttl_invalidate
   - Runs tests
   - Records results
   - Stops service
5. Generates summary report
```

### Output File:

```
cache-test-results-20240115_143022.txt
```

### View Results:

```bash
# View full results
cat cache-test-results-*.txt

# View just summary
grep -A 20 'FINAL TEST SUMMARY' cache-test-results-*.txt

# View specific scenario
grep -A 30 'Scenario A' cache-test-results-*.txt
```

### Sample Output:

```
EDS Marketplace Cache Scenarios Test Results
============================================
Test Run: Mon Jan 15 14:30:22 PST 2024
Test ID: 20240115_143022

This test validates the three cache invalidation scenarios:
1. Scenario A: No Cache (CACHE_MODE=none)
2. Scenario B: TTL-Only Cache (CACHE_MODE=ttl) 
3. Scenario C: TTL + Kafka Invalidation (CACHE_MODE=ttl_invalidate)

=========================================
Testing Scenario A: No Cache
=========================================

Test 1: First Read (Cache Miss Expected)
GET http://localhost:8081/products/1
Response time: 245ms
Price: 149.99, Version: 1

Test 2: Second Read (Cache Hit Expected for Cached Scenarios)
GET http://localhost:8081/products/1
Response time: 238ms
Price: 149.99, Version: 1

Test 3: Update Product
POST http://localhost:8081/products/1
Body: {"price": 199.99, "stock": 75}
Response time: 156ms
New Price: 199.99, New Version: 2

Test 4: Read After Update
GET http://localhost:8081/products/1
Response time: 241ms
Price: 199.99, Version: 2
✓ Fresh data confirmed (version updated)

Scenario A Summary:
- Cache Mode: No Cache
- First read: 245ms
- Second read: 238ms (no cache benefit)
- Update: 156ms
- Post-update read: 241ms
- Stale data detected: No

=========================================
Testing Scenario B: TTL-Only Cache
=========================================

Test 1: First Read (Cache Miss Expected)
GET http://localhost:8081/products/1
Response time: 251ms
Price: 149.99, Version: 1

Test 2: Second Read (Cache Hit Expected for Cached Scenarios)
GET http://localhost:8081/products/1
Response time: 12ms
Price: 149.99, Version: 1
✓ Cache hit detected (90% faster!)

Test 3: Update Product
POST http://localhost:8081/products/1
Body: {"price": 199.99, "stock": 75}
Response time: 163ms
New Price: 199.99, New Version: 2

Test 4: Read After Update
GET http://localhost:8081/products/1
Response time: 247ms
Price: 199.99, Version: 2
✓ Fresh data confirmed (cache evicted on update)

Scenario B Summary:
- Cache Mode: TTL-Only Cache
- First read: 251ms
- Second read: 12ms (95% faster!)
- Update: 163ms
- Post-update read: 247ms
- Stale data detected: No (single instance)

=========================================
Testing Scenario C: TTL + Kafka Invalidation
=========================================

Test 1: First Read (Cache Miss Expected)
GET http://localhost:8081/products/1
Response time: 248ms
Price: 149.99, Version: 1

Test 2: Second Read (Cache Hit Expected for Cached Scenarios)
GET http://localhost:8081/products/1
Response time: 11ms
Price: 149.99, Version: 1
✓ Cache hit detected (96% faster!)

Test 3: Update Product
POST http://localhost:8081/products/1
Body: {"price": 199.99, "stock": 75}
Response time: 178ms
New Price: 199.99, New Version: 2

Test 4: Read After Update
GET http://localhost:8081/products/1
Response time: 243ms
Price: 199.99, Version: 2
✓ Fresh data confirmed (Kafka invalidation worked)

Scenario C Summary:
- Cache Mode: TTL + Kafka Invalidation
- First read: 248ms
- Second read: 11ms (96% faster!)
- Update: 178ms (slightly slower due to Kafka)
- Post-update read: 243ms
- Stale data detected: No

=========================================
FINAL TEST SUMMARY
=========================================

Scenario A (No Cache):
  - Avg Latency: 245ms
  - Cache Benefit: 0%
  - Stale Data: 0%
  - Best for: Guaranteed consistency, low traffic

Scenario B (TTL-Only):
  - Avg Latency: 12ms (95% improvement)
  - Cache Benefit: 95%
  - Stale Data: 0% (single instance)
  - Best for: High read traffic, eventual consistency OK

Scenario C (TTL + Kafka):
  - Avg Latency: 11ms (96% improvement)
  - Cache Benefit: 96%
  - Stale Data: 0%
  - Best for: High traffic + strict consistency

Recommendation: Scenario C (TTL + Kafka Invalidation)
- Best performance (96% faster)
- Guaranteed consistency
- Scales horizontally
- Production-ready

Test completed at: Mon Jan 15 14:45:33 PST 2024
Results saved to: cache-test-results-20240115_143022.txt
```

---

## Option 2: Quick Test (Current Scenario Only)

### What It Does:

- Tests whatever cache mode is currently running
- Faster (2 minutes vs 20 minutes)
- Good for quick validation

### Run the Test:

```bash
# Make sure catalog-service is running with desired CACHE_MODE
cd catalog-service
export CACHE_MODE=ttl_invalidate
mvn spring-boot:run &

# In another terminal, run quick test
cd eds-lite/scripts
./quick-cache-test.sh
```

### Output File:

```
quick-cache-test-20240115_143022.txt
```

### View Results:

```bash
cat quick-cache-test-*.txt
```

---

## Step-by-Step: Testing All 3 Scenarios

### Step 1: Start Infrastructure

```bash
# Terminal 1: MongoDB
cd eds-lite/scripts
./start-mongo.sh

# Terminal 2: Redis
./start-redis.sh

# Terminal 3: Kafka
./start-kafka.sh

# Terminal 4: Seed database
cd eds-lite
mongosh mongodb://localhost:27017/eds < scripts/seed-marketplace.js
```

### Step 2: Run Full Test

```bash
# Terminal 5: Run test script
cd eds-lite/scripts
./test-cache-scenarios.sh
```

### Step 3: Wait for Completion

```
⏱️ Estimated time: 15-20 minutes

The script will:
- Test Scenario A (~5 min)
- Test Scenario B (~5 min)
- Test Scenario C (~5 min)
- Generate report (~1 min)
```

### Step 4: View Results

```bash
# Find the results file
ls -lt cache-test-results-*.txt | head -1

# View full results
cat cache-test-results-20240115_143022.txt

# View just summary
tail -50 cache-test-results-20240115_143022.txt
```

---

## Troubleshooting

### Script Fails: "Service not running"

**Solution:**
```bash
# Check what's running
./scripts/check-services.sh

# Start missing services
./scripts/start-mongo.sh
./scripts/start-redis.sh
./scripts/start-kafka.sh
```

### Script Fails: "Product not found"

**Solution:**
```bash
# Seed the database
mongosh mongodb://localhost:27017/eds < scripts/seed-marketplace.js
```

### Script Fails: "Port 8081 already in use"

**Solution:**
```bash
# Kill existing catalog-service
lsof -ti:8081 | xargs kill -9

# Run script again
./test-cache-scenarios.sh
```

### Kafka Connection Errors (Scenario C)

**Solution:**
```bash
# Make sure Kafka is running
./scripts/start-kafka.sh

# Check Kafka logs
tail -f /tmp/kafka-logs/server.log
```

---

## What Gets Tested

### For Each Scenario:

1. **First Read (Cache Miss)**
   - Measures latency
   - Records product data

2. **Second Read (Cache Hit Expected)**
   - Measures latency
   - Compares with first read
   - Detects cache hit (faster response)

3. **Update Product**
   - Changes price and stock
   - Measures update latency
   - Records new version

4. **Read After Update**
   - Measures latency
   - Checks for stale data
   - Verifies version changed

### Metrics Collected:

- ✅ Response times (ms)
- ✅ Cache hit/miss detection
- ✅ Stale data detection
- ✅ Version tracking
- ✅ Performance improvements

---

## Interpreting Results

### Good Results:

**Scenario A (No Cache):**
- All reads: 200-300ms ✅
- No cache hits ✅
- No stale data ✅

**Scenario B (TTL-Only):**
- First read: 200-300ms ✅
- Second read: < 20ms ✅ (90%+ faster)
- Post-update read: Fresh data ✅ (single instance)

**Scenario C (TTL + Kafka):**
- First read: 200-300ms ✅
- Second read: < 20ms ✅ (90%+ faster)
- Post-update read: Fresh data ✅
- Kafka events logged ✅

### Bad Results:

- ❌ All reads slow (cache not working)
- ❌ Stale data after update (invalidation failed)
- ❌ Errors in logs (configuration issue)

---

## Sharing Results

### For Reports/Presentations:

```bash
# Copy results file
cp cache-test-results-*.txt ~/Desktop/

# Or email it
cat cache-test-results-*.txt | mail -s "Cache Test Results" your@email.com
```

### For GitHub:

```bash
# Add to repo (optional)
git add cache-test-results-*.txt
git commit -m "Add cache test results"
git push
```

---

## Summary

**Yes, you can test all 3 scenarios locally and get text results!**

**Quick Start:**
```bash
# 1. Start infrastructure
./scripts/start-mongo.sh
./scripts/start-redis.sh
./scripts/start-kafka.sh

# 2. Seed database
mongosh mongodb://localhost:27017/eds < scripts/seed-marketplace.js

# 3. Run test
./scripts/test-cache-scenarios.sh

# 4. View results
cat cache-test-results-*.txt
```

**Time Required:** 15-20 minutes  
**Output:** Comprehensive text file with all results  
**Location:** `eds-lite/cache-test-results-TIMESTAMP.txt`
