# 🚀 Deploy NOW - 30 Minute Guide

Stop reading, start deploying. This is the fastest path to get your app live.

---

## ✅ Prerequisites (10 minutes)

### 1. MongoDB Atlas
```
1. Go to: https://mongodb.com/atlas
2. Create FREE M0 cluster
3. Create user: eds-user / [password]
4. Whitelist IP: 0.0.0.0/0
5. Copy connection string
```
**Save this:** `mongodb+srv://eds-user:[password]@cluster0.xxxxx.mongodb.net/eds`

### 2. Upstash Redis
```
1. Go to: https://upstash.com
2. Create Redis database
3. Copy: Host, Port, Password
```
**Save these:** Host, Port (6379), Password

### 3. Confluent Cloud Kafka
```
1. Go to: https://confluent.cloud
2. Create Basic cluster (FREE)
3. Create API Key
4. Create topics: cache-invalidation, order-events
5. Copy bootstrap server
```
**Save these:** Bootstrap server, API Key, API Secret

---

## 🔧 Fix Railway (5 minutes)

Your API Gateway is failing because of missing root directory.

### For Each Service:
1. Click service in Railway
2. Go to **Settings**
3. Find **Root Directory**
4. Enter:
   - API Gateway: `eds-lite/api-gateway`
   - Catalog: `eds-lite/catalog-service`
   - Order: `eds-lite/order-service`
   - User: `eds-lite/user-service`
5. Click **Redeploy**

---

## ⚙️ Environment Variables (10 minutes)

### API Gateway
```
PORT=8080
SPRING_PROFILES_ACTIVE=prod
```

### Catalog Service
```
PORT=8081
MONGODB_URI=[your-mongodb-string]
REDIS_HOST=[your-upstash-host]
REDIS_PORT=6379
REDIS_PASSWORD=[your-upstash-password]
KAFKA_BOOTSTRAP_SERVERS=[confluent-bootstrap-server]
KAFKA_SASL_JAAS_CONFIG=org.apache.kafka.common.security.plain.PlainLoginModule required username="[API_KEY]" password="[API_SECRET]";
KAFKA_SECURITY_PROTOCOL=SASL_SSL
KAFKA_SASL_MECHANISM=PLAIN
CACHE_MODE=ttl_invalidate
SPRING_PROFILES_ACTIVE=prod
```

### Order Service
```
PORT=8082
MONGODB_URI=[your-mongodb-string]
KAFKA_BOOTSTRAP_SERVERS=[confluent-bootstrap-server]
KAFKA_SASL_JAAS_CONFIG=org.apache.kafka.common.security.plain.PlainLoginModule required username="[API_KEY]" password="[API_SECRET]";
KAFKA_SECURITY_PROTOCOL=SASL_SSL
KAFKA_SASL_MECHANISM=PLAIN
SPRING_PROFILES_ACTIVE=prod
```

### User Service
```
PORT=8083
MONGODB_URI=[your-mongodb-string]
JWT_SECRET=[random-string-here]
SPRING_PROFILES_ACTIVE=prod
```

---

## 🌐 Deploy Frontend (5 minutes)

### Vercel
```
1. Go to: https://vercel.com
2. Import your GitHub repo
3. Root Directory: marketplace-ui
4. Build Command: npm run build
5. Output Directory: build
6. Add environment variables:
   REACT_APP_API_GATEWAY_URL=[railway-api-gateway-url]
   REACT_APP_CATALOG_SERVICE_URL=[railway-catalog-url]
   REACT_APP_USER_SERVICE_URL=[railway-user-url]
   REACT_APP_ORDER_SERVICE_URL=[railway-order-url]
7. Deploy
```

---

## ✅ Verify (2 minutes)

### Check Railway Services
- [ ] All 4 services show "Active"
- [ ] No errors in deploy logs
- [ ] Each service has a public URL

### Check Frontend
- [ ] Vercel deployment successful
- [ ] Can access your-app.vercel.app
- [ ] No console errors

### Test App
- [ ] Can view products
- [ ] Can register/login
- [ ] Can add to cart

---

## 🆘 Troubleshooting

### Railway Build Fails
**Problem:** "failed to read dockerfile"  
**Fix:** Set root directory (see above)

### Service Won't Start
**Problem:** Crashes on startup  
**Fix:** Check environment variables are set correctly

### Frontend Can't Connect
**Problem:** API calls fail  
**Fix:** Update CORS in Railway services:
```
CORS_ALLOWED_ORIGINS=https://your-app.vercel.app,http://localhost:3000
```

### Kafka Errors
**Problem:** Can't connect to Kafka  
**Fix:** Verify Confluent Cloud credentials and bootstrap server

---

## 📋 Checklist

- [ ] MongoDB Atlas created
- [ ] Upstash Redis created
- [ ] Confluent Cloud Kafka created
- [ ] Railway root directories set
- [ ] All environment variables configured
- [ ] All 4 services deployed and active
- [ ] Frontend deployed to Vercel
- [ ] CORS configured
- [ ] App tested and working

---

## 🎉 Done!

Your app is live at: `https://your-app.vercel.app`

**Cost:** $5/month (Railway only)

**Next steps:**
- Create admin user (see QUICK_DEPLOY.md)
- Seed database with products
- Share your app!

---

## 📚 Need More Details?

- **Railway issues:** RAILWAY_SETUP.md
- **Full guide:** QUICK_DEPLOY.md
- **Platform comparison:** PLATFORM_COMPARISON.md
- **Heroku alternative:** HEROKU_DEPLOYMENT.md
