#!/bin/bash

# Seed cloud MongoDB database with products and create admin user
# This script works with your deployed services

set -e

echo "=========================================="
echo "🌱 Seeding Cloud Database"
echo "=========================================="
echo ""

# Get MongoDB connection string
read -p "MongoDB Atlas URI (mongodb+srv://...): " MONGODB_URI
echo ""

# Get deployed user service URL
read -p "Deployed User Service URL (https://user-service-xxxx.onrender.com): " USER_SERVICE_URL
echo ""

echo "📦 Step 1: Seeding products..."
echo "Connecting to MongoDB Atlas..."

# Seed products
mongosh "$MONGODB_URI" <<'EOF'
use('eds');

// Clear existing data
print("🗑️  Clearing existing products...");
db.products.deleteMany({});

// Sample products
const products = [
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
  },
  {
    _id: "4",
    name: "Nike Air Max 270",
    description: "Nike's biggest heel Air unit yet",
    price: NumberDecimal("150.00"),
    stock: 67,
    category: "Clothing",
    tags: ["sneakers", "nike"],
    images: ["https://images.unsplash.com/photo-1549298916-b41d501d3772?w=500"],
    featured: true,
    rating: 4.3,
    reviewCount: 234,
    version: 1,
    updatedAt: new Date()
  },
  {
    _id: "5",
    name: "Levi's 501 Original Jeans",
    description: "The original blue jean since 1873",
    price: NumberDecimal("89.50"),
    stock: 120,
    category: "Clothing",
    tags: ["jeans", "levis"],
    images: ["https://images.unsplash.com/photo-1542272604-787c3835535d?w=500"],
    featured: false,
    rating: 4.4,
    reviewCount: 156,
    version: 1,
    updatedAt: new Date()
  }
];

db.products.insertMany(products);
print("✅ Inserted " + products.length + " products");
EOF

if [ $? -eq 0 ]; then
  echo "✅ Products seeded successfully!"
else
  echo "❌ Failed to seed products"
  exit 1
fi

echo ""
echo "👤 Step 2: Creating admin user..."
echo "Calling deployed user service..."

# Remove existing admin user
mongosh "$MONGODB_URI" --eval "use eds; db.users.deleteOne({email: 'admin@marketplace.com'})" > /dev/null 2>&1

# Register admin user through deployed service
RESPONSE=$(curl -s -X POST "$USER_SERVICE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@marketplace.com", "password": "admin123", "firstName": "Admin", "lastName": "User"}')

if echo "$RESPONSE" | grep -q "token"; then
  echo "✅ Admin user registered"
  
  # Update role to ADMIN
  echo "🛡️  Updating role to ADMIN..."
  mongosh "$MONGODB_URI" --eval "use eds; db.users.updateOne({email: 'admin@marketplace.com'}, {\$set: {role: 'ADMIN'}})" > /dev/null
  
  echo "✅ Admin user created successfully!"
else
  echo "⚠️  Admin user registration failed"
  echo "Response: $RESPONSE"
  echo ""
  echo "You can create admin user manually:"
  echo "1. Register at your frontend: https://marketplace-ui-tau.vercel.app/register"
  echo "2. Then update role in MongoDB Atlas:"
  echo "   db.users.updateOne({email: 'your@email.com'}, {\$set: {role: 'ADMIN'}})"
fi

echo ""
echo "=========================================="
echo "✅ Cloud Database Seeding Complete!"
echo "=========================================="
echo ""
echo "📊 Summary:"
echo "  - Products: 5 sample products added"
echo "  - Admin: admin@marketplace.com / admin123"
echo ""
echo "🌐 Test your deployed app:"
echo "  https://marketplace-ui-tau.vercel.app"
echo ""
