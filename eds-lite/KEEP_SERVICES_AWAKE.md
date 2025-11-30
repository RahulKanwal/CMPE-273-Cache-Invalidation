# Keep Render Services Awake

Render free tier services sleep after 15 minutes of inactivity. This guide shows you how to keep them awake using free monitoring services.

## Option 1: UptimeRobot (Recommended - Free & Easy)

UptimeRobot is a free service that can ping your services every 5 minutes.

### Setup Steps:

1. **Sign up for UptimeRobot**
   - Go to https://uptimerobot.com/
   - Create a free account (no credit card required)
   - Free plan allows 50 monitors with 5-minute intervals

2. **Add Monitors for Each Service**
   
   Click "Add New Monitor" and create monitors for each service:

   **Monitor 1: API Gateway**
   - Monitor Type: HTTP(s)
   - Friendly Name: `EDS API Gateway`
   - URL: `https://api-gateway-lpnh.onrender.com/actuator/health`
   - Monitoring Interval: 5 minutes
   - Monitor Timeout: 30 seconds

   **Monitor 2: Catalog Service**
   - Monitor Type: HTTP(s)
   - Friendly Name: `EDS Catalog Service`
   - URL: `https://catalog-service-[YOUR-ID].onrender.com/actuator/health`
   - Monitoring Interval: 5 minutes
   - Monitor Timeout: 30 seconds

   **Monitor 3: Order Service**
   - Monitor Type: HTTP(s)
   - Friendly Name: `EDS Order Service`
   - URL: `https://order-service-[YOUR-ID].onrender.com/actuator/health`
   - Monitoring Interval: 5 minutes
   - Monitor Timeout: 30 seconds

   **Monitor 4: User Service**
   - Monitor Type: HTTP(s)
   - Friendly Name: `EDS User Service`
   - URL: `https://user-service-[YOUR-ID].onrender.com/actuator/health`
   - Monitoring Interval: 5 minutes
   - Monitor Timeout: 30 seconds

3. **Get Your Service URLs from Render**
   - Go to your Render dashboard
   - Click on each service
   - Copy the service URL (e.g., `https://catalog-service-abc123.onrender.com`)
   - Replace `[YOUR-ID]` in the URLs above

4. **Verify Setup**
   - UptimeRobot will start pinging every 5 minutes
   - Your services will stay awake 24/7
   - You'll get email alerts if any service goes down

---

## Option 2: Cron-job.org (Alternative)

Another free option with similar functionality.

### Setup Steps:

1. **Sign up**
   - Go to https://cron-job.org/
   - Create a free account
   - Free plan allows unlimited cron jobs

2. **Create Cron Jobs**
   
   For each service, create a cron job:
   - Execution Schedule: `*/10 * * * *` (every 10 minutes)
   - URL: Your service health endpoint
   - Request Method: GET
   - Timeout: 30 seconds

---

## Option 3: GitHub Actions (For Developers)

Use GitHub Actions to ping your services automatically.

### Setup:

1. Create `.github/workflows/keep-alive.yml` in your repository:

```yaml
name: Keep Services Awake

on:
  schedule:
    # Run every 10 minutes
    - cron: '*/10 * * * *'
  workflow_dispatch: # Allow manual trigger

jobs:
  ping-services:
    runs-on: ubuntu-latest
    steps:
      - name: Ping API Gateway
        run: curl -f https://api-gateway-lpnh.onrender.com/actuator/health || true
      
      - name: Ping Catalog Service
        run: curl -f https://catalog-service-[YOUR-ID].onrender.com/actuator/health || true
      
      - name: Ping Order Service
        run: curl -f https://order-service-[YOUR-ID].onrender.com/actuator/health || true
      
      - name: Ping User Service
        run: curl -f https://user-service-[YOUR-ID].onrender.com/actuator/health || true
```

2. Replace `[YOUR-ID]` with your actual Render service IDs

3. Commit and push to GitHub

4. GitHub Actions will automatically run every 10 minutes

**Note:** GitHub Actions has usage limits on free accounts (2,000 minutes/month), but this workflow uses minimal minutes.

---

## Option 4: Simple Bash Script (Manual)

If you want to run it manually or set up your own cron job:

```bash
#!/bin/bash

# Keep Render services awake
echo "Pinging services..."

curl -s https://api-gateway-lpnh.onrender.com/actuator/health > /dev/null
echo "✓ API Gateway pinged"

curl -s https://catalog-service-[YOUR-ID].onrender.com/actuator/health > /dev/null
echo "✓ Catalog Service pinged"

curl -s https://order-service-[YOUR-ID].onrender.com/actuator/health > /dev/null
echo "✓ Order Service pinged"

curl -s https://user-service-[YOUR-ID].onrender.com/actuator/health > /dev/null
echo "✓ User Service pinged"

echo "All services pinged successfully!"
```

Save as `keep-alive.sh`, make executable with `chmod +x keep-alive.sh`, and run with `./keep-alive.sh`

---

## Comparison

| Service | Free Tier | Interval | Setup Difficulty | Reliability |
|---------|-----------|----------|------------------|-------------|
| UptimeRobot | 50 monitors | 5 min | Easy | High |
| Cron-job.org | Unlimited | Custom | Easy | High |
| GitHub Actions | 2000 min/month | Custom | Medium | High |
| Manual Script | N/A | Manual | Easy | Low |

---

## Recommended Approach

**For Production:** Use **UptimeRobot** - it's the easiest and most reliable option with bonus uptime monitoring and alerts.

**For Development:** The retry logic in the API Gateway should be sufficient. Services will wake up on first request (takes 30-60 seconds).

---

## Important Notes

1. **Health Endpoints:** All services expose `/actuator/health` which is perfect for keep-alive pings
2. **Render Limits:** Even with keep-alive, Render free tier has bandwidth limits (100GB/month)
3. **Cost:** All options above are completely free
4. **Privacy:** These services only ping public health endpoints, no sensitive data is exposed

---

## Troubleshooting

**Services still sleeping?**
- Check that the URLs are correct
- Verify the monitoring service is actually running
- Check Render dashboard to see service status

**Getting timeout errors?**
- Increase timeout to 60 seconds
- Services might be under heavy load

**Want to verify it's working?**
- Check UptimeRobot dashboard for uptime percentage
- Should show 99%+ uptime after setup
