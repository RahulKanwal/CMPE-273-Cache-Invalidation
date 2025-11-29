# Railway Setup Guide - Step by Step

## The Problem You're Facing

Railway is looking for the Dockerfile at the wrong path because your repository structure has `eds-lite` as a subdirectory.

```
your-repo/
├── eds-lite/           ← Your app is here
│   ├── api-gateway/
│   │   └── Dockerfile
│   ├── catalog-service/
│   └── ...
└── (Railway is looking here by default)
```

## The Solution: Set Root Directory

For **each service** you deploy to Railway, you need to tell it where to find the code.

---

## Step-by-Step: Deploy API Gateway

### 1. Create New Service
- In Railway dashboard, click **New**
- Select **GitHub Repo**
- Choose your repository

### 2. Configure Root Directory
- After the service is created, click on it
- Go to **Settings** tab (gear icon)
- Scroll down to **Root Directory**
- Enter: `eds-lite/api-gateway`
- Railway will auto-detect the Dockerfile

### 3. Set Environment Variables
- Go to **Variables** tab
- Add:
  ```
  PORT=8080
  SPRING_PROFILES_ACTIVE=prod
  ```

### 4. Deploy
- Railway will automatically start building
- Check **Deployments** tab for build logs
- Wait for "Build successful" message

---

## Repeat for Other Services

### Catalog Service
- **Root Directory**: `eds-lite/catalog-service`
- **Environment Variables**: (see QUICK_DEPLOY.md)

### Order Service
- **Root Directory**: `eds-lite/order-service`
- **Environment Variables**: (see QUICK_DEPLOY.md)

### User Service
- **Root Directory**: `eds-lite/user-service`
- **Environment Variables**: (see QUICK_DEPLOY.md)

---

## How to Fix Existing Service

If you already created a service and it's failing:

1. Click on the failing service
2. Go to **Settings** tab
3. Find **Root Directory** section
4. Enter the correct path (e.g., `eds-lite/api-gateway`)
5. Click **Redeploy** button in the top right

---

## Verify It's Working

After setting the root directory correctly, you should see:

✅ **Build Logs** show:
```
Building Dockerfile
Step 1/8 : FROM openjdk:21-jdk-slim
...
Successfully built
```

✅ **Deploy Logs** show:
```
Starting application...
Started ApiGatewayApplication in X seconds
```

✅ **Service URL** is accessible (click the URL in Railway dashboard)

---

## Common Mistakes

❌ **Wrong:** Root Directory = `api-gateway`
✅ **Correct:** Root Directory = `eds-lite/api-gateway`

❌ **Wrong:** Leaving Root Directory empty
✅ **Correct:** Always set it for each service

❌ **Wrong:** Using absolute paths like `/eds-lite/api-gateway`
✅ **Correct:** Use relative paths from repo root

---

## Alternative: Restructure Repository (Optional)

If you want to avoid setting root directory for each service, you can move everything up one level:

```bash
# Move contents of eds-lite to root
cd your-repo
mv eds-lite/* .
rm -rf eds-lite
git add .
git commit -m "Restructure for Railway deployment"
git push
```

Then Railway will find the Dockerfiles automatically without setting root directory.

**Note:** Only do this if you're comfortable restructuring your repo!

---

## Quick Reference

| Service | Root Directory |
|---------|---------------|
| API Gateway | `eds-lite/api-gateway` |
| Catalog Service | `eds-lite/catalog-service` |
| Order Service | `eds-lite/order-service` |
| User Service | `eds-lite/user-service` |

---

## Still Having Issues?

Check the troubleshooting section in DEPLOYMENT_GUIDE.md or:

1. Verify the Dockerfile exists at the path you specified
2. Check Railway build logs for specific errors
3. Ensure all environment variables are set
4. Try redeploying after making changes
