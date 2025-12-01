# Testing Cache Scenarios on Render Deployment

Since your application is deployed on Render, you can test the cache scenarios in a **real production environment** with actual multiple instances (if scaled).

---

## Current Deployment Configuration

Your Render deployment is currently configured as:

**Cache Configuration:**
- `CACHE_TYPE=none` (Redis disabled)
- `CACHE_MODE=none` (No caching)
- **Currently running: Scenario A (No Cache)**

This means you're experiencing the slowest performance but guaranteed fresh data.

---

## How to Test Each Scenario on Render

### Prerequisites

1. Access to Render Dashboard: https://dashboard.render.com/
2. Your deployed services:
   - API Gateway: `https://api-gateway-lpnh.onrender.com`
   - Catalog Service: `https://catalog-service-[YOUR-ID].onrender.com`
   - Frontend: `https://marketplace-ui-tau.vercel.app`

---

## Scenario A: No Cache (Current Configuration)

### Configuration

**Render Environment Variables:**
```
CACHE_TYPE=none
CACHE_MODE=none
```

### How to Test

#### Step 1: Access the Cache Demo Page

```
https://marketplace-ui-tau.vercel.app/cache-demo
```

#### Step 2: Select "No Cache" Scenario

- Click on the "No Cache" card
- Click "Run Cache Test"

#### Step 3: Observe the Results

**What you'll see:**
- ✅ First Read: ~500-1000ms (slow - hits MongoDB)
- ✅ Second Read: ~500-1000ms (slow - hits MongoDB again)
- ✅ Update: ~300-500ms
- ✅ Post-Update Read: ~500-1000ms (fresh data)

**Metrics:**
- Cache Hit Rate: 0%
- Stale Data: 0%
- Average Latency: 500-1000ms

#### Step 4: Manual Testing (Optional)

Open browser DevTools (F12) → Network tab:

```bash
# First request
GET https://api-gateway-lpnh.onrender.com/api/catalog/products/1
# Time: ~800ms

# Second request (same product)
GET https://api-gateway-lpnh.onrender.com/api/catalog/products/1
# Time: ~800ms (no improvement - no cache)

# Update product
POST https://api-gateway-lpnh.onrender.com/api/catalog/products/1
Body: { "price": 99.99, "stock": 50 }
# Time: ~400ms

# Read after update
GET https://api-gateway-lpnh.onrender.com/api/catalog/products/1
# Time: ~800ms
# Result: Fresh data (new price)
```

---

## Scenario B: TTL-Only Cache

### Configuration

**Render Environment Variables:**
```
CACHE_TYPE=redis
CACHE_MODE=ttl
REDIS_HOST=your-upstash-redis.upstash.io
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password
```

### Setup Steps

#### Step 1: Get Upstash Redis (Free)

1. Go to https://upstash.com/
2. Sign up (free tier available)
3. Create a Redis database
4. Copy credentials:
   - Endpoint (host)
   - Port (usually 6379)
   - Password

#### Step 2: Update Render Environment Variables

1. Go to Render Dashboard
2. Click on **catalog-service**
3. Go to **Environment** tab
4. Add/Update these variables:
   ```
   CACHE_TYPE=redis
   CACHE_MODE=ttl
   REDIS_HOST=your-redis-host.upstash.io
   REDIS_PORT=6379
   REDIS_PASSWORD=your-redis-password
   REDIS_SSL=true
   ```
5. Click **Save Changes**
6. Wait for service to redeploy (~5 minutes)

#### Step 3: Test on Cache Demo Page

```
https://marketplace-ui-tau.vercel.app/cache-demo
```

- Select "TTL-Only Cache" scenario
- Click "Run Cache Test"

#### Step 4: Observe the Results

**What you'll see:**
- ✅ First Read: ~800ms (cache miss - hits MongoDB)
- ✅ Second Read: ~50-100ms (cache hit - 90% faster!)
- ✅ Update: ~400ms
- ⚠️ Post-Update Read: ~50-100ms (might be stale data!)

**Metrics:**
- Cache Hit Rate: 85-95%
- Stale Data: 5-10% (possible)
- Average Latency: 100-200ms

#### Step 5: Test Stale Data (Multiple Instances)

**If Render is running multiple instances:**

```bash
# Terminal 1: Update product
curl -X POST https://api-gateway-lpnh.onrender.com/api/catalog/products/1 \
  -H "Content-Type: application/json" \
  -d '{"price": 199.99, "stock": 100}'

# Terminal 2: Immediately read (might hit different instance)
curl https://api-gateway-lpnh.onrender.com/api/catalog/products/1

# Result: Might show old price if it hits an instance that hasn't evicted cache
# Stale data will persist until TTL expires (5 minutes)
```

---

## Scenario C: TTL + Kafka Invalidation (Recommended)

### Configuration

