# 🧪 Test Your Cloud Services

Quick guide to verify MongoDB Atlas, Upstash Redis, and Confluent Cloud Kafka are working.

---

## 🎯 Quick Test (No Tools Required)

### 1. Test MongoDB Atlas

**Via MongoDB Atlas Dashboard:**
1. Go to https://cloud.mongodb.com/
2. Login to your account
3. Click on your cluster
4. Click **Connect** button
5. If you see connection options → ✅ **Working**
6. If you see errors → ❌ **Not working**

**Via Browser (Simple Test):**
1. Go to your cluster in MongoDB Atlas
2. Click **Browse Collections**
3. If you can see your `eds` database → ✅ **Working**
4. If you get errors → ❌ **Check IP whitelist**

**Common Issues:**
- ❌ IP not whitelisted → Add `0.0.0.0/0` in Network Access
- ❌ Wrong password → Reset password in Database Access
- ❌ Cluster paused → Resume cluster

---

### 2. Test Upstash Redis

**Via Upstash Dashboard:**
1. Go to https://console.upstash.com/
2. Login to your account
3. Click on your Redis database
4. Click **CLI** tab
5. Type: `PING`
6. If you see `PONG` → ✅ **Working**
7. If you see errors → ❌ **Not working**

**Via REST API (Browser):**
1. Go to your Redis database in Upstash
2. Copy the **REST URL** (looks like `https://xxxxx.upstash.io`)
3. Copy the **REST Token**
4. Open terminal and run:
   ```bash
   curl -H "Authorization: Bearer YOUR_REST_TOKEN" \
        https://xxxxx.upstash.io/ping
   ```
5. If you see `{"result":"PONG"}` → ✅ **Working**

**Common Issues:**
- ❌ Wrong password → Check password in Upstash dashboard
- ❌ Wrong host → Verify endpoint URL

---

### 3. Test Confluent Cloud Kafka

**Via Confluent Cloud Dashboard:**
1. Go to https://confluent.cloud/
2. Login to your account
3. Click on your cluster
4. Go to **Topics** tab
5. If you see your topics (`cache-invalidation`, `order-events`) → ✅ **Working**
6. Click on a topic → **Messages** tab
7. If you can see the interface → ✅ **Working**

**Check Cluster Status:**
1. In Confluent Cloud, go to your cluster
2. Look at the status indicator
3. Green/Active → ✅ **Working**
4. Red/Error → ❌ **Not working**

**Verify API Keys:**
1. Go to **Data integration** → **API keys**
2. Check your API key exists
3. If you see it → ✅ **Key is valid**
4. If deleted → ❌ **Create new key**

**Common Issues:**
- ❌ API key deleted → Create new API key
- ❌ Topics don't exist → Create topics manually
- ❌ Cluster deleted → Create new cluster

---

## 🔧 Advanced Testing (With Tools)

### Test MongoDB with mongosh

```bash
# Install mongosh first (if not installed)
brew install mongosh  # macOS
# or download from https://www.mongodb.com/try/download/shell

# Test connection
mongosh "mongodb+srv://user:password@cluster.mongodb.net/eds"

# If connected, you'll see:
# Current Mongosh Log ID: ...
# Connecting to: mongodb+srv://...
# Using MongoDB: 7.0.x
# test>

# Test a command
test> db.products.countDocuments()
# Should return a number (0 if empty, >0 if seeded)

# Exit
test> exit
```

**✅ Success:** You see the `test>` prompt  
**❌ Failed:** Connection timeout or authentication error

---

### Test Redis with redis-cli

```bash
# Install redis-cli first (if not installed)
brew install redis  # macOS

# Test connection (Upstash uses TLS)
redis-cli -h your-redis.upstash.io -p 6379 -a YOUR_PASSWORD --tls

# If connected, you'll see:
# your-redis.upstash.io:6379>

# Test a command
your-redis.upstash.io:6379> PING
# Should return: PONG

# Exit
your-redis.upstash.io:6379> exit
```

**✅ Success:** You see `PONG`  
**❌ Failed:** Connection refused or authentication error

---

### Test Kafka (Advanced)

Kafka testing requires kafka-console tools, which are complex to install. **Use the dashboard method instead.**

If you really want to test with CLI:
```bash
# This requires Confluent CLI installation
# Not recommended for quick testing
```

---

## 📋 Quick Checklist

Before deploying to Railway, verify:

- [ ] **MongoDB Atlas**
  - [ ] Cluster is active (not paused)
  - [ ] IP whitelist includes `0.0.0.0/0`
  - [ ] Database user exists with correct password
  - [ ] Can connect via mongosh or dashboard
  - [ ] Connection string is correct

- [ ] **Upstash Redis**
  - [ ] Database is active
  - [ ] Can PING via dashboard CLI
  - [ ] Have correct: host, port (6379), password
  - [ ] REST API works (optional)

- [ ] **Confluent Cloud Kafka**
  - [ ] Cluster is active (green status)
  - [ ] Topics exist: `cache-invalidation`, `order-events`
  - [ ] API key exists and not deleted
  - [ ] Have correct: bootstrap server, API key, API secret

---

## 🎯 What to Copy for Railway

Once verified, copy these values:

### MongoDB
```
mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/eds
```

### Redis
```
Host: your-redis-xxxxx.upstash.io
Port: 6379
Password: your-password-here
```

### Kafka
```
Bootstrap: pkc-xxxxx.region.aws.confluent.cloud:9092
API Key: your-api-key
API Secret: your-api-secret
```

---

## 🆘 Troubleshooting

### MongoDB: "Authentication failed"
- Check username and password in Database Access
- Make sure password doesn't have special characters (or URL encode them)
- Try resetting the password

### MongoDB: "Connection timeout"
- Add `0.0.0.0/0` to IP whitelist in Network Access
- Check if cluster is paused (resume it)
- Verify connection string format

### Redis: "Connection refused"
- Check host and port are correct
- Verify password (copy from Upstash dashboard)
- Make sure you're using `--tls` flag with redis-cli

### Kafka: "Authentication failed"
- Verify API key hasn't been deleted
- Check API key and secret are correct
- Make sure bootstrap server URL is correct

---

## ✅ All Working?

If all three services are working, you're ready to deploy to Railway!

**Next steps:**
1. Go to Railway dashboard
2. Check deployment logs for each service
3. Add the correct environment variables
4. Redeploy

See [SIMPLE_DEPLOYMENT_GUIDE.md](SIMPLE_DEPLOYMENT_GUIDE.md) for deployment instructions.
