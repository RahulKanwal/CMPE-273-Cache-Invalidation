# 🌱 Seed Your Cloud Database

## ⚠️ Important: The Old Script is for LOCAL Only!

The `seed-marketplace.js` script connects to `localhost` by default, which is your LOCAL database, NOT your cloud database.

To seed your **DEPLOYED/CLOUD** database, you have two options:

---

## ✅ Option 1: Use the New Cloud Seeding Script (Recommended)

I've created a script that seeds your cloud database:

```bash
./eds-lite/scripts/seed-cloud-database.sh
```

**What it does:**
1. Asks for your MongoDB Atlas URI
2. Asks for your deployed user service URL
3. Seeds products to MongoDB Atlas
4. Creates admin user via your deployed service
5. Updates admin role in MongoDB Atlas

**You'll need:**
- MongoDB Atlas URI: `mongodb+srv://eds-user:PASSWORD@cluster0.s9s86pn.mongodb.net/eds`
- User Service URL: `https://user-service-xxxx.onrender.com`

---

## ✅ Option 2: Manual Steps (If Script Doesn't Work)

### Step 1: Seed Products to Cloud

```bash
mongosh "mongodb+srv://eds-user:YOUR_PASSWORD@cluster0.s9s86pn.mongodb.net/eds"
```

Then paste this:
```javascript
use('eds');

// Clear existing
db.products.deleteMany({});

// Add sample products
db.products.insertMany([
  {
    _id: "1",
    name: "MacBook Pro 16-inch",
    description: "Apple MacBook Pro with M3 Pro chip",
    price: NumberDecimal("2499.00"),
    stock: 15,
    category: "Electronics",
    tags: ["laptop", "apple"],
    images: ["https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=500"],
    featured: true,
    rating: 4.8,
    reviewCount: 127,
    version: 1,
    updatedAt: new Date()
  },
  {
    _id: "2",
    name: "iPhone 15 Pro",
    description: "iPhone 15 Pro with titanium design",
    price: NumberDecimal("999.00"),
    stock: 32,
    category: "Electronics",
    tags: ["smartphone", "apple"],
    images: ["https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=500"],
    featured: true,
    rating: 4.7,
    reviewCount: 89,
    version: 1,
    updatedAt: new Date()
  },
  {
    _id: "3",
    name: "Sony WH-1000XM5 Headphones",
    description: "Industry-leading noise canceling wireless headphones",
    price: NumberDecimal("399.99"),
    stock: 45,
    category: "Electronics",
    tags: ["headphones", "sony"],
    images: ["https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500"],
    featured: false,
    rating: 4.6,
    reviewCount: 203,
    version: 1,
    updatedAt: new Date()
  }
]);

print("✅ Products added!");
exit
```

### Step 2: Create Admin User

**Method A: Via API (Recommended)**

```bash
# Register admin user
curl -X POST https://user-service-xxxx.onrender.com/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@marketplace.com", "password": "admin123", "firstName": "Admin", "lastName": "User"}'
```

Then update role in MongoDB:
```bash
mongosh "mongodb+srv://eds-user:PASSWORD@cluster0.s9s86pn.mongodb.net/eds"
```

```javascript
use('eds');
db.users.updateOne(
  {email: 'admin@marketplace.com'}, 
  {$set: {role: 'ADMIN'}}
);
exit
```

**Method B: Via Frontend**

1. Go to your deployed frontend: `https://marketplace-ui-tau.vercel.app/register`
2. Register with email: `admin@marketplace.com`, password: `admin123`
3. Then update role in MongoDB Atlas:
   - Go to MongoDB Atlas → Browse Collections
   - Find `users` collection
   - Find your user
   - Edit and change `role` from `CUSTOMER` to `ADMIN`

---

## 🎯 Quick Summary

**To seed your CLOUD database (not local):**

1. **Products:** Use mongosh with your Atlas URI
2. **Admin User:** Register via deployed service, then update role

**The key is:** Always use your MongoDB Atlas connection string (`mongodb+srv://...`), NOT `localhost`!

---

## ✅ Verify It Worked

### Check Products:
1. Go to your deployed frontend: `https://marketplace-ui-tau.vercel.app`
2. You should see products on the home page

### Check Admin User:
1. Go to login page
2. Login with: `admin@marketplace.com` / `admin123`
3. You should see admin features

### Check in MongoDB Atlas:
1. Go to MongoDB Atlas → Browse Collections
2. `products` collection should have documents
3. `users` collection should have admin user with `role: "ADMIN"`

---

## 🆘 Troubleshooting

### "Connection failed"
- Check your MongoDB Atlas URI is correct
- Make sure it ends with `/eds`
- Verify IP whitelist includes `0.0.0.0/0`

### "Admin user can't login"
- Make sure role is set to `ADMIN` (not `CUSTOMER`)
- Check in MongoDB Atlas → users collection
- Password should be hashed (starts with `$2a$`)

### "No products showing"
- Check MongoDB Atlas → products collection
- Should have at least 3-5 products
- Verify your deployed services are running

---

## 💡 Recommendation

**Use Option 2 (Manual Steps)** - it's more reliable and you can see exactly what's happening at each step.

The automated script is convenient but can fail if services are sleeping or URLs are wrong.
