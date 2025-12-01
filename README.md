# EDS Marketplace: Modern E-commerce Platform

A full-featured marketplace application built with microservices architecture, demonstrating Kafka-based distributed cache invalidation, real-time performance optimization, and modern web technologies.

## 🏪 Marketplace Features

- **Product Catalog**: Browse, search, and filter products by category, price, and ratings
- **User Authentication**: JWT-based registration and login system
- **Shopping Cart**: Add/remove items with persistent cart storage
- **Order Management**: Complete checkout process and order history
- **Admin Panel**: Product management and system monitoring
- **Responsive Design**: Mobile-friendly React interface
- **Real-time Updates**: Kafka-powered cache invalidation for instant data consistency

## 🏗️ Architecture

### Microservices Overview

This application follows a **microservices architecture** with event-driven communication and distributed caching:

```
┌─────────────────┐
│   Vercel CDN    │  ← Frontend Hosting (React App)
└────────┬────────┘
         │ HTTPS
         ↓
┌─────────────────┐
│  API Gateway    │  ← Spring Cloud Gateway (Render)
│   Port: 8080    │     - Request routing
└────────┬────────┘     - CORS handling
         │              - Load balancing
    ┌────┴────┬─────────────┬──────────┐
    ↓         ↓             ↓          ↓
┌────────┐ ┌────────┐ ┌─────────┐ ┌──────────┐
│Catalog │ │ Order  │ │  User   │ │ MongoDB  │
│Service │ │Service │ │ Service │ │  Atlas   │
│  8081  │ │  8082  │ │  8083   │ └──────────┘
└───┬────┘ └───┬────┘ └─────────┘
    │          │
    │          │ Kafka Events
    │          ↓
    │    ┌──────────────┐
    │    │  Confluent   │  ← Event Streaming
    │    │    Cloud     │     - Cache invalidation
    │    │   (Kafka)    │     - Order events
    │    └──────────────┘
    │
    ↓ Cache
┌──────────┐
│ Upstash  │  ← Redis Cache (Optional)
│  Redis   │     - Product caching
└──────────┘     - TTL-based expiry
```

### Service Details

- **api-gateway** (Port 8080): Spring Cloud Gateway
  - Routes requests to appropriate microservices
  - Handles CORS for cross-origin requests
  - Implements retry logic for sleeping services
  - Provides centralized entry point

- **catalog-service** (Port 8081): Product Catalog Management
  - Product CRUD operations with search and filtering
  - Redis caching with configurable strategies
  - Kafka-based cache invalidation
  - MongoDB for product persistence
  - Real-time inventory updates

- **order-service** (Port 8082): Order Management
  - Order creation and tracking
  - MongoDB for order persistence
  - Kafka event publishing for order events
  - Integration with catalog for inventory

- **user-service** (Port 8083): Authentication & Authorization
  - JWT-based authentication
  - User registration and login
  - Role-based access control (Admin/Customer)
  - MongoDB for user data

- **marketplace-ui** (Port 3000): React Frontend
  - Responsive single-page application
  - Product browsing and search
  - Shopping cart management
  - User authentication UI
  - Admin panel for product management

## ☁️ Cloud Infrastructure

This application is deployed using a **fully cloud-native architecture** with the following platforms:

### Cloud Platforms Used

| Platform | Purpose | Tier | Cost |
|----------|---------|------|------|
| **Render** | Backend Services (4 microservices) | Free | $0/month |
| **Vercel** | Frontend Hosting (React App) | Free | $0/month |
| **MongoDB Atlas** | Database (Products, Orders, Users) | Free (M0) | $0/month |
| **Confluent Cloud** | Kafka Event Streaming | Free | $0/month |
| **Upstash Redis** | Distributed Cache (Optional) | Free | $0/month |
| **UptimeRobot** | Keep Services Awake | Free | $0/month |

**Total Monthly Cost: $0** (All free tiers!)

### Why These Platforms?

1. **Render** - Backend Microservices
   - ✅ Free tier with 4 services
   - ✅ Automatic deployments from GitHub
   - ✅ Built-in health checks and logs
   - ⚠️ Services sleep after 15 min (solved with UptimeRobot)

2. **Vercel** - Frontend Hosting
   - ✅ Optimized for React applications
   - ✅ Global CDN for fast loading
   - ✅ Automatic HTTPS and deployments
   - ✅ Preview deployments for PRs

3. **MongoDB Atlas** - Database
   - ✅ Managed MongoDB in the cloud
   - ✅ 512MB storage on free tier
   - ✅ Automatic backups and scaling
   - ✅ Global clusters for low latency

