# 🚀 Render Deployment Guide (Backup Option)

Deploy all 4 backend services on Render for **completely free**.

## ⚠️ Important Notes

**Pros:**
- ✅ Completely free
- ✅ Unlimited services
- ✅ No credit card required
- ✅ Simple setup

**Cons:**
- ⚠️ Services sleep after 15 minutes of inactivity
- ⚠️ Cold start takes 30-60 seconds on first request
- ⚠️ Slower than Railway (but still usable)

---

## 📋 Prerequisites

Before starting, make sure you have:
- [ ] GitHub account with your repository
- [ ] MongoDB Atlas connection string
- [ ] Upstash Redis credentials
- [ ] Confluent Cloud Kafka credentials
- [ ] JWT secret for user service

---

## 🎯 Step-by-Step Deployment

### Step 1: Sign Up for Render

1. Go to https://render.com/
2. Click **Get Started**
3. Sign up with GitHub (recommended)
4. Authorize Render to access your repositories

---

### Step 2: Deploy API Gateway

1. Click **New +** → **Web Service**
2. Connect your GitHub repository
3. Configure:
   - **Name**: `api-gateway`
   - **Region**: Choose closest to you (e.g., Oregon, Frankfurt)
   - **Branch**: `main`
   - **Root Directory**: Leave empty
   - **Runtime**: Docker
   - **Dockerfile Path**: `Dockerfile.api-gateway`
   - **Instance Type**: Free

4. **Environment Variables** (click Advanced):
   ```
   PORT=8080
   SPRING_PROFILES_ACTIVE=prod
   ```

5. Click **Create Web Service**
6. Wait for deployment (5-10 minutes)
7. **Copy the service URL** (e.g., `https://api-gateway-xxxx.onrender.com`)

---

### Step 3: Deploy Catalog Service

1. Click **New +** → **Web Service**
2. Select same repository
3. Configure:
   - **Name**: `catalog-service`
   - **Region**: Same as API Gateway
   - **Branch**: `main`
   - **Root Directory**: Leave empty
   - **Runtime**: Docker
   - **Dockerfile Path**: `Dockerfile.catalog-service`
   - **Instance Type**: Free

4. **Environment Variables**:
   ```
   PORT=8081
   MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net/eds
   REDIS_HOST=your-redis.upstash.io
   REDIS_PORT=6379
   REDIS_PASSWORD=your-redis-password
   KAFKA_BOOTSTRAP_SERVERS=pkc-xxxxx.region.aws.confluent.cloud:9092
   KAFKA_SASL_JAAS_CONFIG=org.apache.kafka.common.security.plain.PlainLoginModule required username="YOUR_API_KEY" password="YOUR_API_SECRET";
   KAFKA_SECURITY_PROTOCOL=SASL_SSL
   KAFKA_SASL_MECHANISM=PLAIN
   CACHE_MODE=ttl_invalidate
   SPRING_PROFILES_ACTIVE=prod
   ```

5. Click **Create Web Service**
6. **Copy the service URL**

---

### Step 4: Deploy Order Service

1. Click **New +** → **Web Service**
2. Select same repository
3. Configure:
   - **Name**: `order-service`
   - **Region**: Same as others
   - **Branch**: `main`
   - **Root Directory**: Leave empty
   - **Runtime**: Docker
   - **Dockerfile Path**: `Dockerfile.order-service`
   - **Instance Type**: Free

4. **Environment Variables**:
   ```
   PORT=8082
   MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net/eds
   KAFKA_BOOTSTRAP_SERVERS=pkc-xxxxx.region.aws.confluent.cloud:9092
   KAFKA_SASL_JAAS_CONFIG=org.apache.kafka.common.security.plain.PlainLoginModule required username="YOUR_API_KEY" password="YOUR_API_SECRET";
   KAFKA_SECURITY_PROTOCOL=SASL_SSL
   KAFKA_SASL_MECHANISM=PLAIN
   SPRING_PROFILES_ACTIVE=prod
   ```

