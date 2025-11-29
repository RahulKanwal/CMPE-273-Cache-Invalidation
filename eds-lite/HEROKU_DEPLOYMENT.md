# Heroku Deployment Guide

## ⚠️ Important: Heroku Pricing Changes

**Heroku no longer has a free tier** (as of November 2022). Minimum cost is ~$7/month per dyno.

**Cost Estimate:**
- 4 backend services × $7 = $28/month
- MongoDB Atlas: Free
- Redis (Heroku addon): $3-15/month
- Kafka (Heroku addon): $25+/month
- **Total: ~$56+/month**

**Recommendation:** Use Railway ($5/month) or Render (free tier) instead for cost savings.

---

## If You Still Want to Use Heroku

Heroku doesn't support monorepo deployments easily. You have **two options**:

### Option A: Deploy Each Service Separately (Recommended)
Create 4 separate Heroku apps, one for each service.

### Option B: Use Heroku Monorepo Buildpack
Deploy all services from one repo using a special buildpack.

---

## Option A: Separate Heroku Apps (Step-by-Step)

### Prerequisites
1. Heroku account: https://heroku.com
2. Heroku CLI installed: `brew install heroku/brew/heroku`
3. Credit card (required even for paid tiers)

### Step 1: Login to Heroku
```bash
heroku login
```

### Step 2: Setup MongoDB and Redis

#### MongoDB Atlas (Free)
1. Go to https://mongodb.com/atlas
2. Create free M0 cluster
3. Get connection string: `mongodb+srv://user:pass@cluster.mongodb.net/eds`

#### Heroku Redis
You'll add this as an addon to each service that needs it.

#### Kafka - Use Confluent Cloud
Heroku Kafka is expensive ($25+/month). Use Confluent Cloud free tier instead:
1. Sign up at https://confluent.cloud
2. Create Basic cluster (free)
3. Get bootstrap servers and API keys

### Step 3: Deploy API Gateway

```bash
cd eds-lite/api-gateway

# Create Heroku app
heroku create your-app-api-gateway

# Set buildpack for Java
heroku buildpacks:set heroku/java -a your-app-api-gateway

# Set environment variables
heroku config:set SPRING_PROFILES_ACTIVE=prod -a your-app-api-gateway

# Create Procfile for this service
echo "web: java -Dserver.port=\$PORT -jar target/api-gateway-1.0.0.jar" > Procfile

# Deploy
git init
git add .
git commit -m "Deploy API Gateway"
heroku git:remote -a your-app-api-gateway
git push heroku main
```

### Step 4: Deploy Catalog Service

```bash
cd ../catalog-service

# Create Heroku app
heroku create your-app-catalog-service

# Set buildpack
heroku buildpacks:set heroku/java -a your-app-catalog-service

# Add Redis addon
heroku addons:create heroku-redis:mini -a your-app-catalog-service

# Set environment variables
heroku config:set \
  SPRING_PROFILES_ACTIVE=prod \
  MONGODB_URI="mongodb+srv://user:pass@cluster.mongodb.net/eds" \
  KAFKA_BOOTSTRAP_SERVERS="pkc-xxxxx.confluent.cloud:9092" \
  KAFKA_SASL_JAAS_CONFIG='org.apache.kafka.common.security.plain.PlainLoginModule required username="API_KEY" password="API_SECRET";' \
  KAFKA_SECURITY_PROTOCOL=SASL_SSL \
  KAFKA_SASL_MECHANISM=PLAIN \
  CACHE_MODE=ttl_invalidate \
  -a your-app-catalog-service

# Heroku Redis sets REDIS_URL automatically, but we need to parse it
# Add this to your application.yml or use REDIS_URL directly

# Create Procfile
echo "web: java -Dserver.port=\$PORT -jar target/catalog-service-1.0.0.jar" > Procfile

# Deploy
git init
git add .
git commit -m "Deploy Catalog Service"
heroku git:remote -a your-app-catalog-service
git push heroku main
```

### Step 5: Deploy Order Service

```bash
cd ../order-service

# Create Heroku app
heroku create your-app-order-service

# Set buildpack
heroku buildpacks:set heroku/java -a your-app-order-service

# Set environment variables
heroku config:set \
  SPRING_PROFILES_ACTIVE=prod \
  MONGODB_URI="mongodb+srv://user:pass@cluster.mongodb.net/eds" \
  KAFKA_BOOTSTRAP_SERVERS="pkc-xxxxx.confluent.cloud:9092" \
  KAFKA_SASL_JAAS_CONFIG='org.apache.kafka.common.security.plain.PlainLoginModule required username="API_KEY" password="API_SECRET";' \
  KAFKA_SECURITY_PROTOCOL=SASL_SSL \
  KAFKA_SASL_MECHANISM=PLAIN \
  -a your-app-order-service

# Create Procfile
echo "web: java -Dserver.port=\$PORT -jar target/order-service-1.0.0.jar" > Procfile

# Deploy
git init
git add .
git commit -m "Deploy Order Service"
heroku git:remote -a your-app-order-service
git push heroku main
```

