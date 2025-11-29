# 🚀 Vercel Frontend Deployment Guide

## ✅ Environment Variables You Need

In Vercel, go to your project → Settings → Environment Variables and add:

### Required Variables:

```
REACT_APP_API_GATEWAY_URL=https://your-api-gateway.railway.app
REACT_APP_CATALOG_SERVICE_URL=https://your-catalog-service.railway.app
REACT_APP_ORDER_SERVICE_URL=https://your-order-service.railway.app
REACT_APP_USER_SERVICE_URL=https://your-user-service.onrender.com
```

### Your Actual URLs:

Based on your deployment:

**Railway Services:**
- API Gateway: `https://[your-api-gateway-url].up.railway.app`
- Catalog Service: `https://[your-catalog-service-url].up.railway.app`
- Order Service: `https://[your-order-service-url].up.railway.app`

**Render Service:**
- User Service: `https://[your-user-service-url].onrender.com`

## 🔧 How to Get Your Service URLs

### From Railway:
1. Go to Railway dashboard
2. Click on each service
3. Look for the public URL (e.g., `https://api-gateway-production-xxxx.up.railway.app`)
4. Copy each URL

### From Render:
1. Go to Render dashboard
2. Click on user-service
3. Copy the URL at the top (e.g., `https://user-service-xxxx.onrender.com`)

## 📋 Step-by-Step Vercel Setup

### Step 1: Add Environment Variables

1. Go to https://vercel.com/dashboard
2. Click on your `marketplace-ui` project
3. Go to **Settings** → **Environment Variables**
4. Add each variable:
   - Click **Add New**
   - Name: `REACT_APP_API_GATEWAY_URL`
   - Value: Your Railway API Gateway URL
   - Environment: Production (check the box)
   - Click **Save**
5. Repeat for all 4 variables

### Step 2: Redeploy

After adding environment variables:
1. Go to **Deployments** tab
2. Click **⋮** (three dots) on the latest deployment
3. Click **Redeploy**
4. Wait for deployment to complete

## 🆘 Troubleshooting

### Error: "n.map is not a function"

This means the frontend can't reach the backend. Check:

1. **Environment variables are set correctly**
   - Go to Vercel Settings → Environment Variables
   - Verify all 4 URLs are correct
   - Make sure they start with `https://`
   - No trailing slashes

2. **Backend services are running**
   - Check Railway dashboard - all services should be "Active"
   - Check Render dashboard - user-service should be "Live"
   - Try accessing each URL in your browser

3. **CORS is configured**
   - Your backend services need to allow requests from Vercel
   - Add this environment variable to each Railway service:
     ```
     CORS_ALLOWED_ORIGINS=https://marketplace-ui-tau.vercel.app,http://localhost:3000
     ```

### Error: "Failed to fetch" or "Network Error"

**Check 1: Backend URLs are accessible**
```bash
curl https://your-catalog-service.railway.app/products/featured
```
Should return JSON data, not an error.

**Check 2: HTTPS is used**
All URLs must use `https://`, not `http://`

**Check 3: Services are not sleeping**
- Railway services should always be active
- Render free tier services sleep after 15 min
- First request to Render will take 30-60 seconds to wake up

### Error: "CORS policy" in browser console

Add CORS configuration to your backend services:

**In Railway (for each service):**
1. Go to service → Variables
2. Add:
   ```
   CORS_ALLOWED_ORIGINS=https://marketplace-ui-tau.vercel.app,http://localhost:3000
   ```

**In Render (user-service):**
1. Go to user-service → Environment
2. Add same variable

## ✅ Verification Checklist

- [ ] All 4 environment variables added in Vercel
- [ ] Environment variables use correct URLs (https://)
- [ ] No trailing slashes in URLs
- [ ] Vercel redeployed after adding variables
- [ ] All Railway services showing "Active"
- [ ] Render user-service showing "Live"
- [ ] CORS configured on all backend services
- [ ] Frontend loads without errors
- [ ] Can see products on home page

## 🎯 Quick Test

After deployment, open browser console on your Vercel site:

```javascript
// Test API connection
fetch('https://your-catalog-service.railway.app/products/featured')
  .then(r => r.json())
  .then(console.log)
```

Should return an array of products.

## 📞 Example Configuration

Here's what your Vercel environment variables should look like:

```
REACT_APP_API_GATEWAY_URL=https://api-gateway-production-abc123.up.railway.app
REACT_APP_CATALOG_SERVICE_URL=https://catalog-service-production-def456.up.railway.app
REACT_APP_ORDER_SERVICE_URL=https://order-service-production-ghi789.up.railway.app
REACT_APP_USER_SERVICE_URL=https://user-service-jkl012.onrender.com
```

**Important:** Replace with YOUR actual URLs!

## 🔄 After Fixing

1. Commit the code changes (axios configuration)
2. Push to GitHub
3. Vercel will auto-deploy
4. Or manually redeploy in Vercel dashboard

Your frontend should now work correctly!