4. **Confluent Cloud** - Kafka
   - ✅ Managed Kafka service
   - ✅ Event streaming for cache invalidation
   - ✅ Real-time data processing
   - ⚠️ Optional (app works without it)

5. **Upstash Redis** - Caching
   - ✅ Serverless Redis
   - ✅ Global replication
   - ✅ REST API support
   - ⚠️ Optional (app works without it)

6. **UptimeRobot** - Service Monitoring
   - ✅ Pings services every 5 minutes
   - ✅ Keeps Render services awake
   - ✅ Email alerts for downtime
   - ✅ 50 monitors on free tier

### Deployment Guides

📖 **Complete Deployment Guide:** [RENDER_DEPLOYMENT.md](eds-lite/RENDER_DEPLOYMENT.md)

📖 **Keep Services Awake:** [KEEP_SERVICES_AWAKE.md](eds-lite/KEEP_SERVICES_AWAKE.md)

📖 **Frontend Deployment:** [VERCEL_DEPLOYMENT.md](eds-lite/VERCEL_DEPLOYMENT.md)

---

## Prerequisites (Local Development)

- Java 21
- Maven 3.8+
- Node.js 16+ and npm
- Redis (local or Upstash)
- MongoDB (local or Atlas)
- Kafka (Redpanda local or Confluent Cloud)
- k6 (for load testing)
- Python 3.8+ (for metrics summarization)

## 🚀 Quick Start

### Option A: Automated Startup (Recommended)

```bash
# 1. Setup infrastructure (first time only)
./scripts/setup-local.sh
./scripts/setup-kafka.sh

# 2. Start infrastructure
./scripts/start-kafka.sh    # Terminal 1
./scripts/start-redis.sh    # Terminal 2  
./scripts/start-mongo.sh    # Terminal 3

# 3. Seed marketplace data (includes admin user)
mongosh mongodb://localhost:27017/eds < scripts/seed-marketplace.js

# 4. Start all marketplace services
./scripts/start-marketplace.sh

# 5. Access the marketplace
# Frontend: http://localhost:3000
# Admin Login: admin@marketplace.com / admin123
```

### Option B: Manual Setup

### 0. Setup Local Infrastructure (First Time Only)

```bash
# Install and setup Redis, MongoDB, and Kafka
./scripts/setup-local.sh

# For Kafka, choose one:
# Option A: Apache Kafka (native, no Docker) - RECOMMENDED
./scripts/setup-kafka.sh

# Option B: Redpanda (requires Docker on macOS)
# ./scripts/setup-local.sh  # Already includes Redpanda setup
```

### 1. Start Infrastructure

```bash
# Terminal 1: Start Kafka (choose one)
# Option A: Apache Kafka (no Docker) - RECOMMENDED
./scripts/start-kafka.sh

# Option B: Redpanda (requires Docker)
# ./scripts/start-redpanda.sh

# Option C: Use Confluent Cloud (no local setup)
# Just set environment variables (see Step 2)

# Terminal 2: Start Redis
./scripts/start-redis.sh

# Terminal 3: Start MongoDB
./scripts/start-mongo.sh

# Verify all services are running
./scripts/check-services.sh

# Terminal 4: Seed MongoDB with marketplace data (includes admin user)
mongosh mongodb://localhost:27017/eds < scripts/seed-marketplace.js
```

### 2. Configure Kafka (if using Confluent Cloud)

Set environment variables:
```bash
export KAFKA_BOOTSTRAP_SERVERS=your-bootstrap-servers
export KAFKA_SASL_JAAS_CONFIG=your-jaas-config
export KAFKA_SECURITY_PROTOCOL=SASL_SSL
```

Or edit `catalog-service/src/main/resources/application.yml` and `order-service/src/main/resources/application.yml`.

### 3. Run Backend Services

```bash
# Terminal 5: User Service (Authentication)
cd user-service
mvn spring-boot:run

# Terminal 6: Catalog Service
cd catalog-service
export CACHE_MODE=ttl_invalidate  # Options: none, ttl, ttl_invalidate
mvn spring-boot:run

# Terminal 7: Order Service
cd order-service
mvn spring-boot:run

# Terminal 8: API Gateway
cd api-gateway
mvn spring-boot:run
```

### 4. Run Frontend

```bash
# Terminal 9: React Frontend
cd marketplace-ui
npm install
npm start
```

The marketplace will be available at:
- **Frontend**: http://localhost:3000
- **API Gateway**: http://localhost:8080

## � Datagbase Setup

### Seeding Options

