# 🎯 Railway Deployment - FINAL SOLUTION

## The Problem

Railway's Root Directory setting is not working correctly for Dockerfile detection in your repository structure.

## ✅ The Solution

I've created Dockerfiles at the repository root that reference your service directories. This bypasses the root directory issue.

---

## 📋 Step-by-Step Deployment

### Step 1: Commit and Push the New Dockerfiles

```bash
git add Dockerfile.*
git commit -m "Add Railway-compatible Dockerfiles at repo root"
git push origin main
```

### Step 2: Deploy API Gateway

1. **In Railway, delete the failing API Gateway service**
   - Settings → Delete Service

2. **Create new service:**
   - Click **+ New** → **GitHub Repo**
   - Select your repository

3. **Configure the service:**
   - Click **Settings**
   - **Service Name**: `api-gateway`
   - **Root Directory**: Leave EMPTY (don't set it!)
   - **Dockerfile Path**: `Dockerfile.api-gateway`

4. **Add environment variables:**
   - Click **Variables** tab
   - Add:
     ```
     PORT=8080
     SPRING_PROFILES_ACTIVE=prod
     ```

5. **Deploy:**
   - Railway will automatically build using `Dockerfile.api-gateway`
   - Check build logs - should work now!

### Step 3: Deploy Catalog Service

1. **Create new service:**
   - Click **+ New** → **GitHub Repo**
   - Select same repository

2. **Configure:**
   - **Service Name**: `catalog-service`
   - **Root Directory**: Leave EMPTY
   - **Dockerfile Path**: `Dockerfile.catalog-service`

3. **Add environment variables:**
   ```
   PORT=8081
   MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/eds
   REDIS_HOST=your-upstash-host.upstash.io
   REDIS_PORT=6379
   REDIS_PASSWORD=your-redis-password
   KAFKA_BOOTSTRAP_SERVERS=pkc-xxxxx.confluent.cloud:9092
   KAFKA_SASL_JAAS_CONFIG=org.apache.kafka.common.security.plain.PlainLoginModule required username="API_KEY" password="API_SECRET";
   KAFKA_SECURITY_PROTOCOL=SASL_SSL
   KAFKA_SASL_MECHANISM=PLAIN
   CACHE_MODE=ttl_invalidate
   SPRING_PROFILES_ACTIVE=prod
   ```

### Step 4: Deploy Order Service

1. **Create new service:**
   - Click **+ New** → **GitHub Repo**

2. **Configure:**
   - **Service Name**: `order-service`
   - **Root Directory**: Leave EMPTY
   - **Dockerfile Path**: `Dockerfile.order-service`

3. **Add environment variables:**
   ```
   PORT=8082
   MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/eds
   KAFKA_BOOTSTRAP_SERVERS=pkc-xxxxx.confluent.cloud:9092
   KAFKA_SASL_JAAS_CONFIG=org.apache.kafka.common.security.plain.PlainLoginModule required username="API_KEY" password="API_SECRET";
   KAFKA_SECURITY_PROTOCOL=SASL_SSL
   KAFKA_SASL_MECHANISM=PLAIN
   SPRING_PROFILES_ACTIVE=prod
   ```

### Step 5: Deploy User Service

1. **Create new service:**
   - Click **+ New** → **GitHub Repo**

2. **Configure:**
   - **Service Name**: `user-service`
   - **Root Directory**: Leave EMPTY
   - **Dockerfile Path**: `Dockerfile.user-service`

3. **Add environment variables:**
   ```
   PORT=8083
   MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/eds
   JWT_SECRET=your-random-secret-key-here
   SPRING_PROFILES_ACTIVE=prod
   ```

---

## 🎯 Key Points

### What Changed:

**Before (didn't work):**
- Root Directory: `eds-lite/api-gateway`
- Dockerfile: `eds-lite/api-gateway/Dockerfile`
- Railway couldn't find it

**Now (works):**
- Root Directory: EMPTY (repository root)
- Dockerfile Path: `Dockerfile.api-gateway` (at repo root)
- Dockerfile copies files from `eds-lite/api-gateway/`

### Why This Works:

The Dockerfiles at the repository root can access all subdirectories. They copy files from `eds-lite/[service]/` into the build context.

---

## 🔍 How to Set Dockerfile Path in Railway

### Method 1: Railway UI (Recommended)

1. Go to service **Settings**
2. Find **Build** section
3. Look for **Dockerfile Path** field
4. Enter: `Dockerfile.api-gateway` (or appropriate service)
5. Save

### Method 2: If Dockerfile Path Field Doesn't Exist

Railway should auto-detect `Dockerfile.api-gateway` if:
- You name the service "api-gateway"
- The Dockerfile exists at repo root

If it doesn't auto-detect:
1. Settings → **Builder** → Select "Dockerfile"
2. It should then ask for Dockerfile path

### Method 3: Using railway.json (Fallback)

Create `railway.json` at repository root:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile.api-gateway"
  }
}
```

**Note:** You'll need different railway.json for each service, which is complex. Use Method 1 instead.

---

## ✅ Verification

After deployment, check:

1. **Build Logs** should show:
   ```
   Building Dockerfile.api-gateway
   Step 1/8 : FROM openjdk:21-jdk-slim
   Step 2/8 : WORKDIR /app
   Step 3/8 : COPY eds-lite/api-gateway/pom.xml .
   ...
   Successfully built
   ```

2. **Deploy Logs** should show:
   ```
   Starting application...
   Started ApiGatewayApplication
   ```

3. **Service Status**: Active (green)

4. **Service URL**: Accessible

---

## 🆘 Troubleshooting

### If Railway Still Can't Find Dockerfile:

**Check 1: Verify files are pushed to GitHub**
```bash
git log --oneline -1
# Should show your latest commit with Dockerfiles
```

**Check 2: Verify Dockerfile exists in GitHub**
- Go to your GitHub repository
- Check that `Dockerfile.api-gateway` exists at root

**Check 3: Force Railway to use Dockerfile builder**
- Settings → Builder → Select "Dockerfile"
- Settings → Dockerfile Path → Enter `Dockerfile.api-gateway`

**Check 4: Try Railway CLI**
```bash
railway login
railway link
railway up --dockerfile Dockerfile.api-gateway
```

---

## 📊 Repository Structure Now

```
CMPE-273-Cache-Invalidation/
├── Dockerfile.api-gateway       ← NEW (Railway uses this)
├── Dockerfile.catalog-service   ← NEW
├── Dockerfile.order-service     ← NEW
├── Dockerfile.user-service      ← NEW
└── eds-lite/
    ├── api-gateway/
    │   ├── Dockerfile           ← Original (for local dev)
    │   ├── pom.xml
    │   └── src/
    ├── catalog-service/
    ├── order-service/
    └── user-service/
