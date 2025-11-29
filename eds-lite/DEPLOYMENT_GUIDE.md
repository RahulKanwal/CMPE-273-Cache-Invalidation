# 🚀 EDS Marketplace Deployment Guide

Deploy your EDS Marketplace to the cloud using free services with GitHub integration.

## 🏗️ Deployment Architecture

- **Frontend (React)**: Vercel (Free)
- **Backend Services**: Railway (Free tier - $5/month after trial)
- **Database**: MongoDB Atlas (Free tier - 512MB)
- **Cache**: Upstash Redis (Free tier - 10K requests/day)
- **Message Queue**: Confluent Cloud (Free tier - 1 cluster, unlimited topics)

## 📋 Prerequisites

1. GitHub account with your project repository
2. Accounts on deployment platforms (all free to create)

## 🎯 Step-by-Step Deployment

### Step 1: Setup Cloud Databases

#### 1.1 MongoDB Atlas (Database)

1. Go to [MongoDB Atlas](https://www.mongodb.com/atlas)
2. Sign up/Login and create a new project
3. Create a **FREE** M0 cluster
4. **Important**: Choose a region close to your users
5. Create a database user:
   - Username: `eds-user`
   - Password: Generate a secure password
6. Add IP addresses to whitelist:
   - Add `0.0.0.0/0` (allow from anywhere) for simplicity
   - Or add specific Railway IP ranges for security
7. Get your connection string:
   ```
   mongodb+srv://eds-user:<password>@cluster0.xxxxx.mongodb.net/eds
   ```

#### 1.2 Upstash Redis (Cache)

1. Go to [Upstash](https://upstash.com/)
2. Sign up/Login with GitHub
3. Create a new Redis database:
   - Name: `eds-cache`
   - Region: Choose same region as MongoDB
   - Type: Free tier
4. Get connection details:
   - Endpoint: `your-db.upstash.io`
   - Port: `6379`
   - Password: Copy the password

#### 1.3 Confluent Cloud (Message Queue) - RECOMMENDED

1. Go to [Confluent Cloud](https://confluent.cloud/)
2. Sign up for a free account (requires credit card but **won't charge on free tier**)
3. Create a new cluster:
   - Click **Create cluster**
   - Select **Basic** cluster type
   - Choose **AWS** (or your preferred cloud)
   - Region: Choose closest to your MongoDB/Redis
   - Cluster name: `eds-marketplace`
4. Create API Keys:
   - Go to **Data integration** > **API keys**
   - Click **Create key** (Global access)
   - **Save the Key and Secret** - you won't see them again!
5. Create topics:
   - Go to **Topics** tab
   - Create topic: `cache-invalidation`
   - Create topic: `order-events`
   - Use default settings (1 partition is fine for free tier)
6. Get connection details:
   - Go to **Cluster settings** > **Cluster overview**
   - Copy **Bootstrap server** (e.g., `pkc-xxxxx.us-east-1.aws.confluent.cloud:9092`)

**What you need:**
- Bootstrap servers: `pkc-xxxxx.region.aws.confluent.cloud:9092`
- API Key: `YOUR_API_KEY`
- API Secret: `YOUR_API_SECRET`
- Security protocol: `SASL_SSL`
- SASL mechanism: `PLAIN`

**Free Tier Limits:**
- 1 Kafka cluster
- Unlimited topics
- Up to 100 GB storage/month
- Perfect for development and small production apps!

**Alternative: Self-hosted Kafka on Railway (No Credit Card)**

If you don't want to use a credit card, deploy Kafka directly on Railway:

1. In your Railway project, add a new service
2. Deploy from Docker image: `bitnami/kafka:latest`
3. Set environment variables:
   ```
   KAFKA_CFG_NODE_ID=0
   KAFKA_CFG_PROCESS_ROLES=controller,broker
   KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093
   KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
   KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=0@localhost:9093
   KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER
   ```
4. Railway will provide an internal URL like `kafka.railway.internal:9092`
5. Use this URL in your other services' `KAFKA_BOOTSTRAP_SERVERS`

**Note**: Self-hosted Kafka on Railway uses your $5/month Railway credits.

### Step 2: Deploy Backend Services (Railway)

#### 2.1 Setup Railway

1. Go to [Railway](https://railway.app/)
2. Sign up with GitHub
3. Connect your GitHub repository

#### 2.2 Deploy Each Service

**Deploy API Gateway:**
1. Create new project in Railway
2. Click **New** > **GitHub Repo** and select your repository
3. Configure the service:
   - **Root Directory**: `eds-lite/api-gateway`
   - Railway will auto-detect the Dockerfile
4. Set environment variables:
   ```
   PORT=8080
   SPRING_PROFILES_ACTIVE=prod
   ```
5. Deploy

**Deploy Catalog Service:**
1. In the same Railway project, click **New** > **GitHub Repo** (select same repo)
2. Configure the service:
   - **Root Directory**: `eds-lite/catalog-service`
3. Set environment variables:
   ```
   PORT=8081
   MONGODB_URI=mongodb+srv://eds-user:<password>@cluster0.xxxxx.mongodb.net/eds
   REDIS_HOST=your-redis-host.upstash.io
   REDIS_PORT=6379
   REDIS_PASSWORD=your-redis-password
   KAFKA_BOOTSTRAP_SERVERS=pkc-xxxxx.region.aws.confluent.cloud:9092
   KAFKA_SASL_JAAS_CONFIG=org.apache.kafka.common.security.plain.PlainLoginModule required username="YOUR_API_KEY" password="YOUR_API_SECRET";
   KAFKA_SECURITY_PROTOCOL=SASL_SSL
   KAFKA_SASL_MECHANISM=PLAIN
   CACHE_MODE=ttl_invalidate
   SPRING_PROFILES_ACTIVE=prod
   ```

**Deploy Order Service:**
1. Click **New** > **GitHub Repo** (select same repo)
2. Configure the service:
   - **Root Directory**: `eds-lite/order-service`
3. Set environment variables:
   ```
   PORT=8082
   MONGODB_URI=mongodb+srv://eds-user:<password>@cluster0.xxxxx.mongodb.net/eds
   KAFKA_BOOTSTRAP_SERVERS=pkc-xxxxx.region.aws.confluent.cloud:9092
   KAFKA_SASL_JAAS_CONFIG=org.apache.kafka.common.security.plain.PlainLoginModule required username="YOUR_API_KEY" password="YOUR_API_SECRET";
   KAFKA_SECURITY_PROTOCOL=SASL_SSL
   KAFKA_SASL_MECHANISM=PLAIN
   SPRING_PROFILES_ACTIVE=prod
   ```

**Deploy User Service:**
1. Click **New** > **GitHub Repo** (select same repo)
2. Configure the service:
   - **Root Directory**: `eds-lite/user-service`
3. Set environment variables:
   ```
   PORT=8083
   MONGODB_URI=mongodb+srv://eds-user:<password>@cluster0.xxxxx.mongodb.net/eds
   JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
   SPRING_PROFILES_ACTIVE=prod
   ```

#### 2.3 Get Service URLs

After deployment, Railway will provide URLs like:
- API Gateway: `https://api-gateway-production-xxxx.up.railway.app`
- Catalog Service: `https://catalog-service-production-xxxx.up.railway.app`
- Order Service: `https://order-service-production-xxxx.up.railway.app`
- User Service: `https://user-service-production-xxxx.up.railway.app`

### Step 3: Deploy Frontend (Vercel)

#### 3.1 Setup Vercel

1. Go to [Vercel](https://vercel.com/)
2. Sign up with GitHub
3. Import your repository

#### 3.2 Configure Frontend

1. Set build settings:
   - Framework: Create React App
   - Build Command: `cd marketplace-ui && npm run build`
   - Output Directory: `marketplace-ui/build`

2. Set environment variables:
   ```
   REACT_APP_API_GATEWAY_URL=https://api-gateway-production-xxxx.up.railway.app
   REACT_APP_CATALOG_SERVICE_URL=https://catalog-service-production-xxxx.up.railway.app
   REACT_APP_USER_SERVICE_URL=https://user-service-production-xxxx.up.railway.app
   REACT_APP_ORDER_SERVICE_URL=https://order-service-production-xxxx.up.railway.app
   ```

3. Deploy

### Step 4: Update CORS Configuration

Update your backend services to allow your Vercel domain:

In each service's `application.yml` or environment variables:
```yaml
cors:
  allowed-origins: 
    - https://your-app.vercel.app
    - http://localhost:3000
```

### Step 5: Seed Production Database

1. Connect to your MongoDB Atlas cluster
2. Use MongoDB Compass or mongosh:
   ```bash
   mongosh "mongodb+srv://eds-user:<password>@cluster0.xxxxx.mongodb.net/eds"
   ```
3. Run the seed script:
   ```javascript
   // Copy content from scripts/seed-marketplace.js and run
   ```

### Step 6: Create Admin User

Since you can't run scripts directly in production, create admin user via API:

1. Use your deployed user service URL
2. Register admin user:
   ```bash
   curl -X POST https://user-service-production-xxxx.up.railway.app/auth/register \
     -H "Content-Type: application/json" \
     -d '{"email": "admin@marketplace.com", "password": "admin123", "firstName": "Admin", "lastName": "User"}'
   ```
3. Update role in MongoDB Atlas to "ADMIN"

## 🎯 Alternative: Simpler Deployment Options

### Option 1: Render (All-in-One)

1. **Render** - Deploy all services on one platform
   - Free tier available
   - Automatic GitHub integration
   - Built-in PostgreSQL (free tier)

### Option 2: Heroku (Traditional)

1. **Heroku** - Classic PaaS
   - Free tier discontinued, but affordable
   - Easy GitHub integration
   - Add-ons for databases

### Option 3: Netlify + Supabase

1. **Frontend**: Netlify (free)
2. **Backend**: Supabase (free tier)
   - Built-in PostgreSQL
   - Built-in authentication
   - Real-time subscriptions

## 🔧 Production Configuration

### Environment-Specific Configs

Create `application-prod.yml` files for each service:

**catalog-service/src/main/resources/application-prod.yml:**
```yaml
server:
  port: ${PORT:8081}

spring:
  data:
    mongodb:
      uri: ${MONGODB_URI}
  redis:
    host: ${REDIS_HOST}
    port: ${REDIS_PORT}
    password: ${REDIS_PASSWORD}
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS}
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
      properties:
        security.protocol: ${KAFKA_SECURITY_PROTOCOL:SASL_SSL}
        sasl.mechanism: ${KAFKA_SASL_MECHANISM:PLAIN}
        sasl.jaas.config: ${KAFKA_SASL_JAAS_CONFIG}

cache:
  mode: ${CACHE_MODE:ttl_invalidate}

logging:
  level:
    com.eds: INFO
    org.springframework.kafka: WARN
```

### Security Considerations

1. **Use strong JWT secrets**
2. **Enable HTTPS only**
3. **Restrict CORS origins**
4. **Use environment variables for all secrets**
5. **Enable MongoDB authentication**
6. **Use Redis AUTH**

## 📊 Monitoring & Maintenance

### Health Checks

Add health check endpoints to each service:
```java
@RestController
public class HealthController {
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("OK");
    }
}
```

### Logging

Configure structured logging for production:
```yaml
logging:
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"
  level:
    com.eds: INFO
    org.springframework: WARN
```

## 💰 Cost Breakdown (Monthly)

- **MongoDB Atlas**: Free (512MB)
- **Upstash Redis**: Free (10K requests/day)
- **Confluent Cloud**: Free (1 cluster, 100GB/month)
- **Railway**: $5/month (after free trial)
- **Vercel**: Free (hobby plan)

**Total: ~$5/month** for a fully deployed microservices application!

## 🚀 Quick Deploy Commands

```bash
# 1. Push to GitHub
git add .
git commit -m "Add deployment configuration"
git push origin main

# 2. Deploy frontend to Vercel
npx vercel --prod

# 3. Deploy services to Railway
# (Use Railway dashboard for GitHub integration)

# 4. Seed database
mongosh "your-mongodb-connection-string" < scripts/seed-marketplace.js
```

## 🎯 Success Checklist

- [ ] MongoDB Atlas cluster created and accessible
- [ ] Upstash Redis database created
- [ ] Confluent Cloud cluster created with topics
- [ ] All 4 backend services deployed to Railway
- [ ] Frontend deployed to Vercel
- [ ] CORS configured for production domain
- [ ] Database seeded with products
- [ ] Admin user created and tested
- [ ] All services health checks passing
- [ ] Frontend can communicate with backend APIs

Your EDS Marketplace is now live and accessible worldwide! 🌍

## 🚨
 Railway Deployment Troubleshooting

### Error: "failed to read dockerfile: no such file or directory"

**Problem:** Railway can't find the Dockerfile because the root directory isn't set correctly.

**Solution:**
1. Go to your Railway service settings
2. Click on **Settings** tab
3. Find **Root Directory** setting
4. Set it to the correct path:
   - API Gateway: `eds-lite/api-gateway`
   - Catalog Service: `eds-lite/catalog-service`
   - Order Service: `eds-lite/order-service`
   - User Service: `eds-lite/user-service`
5. Redeploy

**Alternative:** If you want to avoid setting root directory for each service, you can move the `eds-lite` contents to your repository root.

### Error: "Build takes too long" or "Out of memory"

**Problem:** Maven builds can be slow and memory-intensive.

**Solution:**
1. Railway's free tier has limited resources
2. Consider using pre-built JAR files
3. Or upgrade to Railway Pro for faster builds

### Services Won't Start

**Common issues:**
- Missing environment variables (check all required vars are set)
- Wrong MongoDB connection string (check password encoding)
- Kafka connection issues (verify Confluent Cloud credentials)
- Port conflicts (ensure each service uses unique PORT)

### How to View Logs in Railway

1. Click on your service
2. Go to **Deployments** tab
3. Click on the latest deployment
4. View **Build Logs** and **Deploy Logs**
5. Look for error messages

### Quick Railway Setup Checklist

For each service, verify:
- [ ] Root Directory is set correctly
- [ ] All environment variables are configured
- [ ] Dockerfile exists in the service directory
- [ ] Build completes successfully
- [ ] Service starts and health check passes
- [ ] Service URL is accessible
