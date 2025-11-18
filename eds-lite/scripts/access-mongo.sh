#!/bin/bash

# Quick script to access MongoDB shell
# This opens an interactive MongoDB shell connected to the local database

echo "Connecting to MongoDB..."
echo "Database: eds"
echo "Connection: mongodb://localhost:27017/eds"
echo ""
echo "Useful commands:"
echo "  show collections          - List all collections"
echo "  db.products.countDocuments()  - Count products"
echo "  db.products.findOne()     - Get one product"
echo "  db.products.find().limit(5)  - Get 5 products"
echo "  db.orders.find()          - Get all orders"
echo "  exit                      - Exit shell"
echo ""
echo "=========================================="
echo ""

mongosh mongodb://localhost:27017/eds


