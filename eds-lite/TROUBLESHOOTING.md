# Troubleshooting Guide

## Common Issues

### 404 Error on API Gateway

**Problem**: Getting 404 when accessing `http://localhost:8080/api/catalog/products/1`

**Solution**:
1. **Restart the API Gateway** - Configuration changes require a restart:
   ```bash
   # Stop the gateway (Ctrl+C)
   # Then restart:
   cd api-gateway
   mvn spring-boot:run
   ```

2. **Verify services are running**:
   ```bash
   # Check if services are listening
   lsof -i :8080  # Gateway
   lsof -i :8081  # Catalog Service
   lsof -i :8082  # Order Service
   ```

3. **Test direct service access**:
   ```bash
   # Test catalog-service directly (bypass gateway)
   curl http://localhost:8081/products/1
   
   # If this works, the issue is with the gateway routing
   ```

4. **Check gateway logs** for routing errors

### Gateway Route Configuration

The gateway strips 2 path segments:
- Request: `/api/catalog/products/1`
- Strips: `api` and `catalog` (StripPrefix=2)
- Forwards: `/products/1` to catalog-service

### Service Not Starting

**Check logs for**:
- Port already in use: `Address already in use`
- Database connection errors
- Kafka connection errors
- Redis connection errors

**Solutions**:
```bash
# Kill process on port
lsof -ti:8081 | xargs kill -9

# Check if services are running
./scripts/check-services.sh
```

### Database Connection Issues

**MongoDB not accessible**:
```bash
# Check if MongoDB is running
pgrep -f mongod

# Start MongoDB
./scripts/start-mongo.sh

# Test connection
mongosh mongodb://localhost:27017/eds --eval "db.products.countDocuments()"
```

### Redis Connection Issues

**Redis not accessible**:
```bash
# Check if Redis is running
pgrep -f redis-server

# Start Redis
./scripts/start-redis.sh

# Test connection
redis-cli ping
```

### Kafka Connection Issues

**Kafka not accessible**:
```bash
# Check if Kafka is running
pgrep -f kafka

# Start Kafka
./scripts/start-kafka.sh

# Test connection
# (Check logs for connection errors)
```

### Cache Not Working

**Check CACHE_MODE**:
```bash
# Verify environment variable
echo $CACHE_MODE

# Should be one of: none, ttl, ttl_invalidate
# Restart service after changing
```

### Metrics Not Appearing

**Check metrics directory**:
```bash
# Ensure directory exists and is writable
mkdir -p /tmp/metrics
chmod 777 /tmp/metrics

# Check if files are being created
ls -la /tmp/metrics/
```

## Service Health Checks

### Check All Services
```bash
# Gateway health
curl http://localhost:8080/actuator/health

# Catalog service health
curl http://localhost:8081/actuator/health

# Order service health
curl http://localhost:8082/actuator/health
```

### Check Service Logs

Look for:
- `Started CatalogServiceApplication` - Service started successfully
- `Started ApiGatewayApplication` - Gateway started
- Connection errors to MongoDB, Redis, Kafka
- Cache invalidation messages

## Quick Diagnostic Commands

```bash
# Check all ports
lsof -i :8080 -i :8081 -i :8082

# Check infrastructure
./scripts/check-services.sh

# Test direct service access
curl http://localhost:8081/products/1
curl http://localhost:8082/orders

# Test through gateway
curl http://localhost:8080/api/catalog/products/1
curl http://localhost:8080/api/orders
```