**Render Environment Variables:**
```
CACHE_TYPE=redis
CACHE_MODE=ttl_invalidate
KAFKA_ENABLED=true
REDIS_HOST=your-upstash-redis.upstash.io
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password
KAFKA_BOOTSTRAP_SERVERS=your-kafka.confluent.cloud:9092
KAFKA_SASL_JAAS_CONFIG=org.apache.kafka.common.security.plain.PlainLoginModule required username="YOUR_KEY" password="YOUR_SECRET";
KAFKA_SECURITY_PROTOCOL=SASL_SSL
KAFKA_SASL_MECHANISM=PLAIN
```

### Setup Steps

#### Step 1: Get Confluent Cloud Kafka (Free)

1. Go to https://confluent.cloud/
2. Sign up (free tier available)
3. Create a Kafka cluster
4. Create API keys
5. Copy credentials:
   - Bootstrap servers
   - API Key
   - API Secret

#### Step 2: Update Render Environment Variables

**For catalog-service:**
1. Go to Render Dashboard → catalog-service
2. Environment tab
3. Add/Update:
   ```
   CACHE_TYPE=redis
   CACHE_MODE=ttl_invalidate
   KAFKA_ENABLED=true
   REDIS_HOST=your-redis-host.upstash.io
   REDIS_PORT=6379
   REDIS_PASSWORD=your-redis-password
   REDIS_SSL=true
   KAFKA_BOOTSTRAP_SERVERS=pkc-xxxxx.region.aws.confluent.cloud:9092
   KAFKA_SASL_JAAS_CONFIG=org.apache.kafka.common.security.plain.PlainLoginModule required username="YOUR_API_KEY" password="YOUR_API_SECRET";
   KAFKA_SECURITY_PROTOCOL=SASL_SSL
   KAFKA_SASL_MECHANISM=PLAIN
   ```
4. Save and wait for redeploy

**For order-service (if using Kafka):**
- Same Kafka configuration

#### Step 3: Create Kafka Topic

In Confluent Cloud:
1. Go to Topics
2. Create topic: `cache.invalidate`
3. Partitions: 3
4. Retention: 1 day

#### Step 4: Test on Cache Demo Page

```
https://marketplace-ui-tau.vercel.app/cache-demo
```

- Select "TTL + Kafka Invalidation" scenario
- Click "Run Cache Test"

#### Step 5: Observe the Results

**What you'll see:**
- ✅ First Read: ~800ms (cache miss - hits MongoDB)
- ✅ Second Read: ~50-100ms (cache hit - 90% faster!)
- ✅ Update: ~450ms (slightly slower due to Kafka)
- ✅ Post-Update Read: ~800ms (fresh data - cache invalidated!)

**Metrics:**
- Cache Hit Rate: 85-95%
- Stale Data: < 0.1%
- Average Latency: 100-200ms
- Inconsistency Window: < 100ms

#### Step 6: Test Distributed Invalidation (Multiple Instances)

**If Render is running multiple instances:**

```bash
# Terminal 1: Update product
curl -X POST https://api-gateway-lpnh.onrender.com/api/catalog/products/1 \
  -H "Content-Type: application/json" \
  -d '{"price": 299.99, "stock": 150}'

# Wait 200ms for Kafka propagation

# Terminal 2: Read from any instance
curl https://api-gateway-lpnh.onrender.com/api/catalog/products/1

# Result: Fresh data! All instances invalidated cache via Kafka
```

#### Step 7: Monitor Kafka Events (Optional)

In Confluent Cloud:
1. Go to Topics → `cache.invalidate`
2. Click "Messages"
3. You'll see events like:
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

## Comparison: Testing Results on Render

### Expected Performance

| Scenario | First Read | Second Read | Update | Post-Update Read | Stale Data |
|----------|------------|-------------|--------|------------------|------------|
| **A: No Cache** | 800ms | 800ms | 400ms | 800ms | 0% |
| **B: TTL Only** | 800ms | 80ms | 400ms | 80ms | 5-10% |
| **C: TTL + Kafka** | 800ms | 80ms | 450ms | 800ms | < 0.1% |

### Why Render is Slower than Local

- **Network latency**: Requests travel over internet
- **Cold starts**: Free tier services sleep after 15 min
- **Database location**: MongoDB Atlas might be in different region
- **Redis location**: Upstash Redis might be in different region

**Tip:** Use UptimeRobot to keep services awake!

---

## Step-by-Step Testing Guide

### Quick Test (5 minutes)

1. **Open Cache Demo:**
   ```
   https://marketplace-ui-tau.vercel.app/cache-demo
   ```

2. **Test Current Scenario (No Cache):**
   - Click "No Cache" card
   - Click "Run Cache Test"
   - Observe: All requests are slow (~800ms)

3. **Done!** You've tested Scenario A

### Full Test (30 minutes)

#### Test Scenario A (Current - No Cache)