```

---

## 💡 Why We Need Both Dockerfiles

- **Original Dockerfiles** (`eds-lite/*/Dockerfile`): For local development
- **Root Dockerfiles** (`Dockerfile.*`): For Railway deployment

This is a workaround for Railway's root directory issue with your monorepo structure.

---

## 🎉 After All Services Deploy

1. Copy all 4 service URLs from Railway
2. Deploy frontend to Vercel with these URLs
3. Update CORS settings in backend services
4. Test your application

See QUICK_DEPLOY.md for complete checklist.

---

## 📞 Quick Reference

| Service | Dockerfile Path | Port |
|---------|----------------|------|
| API Gateway | `Dockerfile.api-gateway` | 8080 |
| Catalog Service | `Dockerfile.catalog-service` | 8081 |
| Order Service | `Dockerfile.order-service` | 8082 |
| User Service | `Dockerfile.user-service` | 8083 |

**Root Directory for all services:** EMPTY (leave blank)

---

## ✅ Success Checklist

- [ ] New Dockerfiles committed and pushed
- [ ] Old failing services deleted
- [ ] New services created with correct Dockerfile paths
- [ ] Environment variables configured
- [ ] All services building successfully
- [ ] All services showing "Active" status
- [ ] Service URLs accessible

This should finally work! The issue was Railway's handling of monorepo structures with nested Dockerfiles.
