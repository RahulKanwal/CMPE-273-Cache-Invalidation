// MongoDB seed script for marketplace data
// Run with: mongosh mongodb://localhost:27017/eds < scripts/seed-marketplace.js

use('eds');

// Clear existing data
db.products.deleteMany({});
db.users.deleteMany({});

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

// Sample products with marketplace features
const products = [
  // Electronics
  {
    _id: "1",
    name: "MacBook Pro 16-inch",
    description: "Apple MacBook Pro with M3 Pro chip, 16-inch Liquid Retina XDR display, 18GB unified memory, 512GB SSD storage. Space Black.",
    price: NumberDecimal("2499.00"),
    stock: 15,
    category: "Electronics",
    tags: ["laptop", "apple", "macbook", "professional", "m3"],
    images: ["https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=500", "https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=500"],
    featured: true,
    rating: 4.8,
    reviewCount: 127,
    version: 1,
    updatedAt: new Date()
  },
  {
    _id: "2", 
    name: "iPhone 15 Pro",
    description: "iPhone 15 Pro with titanium design, A17 Pro chip, Pro camera system with 5x telephoto. Natural Titanium, 128GB.",
    price: NumberDecimal("999.00"),
    stock: 32,
    category: "Electronics",
    tags: ["smartphone", "apple", "iphone", "titanium", "a17"],
    images: ["https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=500", "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=500"],
    featured: true,
    rating: 4.7,
    reviewCount: 89,
    version: 1,
    updatedAt: new Date()
  },
  {
    _id: "3",
    name: "Sony WH-1000XM5 Headphones",
    description: "Industry-leading noise canceling wireless headphones with crystal clear hands-free calling and Alexa voice control.",
    price: NumberDecimal("399.99"),
    stock: 45,
    category: "Electronics",
    tags: ["headphones", "sony", "wireless", "noise-canceling", "bluetooth"],
    images: ["https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500"],
    featured: false,
    rating: 4.6,
    reviewCount: 203,
    version: 1,
    updatedAt: new Date()
  },
  {
    _id: "4",
    name: "Samsung 65\" QLED 4K TV",
    description: "65-inch QLED 4K Smart TV with Quantum HDR, Object Tracking Sound+, and Gaming Hub. Neo QLED technology.",
    price: NumberDecimal("1299.99"),
    stock: 8,
    category: "Electronics",
    tags: ["tv", "samsung", "qled", "4k", "smart-tv", "gaming"],
    images: ["https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=500"],
    featured: false,
    rating: 4.5,
    reviewCount: 67,
    version: 1,
    updatedAt: new Date()
  },

  // Clothing
  {
    _id: "5",
    name: "Levi's 501 Original Jeans",
    description: "The original blue jean since 1873. Straight fit with button fly. 100% cotton denim in classic stonewash.",
    price: NumberDecimal("89.50"),
    stock: 120,
    category: "Clothing",
    tags: ["jeans", "levis", "denim", "classic", "straight-fit"],
    images: ["https://images.unsplash.com/photo-1542272604-787c3835535d?w=500"],
    featured: false,
    rating: 4.4,
    reviewCount: 156,
    version: 1,
    updatedAt: new Date()
  },
  {
    _id: "6",
    name: "Nike Air Max 270",
    description: "Nike's biggest heel Air unit yet delivers exceptional comfort. Engineered mesh upper with synthetic overlays.",
    price: NumberDecimal("150.00"),
    stock: 67,
    category: "Clothing",
    tags: ["sneakers", "nike", "air-max", "running", "comfort"],
    images: ["https://images.unsplash.com/photo-1549298916-b41d501d3772?w=500"],
    featured: true,
    rating: 4.3,
    reviewCount: 234,
    version: 1,
    updatedAt: new Date()
  },
  {
    _id: "7",
    name: "Patagonia Better Sweater Fleece",
    description: "Classic fleece jacket made from recycled polyester. Full-zip with stand-up collar and handwarmer pockets.",
    price: NumberDecimal("139.00"),
    stock: 34,
    category: "Clothing",
    tags: ["fleece", "patagonia", "jacket", "recycled", "outdoor"],
    images: ["https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=500"],
    featured: false,
    rating: 4.7,
    reviewCount: 98,
    version: 1,
    updatedAt: new Date()
  },

  // Home & Garden
  {
    _id: "8",
    name: "Dyson V15 Detect Vacuum",
    description: "Cordless vacuum with laser dust detection, LCD screen showing particle count and size in real time.",
    price: NumberDecimal("749.99"),
    stock: 23,
    category: "Home & Garden",
    tags: ["vacuum", "dyson", "cordless", "laser", "cleaning"],
    images: ["https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500"],
    featured: true,
    rating: 4.6,
    reviewCount: 145,
    version: 1,
    updatedAt: new Date()
  },
  {
    _id: "9",
    name: "Instant Pot Duo 7-in-1",
    description: "7-in-1 electric pressure cooker: pressure cooker, slow cooker, rice cooker, steamer, sauté, yogurt maker, warmer.",
    price: NumberDecimal("99.95"),
    stock: 78,
    category: "Home & Garden",
    tags: ["instant-pot", "pressure-cooker", "kitchen", "multi-cooker"],
    images: ["https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=500"],
    featured: false,
    rating: 4.5,
    reviewCount: 312,
    version: 1,
    updatedAt: new Date()
  },
  {
    _id: "10",
    name: "Philips Hue Smart Bulb Starter Kit",
    description: "Smart LED bulbs with 16 million colors, voice control compatible with Alexa, Google Assistant, Apple HomeKit.",
    price: NumberDecimal("199.99"),
    stock: 56,
    category: "Home & Garden",
    tags: ["smart-home", "philips", "led", "voice-control", "lighting"],
    images: ["https://images.unsplash.com/photo-1558002038-1055907df827?w=500"],
    featured: false,
    rating: 4.4,
    reviewCount: 89,
    version: 1,
    updatedAt: new Date()
  },

  // Books
  {
    _id: "11",
    name: "The Psychology of Money",
    description: "Timeless lessons on wealth, greed, and happiness by Morgan Housel. 19 short stories exploring how people think about money.",
    price: NumberDecimal("16.99"),
    stock: 145,
    category: "Books",
    tags: ["finance", "psychology", "money", "investing", "bestseller"],
    images: ["https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=500"],
    featured: false,
    rating: 4.8,
    reviewCount: 567,
    version: 1,
    updatedAt: new Date()
  },
  {
    _id: "12",
    name: "Atomic Habits",
    description: "An Easy & Proven Way to Build Good Habits & Break Bad Ones by James Clear. #1 New York Times bestseller.",
    price: NumberDecimal("18.00"),
    stock: 89,
    category: "Books",
    tags: ["self-help", "habits", "productivity", "bestseller", "james-clear"],
    images: ["https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=500"],
    featured: true,
    rating: 4.7,
    reviewCount: 423,
    version: 1,
    updatedAt: new Date()
  },

  // Sports & Outdoors
  {
    _id: "13",
    name: "YETI Rambler 20oz Tumbler",
    description: "Stainless steel insulated tumbler with MagSlider lid. Keeps drinks cold for 24+ hours, hot for 12+ hours.",
    price: NumberDecimal("35.00"),
    stock: 234,
    category: "Sports & Outdoors",
    tags: ["yeti", "tumbler", "insulated", "stainless-steel", "drinkware"],
    images: ["https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=500"],
    featured: false,
    rating: 4.9,
    reviewCount: 178,
    version: 1,
    updatedAt: new Date()
  },
  {
    _id: "14",
    name: "REI Co-op Merino Wool Long-Sleeve Base Layer",
    description: "Lightweight merino wool base layer for year-round comfort. Naturally odor-resistant and temperature-regulating.",
    price: NumberDecimal("79.95"),
    stock: 67,
    category: "Sports & Outdoors",
    tags: ["merino-wool", "base-layer", "rei", "outdoor", "hiking"],
    images: ["https://images.unsplash.com/photo-1544966503-7cc5ac882d5f?w=500"],
    featured: false,
    rating: 4.6,
    reviewCount: 134,
    version: 1,
    updatedAt: new Date()
  },
  {
    _id: "15",
    name: "Hydro Flask Water Bottle 32oz",
    description: "Stainless steel water bottle with TempShield insulation. Keeps liquids cold for 24 hours, hot for 12 hours.",
    price: NumberDecimal("44.95"),
    stock: 156,
    category: "Sports & Outdoors",
    tags: ["hydro-flask", "water-bottle", "insulated", "stainless-steel"],
    images: ["https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=500"],
    featured: false,
    rating: 4.5,
    reviewCount: 267,
    version: 1,
    updatedAt: new Date()
  }
];

// Insert all products
db.products.insertMany(products);

print("✅ Marketplace data seeded successfully!");
print("📊 Inserted " + products.length + " products");
print("👤 Created admin user: admin@marketplace.com / admin123");
print("🏷️  Categories: Electronics, Clothing, Home & Garden, Books, Sports & Outdoors");
print("⭐ Featured products: " + products.filter(p => p.featured).length);