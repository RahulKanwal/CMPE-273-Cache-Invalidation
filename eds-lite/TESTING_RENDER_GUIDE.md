# Testing Cache Scenarios on Render - Complete Guide

This guide shows you how to test all 3 cache scenarios on your deployed Render application.

---

## Quick Start

```bash
cd eds-lite
chmod +x test-render-deployment.sh
./test-render-deployment.sh
```

**Time:** 30-60 seconds per test  
**Output:** `render-test-results-TIMESTAMP.txt`

---

## Understanding the Current Setup

Your Render deployment is currently configured as:

**Current Configuration: Scenario A (No Cache)**
- `CACHE_TYPE=none`
- No Redis
- No Kafka
- All requests hit MongoDB directly

---

## Testing Each Scenario

### Scenario A: No Cache (Current - Already Configured)

#### Step 1: Verify Configuration

Your catalog-service on Render should have:
```
CACHE_TYPE=none
```

#### Step 2: Run the Test

```bash
cd eds-lite
./test-render-deployment.sh
```

#### Step 3: Wait for Results

```
⏱️ Time: 30-60 seconds

The script will:
1. Read product (first time)
2. Read product (second time)
3. Update product price
4. Read product (after update)
5. Generate report
```

#### Step 4: View Results

```bash
# View full results
cat render-test-results-*.txt

# View just summary
tail -40 render-test-results-*.txt
```

#### Expected Results for Scenario A:

```
Performance Metrics:
  First read:        800-1500ms
  Second read:       800-1500ms (no improvement)
  Update:            400-800ms
  Post-update read:  800-1500ms

Cache Analysis:
  ✓ Cache Status: DISABLED
  ✓ Data Consistency: ALWAYS FRESH

Likely Configuration: Scenario A (No Cache)
  - CACHE_TYPE=none

Average Read Latency: 1000ms
```

---

### Scenario B: TTL-Only Cache

#### Step 1: Set Up Upstash Redis (10 minutes)

1. **Sign up for Upstash:**
   - Go to https://upstash.com/
   - Create account (free tier)
   - Click "Create Database"
   - Choose region closest to your Render services
   - Copy credentials

2. **Get your credentials:**
   ```
   Endpoint: your-redis.upstash.io
   Port: 6379
   Password: your-password
   ```

#### Step 2: Update Render Environment Variables

1. Go to https://dashboard.render.com/
2. Click on **catalog-service**
3. Click **Environment** tab
4. Add/Update these variables:

```
CACHE_TYPE=redis
CACHE_MODE=ttl
REDIS_HOST=your-redis.upstash.io
REDIS_PORT=6379
REDIS_PASSWORD=your-password
REDIS_SSL=true
```

5. Click **Save Changes**
6. Wait for automatic redeploy (~5 minutes)

#### Step 3: Verify Deployment

1. Go to **Logs** tab
2. Wait for "Deploy succeeded"
3. Look for log messages:
   ```
   Cache type: redis
   Redis connected successfully
   ```

#### Step 4: Run the Test

```bash
cd eds-lite
./test-render-deployment.sh
```

#### Step 5: View Results

```bash
cat render-test-results-*.txt
```

#### Expected Results for Scenario B:

```
Performance Metrics:
  First read:        800-1500ms (cache miss)
  Second read:       100-300ms (cache hit - 80% faster!)
  Update:            400-800ms
  Post-update read:  100-300ms or 800-1500ms

Cache Analysis:
  ✓ Cache Status: ENABLED
  ✓ Data Consistency: GOOD (single instance)

Likely Configuration: Scenario B (TTL-Only)
  - CACHE_TYPE=redis
  - CACHE_MODE=ttl

Average Read Latency: 400ms
```

**Note:** On Render free tier with single instance, you likely won't see stale data. Stale data would appear with multiple instances.

---

### Scenario C: TTL + Kafka Invalidation

#### Step 1: Set Up Upstash Redis (if not done)

Follow Step 1 from Scenario B above.

#### Step 2: Set Up Confluent Cloud Kafka (15 minutes)

1. **Sign up for Confluent Cloud:**
   - Go to https://confluent.cloud/
   - Create account (free tier)
   - Click "Create Cluster"
   - Choose "Basic" cluster (free)
   - Select region closest to Render

2. **Create API Keys:**
   - Go to "API Keys"
   - Click "Add Key"
   - Select "Global access"
   - Copy API Key and Secret

3. **Create Topic:**
   - Go to "Topics"
   - Click "Create Topic"
   - Name: `cache.invalidate`
   - Partitions: 3
   - Retention: 1 day
   - Click "Create"

4. **Get Bootstrap Servers:**
   - Go to "Cluster Settings"
   - Copy "Bootstrap server" URL
   - Example: `pkc-xxxxx.us-east-1.aws.confluent.cloud:9092`

