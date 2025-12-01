# Database Schema Documentation

## Overview

This application uses **MongoDB** as the primary database, hosted on **MongoDB Atlas** (cloud). The database is named `eds` and contains 4 main collections.

**Database:** `eds`  
**Platform:** MongoDB Atlas (Free Tier M0)  
**Connection:** `mongodb+srv://[credentials]@cluster.mongodb.net/eds`

---

## Collections

### 1. Products Collection

**Collection Name:** `products`  
**Service:** catalog-service  
**Purpose:** Store product catalog information

#### Schema

```javascript
{
  _id: ObjectId,                    // MongoDB auto-generated ID
  id: String,                       // Application ID (same as _id)
  name: String,                     // Product name
  description: String,              // Product description
  price: Decimal128,                // Product price (BigDecimal in Java)
  stock: Integer,                   // Available quantity
  category: String,                 // Product category (e.g., "Electronics", "Clothing")
  tags: [String],                   // Array of tags for search/filtering
  images: [String],                 // Array of image URLs
  featured: Boolean,                // Whether product is featured on homepage
  rating: Double,                   // Average rating (0.0 - 5.0)
  reviewCount: Integer,             // Number of reviews
  version: Integer,                 // Optimistic locking version (auto-incremented)
  updatedAt: ISODate                // Last update timestamp
}
```

#### Example Document

```json
{
  "_id": "1",
  "id": "1",
  "name": "Wireless Bluetooth Headphones",
  "description": "Premium noise-cancelling headphones with 30-hour battery life",
  "price": NumberDecimal("149.99"),
  "stock": 50,
  "category": "Electronics",
  "tags": ["audio", "wireless", "bluetooth", "headphones"],
  "images": [
    "https://picsum.photos/seed/product1/400/400",
    "https://picsum.photos/seed/product1-2/400/400"
  ],
  "featured": true,
  "rating": 4.5,
  "reviewCount": 128,
  "version": 1,
  "updatedAt": ISODate("2024-01-15T10:30:00Z")
}
```

#### Indexes

- `_id`: Primary key (automatic)
- `category`: For category filtering
- `featured`: For featured products query
- `name`: Text index for search functionality

#### Key Features

- **Optimistic Locking**: Uses `@Version` annotation for concurrent update handling
- **Caching**: Products are cached in Redis with TTL and Kafka-based invalidation
- **Search**: Supports full-text search on name, description, and tags

---

### 2. Reviews Collection

**Collection Name:** `reviews`  
**Service:** catalog-service  
**Purpose:** Store product reviews and ratings

#### Schema

```javascript
{
  _id: ObjectId,                    // MongoDB auto-generated ID
  id: String,                       // Application ID
  productId: String,                // Reference to product._id
  userId: String,                   // Reference to user._id
  userName: String,                 // Cached user name for display
  rating: Integer,                  // Star rating (1-5)
  comment: String,                  // Review text
  createdAt: ISODate                // Review creation timestamp
}
```

#### Example Document

```json
{
  "_id": ObjectId("507f1f77bcf86cd799439011"),
  "id": "507f1f77bcf86cd799439011",
  "productId": "1",
  "userId": "user123",
  "userName": "John Doe",
  "rating": 5,
  "comment": "Excellent headphones! Great sound quality and battery life.",
  "createdAt": ISODate("2024-01-10T14:20:00Z")
}
```

#### Indexes

- `_id`: Primary key (automatic)
- `productId`: For fetching reviews by product
- `userId`: For fetching reviews by user

#### Relationships

- **productId** → products._id (Many-to-One)
- **userId** → users._id (Many-to-One)

---

### 3. Orders Collection

**Collection Name:** `orders`  
**Service:** order-service  
**Purpose:** Store customer orders and order items

#### Schema

```javascript
{
  _id: ObjectId,                    // MongoDB auto-generated ID
  id: String,                       // Application ID (UUID)
  customerId: String,               // Customer email (reference to user.email)
  items: [                          // Array of order items (embedded)
    {
      productId: String,            // Reference to product._id
      quantity: Integer,            // Quantity ordered
      price: Decimal128             // Price at time of order
    }
  ],
  total: Decimal128,                // Total order amount
  status: String,                   // Order status: "CREATED", "PAID", "CANCELED"
  createdAt: ISODate,               // Order creation timestamp
  updatedAt: ISODate                // Last update timestamp
}
```

#### Example Document

```json
{
  "_id": ObjectId("507f191e810c19729de860ea"),
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "customerId": "customer@example.com",
  "items": [
    {
      "productId": "1",
      "quantity": 2,
      "price": NumberDecimal("149.99")
    },
    {
      "productId": "5",
      "quantity": 1,
      "price": NumberDecimal("79.99")
    }
  ],
  "total": NumberDecimal("379.97"),
  "status": "CREATED",
  "createdAt": ISODate("2024-01-15T16:45:00Z"),
  "updatedAt": ISODate("2024-01-15T16:45:00Z")
}
```

