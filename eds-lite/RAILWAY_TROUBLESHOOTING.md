# 🔧 Railway Deployment Troubleshooting

## Error: "failed to read dockerfile: open eds-lite/api-gateway/Dockerfile: no such file or directory"

This error means Railway is looking for the Dockerfile at the wrong path.

---

## ✅ Solution: Correct Root Directory Configuration

Your repository structure is:
```
your-repo/              ← Git repository root
└── eds-lite/           ← Application directory
    ├── api-gateway/
    │   └── Dockerfile
    ├── catalog-service/
    │   └── Dockerfile
    ├── order-service/
    │   └── Dockerfile
    └── user-service/
        └── Dockerfile
```

### Step-by-Step Fix

#### 1. For Each Service in Railway:

**Go to Service Settings:**
1. Click on your service (e.g., "api-gateway")
2. Click **Settings** tab
3. Scroll to **Root Directory**

**Set the CORRECT path:**
```
Root Directory: eds-lite/api-gateway
```

**Important:** The path should be relative to your Git repository root, NOT from inside eds-lite.

#### 2. Verify Builder Settings:

In the same Settings page:
1. Scroll to **Builder**
2. Ensure it's set to **Dockerfile** (not Nixpacks or Buildpacks)
3. If not, change it to **Dockerfile**

#### 3. Commit and Push railway.json Files:

I've created `railway.json` files in each service directory. Commit them:

```bash
git add eds-lite/*/railway.json
git commit -m "Add Railway configuration files"
git push
```

#### 4. Trigger Redeploy:

In Railway:
1. Go to your service
2. Click **Deployments** tab
3. Click **Redeploy** on the latest deployment

---

## 🎯 Correct Configuration for Each Service

### API Gateway
- **Root Directory**: `eds-lite/api-gateway`
- **Builder**: Dockerfile
- **Dockerfile Path**: `Dockerfile` (relative to root directory)

### Catalog Service
- **Root Directory**: `eds-lite/catalog-service`
- **Builder**: Dockerfile
- **Dockerfile Path**: `Dockerfile`

### Order Service
- **Root Directory**: `eds-lite/order-service`
- **Builder**: Dockerfile
- **Dockerfile Path**: `Dockerfile`

### User Service
- **Root Directory**: `eds-lite/user-service`
- **Builder**: Dockerfile
- **Dockerfile Path**: `Dockerfile`

---

## 🔍 How to Verify It's Working

After setting the root directory correctly, check the build logs:

**✅ Good (should see):**
```
Building Dockerfile
Step 1/8 : FROM openjdk:21-jdk-slim
 ---> Pulling from library/openjdk
...
Successfully built
```

**❌ Bad (error):**
```
failed to read dockerfile: open eds-lite/api-gateway/Dockerfile: no such file or directory
```

---

## 🚨 Common Mistakes

### Mistake 1: Wrong Root Directory
❌ **Wrong:** `api-gateway` (missing eds-lite prefix)
❌ **Wrong:** `/eds-lite/api-gateway` (absolute path)
❌ **Wrong:** `eds-lite/api-gateway/` (trailing slash)
✅ **Correct:** `eds-lite/api-gateway`

### Mistake 2: Wrong Builder
❌ **Wrong:** Nixpacks (tries to auto-detect)
❌ **Wrong:** Buildpacks (for Heroku-style builds)
✅ **Correct:** Dockerfile

### Mistake 3: Not Committing Changes
If you added railway.json files, you MUST commit and push them:
```bash
git add .
git commit -m "Add Railway configs"
git push
```

---

## 🔄 Alternative Solution: Restructure Repository

If you keep having issues, you can move everything up one level:

```bash
# Move contents of eds-lite to repository root
cd your-repo
mv eds-lite/* .
mv eds-lite/.* . 2>/dev/null || true
rm -rf eds-lite

# Commit changes
git add .
git commit -m "Restructure for Railway deployment"
git push
```

Then in Railway, set:
- **Root Directory**: `api-gateway` (no eds-lite prefix)

**⚠️ Warning:** This changes your repository structure. Only do this if you're comfortable with it.

---

## 📋 Deployment Checklist

For each service, verify:

- [ ] Root Directory is set to `eds-lite/[service-name]`
- [ ] Builder is set to "Dockerfile"
- [ ] railway.json exists in service directory
- [ ] Changes are committed and pushed to GitHub
- [ ] Service is redeployed after changes
- [ ] Build logs show "Building Dockerfile"
- [ ] No "file not found" errors

---

## 🆘 Still Not Working?

### Check 1: Verify Dockerfile Exists
```bash
ls -la eds-lite/api-gateway/Dockerfile
```
Should show the file exists.

### Check 2: Verify Git Push
```bash
git log --oneline -1
```
Should show your latest commit.

### Check 3: Railway Service Settings
1. Go to Railway service
2. Settings → Root Directory
3. Should show: `eds-lite/api-gateway`
4. Settings → Builder
5. Should show: `Dockerfile`

### Check 4: Try Manual Trigger
1. Go to service
2. Click **Deployments**
3. Click **⋮** (three dots) on latest deployment
4. Click **Redeploy**

---

## 💡 Pro Tips

### Tip 1: Name Your Services
After deployment works, rename services for clarity:
1. Service Settings → General
2. Change name to "API Gateway", "Catalog Service", etc.

### Tip 2: Use Service Variables
Railway provides internal URLs for service-to-service communication:
- Use `${{API_GATEWAY.RAILWAY_PRIVATE_DOMAIN}}` in other services

### Tip 3: Check Build Logs First
Always check build logs before deploy logs:
1. Deployments tab
2. Click on deployment
3. View "Build Logs" tab first

---

## 📞 Quick Reference

| Setting | Value |
|---------|-------|
| Root Directory | `eds-lite/api-gateway` |
| Builder | Dockerfile |
| Dockerfile Path | `Dockerfile` |
| Watch Paths | (leave empty) |

---

## ✅ Success Indicators

You'll know it's working when:
1. ✅ Build logs show "Building Dockerfile"
2. ✅ Build completes successfully
3. ✅ Deploy logs show "Starting application"
4. ✅ Service status shows "Active"
5. ✅ Service URL is accessible

---

## 🎉 Next Steps After Fix

Once all services are deployed:
1. Copy all service URLs
2. Update frontend environment variables
3. Deploy frontend to Vercel
4. Test the complete application

See QUICK_DEPLOY.md for complete deployment steps.
