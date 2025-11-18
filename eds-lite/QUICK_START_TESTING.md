# Quick Start: Testing in 5 Minutes

This guide gets you from zero to testing cache invalidation in 5 minutes.

## Step 1: Start Infrastructure (1 minute)

```bash
cd eds-lite/scripts
./start-all-infrastructure.sh
```

This starts Kafka, Redis, and MongoDB in the background.

## Step 2: Seed Database (30 seconds)

```bash
mongosh mongodb://localhost:27017/eds < seed-mongo.js
```

This creates 2000 products in MongoDB.

## Step 3: Start Services (1 minute)

Open three new terminals:

**Terminal 1: API Gateway**
```bash
cd eds-lite/api-gateway
mvn spring-boot:run
```

**Terminal 2: Order Service**
```bash
cd eds-lite/order-service
mvn spring-boot:run
```

**Terminal 3: Catalog Service**
```bash
cd eds-lite/catalog-service
export CACHE_MODE=ttl_invalidate
mvn spring-boot:run
```

Wait for all services to show "Started" messages (~30 seconds).

## Step 4: Run Quick Test (2 minutes)

```bash
cd eds-lite/scripts
./quick-test.sh
```

**Expected output:**
```
✓ All services are running!

Test 1: First Read (Cache Miss)
✓ Product retrieved

Test 2: Second Read (Cache Hit)
✓ Product retrieved from cache

Test 3: Update Product (Triggers Cache Invalidation)
✓ Product updated

Test 4: Read After Update (Should Get Fresh Data)
✓ Fresh data retrieved! Price=199.99, Stock=999
✓ Cache invalidation worked!

✓ Cache invalidation is working correctly! 🎉
```

## Done! 🎉

You've just verified that:
- ✅ Caching works (cache hits on repeated reads)
- ✅ Updates trigger Kafka events
- ✅ Cache invalidation propagates instantly
- ✅ Fresh data is retrieved after updates

---

## What Just Happened?

1. **First read:** Product fetched from MongoDB, stored in Redis
2. **Second read:** Product served from Redis cache (fast!)
3. **Update:** Product updated in MongoDB, Kafka event published
4. **Kafka consumer:** Received event, deleted cache entry
5. **Next read:** Fresh data fetched from MongoDB

**Result:** You get the speed of caching with the freshness of direct database access!

---

## Next Steps

### Option A: Manual Testing
```bash
# Get a product
curl http://localhost:8080/api/catalog/products/1

# Update it
curl -X POST http://localhost:8080/api/catalog/products/1 \
  -H "Content-Type: application/json" \
  -d '{"price": 99.99, "stock": 50}'

# Get it again (fresh data!)
curl http://localhost:8080/api/catalog/products/1
```

### Option B: Use Demo UI
```bash
./scripts/serve-demo.sh
# Open: http://localhost:8000/demo.html
```

### Option C: Full Performance Test
```bash
./scripts/run-all-scenarios.sh
# Takes 30-45 minutes, compares all three caching strategies
```

---

## Troubleshooting

### Services won't start
```bash
# Check what's running
./scripts/check-services.sh

# Kill stuck processes
lsof -ti:8081 | xargs kill -9
```

### Test fails
```bash
# Check service logs
# Look at the terminal where catalog-service is running

# Verify infrastructure
./scripts/check-services.sh

# Restart catalog service
cd catalog-service
export CACHE_MODE=ttl_invalidate
mvn spring-boot:run
```

### No metrics
```bash
# Create metrics directory
mkdir -p /tmp/metrics
chmod 777 /tmp/metrics

# Restart catalog service
```

---

## Understanding the Test

The quick test demonstrates the core value proposition:

**Without Kafka invalidation (Scenario B):**
- Update happens
- Cache stays stale for 5 minutes (TTL)
- Users see old data

**With Kafka invalidation (Scenario C):**
- Update happens
- Kafka event sent instantly
- Cache cleared in <100ms
- Users see fresh data immediately

**This is what the project proves!**

---

## Full Documentation

- [README.md](README.md) - Complete project documentation
- [TESTING_GUIDE.md](TESTING_GUIDE.md) - Detailed testing instructions
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [scripts/README.md](scripts/README.md) - All available scripts

---

## One-Line Commands

```bash
# Start everything
./scripts/start-all-infrastructure.sh

# Quick test
./scripts/quick-test.sh

# Full test
./scripts/run-all-scenarios.sh

# Check status
./scripts/check-services.sh

# Demo UI
./scripts/serve-demo.sh
```

That's it! You're ready to demonstrate Kafka-based distributed cache invalidation. 🚀
