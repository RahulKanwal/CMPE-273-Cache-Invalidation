# Caching Scenarios: Detailed Step-by-Step Guide

This document explains exactly what happens in each of the three caching scenarios, step by step.

---

## Scenario A: No Cache

**Configuration:**
```bash
CACHE_TYPE=none
```

### Step-by-Step Flow

#### 1. Initial Product Read

```
User Request: GET /api/catalog/products/1
```

**Step 1:** User clicks on a product in the frontend
- Frontend sends HTTP GET request to API Gateway
- Request: `GET https://api-gateway.onrender.com/api/catalog/products/1`

**Step 2:** API Gateway routes request
- Receives request at port 8080
- Routes to catalog-service based on path `/api/catalog/**`
- Forwards: `GET http://catalog-service:8081/products/1`

**Step 3:** Catalog Service processes request
- Controller receives request
- Calls `productService.getProduct("1")`
- **NO cache check** (caching disabled)
- Directly queries MongoDB

**Step 4:** MongoDB query
- Query: `db.products.findOne({ _id: "1" })`
- Database performs disk I/O
- Returns product document
- **Time: ~100-200ms**

**Step 5:** Response sent back
- Catalog Service → API Gateway → Frontend
- Product displayed to user
- **Total Time: ~250ms**

#### 2. Second Product Read (Same Product)

```
User Request: GET /api/catalog/products/1 (again)
```

**Step 1-3:** Same as above

**Step 4:** MongoDB query (AGAIN)
- Query: `db.products.findOne({ _id: "1" })`
- **NO cache used** - hits database every time
- Returns same product document
- **Time: ~100-200ms**

**Step 5:** Response sent back
- **Total Time: ~250ms** (same as first request)

#### 3. Product Update

```
Admin Action: Update product price to $99.99
```

**Step 1:** Admin submits update form
- Frontend sends: `POST /api/catalog/products/1`
- Body: `{ price: 99.99, stock: 50 }`

**Step 2:** Catalog Service updates product
- Fetches product from MongoDB
- Updates price and stock fields
- Increments version number (optimistic locking)
- Saves to MongoDB: `db.products.update({ _id: "1" }, { $set: { price: 99.99, stock: 50, version: 2 } })`
- **NO cache to invalidate** (no cache exists)
- **NO Kafka event** (not needed)

**Step 3:** Response sent
- Returns updated product
- **Time: ~150ms**

#### 4. Read After Update

```
User Request: GET /api/catalog/products/1 (after update)
```

**Step 1-3:** Same as initial read

**Step 4:** MongoDB query
- Query: `db.products.findOne({ _id: "1" })`
- Returns product with NEW price ($99.99)
- **Always fresh data** ✅
- **Time: ~100-200ms**

**Step 5:** Response sent back
- User sees updated price immediately
- **Total Time: ~250ms**

### Summary - Scenario A

| Operation | Steps | Time | Cache Hit | Stale Data |
|-----------|-------|------|-----------|------------|
| First Read | MongoDB query | 250ms | N/A | Never |
| Second Read | MongoDB query | 250ms | N/A | Never |
| Update | MongoDB update | 150ms | N/A | N/A |
| Read After Update | MongoDB query | 250ms | N/A | Never |

**Pros:**
- ✅ Always fresh data
- ✅ Simple implementation
- ✅ No cache consistency issues

**Cons:**
- ❌ High latency (every request hits database)
- ❌ High database load
- ❌ Poor scalability
- ❌ Expensive at scale

---

## Scenario B: TTL-Only Cache

**Configuration:**
```bash
CACHE_TYPE=redis
CACHE_MODE=ttl
TTL=300000  # 5 minutes
```

### Step-by-Step Flow

#### 1. Initial Product Read (Cache Miss)

```
User Request: GET /api/catalog/products/1
```

**Step 1:** User clicks on product
- Frontend sends: `GET /api/catalog/products/1`

**Step 2:** API Gateway routes request
- Forwards to catalog-service

**Step 3:** Catalog Service checks cache
- Calls `cacheManager.getCache("productById")`
- Checks Redis: `GET productById::1`
- **Result: NULL** (cache miss - first time)
- Logs: "Cache MISS for product 1"

**Step 4:** Query MongoDB (cache miss)
- Query: `db.products.findOne({ _id: "1" })`
- Returns product document
- **Time: ~100-200ms**

