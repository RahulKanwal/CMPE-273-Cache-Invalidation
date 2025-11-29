# 🚀 Simple Deployment Guide

## Your Current Setup

- **Railway**: API Gateway, Catalog Service, Order Service (3 services)
- **Render**: User Service (1 service)
- **Vercel**: Frontend (React app)

---

## 🎯 Can You Use Just ONE Platform?

### Short Answer: **No, not with free tiers**

Here's why:

| Platform | Free Tier Limit | Can Deploy All? |
|----------|----------------|-----------------|
| **Railway** | 3 services max (free) | ❌ No (you need 4 backend + 1 frontend) |
| **Render** | Unlimited services | ✅ Yes, BUT services sleep after 15 min |
| **Vercel** | Frontend only | ❌ No (can't deploy Java backends) |

### Best Free Option: **Render (All Services)**

You CAN deploy everything on Render for free, but:
- ⚠️ Services sleep after 15 minutes of inactivity
- ⚠️ Cold start takes 30-60 seconds
- ⚠️ First request will be slow

### Your Current Setup is Actually Good!

**Railway (3 services) + Render (1 service) + Vercel (frontend)** is a smart approach:
- ✅ Railway services don't sleep (always fast)
- ✅ Render free for user service (less critical)
- ✅ Vercel perfect for React frontend
- ✅ Total cost: FREE

---

## 🔧 Fix Your Current Deployment

### Step 1: Check Railway Services (They're Crashing!)

Your services are returning 502 errors. Check logs:

1. Go to Railway dashboard
2. Click each service → **Deployments** → Latest deployment
3. Check **Deploy Logs** for errors

**Common Issues:**
- Missing environment variables
- MongoDB connection string wrong
- Kafka credentials wrong
- Redis credentials wrong

### Step 2: Required Environment Variables

**API Gateway:**
```
PORT=8080
SPRING_PROFILES_ACTIVE=prod
```

**Catalog Service:**
```
PORT=8081
MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net/eds
REDIS_HOST=your-redis.upstash.io
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password
KAFKA_BOOTSTRAP_SERVERS=pkc-xxxxx.confluent.cloud:9092
KAFKA_SASL_JAAS_CONFIG=org.apache.kafka.common.security.plain.PlainLoginModule required username="YOUR_KEY" password="YOUR_SECRET";
KAFKA_SECURITY_PROTOCOL=SASL_SSL
KAFKA_SASL_MECHANISM=PLAIN
CACHE_MODE=ttl_invalidate
SPRING_PROFILES_ACTIVE=prod
```

**Order Service:**
```
PORT=8082
MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net/eds
KAFKA_BOOTSTRAP_SERVERS=pkc-xxxxx.confluent.cloud:9092
KAFKA_SASL_JAAS_CONFIG=org.apache.kafka.common.security.plain.PlainLoginModule required username="YOUR_KEY" password="YOUR_SECRET";
KAFKA_SECURITY_PROTOCOL=SASL_SSL
KAFKA_SASL_MECHANISM=PLAIN
SPRING_PROFILES_ACTIVE=prod
```

**User Service (Render):**
```
PORT=8083
MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net/eds
JWT_SECRET=eEC0caLTyMUR90/hY6JR3kjCpcNlYi/8zXXSFjxKKfHNrPMt0DoIZ+N2XAiRjbU24ymeacruGCHzo1kox5+lkQ==
SPRING_PROFILES_ACTIVE=prod
```

### Step 3: Fix Vercel Environment Variables

In Vercel → Settings → Environment Variables:

```
REACT_APP_API_GATEWAY_URL=https://api-gateway-production-383c.up.railway.app
REACT_APP_CATALOG_SERVICE_URL=https://catalog-service-production-8579.up.railway.app
REACT_APP_ORDER_SERVICE_URL=https://order-service-production-75fa.up.railway.app
REACT_APP_USER_SERVICE_URL=https://user-service-f6ix.onrender.com
```

**Important:**
- ✅ Include `https://`
- ✅ No trailing slashes
- ✅ Correct service names (you had them swapped!)

### Step 4: Add CORS Configuration

In each Railway service, add:
```
CORS_ALLOWED_ORIGINS=https://marketplace-ui-tau.vercel.app,http://localhost:3000
```

---

## 🆘 Troubleshooting

### Railway Services Show 502 Error

**Check:**
1. Deployment logs for error messages
2. All environment variables are set
3. MongoDB/Redis/Kafka credentials are correct

**Common Errors:**
- `MongoTimeoutException` → Check MongoDB URI
- `RedisConnectionException` → Check Redis credentials
- `KafkaException` → Check Kafka credentials
- `ClassNotFoundException` → Redeploy (Dockerfile is fixed)

### Frontend Shows "n.map is not a function"

**Fix:**
1. Verify Vercel environment variables are correct
2. Make sure Railway services are running (not 502)
3. Check browser console for actual error
4. Redeploy Vercel after adding variables

### Render Service is Slow

**This is normal!** Free tier services sleep after 15 min.
- First request takes 30-60 seconds to wake up
- Subsequent requests are fast
- Consider upgrading to paid tier ($7/mo) if this is a problem

---

## ✅ Quick Checklist

- [ ] All Railway services deployed and showing "Active"
- [ ] Render user-service deployed and showing "Live"
- [ ] All environment variables set correctly
- [ ] MongoDB Atlas cluster created and accessible
- [ ] Upstash Redis created
- [ ] Confluent Cloud Kafka created with topics
- [ ] Vercel environment variables configured
- [ ] CORS configured on all backend services
- [ ] Frontend deployed and accessible
- [ ] Can access https://marketplace-ui-tau.vercel.app without errors

---

## 📞 Need Help?

**Check Railway logs first!**
1. Go to service → Deployments → Latest
2. Look at Deploy Logs
3. Find the error message
4. Share it if you need help

**Test your services:**
```bash
# Test catalog service
curl https://catalog-service-production-8579.up.railway.app/products/featured

# Should return JSON array of products, not 502 error
```

---

## 💡 Alternative: Deploy Everything on Render (Free)

If Railway is giving you trouble, you can deploy all 4 backend services on Render:

**Pros:**
- ✅ Completely free
- ✅ Unlimited services
- ✅ Simple setup

**Cons:**
- ⚠️ Services sleep after 15 min inactivity
- ⚠️ 30-60 second cold start
- ⚠️ Slower performance

**How to do it:**
1. Create 4 web services on Render
2. Use Dockerfile for each
3. Set environment variables
4. Deploy

But your current setup (Railway + Render) is better because Railway services don't sleep!

---

## 🎯 Summary

**Your setup is good!** The issue is that your Railway services are crashing. Fix the environment variables and check the logs to see what's wrong.

**Most likely issue:** Missing or incorrect MongoDB/Redis/Kafka credentials.

**Next step:** Check Railway deployment logs and share the error message if you need help.
