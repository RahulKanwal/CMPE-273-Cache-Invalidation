// Seed MongoDB with ~2000 products
// Run: mongosh mongodb://localhost:27017/eds seed-mongo.js
// Or: node seed-mongo.js (if using MongoDB Node.js driver)

const db = db.getSiblingDB('eds');

// Clear existing products
db.products.deleteMany({});

print("Seeding products...");

const products = [];
for (let i = 1; i <= 2000; i++) {
    products.push({
        _id: String(i),
        name: `Product ${i}`,
        description: `Description for product ${i}`,
        price: NumberDecimal((Math.random() * 1000 + 10).toFixed(2)),
        stock: Math.floor(Math.random() * 1000),
        version: 1,
        updatedAt: new Date()
    });
    
    // Insert in batches of 100
    if (products.length >= 100) {
        db.products.insertMany(products);
        products.length = 0;
        print(`Inserted ${i} products...`);
    }
}

// Insert remaining
if (products.length > 0) {
    db.products.insertMany(products);
}

print(`\nSeeded ${db.products.countDocuments()} products`);
print("Done!");