**Option 1: Full Marketplace Data (Recommended)**
```bash
# Seeds products AND creates admin user
mongosh mongodb://localhost:27017/eds < scripts/seed-marketplace.js
```

**Option 2: Products Only**
```bash
# Seeds 2000 products but NO admin user
mongosh mongodb://localhost:27017/eds < scripts/seed-mongo.js
```

**Option 3: Admin User Only**
```bash
# Creates admin user without affecting existing products
mongosh mongodb://localhost:27017/eds < scripts/create-admin-user.js
```

### ⚠️ Important Notes
- **Always use Option 1** for first-time setup
- If you get "invalid credentials" for admin login, you likely used Option 2
- The admin user credentials are: `admin@marketplace.com` / `admin123`

## 🚀 Using the Marketplace

### Access the Application
1. **Frontend**: http://localhost:3000
2. **Admin Panel**: Login with `admin@marketplace.com` / `admin123`

### Demo Accounts
- **Admin**: admin@marketplace.com / admin123 (created by seed script)
- **Customer**: Register a new account or use the demo interface

> **Note**: If you get "invalid credentials" when logging in as admin, make sure you ran the marketplace seed script: `mongosh mongodb://localhost:27017/eds < scripts/seed-marketplace.js`

### Key Features to Test
1. **Product Search & Filtering**: Use the search bar and category filters
2. **Shopping Cart**: Add products and proceed to checkout
3. **Cache Performance**: Watch the console logs for cache hits/misses
4. **Admin Functions**: Manage products and view system metrics
5. **Real-time Updates**: Update product prices in admin panel and see instant cache invalidation

### API Testing (Optional)
```bash
# Update a product (triggers cache invalidation)
curl -X POST http://localhost:8080/api/catalog/products/1 \
  -H "Content-Type: application/json" \
  -d '{"price": 99.99, "stock": 50}'

# Search products
curl "http://localhost:8080/api/catalog/products?search=laptop&category=Electronics"

# Get featured products
curl http://localhost:8080/api/catalog/products/featured
```

### 5. Test the System

**Option A: Quick Test (2 minutes)**
```bash
./scripts/quick-test.sh
```

**Option B: Full Scenario Comparison (30-45 minutes)**
```bash
./scripts/run-all-scenarios.sh
```

See [TESTING_GUIDE.md](TESTING_GUIDE.md) for detailed testing instructions.

## 🔄 Request Flow

### Typical User Request Flow

```
1. User Action (Browser)
   ↓
2. React Frontend (Vercel)
   │ - User clicks "View Product"
   │ - Axios makes API call
   ↓
3. API Gateway (Render)
   │ - Receives request at /api/catalog/products/123
   │ - Routes to catalog-service
   │ - Applies retry logic if service is sleeping
   ↓
4. Catalog Service (Render)
   │ - Checks Redis cache first
   │ - If CACHE HIT: Return cached data (< 10ms)
   │ - If CACHE MISS: Query MongoDB
   ↓
5. MongoDB Atlas
   │ - Fetch product data
   │ - Return to catalog-service
   ↓
6. Catalog Service
   │ - Store result in Redis cache
   │ - Return to API Gateway
   ↓
7. API Gateway
   │ - Return to frontend
   ↓
8. React Frontend
   │ - Display product to user
```

### Cache Invalidation Flow

```
1. Admin Updates Product Price
   ↓
2. Frontend sends POST /api/catalog/products/123
   ↓
3. Catalog Service
   │ - Updates product in MongoDB
   │ - Evicts from local Redis cache
   │ - Publishes Kafka event: "product.123.updated"
   ↓
4. Kafka (Confluent Cloud)
   │ - Distributes event to all subscribers
   ↓
5. All Catalog Service Instances
   │ - Receive Kafka event
   │ - Evict product.123 from their Redis caches
   │ - Next request will fetch fresh data
   ↓
6. Result: All caches invalidated in < 100ms
   │ - No stale data served
   │ - Consistent across all instances
```

## 🧪 Cache Testing: Three Scenarios

This application demonstrates three different caching strategies to compare performance and consistency:

### Scenario A: No Cache

**Configuration:**
```bash
CACHE_TYPE=none
```

**How it works:**
- Every request goes directly to MongoDB
- No caching layer at all
- Guaranteed fresh data, but slow

**Performance:**
- ❌ High latency (100-500ms per request)
- ✅ 0% stale data (always fresh)
- ❌ High database load
- ❌ Poor scalability

**Use Case:** When data changes extremely frequently and consistency is critical

---

### Scenario B: TTL-Only Cache

