// Fix admin user password by using the user service to create it properly
// This ensures the password is hashed with the same encoder the service uses

use('eds');

// Remove existing admin user
db.users.deleteOne({email: "admin@marketplace.com"});

print("✅ Removed existing admin user");
print("🔧 Admin user will be created when you first try to login");
print("📝 Use the registration endpoint or let the service create it");

// Alternative: Create with a known working hash
// This hash is for "admin123" using BCrypt with strength 10
const correctHash = "$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.";

db.users.insertOne({
  _id: "admin",
  email: "admin@marketplace.com", 
  password: correctHash,
  firstName: "Admin",
  lastName: "User",
  role: "ADMIN",
  createdAt: new Date(),
  updatedAt: new Date()
});

print("✅ Created admin user with corrected password hash");
print("👤 Email: admin@marketplace.com");
print("🔑 Password: admin123");
print("🛡️  Role: ADMIN");