#### Step 3: Update Render Environment Variables

1. Go to https://dashboard.render.com/
2. Click on **catalog-service**
3. Click **Environment** tab
4. Add/Update these variables:

```
CACHE_TYPE=redis
CACHE_MODE=ttl_invalidate
KAFKA_ENABLED=true

REDIS_HOST=your-redis.upstash.io
REDIS_PORT=6379
REDIS_PASSWORD=your-password
REDIS_SSL=true

KAFKA_BOOTSTRAP_SERVERS=pkc-xxxxx.us-east-1.aws.confluent.cloud:9092
KAFKA_SASL_JAAS_CONFIG=org.apache.kafka.common.security.plain.PlainLoginModule required username="YOUR_API_KEY" password="YOUR_API_SECRET";
KAFKA_SECURITY_PROTOCOL=SASL_SSL
KAFKA_SASL_MECHANISM=PLAIN
```

**Important:** Replace:
- `YOUR_API_KEY` with your Confluent API Key
- `YOUR_API_SECRET` with your Confluent API Secret
- `pkc-xxxxx...` with your actual bootstrap server

5. Click **Save Changes**
6. Wait for automatic redeploy (~5 minutes)

#### Step 4: Verify Deployment

1. Go to **Logs** tab
2. Wait for "Deploy succeeded"
3. Look for log messages:
   ```
   Cache type: redis
   Cache mode: ttl_invalidate
   Redis connected successfully
   Kafka connected successfully
   ```

#### Step 5: Run the Test

```bash
cd eds-lite
./test-render-deployment.sh
```

#### Step 6: View Results

```bash
cat render-test-results-*.txt
```

#### Expected Results for Scenario C:

```
Performance Metrics:
  First read:        800-1500ms (cache miss)
  Second read:       100-300ms (cache hit - 80% faster!)
  Update:            500-900ms (slightly slower due to Kafka)
  Post-update read:  800-1500ms (fresh data - cache invalidated!)

Cache Analysis:
  ✓ Cache Status: ENABLED
  ✓ Cache Invalidation: WORKING
  ✓ Data Consistency: GOOD

Likely Configuration: Scenario C (TTL + Kafka Invalidation)
  - CACHE_TYPE=redis
  - CACHE_MODE=ttl_invalidate
  - KAFKA_ENABLED=true

Average Read Latency: 600ms
```

#### Step 7: Verify Kafka Events (Optional)

1. Go to Confluent Cloud dashboard
2. Click your cluster
3. Go to "Topics" → `cache.invalidate`
4. Click "Messages"
5. You should see events like:
   ```json
   {
     "type": "product",
     "keys": ["1"],
     "version": 5,
     "timestamp": "2024-01-15T10:30:00Z",
     "reason": "product_update"
   }
   ```

---

## Comparison of Results

### Summary Table

| Metric | Scenario A | Scenario B | Scenario C |
|--------|------------|------------|------------|
| **First Read** | 1000ms | 1000ms | 1000ms |
| **Second Read** | 1000ms | 200ms | 200ms |
| **Update** | 500ms | 500ms | 600ms |
| **Post-Update Read** | 1000ms | 200ms (stale?) | 1000ms (fresh) |
| **Cache Hit Rate** | 0% | 80-90% | 80-90% |
| **Stale Data** | 0% | Possible | < 0.1% |
| **Avg Latency** | 1000ms | 400ms | 600ms |
| **Setup Time** | 0 min | 15 min | 30 min |
| **Monthly Cost** | $0 | $0 | $0 |

---

## Troubleshooting

### Test Fails: "Services are sleeping"

**Problem:** Render free tier services sleep after 15 minutes.

**Solution:**
```bash
# Wake up services manually
curl https://api-gateway-lpnh.onrender.com/actuator/health
curl https://catalog-service-YOUR-ID.onrender.com/actuator/health

# Wait 30-60 seconds, then run test again
./test-render-deployment.sh
```

**Permanent Solution:** Set up UptimeRobot (see [KEEP_SERVICES_AWAKE.md](./KEEP_SERVICES_AWAKE.md))

### Test Fails: "Product not found"

**Problem:** Test product doesn't exist in database.

**Solution:**
1. Go to your deployed frontend
2. Login as admin
3. Create a product with ID "1"
4. Or change `TEST_PRODUCT_ID` in the script

### Redis Connection Errors

**Check:**
1. REDIS_HOST is correct (no `https://` prefix)
2. REDIS_PASSWORD is correct
3. REDIS_SSL=true (required for Upstash)
4. Upstash database is active

**Verify in Render Logs:**
```
Redis connected successfully
```

If you see:
```
Unable to connect to Redis
```

Then check your environment variables.

### Kafka Connection Errors