**Configuration:**
```bash
CACHE_TYPE=redis
CACHE_MODE=ttl
```

**How it works:**
- Products cached in Redis with 5-minute TTL
- Cache automatically expires after TTL
- No active invalidation on updates
- Updates only visible after cache expires

**Performance:**
- ✅ Low latency (< 10ms for cache hits)
- ✅ 85-95% cache hit rate
- ⚠️ Stale data possible (up to 5 minutes old)
- ⚠️ Inconsistency window = TTL duration

**Use Case:** When eventual consistency is acceptable and simplicity is preferred

---

### Scenario C: TTL + Kafka Invalidation (Recommended)

**Configuration:**
```bash
CACHE_TYPE=redis
CACHE_MODE=ttl_invalidate
KAFKA_ENABLED=true
```

**How it works:**
- Products cached in Redis with 5-minute TTL (safety net)
- On product update, Kafka event published
- All service instances receive event and evict cache
- Next request fetches fresh data from MongoDB
- Combines speed of caching with consistency of invalidation

**Performance:**
- ✅ Low latency (< 10ms for cache hits)
- ✅ 85-95% cache hit rate
- ✅ Near-zero stale data (< 0.1%)
- ✅ Inconsistency window < 100ms
- ✅ Best of both worlds!

**Use Case:** Production systems requiring both performance and consistency

---

### Performance Comparison

| Metric | No Cache | TTL Only | TTL + Kafka |
|--------|----------|----------|-------------|
| **Avg Latency** | 250ms | 15ms | 15ms |
| **p95 Latency** | 500ms | 25ms | 25ms |
| **Cache Hit Rate** | 0% | 90% | 90% |
| **Stale Data Rate** | 0% | 5-10% | < 0.1% |
| **Inconsistency Window** | 0ms | 300,000ms | < 100ms |
| **Database Load** | 100% | 10% | 10% |
| **Complexity** | Low | Low | Medium |
| **Scalability** | Poor | Good | Excellent |

### Testing the Scenarios

**Interactive Demo:**
Visit the Cache Demo page in the application:
```
http://localhost:3000/cache-demo
```

**Automated Testing:**
```bash
# Quick test (2 minutes)
./scripts/quick-cache-test.sh

# Full comparison (30-45 minutes)
./scripts/run-all-scenarios.sh
```

**What the tests measure:**
1. **Latency**: How fast requests are served
2. **Cache Hit Rate**: Percentage of requests served from cache
3. **Stale Data Detection**: How often outdated data is served
4. **Inconsistency Window**: Time between update and cache refresh

## Cache Modes

- **none**: Disable caching entirely (Scenario A)
- **ttl**: Enable caching with TTL only (Scenario B)
- **ttl_invalidate**: Enable caching + Kafka invalidation (Scenario C - Recommended)

## Metrics

Metrics are written to `/tmp/metrics/*.jsonl`:
- `catalog.jsonl`: Cache hits/misses, invalidations, stale reads, inconsistency windows
- `gateway.jsonl`: Request latencies
- `order.jsonl`: Order operations

## Expected Results

| Scenario | p95 (ms) | Hit Rate | Stale Rate | Inconsistency p95 (ms) |
|----------|----------|----------|------------|------------------------|
| A (none) | HIGH     | 0%       | 0%         | 0                      |
| B (ttl)  | LOW      | 85-95%   | >0%        | ≈ TTL (seconds)        |
| C (ttl+inv) | LOW   | 85-95%   | ~0%        | < 100                  |

## 📁 Project Structure

```
eds-lite/
├── api-gateway/          # Spring Cloud Gateway with CORS
├── catalog-service/      # Enhanced product catalog with search & filtering
├── order-service/        # Order management system
├── user-service/         # JWT authentication & user management
├── marketplace-ui/       # React frontend application
│   ├── src/
│   │   ├── components/   # Reusable React components
│   │   ├── pages/        # Main application pages
│   │   ├── context/      # React context providers
│   │   └── App.js        # Main application component
├── scripts/              # Infrastructure and test scripts
│   ├── start-redpanda.sh
│   ├── start-redis.sh
│   ├── start-mongo.sh
│   ├── seed-marketplace.js  # Marketplace sample data
│   ├── run-k6-*.sh      # Load testing scripts
│   └── summarize-metrics.py
└── ops/
    └── k6/
        └── load-mixed.js
```

## 🧪 Performance Testing

The original cache invalidation testing capabilities are preserved and enhanced:

### Quick Test (2 minutes)
Fast validation that cache invalidation is working:
```bash
./scripts/quick-test.sh
```