#### Indexes

- `_id`: Primary key (automatic)
- `customerId`: For fetching orders by customer
- `status`: For filtering by order status
- `createdAt`: For sorting by date

#### Order Status Values

- **CREATED**: Order placed but not paid
- **PAID**: Payment confirmed
- **CANCELED**: Order canceled by customer or admin

#### Key Features

- **Embedded Items**: Order items are embedded documents (not separate collection)
- **Price Snapshot**: Stores price at time of order (not current price)
- **Event Publishing**: Publishes Kafka events on order creation

---

### 4. Users Collection

**Collection Name:** `users`  
**Service:** user-service  
**Purpose:** Store user accounts and authentication data

#### Schema

```javascript
{
  _id: ObjectId,                    // MongoDB auto-generated ID
  id: String,                       // Application ID
  email: String,                    // User email (unique, indexed)
  password: String,                 // BCrypt hashed password
  firstName: String,                // User's first name
  lastName: String,                 // User's last name
  role: String,                     // User role: "CUSTOMER" or "ADMIN"
  createdAt: ISODate,               // Account creation timestamp
  updatedAt: ISODate                // Last update timestamp
}
```

#### Example Document

```json
{
  "_id": ObjectId("507f1f77bcf86cd799439012"),
  "id": "507f1f77bcf86cd799439012",
  "email": "customer@example.com",
  "password": "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy",
  "firstName": "Jane",
  "lastName": "Smith",
  "role": "CUSTOMER",
  "createdAt": ISODate("2024-01-01T08:00:00Z"),
  "updatedAt": ISODate("2024-01-01T08:00:00Z")
}
```

#### Indexes

- `_id`: Primary key (automatic)
- `email`: Unique index for login and user lookup

#### User Roles

- **CUSTOMER**: Regular user (can browse, order, review)
- **ADMIN**: Administrator (can manage products, view all orders)

#### Security

- **Password Hashing**: Uses BCrypt with strength 10
- **JWT Authentication**: Issues JWT tokens on successful login
- **Email Uniqueness**: Enforced by unique index

---

## Relationships

### Entity Relationship Diagram

```
┌─────────────┐
│   Users     │
│  (users)    │
└──────┬──────┘
       │
       │ 1:N (userId)
       │
       ↓
┌─────────────┐         ┌─────────────┐
│   Reviews   │    N:1  │  Products   │
│  (reviews)  │────────→│ (products)  │
└─────────────┘         └──────┬──────┘
                               │
                               │ N:1 (productId)
                               │
                               ↓
                        ┌─────────────┐
                        │   Orders    │
                        │  (orders)   │
                        └──────┬──────┘
                               │
                               │ N:1 (customerId)
                               │
                               ↓
                        ┌─────────────┐
                        │   Users     │
                        │  (users)    │
                        └─────────────┘
```

### Relationship Details

1. **Users → Reviews** (One-to-Many)
   - One user can write many reviews
   - Foreign key: `reviews.userId` → `users._id`

2. **Products → Reviews** (One-to-Many)
   - One product can have many reviews
   - Foreign key: `reviews.productId` → `products._id`

3. **Users → Orders** (One-to-Many)
   - One user can place many orders
   - Foreign key: `orders.customerId` → `users.email`

4. **Products → Order Items** (One-to-Many)
   - One product can appear in many order items
   - Foreign key: `orders.items[].productId` → `products._id`
   - Note: Items are embedded in orders, not a separate collection

---

## Data Types

### MongoDB to Java Mapping

| MongoDB Type | Java Type | Example |
|--------------|-----------|---------|
| ObjectId | String | `"507f1f77bcf86cd799439011"` |
| String | String | `"Product Name"` |
| Int32 | Integer | `42` |
| Int64 | Long | `1234567890L` |
| Decimal128 | BigDecimal | `149.99` |
| Double | Double | `4.5` |
| Boolean | boolean | `true` |
| Date | Instant | `2024-01-15T10:30:00Z` |
| Array | List<T> | `["tag1", "tag2"]` |
| Object | Embedded Class | `{ productId: "1", quantity: 2 }` |

---

## Indexes and Performance

### Existing Indexes

1. **products**
   - Primary: `_id`
   - Secondary: `category`, `featured`
   - Text: `name`, `description`

2. **reviews**
   - Primary: `_id`
   - Secondary: `productId`, `userId`

3. **orders**
   - Primary: `_id`
   - Secondary: `customerId`, `status`, `createdAt`