5. Click **Create Web Service**
6. **Copy the service URL**

---

### Step 5: Deploy User Service

1. Click **New +** → **Web Service**
2. Select same repository
3. Configure:
   - **Name**: `user-service`
   - **Region**: Same as others
   - **Branch**: `main`
   - **Root Directory**: Leave empty
   - **Runtime**: Docker
   - **Dockerfile Path**: `Dockerfile.user-service`
   - **Instance Type**: Free

4. **Environment Variables**:
   ```
   PORT=8083
   MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net/eds
   JWT_SECRET=eEC0caLTyMUR90/hY6JR3kjCpcNlYi/8zXXSFjxKKfHNrPMt0DoIZ+N2XAiRjbU24ymeacruGCHzo1kox5+lkQ==
   SPRING_PROFILES_ACTIVE=prod
   ```

5. Click **Create Web Service**
6. **Copy the service URL**

---

### Step 6: Configure CORS

For each service, add CORS configuration:

1. Go to each service → **Environment**
2. Add new variable:
   ```
   CORS_ALLOWED_ORIGINS=https://marketplace-ui-tau.vercel.app,http://localhost:3000
   ```
3. Click **Save Changes**
4. Service will auto-redeploy

---

### Step 7: Update Vercel Frontend

1. Go to Vercel dashboard
2. Click your `marketplace-ui` project
3. Go to **Settings** → **Environment Variables**
4. Update with your Render URLs:
   ```
   REACT_APP_API_GATEWAY_URL=https://api-gateway-xxxx.onrender.com
   REACT_APP_CATALOG_SERVICE_URL=https://catalog-service-xxxx.onrender.com
   REACT_APP_ORDER_SERVICE_URL=https://order-service-xxxx.onrender.com
   REACT_APP_USER_SERVICE_URL=https://user-service-xxxx.onrender.com
   ```
5. Go to **Deployments** → **Redeploy**

---

## 🔍 Monitoring Your Services

### Check Service Status

1. Go to Render dashboard
2. Each service shows status:
   - 🟢 **Live** - Service is running
   - 🟡 **Building** - Deployment in progress
   - 🔴 **Failed** - Deployment failed
   - ⚪ **Sleeping** - Service is asleep (will wake on request)

### View Logs

1. Click on a service
2. Go to **Logs** tab
3. See real-time logs
4. Look for errors like:
   - `MongoTimeoutException` - MongoDB connection issue
   - `RedisConnectionException` - Redis connection issue
   - `KafkaException` - Kafka connection issue

### Wake Up Sleeping Services

Free tier services sleep after 15 minutes. To wake them:
1. Visit the service URL in browser
2. Wait 30-60 seconds for cold start
3. Service will be active for next 15 minutes

---

## 🆘 Troubleshooting

### Service Won't Start

**Check Logs:**
1. Go to service → **Logs**
2. Look for error messages
3. Common issues:
   - Wrong MongoDB URI
   - Wrong Redis credentials
   - Wrong Kafka credentials
   - Missing environment variables

**Fix:**
1. Go to **Environment** tab
2. Verify all variables are set correctly
3. Click **Manual Deploy** to redeploy

### Build Fails

**Common causes:**
- Dockerfile path is wrong
- GitHub repository not accessible
- Build timeout (free tier has limits)

**Fix:**
1. Check **Dockerfile Path** is correct:
   - `Dockerfile.api-gateway`
   - `Dockerfile.catalog-service`
   - `Dockerfile.order-service`
   - `Dockerfile.user-service`
2. Make sure files exist in your repository
3. Try manual deploy

### Service is Slow

**This is normal for free tier!**
- Services sleep after 15 min
- First request takes 30-60 seconds
- Subsequent requests are fast

**Solutions:**
- Upgrade to paid tier ($7/month per service)
- Use a service like UptimeRobot to ping services every 14 minutes (keeps them awake)
- Accept the cold start delay