**Step 5:** Store in Redis cache
- Command: `SET productById::1 <product-json>`
- Set TTL: `EXPIRE productById::1 300` (5 minutes)
- Logs: "Cached product 1 with version 1"

**Step 6:** Response sent back
- Returns product to user
- **Total Time: ~250ms** (cache miss)

#### 2. Second Product Read (Cache Hit)

```
User Request: GET /api/catalog/products/1 (within 5 minutes)
```

**Step 1-2:** Same as above

**Step 3:** Catalog Service checks cache
- Checks Redis: `GET productById::1`
- **Result: FOUND** ✅ (cache hit)
- Logs: "Cache HIT for product 1"
- **Time: ~5-10ms** (Redis is fast!)

**Step 4:** Return cached data
- **NO MongoDB query** (skipped!)
- Returns cached product directly

**Step 5:** Response sent back
- **Total Time: ~15ms** (90% faster!)

#### 3. Product Update

```
Admin Action: Update product price to $99.99
```

**Step 1:** Admin submits update
- Frontend sends: `POST /api/catalog/products/1`
- Body: `{ price: 99.99, stock: 50 }`

**Step 2:** Catalog Service updates product
- Fetches from MongoDB (bypassing cache for updates)
- Updates: `db.products.update({ _id: "1" }, { $set: { price: 99.99, stock: 50, version: 2 } })`
- **Evicts from Redis**: `DEL productById::1`
- Logs: "Cache cleared for product 1"
- **NO Kafka event** (TTL-only mode)

**Step 3:** Response sent
- Returns updated product
- **Time: ~150ms**

#### 4. Read Immediately After Update (Cache Miss)

```
User Request: GET /api/catalog/products/1 (immediately after update)
```

**Step 1-2:** Same as initial read

**Step 3:** Catalog Service checks cache
- Checks Redis: `GET productById::1`
- **Result: NULL** (was evicted during update)
- Logs: "Cache MISS for product 1"

**Step 4:** Query MongoDB
- Query: `db.products.findOne({ _id: "1" })`
- Returns product with NEW price ($99.99)
- **Time: ~100-200ms**

**Step 5:** Store in Redis cache (again)
- Command: `SET productById::1 <updated-product-json>`
- Set TTL: `EXPIRE productById::1 300`

**Step 6:** Response sent back
- User sees updated price ✅
- **Total Time: ~250ms**

#### 5. Problem: Concurrent Update on Another Instance

```
Scenario: Multiple catalog-service instances running
```

**Step 1:** Admin updates product on Instance A
- Instance A evicts its local cache
- Instance A updates MongoDB
- **Instance B still has old data in cache!** ⚠️