### Full Scenario Test (30-45 minutes)
Complete comparison of all three caching strategies:
```bash
./scripts/run-all-scenarios.sh
```

### Marketplace Load Testing
Test the complete marketplace under load:
```bash
# Test product search and cart operations
./scripts/run-k6-marketplace.sh
```

### What to Monitor
- **Cache Performance**: Redis hit/miss ratios in service logs
- **Search Performance**: MongoDB query optimization with indexes
- **Real-time Updates**: Kafka message processing for cache invalidation
- **Frontend Performance**: React component rendering and API response times

See [TESTING_GUIDE.md](TESTING_GUIDE.md) for detailed instructions.

## 🛠️ Technology Stack

### Backend
- **Java 21** with Spring Boot 3.2
- **Spring Cloud Gateway** for API routing
- **Spring Security** with JWT authentication
- **MongoDB** for data persistence
- **Redis** for high-performance caching
- **Apache Kafka** for real-time event streaming

### Frontend
- **React 18** with functional components and hooks
- **React Router** for client-side routing
- **Axios** for HTTP requests
- **Context API** for state management
- **Responsive CSS** for mobile-first design

### Infrastructure
- **Microservices Architecture** with independent scaling
- **Event-Driven Design** with Kafka messaging
- **Distributed Caching** with Redis and cache invalidation
- **RESTful APIs** with comprehensive error handling

## 🎯 Marketplace Capabilities

### Customer Features
- Browse products with advanced search and filtering
- View detailed product information with images and reviews
- Add items to cart with quantity management
- Secure user registration and authentication
- Complete checkout process with order confirmation
- View order history and status tracking

### Admin Features
- Product management (create, read, update)
- Inventory tracking with low-stock alerts
- System performance monitoring
- Cache invalidation monitoring
- User management capabilities

### Performance Features
- **Sub-100ms response times** with Redis caching
- **Real-time cache invalidation** via Kafka events
- **Horizontal scalability** with microservices
- **Mobile-responsive design** for all devices
- **SEO-friendly URLs** with React Router

## 🔧 Troubleshooting

### Backend Issues
- **Kafka connection issues**: Check `KAFKA_BOOTSTRAP_SERVERS` and security config
- **Redis connection**: Ensure Redis is running on localhost:6379
- **MongoDB connection**: Check `mongodb://localhost:27017/eds`
- **Services not starting**: Run `./scripts/check-services.sh` to diagnose
- **Port conflicts**: Ensure ports 8080-8083 are available

### Frontend Issues
- **React app won't start**: Run `npm install` in marketplace-ui directory
- **API calls failing**: Verify backend services are running
- **CORS errors**: Check API Gateway CORS configuration
- **Build errors**: Ensure Node.js 16+ is installed

### Authentication Issues
- **"Invalid credentials" for admin**: Run the full marketplace seed script:
  ```bash
  mongosh mongodb://localhost:27017/eds < scripts/seed-marketplace.js
  ```
- **Admin user doesn't exist**: Create admin user only:
  ```bash
  mongosh mongodb://localhost:27017/eds < scripts/create-admin-user.js
  ```
- **Can't register new users**: Ensure user-service is running on port 8083

### Performance Issues
- **Slow product search**: Check MongoDB indexes and query optimization
- **Cache misses**: Monitor Redis connection and TTL settings
- **High latency**: Review Kafka consumer lag and processing times

## 🎯 What's New in the Marketplace

This application transforms the original EDS-Lite cache invalidation demo into a full-featured e-commerce marketplace while preserving all the original performance testing capabilities.

### New Features Added
- **React Frontend**: Modern, responsive web interface
- **User Authentication**: JWT-based login/registration system  
- **Product Management**: Enhanced catalog with search, filtering, and categories
- **Shopping Cart**: Persistent cart with quantity management
- **Order System**: Complete checkout flow and order history
- **Admin Panel**: Product management and system monitoring

### Original Features Preserved
- **Cache Invalidation**: Kafka-based distributed cache invalidation
- **Performance Testing**: All original k6 load testing scripts
- **Metrics Collection**: Comprehensive performance monitoring
- **Multiple Cache Modes**: Support for none/ttl/ttl_invalidate modes

### Architecture Benefits
- **Microservices**: Independent, scalable services
- **Event-Driven**: Real-time updates via Kafka messaging
- **High Performance**: Sub-100ms response times with Redis caching
- **Modern Stack**: Latest Spring Boot, React, and cloud-native technologies

The marketplace demonstrates real-world application of distributed systems concepts including caching strategies, event-driven architecture, and microservices patterns while maintaining the educational value of the original performance testing framework.