### Frontend Can't Connect

**Check:**
1. All backend services are "Live" (not sleeping)
2. Vercel environment variables are correct
3. CORS is configured on all services
4. Service URLs use `https://` (not http)

**Test:**
```bash
# Test catalog service
curl https://catalog-service-xxxx.onrender.com/products/featured

# Should return JSON, not HTML error page
```

---

## 💡 Tips for Free Tier

### Keep Services Awake (Optional)

Use a free uptime monitoring service:

1. Sign up for https://uptimerobot.com/ (free)
2. Add monitors for each service:
   - `https://api-gateway-xxxx.onrender.com/actuator/health`
   - `https://catalog-service-xxxx.onrender.com/actuator/health`
   - `https://order-service-xxxx.onrender.com/actuator/health`
   - `https://user-service-xxxx.onrender.com/actuator/health`
3. Set interval to 14 minutes
4. Services will stay awake!

**Note:** This uses more of Render's free tier bandwidth.

### Optimize Build Times

Render caches Docker layers, so rebuilds are faster. To optimize:
- Don't change Dockerfiles unnecessarily
- Let Render auto-deploy on git push
- Use manual deploy only when needed

### Monitor Usage

1. Go to Render dashboard
2. Check **Usage** tab
3. Free tier includes:
   - 750 hours/month per service
   - 100 GB bandwidth/month
   - Unlimited builds

---

## 📊 Comparison: Render vs Railway

| Feature | Render (Free) | Railway (Free) |
|---------|---------------|----------------|
| **Services** | Unlimited | 3 max |
| **Sleep** | Yes (15 min) | No |
| **Cold Start** | 30-60 sec | N/A |
| **Build Time** | 5-10 min | 3-5 min |
| **Reliability** | Good | Excellent |
| **Cost** | $0 | $0 (then $5/mo) |

**Recommendation:**
- Use **Railway** for critical services (faster, no sleep)
- Use **Render** for less critical services or as backup
- Or use **all Render** if you're okay with cold starts

---

## ✅ Deployment Checklist

- [ ] All 4 services deployed on Render
- [ ] All services showing "Live" status
- [ ] Environment variables configured for each service
- [ ] CORS configured on all services
- [ ] Vercel updated with Render URLs
- [ ] Frontend deployed and accessible
- [ ] Can access https://marketplace-ui-tau.vercel.app
- [ ] Products load on home page (may take 60 sec first time)
- [ ] Can register/login
- [ ] Can add to cart

---

## 🎯 Your Service URLs

After deployment, you'll have:

```
API Gateway:     https://api-gateway-xxxx.onrender.com
Catalog Service: https://catalog-service-xxxx.onrender.com
Order Service:   https://order-service-xxxx.onrender.com
User Service:    https://user-service-xxxx.onrender.com
Frontend:        https://marketplace-ui-tau.vercel.app
```

Save these URLs! You'll need them for Vercel configuration.

---

## 🔄 Switching from Railway to Render

If you want to move from Railway to Render:

1. Deploy all 4 services on Render (follow steps above)
2. Update Vercel environment variables with Render URLs
3. Test that everything works
4. Delete Railway services (optional)

**Note:** You can run both simultaneously for testing!

---

## 💰 Cost Breakdown

**Render Free Tier:**
- 4 backend services: $0/month
- Services sleep after 15 min
- 750 hours/month per service (plenty!)

**Render Paid Tier (if you upgrade):**
- $7/month per service
- No sleeping
- Faster performance
- Total: $28/month for 4 services

**Recommendation:** Start with free tier, upgrade only if cold starts are a problem.

---

## 🎉 Done!

Your app is now deployed on Render! 

**First request will be slow (30-60 seconds)** because services are sleeping. This is normal for free tier.

After the first request, services will be fast for the next 15 minutes.

If you need faster performance, consider:
1. Upgrading to Render paid tier ($7/service)
2. Using Railway for critical services
3. Using UptimeRobot to keep services awake