1. Open Cache Demo page
2. Select "No Cache"
3. Click "Run Cache Test"
4. Take screenshot of results
5. Note: High latency, no stale data

#### Test Scenario B (TTL-Only)

1. **Setup Upstash Redis** (10 minutes)
   - Sign up at https://upstash.com/
   - Create database
   - Copy credentials

2. **Update Render Environment Variables** (5 minutes)
   - catalog-service → Environment
   - Add Redis variables
   - Save and wait for redeploy

3. **Test on Cache Demo** (2 minutes)
   - Select "TTL-Only Cache"
   - Click "Run Cache Test"
   - Observe: Fast reads, possible stale data

4. **Manual Stale Data Test** (3 minutes)
   - Update product in Admin panel
   - Immediately refresh product page
   - Might see old data for a few seconds

#### Test Scenario C (TTL + Kafka)

1. **Setup Confluent Cloud Kafka** (10 minutes)
   - Sign up at https://confluent.cloud/
   - Create cluster
   - Create API keys
   - Create topic: `cache.invalidate`

2. **Update Render Environment Variables** (5 minutes)
   - catalog-service → Environment
   - Add Kafka variables
   - Save and wait for redeploy

3. **Test on Cache Demo** (2 minutes)
   - Select "TTL + Kafka Invalidation"
   - Click "Run Cache Test"
   - Observe: Fast reads, fresh data after updates

4. **Manual Fresh Data Test** (3 minutes)
   - Update product in Admin panel
   - Immediately refresh product page
   - Should see new data (no stale data!)

---

## Monitoring and Verification

### Check Render Logs

1. Go to Render Dashboard
2. Click catalog-service
3. Click "Logs" tab
4. Look for:
   ```
   Cache HIT for product 1
   Cache MISS for product 1
   Kafka invalidation event sent
   Cache invalidated via Kafka event
   ```

### Check Redis (Upstash Dashboard)

1. Go to Upstash Dashboard
2. Click your database
3. Click "Data Browser"
4. Look for keys: `productById::1`, `productById::2`, etc.
5. Check TTL values

### Check Kafka (Confluent Cloud)

1. Go to Confluent Cloud
2. Click your cluster
3. Topics → `cache.invalidate`
4. Click "Messages"
5. See invalidation events in real-time

---

## Troubleshooting

### Services Keep Sleeping (502 Errors)

**Solution:** Set up UptimeRobot
- See: [KEEP_SERVICES_AWAKE.md](./KEEP_SERVICES_AWAKE.md)

### Redis Connection Errors

**Check:**
- REDIS_HOST is correct
- REDIS_PASSWORD is correct
- REDIS_SSL=true (for Upstash)
- Upstash database is active

### Kafka Connection Errors

**Check:**
- KAFKA_BOOTSTRAP_SERVERS is correct
- KAFKA_SASL_JAAS_CONFIG has correct API key/secret
- Topic `cache.invalidate` exists
- Confluent Cloud cluster is active

### Cache Not Working

**Check Render Logs:**
```
# Should see:
Cache type: redis
Cache mode: ttl_invalidate
Redis connected successfully
Kafka connected successfully
```

**If you see:**
```
Cache type: none
```
Then environment variables aren't set correctly.

---

## Cost Breakdown

| Service | Free Tier | Cost |
|---------|-----------|------|
| Render (4 services) | ✅ Yes | $0 |
| Vercel (frontend) | ✅ Yes | $0 |
| MongoDB Atlas | ✅ Yes (512MB) | $0 |
| Upstash Redis | ✅ Yes (10K commands/day) | $0 |
| Confluent Cloud Kafka | ✅ Yes (limited) | $0 |
| UptimeRobot | ✅ Yes (50 monitors) | $0 |

**Total: $0/month** (all free tiers!)

---

## Recommended Configuration for Production

```bash
# Best performance + consistency
CACHE_TYPE=redis
CACHE_MODE=ttl_invalidate
KAFKA_ENABLED=true

# With all credentials configured
```

This gives you:
- ⚡ 90% faster reads
- 🎯 < 0.1% stale data
- 📈 Horizontal scalability
- 💰 90% less database load

---

## Summary

**Current State:** Scenario A (No Cache)
- Slow but simple
- No setup required
- Always fresh data

**To Enable Caching:**
1. Set up Upstash Redis (10 min)
2. Update Render environment variables (5 min)
3. Redeploy (automatic)
4. Test on Cache Demo page

**To Enable Full Invalidation:**
1. Set up Confluent Cloud Kafka (10 min)
2. Update Render environment variables (5 min)
3. Create Kafka topic (2 min)
4. Redeploy (automatic)
5. Test on Cache Demo page

**Total Setup Time:** ~30 minutes for full Scenario C
**Performance Improvement:** 90% faster reads
**Consistency:** < 100ms inconsistency window