### Step 6: Deploy User Service

```bash
cd ../user-service

# Create Heroku app
heroku create your-app-user-service

# Set buildpack
heroku buildpacks:set heroku/java -a your-app-user-service

# Set environment variables
heroku config:set \
  SPRING_PROFILES_ACTIVE=prod \
  MONGODB_URI="mongodb+srv://user:pass@cluster.mongodb.net/eds" \
  JWT_SECRET="your-super-secret-jwt-key-change-this" \
  -a your-app-user-service

# Create Procfile
echo "web: java -Dserver.port=\$PORT -jar target/user-service-1.0.0.jar" > Procfile

# Deploy
git init
git add .
git commit -m "Deploy User Service"
heroku git:remote -a your-app-user-service
git push heroku main
```

### Step 7: Deploy Frontend to Heroku

```bash
cd ../marketplace-ui

# Create Heroku app
heroku create your-app-marketplace-ui

# Set buildpack for Node.js
heroku buildpacks:set heroku/nodejs -a your-app-marketplace-ui

# Set environment variables
heroku config:set \
  REACT_APP_API_GATEWAY_URL="https://your-app-api-gateway.herokuapp.com" \
  REACT_APP_CATALOG_SERVICE_URL="https://your-app-catalog-service.herokuapp.com" \
  REACT_APP_USER_SERVICE_URL="https://your-app-user-service.herokuapp.com" \
  REACT_APP_ORDER_SERVICE_URL="https://your-app-order-service.herokuapp.com" \
  -a your-app-marketplace-ui

# Deploy
git init
git add .
git commit -m "Deploy Frontend"
heroku git:remote -a your-app-marketplace-ui
git push heroku main
```

### Step 8: Update CORS

Update each backend service to allow your frontend domain:

```bash
heroku config:set \
  CORS_ALLOWED_ORIGINS="https://your-app-marketplace-ui.herokuapp.com,http://localhost:3000" \
  -a your-app-api-gateway

# Repeat for other services
```

---

## Option B: Monorepo Deployment (Advanced)

This is more complex but keeps everything in one repo.

### 1. Install Heroku Monorepo Buildpack

```bash
cd eds-lite

# Create 4 Heroku apps
heroku create your-app-api-gateway
heroku create your-app-catalog-service
heroku create your-app-order-service
heroku create your-app-user-service
```

### 2. Use heroku-buildpack-monorepo

For each app:
```bash
heroku buildpacks:add -i 1 https://github.com/lstoll/heroku-buildpack-monorepo -a your-app-api-gateway
heroku buildpacks:add -i 2 heroku/java -a your-app-api-gateway

heroku config:set APP_BASE=api-gateway -a your-app-api-gateway
```

Repeat for each service with the correct APP_BASE.

### 3. Create Procfiles

Create `api-gateway/Procfile`:
```
web: java -Dserver.port=$PORT -jar target/api-gateway-1.0.0.jar
```

Repeat for each service.

### 4. Deploy

```bash
git push heroku main
```

---

## Cost Comparison

| Platform | Monthly Cost | Free Tier |
|----------|-------------|-----------|
| **Heroku** | $56+ | ❌ None |
| **Railway** | $5 | ✅ $5 credit |
| **Render** | $0-25 | ✅ Free tier |
| **Vercel + Railway** | $5 | ✅ Vercel free |

---

## My Recommendation

**Don't use Heroku for this project.** Here's why:

1. **Cost:** $56+/month vs $5/month on Railway
2. **Complexity:** Separate deployments for each service
3. **No free tier:** Can't test without paying
4. **Better alternatives:** Railway, Render, or Fly.io

### Better Options:

**Option 1: Railway (Recommended)**
- $5/month total
- Easy monorepo support
- Follow RAILWAY_SETUP.md guide
- Set root directory for each service

**Option 2: Render**
- Free tier available
- Similar to Heroku
- Better pricing
- Native monorepo support

**Option 3: Fly.io**
- Free tier (3 VMs)
- Docker-based (you already have Dockerfiles!)
- Global deployment
- Good for microservices

---

## If You Must Use Heroku

Follow **Option A** (separate apps) above. It's the most straightforward approach.

**Quick checklist:**
- [ ] Create 4 Heroku apps (one per backend service)
- [ ] Set up MongoDB Atlas (free)
- [ ] Set up Confluent Cloud Kafka (free)
- [ ] Add Heroku Redis addon to catalog-service
- [ ] Deploy each service separately
- [ ] Deploy frontend to Vercel (free) instead of Heroku
- [ ] Update CORS settings

**Estimated time:** 2-3 hours
**Monthly cost:** $28-56

---

## Need Help?

If you want to proceed with Heroku, I can help you:
1. Create individual Procfiles for each service
2. Set up the deployment scripts
3. Configure environment variables

But I strongly recommend using Railway instead - it's designed for exactly this use case and costs 90% less.
