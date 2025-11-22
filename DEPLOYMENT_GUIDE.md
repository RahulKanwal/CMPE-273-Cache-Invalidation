# EDS-Lite Deployment Guide

## Infrastructure Services Setup

### 1. Redis - Render Managed Service ✅
- **Where**: Render Dashboard
- **Type**: Managed Redis
- **Plan**: Starter (free tier available)
- **Setup**: Automatically handled by render.yaml

### 2. MongoDB - MongoDB Atlas (External) 🌐
- **Where**: MongoDB Atlas (https://cloud.mongodb.com)
- **Why**: More reliable than self-hosted, free tier available
- **Steps**:
  1. Create MongoDB Atlas account
  2. Create a new cluster (free M0 tier)
  3. Create database user
  4. Whitelist IP addresses (0.0.0.0/0 for Render)
  5. Get connection string
  6. Add to Render environment variables

### 3. Kafka - External Service 🌐
- **Options**:
  - **Upstash Kafka** (recommended - has free tier)
  - **Confluent Cloud** (more features, paid)
  - **CloudKarafka** (simple setup)
- **Why**: Kafka requires significant resources, external services are more reliable

## Deployment Strategy

### Phase 1: Setup External Services
1. **MongoDB Atlas Setup**
2. **Kafka Service Setup** (Upstash recommended)

### Phase 2: Deploy on Render
1. **Redis**: Managed by Render
2. **Java Services**: Deployed as web services

### Phase 3: Configure Environment Variables
- Set MongoDB and Kafka connection strings in Render dashboard

## Step-by-Step Instructions

### 1. MongoDB Atlas Setup
```
1. Go to https://cloud.mongodb.com
2. Sign up/Login
3. Create New Project → "EDS-Lite"
4. Build Database → Free M0 tier
5. Create Database User (username/password)
6. Network Access → Add IP: 0.0.0.0/0
7. Connect → Application → Copy connection string
```

### 2. Upstash Kafka Setup
```
1. Go to https://upstash.com
2. Sign up/Login
3. Create Kafka Cluster
4. Copy Bootstrap Servers URL
5. Create topics: orders, catalog-updates
```

### 3. Render Deployment
```
1. Go to render.com
2. New → Blueprint
3. Connect GitHub repository
4. Render will use render.yaml automatically
5. Add environment variables:
   - MONGODB_URI: <from MongoDB Atlas>
   - KAFKA_BOOTSTRAP_SERVERS: <from Upstash>
```

## Environment Variables to Set in Render

For each service (API Gateway, Catalog Service, Order Service):

```
SPRING_PROFILES_ACTIVE=production
REDIS_URL=<automatically set by Render>
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/eds-lite
KAFKA_BOOTSTRAP_SERVERS=<upstash-kafka-url>:9092
```

## Auto-Deployment
- ✅ Enabled automatically when connecting GitHub
- Every push to main branch triggers redeployment
- Only affected services are redeployed

## Cost Breakdown
- **Render Redis**: Free tier available
- **Render Web Services**: $7/month each (3 services = $21/month)
- **MongoDB Atlas**: Free M0 tier (512MB)
- **Upstash Kafka**: Free tier (10K messages/day)

**Total Free Tier**: $0/month
**Total Paid**: ~$21/month for production-ready setup