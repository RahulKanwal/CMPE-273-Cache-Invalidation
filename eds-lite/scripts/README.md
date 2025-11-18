# Scripts Directory

This directory contains all the scripts needed to run and test the EDS-Lite project.

## Quick Start

### 1. Start Infrastructure
```bash
./start-kafka.sh      # Terminal 1
./start-redis.sh      # Terminal 2
./start-mongo.sh      # Terminal 3
```

### 2. Seed Database
```bash
mongosh mongodb://localhost:27017/eds < seed-mongo.js
```

### 3. Test the System

**Option A: Quick Test (2 minutes)**
```bash
./quick-test.sh
```

**Option B: Full Scenario Comparison (30-45 minutes)**
```bash
./run-all-scenarios.sh
```

---

## Script Reference

### Infrastructure Scripts

| Script | Purpose |
|--------|---------|
| `setup-local.sh` | Install Redis, MongoDB, Redpanda (first time only) |
| `setup-kafka.sh` | Install Apache Kafka (alternative to Redpanda) |
| `start-kafka.sh` | Start Kafka broker |
| `start-redis.sh` | Start Redis server |
| `start-mongo.sh` | Start MongoDB server |
| `check-services.sh` | Verify all services are running |

### Service Management Scripts

| Script | Purpose |
|--------|---------|
| `start-catalog-service.sh` | Start catalog service with specific cache mode |

### Testing & Analysis Scripts

| Script | Purpose |
|--------|---------|
| `quick-test.sh` | Quick 2-minute system validation |
| `run-scenarios-manual.sh` | Manual 3-scenario comparison test |
| `run-all-scenarios.sh` | Automated 3-scenario comparison |
| `test-apis.sh` | Basic API connectivity test |
| `verify-endpoints.sh` | Comprehensive endpoint validation |

### Metrics & Reporting Scripts

| Script | Purpose | Data Source | Saves Report |
|--------|---------|-------------|--------------|
| `summarize-metrics.py` | Basic metrics summary | Current (`/tmp/metrics/`) | ❌ Console only |
| `generate-scenario-report.py` | **📊 Comprehensive scenario comparison** | Historical (`/tmp/eds-results/`) | ✅ Auto-saves |
| `current-metrics-report.py` | **📈 Detailed current system analysis** | Current (`/tmp/metrics/`) | ❌ Console only |
| `save-current-report.py` | **📈 Current analysis + file save** | Current (`/tmp/metrics/`) | ✅ Auto-saves |
| `generate-latest-report.py` | **🚀 COMPREHENSIVE: Latest test analysis** | Current + Latest Historical | ✅ Auto-saves |

### Key Reporting Scripts

#### 📊 Comprehensive Scenario Report
```bash
python3 generate-scenario-report.py
```
- Compares all 3 scenarios (A: No Cache, B: TTL Only, C: TTL + Invalidation)
- Shows performance comparison table
- Detailed analysis for each scenario
- Performance insights and recommendations

#### 🚀 **RECOMMENDED: Latest Test Analysis**
```bash
python3 generate-latest-report.py
```
- **ALL-IN-ONE**: Current system + latest scenario comparison
- **Production readiness assessment** with scoring
- **Executive summary** with clear recommendations
- **Comprehensive analysis** in single report
- **Auto-saves** with timestamp

#### 📈 Current System Analysis
```bash
# Console output only
python3 current-metrics-report.py

# Console output + save to file
python3 save-current-report.py
```
- Detailed analysis of current system state
- Performance scoring (0-100)
- Production readiness assessment
- Specific recommendations for optimization

### 📁 Report Storage

Reports are automatically saved to `/tmp/eds-reports/` with timestamps:
- `current-report-YYYYMMDD_HHMMSS.txt` - Current system analysis
- `scenario-comparison-YYYYMMDD_HHMMSS.txt` - Multi-scenario comparison

### 📊 Data Sources

| Report Type | Data Source | Description |
|-------------|-------------|-------------|
| **Current Reports** | `/tmp/metrics/catalog.jsonl` | Real-time metrics from running system |
| **Scenario Comparison** | `/tmp/eds-results/*/scenario-*-metrics/` | Historical data from scenario test runs |
| **Historical Backups** | Created by `run-scenarios-manual.sh` | Timestamped scenario results |
| `stop-catalog-service.sh` | Stop catalog service |

### Testing Scripts

| Script | Purpose | Duration |
|--------|---------|----------|
| `quick-test.sh` | Fast validation of cache invalidation | 2 min |
| `run-all-scenarios.sh` | Full A/B/C comparison with k6 | 30-45 min |
| `test-apis.sh` | Manual API testing | 1 min |
| `test-update-endpoint.sh` | Test update endpoint specifically | 1 min |
| `verify-endpoints.sh` | Check if all endpoints are available | 1 min |

### Load Testing Scripts

| Script | Purpose |
|--------|---------|
| `run-k6-a.sh` | Run k6 test for Scenario A (no cache) |
| `run-k6-b.sh` | Run k6 test for Scenario B (TTL only) |
| `run-k6-c.sh` | Run k6 test for Scenario C (TTL + invalidation) |

