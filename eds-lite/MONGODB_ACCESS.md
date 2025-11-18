# MongoDB Access Guide

## Quick Access

### Option 1: Use the Script
```bash
./scripts/access-mongo.sh
```

### Option 2: Direct Command
```bash
mongosh mongodb://localhost:27017/eds
```

## Useful MongoDB Commands

Once connected, you can use these commands:

### View Collections
```javascript
show collections
```

### Count Documents
```javascript
// Count all products
db.products.countDocuments()

// Count all orders
db.orders.countDocuments()
```

### Query Products

```javascript
// Get one product
db.products.findOne()

// Get product by ID
db.products.findOne({_id: "1"})

// Get first 5 products
db.products.find().limit(5)

// Get products with stock > 500
db.products.find({stock: {$gt: 500}}).limit(10)

// Get products with price < 100
db.products.find({price: {$lt: 100}}).limit(10)
```

### Query Orders

```javascript
// Get all orders
db.orders.find()

// Get one order
db.orders.findOne()

// Get orders for a specific customer
db.orders.find({customerId: "customer-123"})
```

### Update Documents

```javascript
// Update a product (directly in MongoDB)
db.products.updateOne(
  {_id: "1"},
  {$set: {price: 199.99, stock: 100, version: 2}}
)

// Increment version
db.products.updateOne(
  {_id: "1"},
  {$inc: {version: 1}}
)
```

### Delete Documents

```javascript
// Delete a product
db.products.deleteOne({_id: "1"})

// Delete all products (careful!)
db.products.deleteMany({})
```

### Useful Queries

```javascript
// Find products by name pattern
db.products.find({name: /Product 1/})

// Get product statistics
db.products.aggregate([
  {
    $group: {
      _id: null,
      avgPrice: {$avg: "$price"},
      minPrice: {$min: "$price"},
      maxPrice: {$max: "$price"},
      totalStock: {$sum: "$stock"}
    }
  }
])

// Get products sorted by price
db.products.find().sort({price: 1}).limit(10)

// Get products sorted by stock (descending)
db.products.find().sort({stock: -1}).limit(10)
```

## One-Line Commands (Without Opening Shell)

### Count Products
```bash
mongosh mongodb://localhost:27017/eds --eval "db.products.countDocuments()" --quiet
```

### Get One Product
```bash
mongosh mongodb://localhost:27017/eds --eval "db.products.findOne()" --quiet
```

### Get Product by ID
```bash
mongosh mongodb://localhost:27017/eds --eval "db.products.findOne({_id: '1'})" --quiet
```

### List All Collections
```bash
mongosh mongodb://localhost:27017/eds --eval "show collections" --quiet
```

### Get Product Count and Sample
```bash
mongosh mongodb://localhost:27017/eds --eval "
  print('Total products: ' + db.products.countDocuments());
  print('Sample product:');
  printjson(db.products.findOne())
" --quiet
```

## Using MongoDB Compass (GUI)

If you prefer a GUI:

1. **Download MongoDB Compass**: https://www.mongodb.com/try/download/compass
2. **Connection String**: `mongodb://localhost:27017`
3. **Database**: `eds`
4. **Collections**: `products`, `orders`

## Using Studio 3T or Other GUI Tools

Connection details:
- **Host**: `localhost`
- **Port**: `27017`
- **Database**: `eds`
- **Authentication**: None (local development)

## Troubleshooting

### MongoDB Not Running
```bash
# Start MongoDB
./scripts/start-mongo.sh

# Check if running
pgrep -f mongod
```

### Connection Refused
- Make sure MongoDB is running on port 27017
- Check: `lsof -i :27017`

### Database Not Found
- The database will be created automatically when you first insert data
- Or run the seed script: `mongosh mongodb://localhost:27017/eds < scripts/seed-mongo.js`