**Step 2:** User requests product from Instance B
- Instance B checks its cache: `GET productById::1`
- **Result: FOUND** (but it's STALE data!)
- Returns old price ($149.99 instead of $99.99)
- **Stale data served!** ❌

**Step 3:** Cache expires after 5 minutes
- Redis TTL expires: `TTL productById::1` → 0
- Next request will fetch fresh data
- **Inconsistency window: 5 minutes** ⚠️

### Summary - Scenario B

| Operation | Steps | Time | Cache Hit | Stale Data |
|-----------|-------|------|-----------|------------|
| First Read | MongoDB + Cache Store | 250ms | No | Never |
| Second Read | Cache Hit | 15ms | Yes | Possible |
| Update | MongoDB + Cache Evict | 150ms | N/A | N/A |
| Read After Update (same instance) | MongoDB + Cache Store | 250ms | No | Never |
| Read After Update (other instance) | Cache Hit | 15ms | Yes | **YES** ⚠️ |

**Pros:**
- ✅ Fast reads (15ms vs 250ms)
- ✅ Reduced database load (90% fewer queries)
- ✅ Simple implementation

**Cons:**
- ⚠️ Stale data possible (5-10% of requests)
- ⚠️ Inconsistency window = TTL (5 minutes)
- ⚠️ No coordination between instances
- ⚠️ Cache invalidation only on same instance

---

## Scenario C: TTL + Kafka Invalidation (Recommended)

**Configuration:**
```bash
CACHE_TYPE=redis
CACHE_MODE=ttl_invalidate
KAFKA_ENABLED=true
TTL=300000  # 5 minutes (safety net)
```

### Step-by-Step Flow

#### 1. Initial Product Read (Cache Miss)

```
User Request: GET /api/catalog/products/1
```

**Step 1-6:** Exactly same as Scenario B
- Check cache → Miss → Query MongoDB → Store in cache
- **Total Time: ~250ms**

#### 2. Second Product Read (Cache Hit)

```
User Request: GET /api/catalog/products/1 (within 5 minutes)
```

**Step 1-5:** Exactly same as Scenario B
- Check cache → Hit → Return cached data
- **Total Time: ~15ms**

#### 3. Product Update (WITH Kafka Event)

```
Admin Action: Update product price to $99.99
```

**Step 1:** Admin submits update
- Frontend sends: `POST /api/catalog/products/1`
- Body: `{ price: 99.99, stock: 50 }`

**Step 2:** Catalog Service updates product
- Fetches from MongoDB
- Updates: `db.products.update({ _id: "1" }, { $set: { price: 99.99, stock: 50, version: 2 } })`
- **Evicts from local Redis**: `DEL productById::1`
- Logs: "Cache cleared for product 1"

**Step 3:** Publish Kafka event
- Creates event:
  ```json
  {
    "type": "product",
    "keys": ["1"],
    "version": 2,
    "timestamp": "2024-01-15T10:30:00Z",
    "reason": "product_update"
  }
  ```
- Publishes to Kafka topic: `cache.invalidate`
- Logs: "Kafka invalidation event sent for product 1"
- **Time: ~10-20ms**

**Step 4:** Response sent
- Returns updated product
- **Total Time: ~170ms** (slightly slower due to Kafka)

#### 4. Kafka Event Processing (All Instances)

```
Kafka distributes event to all catalog-service instances
```

**Step 1:** Kafka delivers event
- All subscribed instances receive event
- **Time: ~50-100ms** (Kafka propagation)

**Step 2:** Instance A (where update happened)
- Receives event
- Cache already evicted (during update)
- Logs: "Received invalidation event for product 1 (already evicted)"

**Step 3:** Instance B (other instances)
- Receives event
- Checks cache: `GET productById::1`
- **Evicts from cache**: `DEL productById::1`
- Logs: "Cache invalidated for product 1 via Kafka event"

**Step 4:** Instance C, D, E... (all other instances)
- Same as Instance B
- All caches evicted across cluster
- **Inconsistency window: ~50-100ms** ✅

#### 5. Read Immediately After Update (Any Instance)

```
User Request: GET /api/catalog/products/1 (immediately after update)
```

**Scenario 5a: Request within 100ms (before Kafka propagation)**

**Step 1-2:** Request routed to Instance B

**Step 3:** Instance B checks cache
- Checks Redis: `GET productById::1`
- **Result: FOUND** (Kafka event not yet received)
- Returns cached data with OLD price
- **Stale data served** ⚠️ (but only for ~50-100ms)

**Scenario 5b: Request after 100ms (after Kafka propagation)**

**Step 1-2:** Request routed to Instance B

**Step 3:** Instance B checks cache
- Checks Redis: `GET productById::1`
- **Result: NULL** (evicted by Kafka event)
- Logs: "Cache MISS for product 1"

**Step 4:** Query MongoDB
- Query: `db.products.findOne({ _id: "1" })`
- Returns product with NEW price ($99.99)
- **Time: ~100-200ms**

**Step 5:** Store in Redis cache
- Command: `SET productById::1 <updated-product-json>`
- Set TTL: `EXPIRE productById::1 300`

**Step 6:** Response sent back
- User sees updated price ✅
- **Total Time: ~250ms**

#### 6. Subsequent Reads (Cache Hit with Fresh Data)

```
User Request: GET /api/catalog/products/1 (after Kafka propagation)
```

**Step 1-2:** Request routed to any instance

**Step 3:** Check cache
- Checks Redis: `GET productById::1`
- **Result: FOUND** (fresh data cached after Kafka invalidation)
- Returns NEW price ($99.99)
- **Time: ~5-10ms**

**Step 4:** Response sent
- **Total Time: ~15ms** (fast AND fresh!)

### Detailed Kafka Event Flow

```
Timeline of events:

T=0ms:    Admin clicks "Update Product"
T=10ms:   MongoDB updated
T=20ms:   Local cache evicted (Instance A)
T=30ms:   Kafka event published
T=40ms:   Response sent to admin
T=50ms:   Kafka event received by Instance B
T=60ms:   Cache evicted on Instance B
T=70ms:   Kafka event received by Instance C
T=80ms:   Cache evicted on Instance C
T=100ms:  All instances have evicted cache
T=110ms:  Next request gets fresh data from MongoDB
T=120ms:  Fresh data cached across all instances

Inconsistency Window: 50-100ms ✅
```

### Summary - Scenario C

| Operation | Steps | Time | Cache Hit | Stale Data |
|-----------|-------|------|-----------|------------|
| First Read | MongoDB + Cache Store | 250ms | No | Never |
| Second Read | Cache Hit | 15ms | Yes | < 0.1% |
| Update | MongoDB + Cache Evict + Kafka | 170ms | N/A | N/A |
| Read After Update (< 100ms) | Cache Hit | 15ms | Yes | **Possible** ⚠️ |
| Read After Update (> 100ms) | MongoDB + Cache Store | 250ms | No | Never |
| Subsequent Reads | Cache Hit (fresh) | 15ms | Yes | Never |

**Pros:**
- ✅ Fast reads (15ms vs 250ms)
- ✅ Reduced database load (90% fewer queries)
- ✅ Near-zero stale data (< 0.1%)
- ✅ Inconsistency window < 100ms
- ✅ Distributed cache invalidation
- ✅ Scales horizontally

**Cons:**
- ⚠️ Slightly more complex (requires Kafka)
- ⚠️ Small inconsistency window (50-100ms)
- ⚠️ Kafka dependency (but optional)

---

## Comparison Table

### Performance Metrics

| Metric | No Cache | TTL Only | TTL + Kafka |
|--------|----------|----------|-------------|
| **First Read** | 250ms | 250ms | 250ms |
| **Cached Read** | N/A | 15ms | 15ms |
| **Update** | 150ms | 150ms | 170ms |
| **Read After Update** | 250ms | 15ms (stale) | 250ms (fresh) |
| **Cache Hit Rate** | 0% | 90% | 90% |
| **Stale Data Rate** | 0% | 5-10% | < 0.1% |
| **Inconsistency Window** | 0ms | 300,000ms | < 100ms |
| **Database Load** | 100% | 10% | 10% |

### When to Use Each Scenario

**Scenario A (No Cache):**
- ✅ Data changes extremely frequently
- ✅ Absolute consistency required
- ✅ Low traffic (< 100 req/sec)
- ❌ High traffic applications
- ❌ Cost-sensitive deployments

**Scenario B (TTL Only):**
- ✅ Eventual consistency acceptable
- ✅ Simple deployment (no Kafka)
- ✅ Single instance deployment
- ❌ Multi-instance deployments
- ❌ Strict consistency requirements

**Scenario C (TTL + Kafka):**
- ✅ Production applications
- ✅ Multi-instance deployments
- ✅ High traffic (> 1000 req/sec)
- ✅ Balance of speed and consistency
- ✅ Horizontal scaling needed
- ❌ Simple prototypes
- ❌ Single instance deployments

---

## Testing the Scenarios

### Interactive Demo

Visit the Cache Demo page:
```
http://localhost:3000/cache-demo
```

The demo runs these exact steps:
1. First read (cache miss)
2. Second read (cache hit)
3. Update product
4. Read after update (check for stale data)

### Automated Testing

```bash
# Quick test (2 minutes)
./scripts/quick-cache-test.sh

# Full comparison (30-45 minutes)
./scripts/run-all-scenarios.sh
```

### What to Watch For

**Scenario A:**
- Every request shows "MongoDB query" in logs
- Consistent ~250ms latency
- No cache hit/miss logs

**Scenario B:**
- First request: "Cache MISS"
- Second request: "Cache HIT"
- After update: May see stale data on other instances
- Inconsistency lasts until TTL expires

**Scenario C:**
- First request: "Cache MISS"
- Second request: "Cache HIT"
- After update: "Kafka invalidation event sent"
- All instances: "Cache invalidated via Kafka"
- Inconsistency window < 100ms

---

## Conclusion

**Recommended for Production: Scenario C (TTL + Kafka Invalidation)**

It provides the best balance of:
- ⚡ Performance (90% faster than no cache)
- 🎯 Consistency (< 0.1% stale data)
- 📈 Scalability (horizontal scaling)
- 💰 Cost efficiency (90% less database load)

The small inconsistency window (< 100ms) is acceptable for most applications and provides massive performance benefits.
