# API Test Examples

The database has been seeded with 2000 products. Here are some examples to test the APIs:

## Quick Test Script

```bash
./scripts/test-apis.sh
```

## Manual API Tests

### 1. Get a Product

```bash
curl http://localhost:8080/api/catalog/products/1
```

Expected: Returns product with ID "1"

### 2. Get Multiple Products (Test Cache)

```bash
# First call - cache miss
curl http://localhost:8080/api/catalog/products/1

# Second call - cache hit (if CACHE_MODE is not "none")
curl http://localhost:8080/api/catalog/products/1
```

### 3. Update a Product (Triggers Cache Invalidation)

```bash
curl -X POST http://localhost:8080/api/catalog/products/1 \
  -H "Content-Type: application/json" \
  -d '{
    "price": 99.99,
    "stock": 50
  }'
```

Expected: 
- Product updated with new price and stock
- Version incremented
- Cache invalidation event published to Kafka
- Check catalog-service logs for "invalidations_sent"

### 4. Get Updated Product (Should be Fresh)

```bash
curl http://localhost:8080/api/catalog/products/1
```

Expected: Returns updated product with new price/stock

### 5. Create an Order

```bash
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "customer-123",
    "items": [
      {"productId": "1", "quantity": 2, "price": 99.99},
      {"productId": "2", "quantity": 1, "price": 50.00}
    ]
  }'
```

Expected: Order created and order event published to Kafka

### 6. Get Product Version

```bash
curl http://localhost:8080/api/catalog/products/1/version
```

Expected: Returns the version number (integer)

## Testing Cache Invalidation

1. **Start two instances of catalog-service** (different ports):
   ```bash
   # Terminal 1
   cd catalog-service
   export CACHE_MODE=ttl_invalidate
   export SERVER_PORT=8081
   mvn spring-boot:run
   
   # Terminal 2
   cd catalog-service
   export CACHE_MODE=ttl_invalidate
   export SERVER_PORT=8083
   mvn spring-boot:run
   ```

2. **Update gateway routes** to include both instances

3. **Update a product** on instance 1

4. **Check instance 2 logs** - should show "invalidations_received" and cache key deleted

## Check Metrics

```bash
# View catalog metrics
tail -f /tmp/metrics/catalog.jsonl

# Summarize all metrics
python3 scripts/summarize-metrics.py
```

## Sample Product IDs

The database has products with IDs from "1" to "2000". You can test with any of these:

- Product 1: `curl http://localhost:8080/api/catalog/products/1`
- Product 100: `curl http://localhost:8080/api/catalog/products/100`
- Product 500: `curl http://localhost:8080/api/catalog/products/500`
- Product 2000: `curl http://localhost:8080/api/catalog/products/2000`


