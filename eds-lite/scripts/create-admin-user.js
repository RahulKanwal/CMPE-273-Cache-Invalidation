// Create admin user only
// Run with: mongosh mongodb://localhost:27017/eds < scripts/create-admin-user.js

use('eds');

// Remove existing admin user if it exists
db.users.deleteOne({email: "admin@marketplace.com"});

// Create admin user (password: admin123)
db.users.insertOne({
  _id: "admin",
  email: "admin@marketplace.com",
  password: "$2a$10$8.UnVuG9HHgffUDAlk8qfOuVGkqRdvuoony/4oGGe0TGrGBVxB5Ae", // admin123
  firstName: "Admin",
  lastName: "User", 
  role: "ADMIN",
  createdAt: new Date(),
  updatedAt: new Date()
});

print("✅ Admin user created successfully!");
print("👤 Email: admin@marketplace.com");
print("🔑 Password: admin123");
print("🛡️  Role: ADMIN");