### Utility Scripts

| Script | Purpose |
|--------|---------|
| `access-mongo.sh` | Open MongoDB shell |
| `seed-mongo.js` | Seed database with 2000 products |
| `serve-demo.sh` | Start demo web UI |
| `summarize-metrics.py` | Analyze metrics and generate report |

---

## Common Workflows

### First Time Setup
```bash
# 1. Install infrastructure
./setup-local.sh
./setup-kafka.sh

# 2. Start everything
./start-kafka.sh &
./start-redis.sh &
./start-mongo.sh &

# 3. Seed database
mongosh mongodb://localhost:27017/eds < seed-mongo.js

# 4. Start services (in separate terminals)
cd ../api-gateway && mvn spring-boot:run
cd ../order-service && mvn spring-boot:run
cd ../catalog-service && export CACHE_MODE=ttl_invalidate && mvn spring-boot:run

# 5. Quick test
./quick-test.sh
```

### Daily Development
```bash
# Start infrastructure (if not running)
./check-services.sh

# Start services
cd ../catalog-service && export CACHE_MODE=ttl_invalidate && mvn spring-boot:run

# Test your changes
./quick-test.sh
```

### Performance Testing
```bash
# Run full scenario comparison
./run-all-scenarios.sh

# View results
cat /tmp/eds-results/*/RESULTS_SUMMARY.txt
```

### Debugging
```bash
# Check what's running
./check-services.sh

# Access MongoDB
./access-mongo.sh

# View metrics
cat /tmp/metrics/catalog.jsonl | tail -20

# Test specific endpoint
./test-update-endpoint.sh
```

---

## Environment Variables

### CACHE_MODE
Controls caching behavior in catalog-service:

- `none` - Disable caching (Scenario A)
- `ttl` - Enable caching with TTL only (Scenario B)
- `ttl_invalidate` - Enable caching + Kafka invalidation (Scenario C, default)

**Usage:**
```bash
export CACHE_MODE=ttl_invalidate
cd ../catalog-service && mvn spring-boot:run
```

### Kafka Configuration
If using Confluent Cloud instead of local Kafka:

```bash
export KAFKA_BOOTSTRAP_SERVERS=pkc-xxxxx.us-east-1.aws.confluent.cloud:9092
export KAFKA_SECURITY_PROTOCOL=SASL_SSL
export KAFKA_SASL_JAAS_CONFIG='org.apache.kafka.common.security.plain.PlainLoginModule required username="..." password="...";'
```

---

## Troubleshooting

### Port Already in Use
```bash
# Find and kill process
lsof -ti:8081 | xargs kill -9

# Or use the stop script
./stop-catalog-service.sh
```

### Services Won't Start
```bash
# Check logs
tail -f /tmp/catalog-*.log

# Verify infrastructure
./check-services.sh

# Restart infrastructure
pkill -f kafka
pkill -f redis
pkill -f mongod

./start-kafka.sh
./start-redis.sh
./start-mongo.sh
```

### No Metrics
```bash
# Create metrics directory
mkdir -p /tmp/metrics
chmod 777 /tmp/metrics

# Restart catalog service
./stop-catalog-service.sh
./start-catalog-service.sh
```

### k6 Tests Fail
```bash
# Install k6
brew install k6  # macOS
# or
sudo apt-get install k6  # Linux

# Check if gateway is running
curl http://localhost:8080/api/catalog/products/1
```

---

## Script Details

### quick-test.sh
**What it does:**
1. Checks all services are running
2. Performs cache miss test (first read)
3. Performs cache hit test (second read)
4. Updates product (triggers invalidation)
5. Verifies fresh data is retrieved
6. Shows metrics summary

**When to use:** Quick validation during development

### run-all-scenarios.sh
**What it does:**
1. Verifies infrastructure is running
2. Runs Scenario A (no cache) with k6
3. Runs Scenario B (TTL only) with k6
4. Runs Scenario C (TTL + invalidation) with k6
5. Backs up metrics for each scenario
6. Generates comparison report

**When to use:** Performance benchmarking, demos, final validation

### summarize-metrics.py
**What it does:**
- Parses `/tmp/metrics/*.jsonl` files
- Calculates p50/p95 latencies
- Computes cache hit rate
- Detects stale read rate
- Measures inconsistency window

**When to use:** After running k6 tests to analyze results

---

## Tips

1. **Always check services first:** Run `./check-services.sh` before testing
2. **Wait for warmup:** Give services 10-15 seconds after starting
3. **Clean metrics:** Delete `/tmp/metrics/` between test runs for clean results
4. **Use quick-test first:** Validate basic functionality before running full scenarios
5. **Monitor logs:** Keep service terminals visible to see invalidation messages

---

## Getting Help

If you encounter issues:

1. Check `../TROUBLESHOOTING.md`
2. Check `../TESTING_GUIDE.md`
3. Run `./check-services.sh` to verify infrastructure
4. Check service logs in `/tmp/catalog-*.log`
5. Verify metrics directory exists: `ls -la /tmp/metrics/`