**Check:**
1. KAFKA_BOOTSTRAP_SERVERS is correct
2. KAFKA_SASL_JAAS_CONFIG has correct API key/secret
3. Topic `cache.invalidate` exists
4. Confluent Cloud cluster is active

**Verify in Render Logs:**
```
Kafka connected successfully
```

### Slow Response Times (> 5 seconds)

**Causes:**
- Services are waking up from sleep
- Network latency
- Database in different region

**Solutions:**
- Use UptimeRobot to keep services awake
- Wait 60 seconds and try again
- Consider upgrading to paid tier

---

## Running All 3 Tests in Sequence

If you want to test all 3 scenarios and compare results:

### Option 1: Manual (Recommended)

```bash
# Test Scenario A
./test-render-deployment.sh
mv render-test-results-*.txt scenario-a-results.txt

# Configure Scenario B on Render (15 min)
# Then test:
./test-render-deployment.sh
mv render-test-results-*.txt scenario-b-results.txt

# Configure Scenario C on Render (15 min)
# Then test:
./test-render-deployment.sh
mv render-test-results-*.txt scenario-c-results.txt

# Compare results
cat scenario-a-results.txt scenario-b-results.txt scenario-c-results.txt > all-scenarios-comparison.txt
```

### Option 2: Automated (Advanced)

Create a script that tests, waits for you to reconfigure, then tests again:

```bash
#!/bin/bash

echo "Testing Scenario A (current configuration)..."
./test-render-deployment.sh
mv render-test-results-*.txt scenario-a-results.txt

echo ""
echo "Now configure Scenario B on Render:"
echo "1. Go to Render dashboard"
echo "2. Update environment variables"
echo "3. Wait for redeploy"
echo ""
read -p "Press Enter when Scenario B is deployed..."

echo "Testing Scenario B..."
./test-render-deployment.sh
mv render-test-results-*.txt scenario-b-results.txt

echo ""
echo "Now configure Scenario C on Render:"
echo "1. Go to Render dashboard"
echo "2. Update environment variables"
echo "3. Wait for redeploy"
echo ""
read -p "Press Enter when Scenario C is deployed..."

echo "Testing Scenario C..."
./test-render-deployment.sh
mv render-test-results-*.txt scenario-c-results.txt

echo ""
echo "All tests complete!"
echo "Results:"
echo "  - scenario-a-results.txt"
echo "  - scenario-b-results.txt"
echo "  - scenario-c-results.txt"
```

---

## What the Test Does

### Test Sequence:

1. **First Read (Cache Miss)**
   - Measures baseline latency
   - Records product data (price, version)

2. **Second Read (Cache Hit Expected)**
   - Measures cached latency
   - Compares with first read
   - Detects if cache is working

3. **Update Product**
   - Changes price to $299.99
   - Measures update latency
   - Records new version

4. **Wait 5 Seconds**
   - Allows Kafka events to propagate
   - Gives cache time to invalidate

5. **Read After Update**
   - Checks for fresh vs stale data
   - Verifies cache invalidation worked

6. **Restore Original Price**
   - Puts product back to original state
   - Keeps database clean

### Metrics Collected:

- ✅ Response times (milliseconds)
- ✅ HTTP status codes
- ✅ Cache hit detection
- ✅ Stale data detection
- ✅ Version tracking
- ✅ Performance improvements

---

## Tips for Best Results

### Before Testing:

1. **Wake up services** (if using free tier)
   ```bash
   curl https://api-gateway-lpnh.onrender.com/actuator/health
   ```
   Wait 60 seconds

2. **Verify configuration** in Render dashboard
   - Check environment variables
   - Confirm deployment succeeded

3. **Clear browser cache** (if testing via UI)

### During Testing:

1. **Don't interrupt** the test (takes 30-60 seconds)
2. **Run multiple times** for consistent results
3. **Note any errors** in the output

### After Testing:

1. **Save results** with descriptive names
2. **Compare** with expected results
3. **Document** any anomalies

---

## Cost Breakdown

| Service | Free Tier | Monthly Cost |
|---------|-----------|--------------|
| Render (4 services) | ✅ Yes | $0 |
| Upstash Redis | ✅ Yes (10K commands/day) | $0 |
| Confluent Cloud Kafka | ✅ Yes (limited) | $0 |
| UptimeRobot | ✅ Yes (50 monitors) | $0 |

**Total: $0/month** for all 3 scenarios!

---

## Summary

**To test each scenario:**

1. **Configure** backend on Render (5-30 min setup)
2. **Run** test script (30-60 sec)
3. **View** results in text file
4. **Compare** with expected results

**Time per scenario:**
- Scenario A: 1 minute (already configured)
- Scenario B: 16 minutes (15 min setup + 1 min test)
- Scenario C: 31 minutes (30 min setup + 1 min test)

**Total time to test all 3:** ~50 minutes

**Output:** 3 text files with complete results and analysis