4. **users**
   - Primary: `_id`
   - Unique: `email`

### Query Patterns

**Most Common Queries:**

1. Get product by ID (cached in Redis)
   ```javascript
   db.products.findOne({ _id: "1" })
   ```

2. Search products by category
   ```javascript
   db.products.find({ category: "Electronics" })
   ```

3. Get featured products
   ```javascript
   db.products.find({ featured: true })
   ```

4. Get orders by customer
   ```javascript
   db.orders.find({ customerId: "customer@example.com" })
   ```

5. Get user by email (for login)
   ```javascript
   db.users.findOne({ email: "user@example.com" })
   ```

---

## Sample Data

### Default Admin User

```json
{
  "email": "admin@marketplace.com",
  "password": "admin123",
  "firstName": "Admin",
  "lastName": "User",
  "role": "ADMIN"
}
```

### Sample Products

The database is seeded with 2000+ products across categories:
- Electronics (laptops, phones, headphones)
- Clothing (shirts, pants, shoes)
- Home & Garden (furniture, decor)
- Books (fiction, non-fiction)
- Sports & Outdoors (equipment, apparel)

---

## Database Operations

### Seeding the Database

```bash
# Full marketplace data (products + admin user)
mongosh mongodb://localhost:27017/eds < scripts/seed-marketplace.js

# Products only (2000 products)
mongosh mongodb://localhost:27017/eds < scripts/seed-mongo.js

# Admin user only
mongosh mongodb://localhost:27017/eds < scripts/create-admin-user.js
```

### Backup and Restore

```bash
# Backup
mongodump --uri="mongodb+srv://[credentials]@cluster.mongodb.net/eds" --out=backup/

# Restore
mongorestore --uri="mongodb+srv://[credentials]@cluster.mongodb.net/eds" backup/eds/
```

### Useful Queries

```javascript
// Count products by category
db.products.aggregate([
  { $group: { _id: "$category", count: { $sum: 1 } } }
])

// Get top-rated products
db.products.find({ rating: { $gte: 4.5 } }).sort({ rating: -1 }).limit(10)

// Get recent orders
db.orders.find().sort({ createdAt: -1 }).limit(20)

// Count users by role
db.users.aggregate([
  { $group: { _id: "$role", count: { $sum: 1 } } }
])
```

---

## Caching Strategy

### Redis Cache Keys

Products are cached in Redis with the following key format:

```
productById::<productId>
```

**Example:**
```
productById::1 → { id: "1", name: "Wireless Headphones", ... }
```

### Cache Invalidation

When a product is updated:
1. Product updated in MongoDB
2. Cache evicted from Redis
3. Kafka event published: `cache.invalidate`
4. All service instances receive event and evict their caches
5. Next request fetches fresh data from MongoDB

---

## Migration and Versioning

### Schema Versioning

- **Current Version**: 1.0
- **Versioning Strategy**: Optimistic locking on products collection
- **Migration Tool**: Manual MongoDB scripts

### Future Enhancements

Potential schema additions:
- `addresses` collection for shipping addresses
- `payments` collection for payment history
- `cart` collection for persistent shopping carts
- `wishlist` collection for saved products
- `categories` collection for hierarchical categories

---

## Best Practices

1. **Always use indexes** for frequently queried fields
2. **Embed related data** when it's always accessed together (e.g., order items)
3. **Reference related data** when it's large or independently accessed (e.g., products)
4. **Use optimistic locking** for concurrent updates (products.version)
5. **Cache frequently accessed data** (products in Redis)
6. **Invalidate caches** on updates (Kafka events)
7. **Hash passwords** before storing (BCrypt)
8. **Validate data** at application layer before database insert

---

## Monitoring

### Key Metrics to Monitor

- **Collection sizes**: Track growth over time
- **Index usage**: Ensure indexes are being used
- **Query performance**: Monitor slow queries
- **Cache hit rate**: Track Redis cache effectiveness
- **Connection pool**: Monitor active connections

### MongoDB Atlas Monitoring

MongoDB Atlas provides built-in monitoring for:
- Query performance
- Index recommendations
- Storage usage
- Connection metrics
- Slow query logs

---

## Summary

| Collection | Documents | Indexes | Cached | Purpose |
|------------|-----------|---------|--------|---------|
| products | 2000+ | 4 | Yes | Product catalog |
| reviews | Variable | 3 | No | Product reviews |
| orders | Variable | 4 | No | Customer orders |
| users | Variable | 2 | No | User accounts |

**Total Database Size:** ~50-100 MB (with sample data)  
**Free Tier Limit:** 512 MB (MongoDB Atlas M0)  
**Backup Frequency:** Daily (automatic on Atlas)
