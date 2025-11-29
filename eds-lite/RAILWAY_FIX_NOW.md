# 🚨 Railway Deployment Fix - EXACT Steps

## The Problem

Railway error: `failed to read dockerfile: open /eds-lite/api-gateway/Dockerfile: no such file or directory`

This happens because Railway is looking for the Dockerfile at the wrong path.

---

## ✅ EXACT Solution (Follow These Steps)

### Step 1: Delete the Failing Service

1. Go to Railway dashboard
2. Click on your API Gateway service
3. Click **Settings** tab (gear icon)
4. Scroll to bottom
5. Click **Delete Service**
6. Confirm deletion

### Step 2: Create Service Correctly

1. In your Railway project, click **+ New**
2. Select **GitHub Repo**
3. Choose your repository: `CMPE-273-Cache-Invalidation`
4. Railway will create a new service

### Step 3: Configure IMMEDIATELY (Before It Builds)

**IMPORTANT: Do this BEFORE the first build completes!**

1. Click on the newly created service
2. Click **Settings** tab
3. Find **Service Name** - rename to "api-gateway" (optional but helpful)
4. Find **Root Directory** section
5. Click **Configure**
6. Enter EXACTLY: `eds-lite/api-gateway`
7. Click **Save** or press Enter

### Step 4: Set Environment Variables

Still in Settings:

1. Click **Variables** tab
2. Click **+ New Variable**
3. Add these:
   ```
   PORT=8080
   SPRING_PROFILES_ACTIVE=prod
   ```

### Step 5: Trigger Build

1. Go to **Deployments** tab
2. If a build is already running, let it finish (it should work now)
3. If not, click **Deploy** button

### Step 6: Verify Build Logs

1. Click on the latest deployment
2. Check **Build Logs**
3. You should see:
   ```
   Building Dockerfile
   Step 1/8 : FROM openjdk:21-jdk-slim
   ...
   Successfully built
   ```

---

## 🎯 Key Points

**Root Directory Value:**
```
eds-lite/api-gateway
```

**NOT:**
- ❌ `api-gateway` (missing eds-lite)
- ❌ `/eds-lite/api-gateway` (no leading slash)
- ❌ `eds-lite/api-gateway/` (no trailing slash)
- ❌ `./eds-lite/api-gateway` (no ./)

**The root directory must be set RELATIVE to your Git repository root.**

---

## 🔍 Why This Happens

Your repository structure:
```
CMPE-273-Cache-Invalidation/    ← Git repo root (Railway starts here)
├── eds-lite/                    ← Your app directory
│   ├── api-gateway/             ← Service directory
│   │   ├── Dockerfile           ← Railway needs to find this
│   │   ├── pom.xml
│   │   └── src/
│   ├── catalog-service/
│   ├── order-service/
│   └── user-service/
├── kafka/
└── mongodb/
```

When you set Root Directory to `eds-lite/api-gateway`:
- Railway changes its working directory to that path
- Then looks for `Dockerfile` (finds it at `eds-lite/api-gateway/Dockerfile`)
- Uses that directory as build context
- Dockerfile can find `pom.xml` and `src` because they're in the same directory

---

## 📋 Repeat for Other Services

### Catalog Service
1. Click **+ New** → **GitHub Repo**
2. Select same repository
3. **Settings** → **Root Directory**: `eds-lite/catalog-service`
4. Add environment variables (see QUICK_DEPLOY.md)

### Order Service
1. Click **+ New** → **GitHub Repo**
2. Select same repository
3. **Settings** → **Root Directory**: `eds-lite/order-service`
4. Add environment variables

### User Service
1. Click **+ New** → **GitHub Repo**
2. Select same repository
3. **Settings** → **Root Directory**: `eds-lite/user-service`
4. Add environment variables

---

## 🆘 If It Still Doesn't Work

### Check 1: Verify Root Directory is Saved

1. Go to service **Settings**
2. Look at **Root Directory** section
3. It should show: `eds-lite/api-gateway`
4. If it's empty or different, set it again and save

### Check 2: Check Railway's Detection

Railway might be auto-detecting the wrong builder. Force it to use Dockerfile:

1. **Settings** → Find **Builder** section
2. If it says "Nixpacks" or "Buildpacks", change to **Dockerfile**
3. Save and redeploy

### Check 3: Verify GitHub Connection

1. **Settings** → **Source**
2. Should show: `RahulKanwal/CMPE-273-Cache-Invalidation`
3. Branch: `main`
4. If wrong, reconnect to GitHub

### Check 4: Manual Dockerfile Path (Last Resort)

If Railway still can't find it:

1. **Settings** → **Build** section
2. Find **Dockerfile Path** (if available)
3. Set to: `Dockerfile` (relative to root directory)
4. Save and redeploy

---

## 💡 Alternative: Use Railway CLI

If the UI isn't working, try the CLI:

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Link to your project
railway link

# Set root directory
railway service api-gateway
railway up --service api-gateway --root eds-lite/api-gateway
```

---

## ✅ Success Checklist

- [ ] Service deleted and recreated
- [ ] Root Directory set to `eds-lite/api-gateway`
- [ ] Environment variables added
- [ ] Build logs show "Building Dockerfile"
- [ ] Build completes successfully
- [ ] Service shows "Active" status
- [ ] Service URL is accessible

---

## 🎉 Once It Works

After API Gateway deploys successfully:

1. Copy the service URL
2. Repeat the process for the other 3 services
3. Deploy frontend to Vercel with all backend URLs
4. Test your application

See QUICK_DEPLOY.md for complete deployment checklist.

---

## 📞 Quick Reference

| Setting | Value |
|---------|-------|
| Root Directory | `eds-lite/api-gateway` |
| Builder | Dockerfile (auto-detected) |
| Dockerfile Path | `Dockerfile` (relative) |
| PORT | 8080 |
| SPRING_PROFILES_ACTIVE | prod |

---

## 🔄 If You Need to Start Over

Delete all services and follow this guide from Step 1. Sometimes Railway caches incorrect settings, and starting fresh helps.
