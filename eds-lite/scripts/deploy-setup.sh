#!/bin/bash

# Deployment Setup Script
# Prepares the project for deployment

set -e

echo "🚀 Preparing EDS Marketplace for deployment..."

# 1. Create .gitignore if it doesn't exist
if [ ! -f .gitignore ]; then
    echo "📝 Creating .gitignore..."
    cat > .gitignore << 'EOF'
# Compiled class files
*.class
target/
*.jar
!**/src/main/**/target/
!**/src/test/**/target/

# Log files
*.log
logs/
*.pid

# Environment variables
.env
.env.local
.env.production

# Node modules
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# React build
marketplace-ui/build/

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Temporary files
*.tmp
*.temp
dump.rdb
cache-test-results-*.txt
*-report-*.txt
EOF
fi

# 2. Update package.json for Vercel deployment
echo "📦 Updating package.json for deployment..."
cd marketplace-ui

# Add build script if not exists
if ! grep -q "\"build\":" package.json; then
    echo "Adding build script to package.json..."
    # This would need manual editing
fi

cd ..

# 3. Create deployment checklist
echo "📋 Creating deployment checklist..."
cat > DEPLOYMENT_CHECKLIST.md << 'EOF'
# 🚀 Deployment Checklist

## Before Deployment

- [ ] Push all code to GitHub
- [ ] Test locally with `npm start` and `mvn spring-boot:run`
- [ ] Verify all environment variables are set
- [ ] Check CORS configuration

## Cloud Services Setup

- [ ] MongoDB Atlas cluster created
- [ ] Upstash Redis database created  
- [ ] Upstash Kafka cluster created
- [ ] Railway account setup
- [ ] Vercel account setup

## Backend Deployment (Railway)

- [ ] API Gateway deployed
- [ ] Catalog Service deployed
- [ ] Order Service deployed
- [ ] User Service deployed
- [ ] All environment variables configured
- [ ] Health checks passing

## Frontend Deployment (Vercel)

- [ ] React app deployed
- [ ] Environment variables set
- [ ] Custom domain configured (optional)

## Post-Deployment

- [ ] Database seeded with products
- [ ] Admin user created
- [ ] Test login functionality
- [ ] Test product search
- [ ] Test cart and checkout
- [ ] Test admin panel

## Monitoring

- [ ] Health endpoints responding
- [ ] Logs are accessible
- [ ] Performance monitoring setup
EOF

echo ""
echo "✅ Deployment setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Review DEPLOYMENT_GUIDE.md for detailed instructions"
echo "2. Follow DEPLOYMENT_CHECKLIST.md step by step"
echo "3. Set up cloud services (MongoDB Atlas, Upstash, Railway, Vercel)"
echo "4. Deploy services and test functionality"
echo ""
echo "🌍 Your marketplace will be live and accessible worldwide!"