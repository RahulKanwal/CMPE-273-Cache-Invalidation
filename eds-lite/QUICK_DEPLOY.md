# ⚡ Quick Deploy Checklist

Use this streamlined guide to deploy your EDS Marketplace in under 30 minutes.

## 🎯 Prerequisites Setup (10 minutes)

### 1. MongoDB Atlas
- Sign up: https://www.mongodb.com/atlas
- Create FREE M0 cluster
- Create user: `eds-user` / `[your-password]`
- Whitelist IP: `0.0.0.0/0`
- **Copy connection string**: `mongodb+srv://eds-user:[password]@cluster0.xxxxx.mongodb.net/eds`

### 2. Upstash Redis
- Sign up: https://upstash.com/
- Create Redis database: `eds-cache`
- **Copy**: Host, Port (6379), Password

### 3. Confluent Cloud (Kafka)
- Sign up: https://confluent.cloud/ (requires credit card, but free tier won't charge)
- Create **Basic** cluster (FREE tier)
- Create API Key (save Key + Secret!)
- **Copy from Cluster Overview**: Bootstrap servers
- Create topics in Topics tab:
  - `cache-invalidation`
  - `order-events`

**Alternative (No Credit Card)**: Deploy Kafka on Railway
- Add new service in Railway
- Use Docker image: `bitnami/kafka:latest`
- Set env vars (see deployment guide)
- Use internal Railway URL

## 🚀 Deploy Backend to Railway (10 minutes)

1. Sign up: https://railway.app/ (use GitHub)
2. Create new project
3. Deploy 4 services (one at a time):

**IMPORTANT:** For each service, set **Root Directory** in Railway settings:
- API Gateway: `eds-lite/api-gateway`
- Catalog Service: `eds-lite/catalog-service`
- Order Service: `eds-lite/order-service`
- User Service: `eds-lite/user-service`

### Service 1: API Gateway
- Root Directory: `eds-lite/api-gateway`
- Environment variables:
```
PORT=8080
SPRING_PROFILES_ACTIVE=prod
```

### Service 2: Catalog Service
- Root Directory: `eds-lite/catalog-service`
- Environment variables:
```
PORT=8081
MONGODB_URI=[your-mongodb-connection-string]
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

### Service 3: Order Service
- Root Directory: `eds-lite/order-service`
- Environment variables:
```
PORT=8082
MONGODB_URI=[your-mongodb-connection-string]
KAFKA_BOOTSTRAP_SERVERS=[confluent-bootstrap-server]
KAFKA_SASL_JAAS_CONFIG=org.apache.kafka.common.security.plain.PlainLoginModule required username="[API_KEY]" password="[API_SECRET]";
KAFKA_SECURITY_PROTOCOL=SASL_SSL
KAFKA_SASL_MECHANISM=PLAIN
SPRING_PROFILES_ACTIVE=prod
```

### Service 4: User Service
- Root Directory: `eds-lite/user-service`
- Environment variables:
```
PORT=8083
MONGODB_URI=[your-mongodb-connection-string]
JWT_SECRET=[generate-random-string-here]
SPRING_PROFILES_ACTIVE=prod
```

**Copy all 4 Railway service URLs after deployment!**

## 🌐 Deploy Frontend to Vercel (5 minutes)

1. Sign up: https://vercel.com/ (use GitHub)
2. Import your repository
3. Build settings:
   - Root Directory: `marketplace-ui`
   - Build Command: `npm run build`
   - Output Directory: `build`
4. Environment variables:
```
REACT_APP_API_GATEWAY_URL=[railway-api-gateway-url]
REACT_APP_CATALOG_SERVICE_URL=[railway-catalog-service-url]
REACT_APP_USER_SERVICE_URL=[railway-user-service-url]
REACT_APP_ORDER_SERVICE_URL=[railway-order-service-url]
```

## ✅ Final Steps (5 minutes)

### 1. Update CORS
In Railway, add to each service:
```
CORS_ALLOWED_ORIGINS=https://[your-vercel-app].vercel.app,http://localhost:3000
```

### 2. Create Admin User
```bash
curl -X POST [your-user-service-url]/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@marketplace.com","password":"admin123","firstName":"Admin","lastName":"User"}'
```

Then update role to "ADMIN" in MongoDB Atlas.

### 3. Test Your App
Visit your Vercel URL and verify:
- [ ] Can view products
- [ ] Can register/login
- [ ] Can add to cart
- [ ] Can place order

## 🎉 Done!

Your app is live at: `https://[your-app].vercel.app`

**Total Cost**: ~$5/month (Railway only, after free trial)

## 🆘 Troubleshooting

**Services won't start?**
- Check Railway logs for each service
- Verify all environment variables are set correctly
- Ensure MongoDB connection string has correct password

**Frontend can't connect to backend?**
- Check CORS settings
- Verify all service URLs in Vercel env vars
- Check Railway service URLs are correct

**Kafka errors?**
- Verify Confluent Cloud API Key and Secret
- Ensure topics exist: cache-invalidation, order-events
- Check SASL mechanism is PLAIN
- Verify bootstrap server URL is correct
