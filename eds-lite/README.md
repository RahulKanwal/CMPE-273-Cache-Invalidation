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

- **api-gateway** (8080): Spring Cloud Gateway with CORS support
- **catalog-service** (8081): Enhanced product catalog with search, filtering, and Redis caching
- **order-service** (8082): Order management with MongoDB persistence
- **user-service** (8083): JWT authentication and user management
- **marketplace-ui** (3000): React frontend with responsive design

## Prerequisites

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

# 3. Seed marketplace data
mongosh mongodb://localhost:27017/eds < scripts/seed-marketplace.js

# 4. Start all marketplace services
./scripts/start-marketplace.sh

# 5. Access the marketplace
# Frontend: http://localhost:3000
# Admin: admin@marketplace.com / admin123
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

# Terminal 4: Seed MongoDB with marketplace data
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

## 🚀 Using the Marketplace

### Access the Application
1. **Frontend**: http://localhost:3000
2. **Admin Panel**: Login with `admin@marketplace.com` / `admin123`

### Demo Accounts
- **Admin**: admin@marketplace.com / admin123
- **Customer**: Register a new account or use the demo interface

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

## Cache Modes

- **none**: Disable caching entirely
- **ttl**: Enable caching with TTL, but no Kafka invalidation consumer
- **ttl_invalidate**: Enable caching + Kafka invalidation consumer (default)

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

