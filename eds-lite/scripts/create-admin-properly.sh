#!/bin/bash

# Create admin user properly using the user service
# This ensures the password is hashed correctly

set -e

echo "🔧 Creating admin user properly..."

# Remove existing admin user if it exists
mongosh mongodb://localhost:27017/eds --eval "db.users.deleteOne({email: 'admin@marketplace.com'})" > /dev/null

# Register admin user through the service (creates with CUSTOMER role)
echo "📝 Registering admin user..."
RESPONSE=$(curl -s -X POST http://localhost:8083/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@marketplace.com", "password": "admin123", "firstName": "Admin", "lastName": "User"}')

if echo "$RESPONSE" | grep -q "token"; then
  echo "✅ Admin user registered successfully"
  
  # Update role to ADMIN
  echo "🛡️  Updating role to ADMIN..."
  mongosh mongodb://localhost:27017/eds --eval "db.users.updateOne({email: 'admin@marketplace.com'}, {\$set: {role: 'ADMIN'}})" > /dev/null
  
  # Test login
  echo "🔐 Testing login..."
  LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8083/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email": "admin@marketplace.com", "password": "admin123"}')
  
  if echo "$LOGIN_RESPONSE" | grep -q "ADMIN"; then
    echo "🎉 Admin user created and login working!"
    echo ""
    echo "Admin Credentials:"
    echo "  Email: admin@marketplace.com"
    echo "  Password: admin123"
    echo "  Role: ADMIN"
  else
    echo "❌ Login test failed"
    echo "Response: $LOGIN_RESPONSE"
  fi
else
  echo "❌ Registration failed"
  echo "Response: $RESPONSE"
fi