#!/bin/bash

# Cleanup Unnecessary Files Script
# This removes files that are not needed for a Render + Vercel deployment

echo "================================================"
echo "EDS Project Cleanup Script"
echo "================================================"
echo ""
echo "This will remove unnecessary files from your project."
echo "A backup will NOT be created - make sure you've committed to git first!"
echo ""
read -p "Have you committed your changes to git? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Please commit your changes first, then run this script again."
    exit 1
fi

echo ""
echo "Choose cleanup level:"
echo "1) Minimal - Remove only obviously unnecessary files (SAFE)"
echo "2) Moderate - Remove local dev and testing files (RECOMMENDED)"
echo "3) Aggressive - Remove everything except production essentials"
echo "4) Cancel"
echo ""
read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo ""
        echo "Running MINIMAL cleanup..."
        echo ""
        
        # Outdated documentation
        rm -f DEPLOYMENT_GUIDE.md && echo "✓ Removed DEPLOYMENT_GUIDE.md"
        rm -f SIMPLE_DEPLOYMENT_GUIDE.md && echo "✓ Removed SIMPLE_DEPLOYMENT_GUIDE.md"
        rm -f SEED_CLOUD_DATABASE.md && echo "✓ Removed SEED_CLOUD_DATABASE.md"
        rm -f TEST_CLOUD_SERVICES.md && echo "✓ Removed TEST_CLOUD_SERVICES.md"
        rm -f TESTING_GUIDE.md && echo "✓ Removed TESTING_GUIDE.md"
        
        # Unused scripts and configs
        rm -f test-cloud-services.sh && echo "✓ Removed test-cloud-services.sh"
        rm -f cleanup-project.sh && echo "✓ Removed cleanup-project.sh"
        rm -f Procfile && echo "✓ Removed Procfile"
        rm -f railway.json && echo "✓ Removed railway.json"
        
        # Database dumps
        rm -f dump.rdb && echo "✓ Removed dump.rdb"
        rm -f scripts/dump.rdb && echo "✓ Removed scripts/dump.rdb"
        
        echo ""
        echo "✅ Minimal cleanup complete!"
        ;;
        
    2)
        echo ""
        echo "Running MODERATE cleanup..."
        echo ""
        
        # Run minimal cleanup first
        rm -f DEPLOYMENT_GUIDE.md && echo "✓ Removed DEPLOYMENT_GUIDE.md"
        rm -f SIMPLE_DEPLOYMENT_GUIDE.md && echo "✓ Removed SIMPLE_DEPLOYMENT_GUIDE.md"
        rm -f SEED_CLOUD_DATABASE.md && echo "✓ Removed SEED_CLOUD_DATABASE.md"
        rm -f TEST_CLOUD_SERVICES.md && echo "✓ Removed TEST_CLOUD_SERVICES.md"
        rm -f TESTING_GUIDE.md && echo "✓ Removed TESTING_GUIDE.md"
        rm -f test-cloud-services.sh && echo "✓ Removed test-cloud-services.sh"
        rm -f cleanup-project.sh && echo "✓ Removed cleanup-project.sh"
        rm -f Procfile && echo "✓ Removed Procfile"
        rm -f railway.json && echo "✓ Removed railway.json"
        rm -f dump.rdb && echo "✓ Removed dump.rdb"
        rm -f scripts/dump.rdb && echo "✓ Removed scripts/dump.rdb"
        
        # Local development scripts
        rm -f scripts/start-all-infrastructure.sh && echo "✓ Removed scripts/start-all-infrastructure.sh"
        rm -f scripts/start-all-services.sh && echo "✓ Removed scripts/start-all-services.sh"
        rm -f scripts/start-kafka.sh && echo "✓ Removed scripts/start-kafka.sh"
        rm -f scripts/start-mongo.sh && echo "✓ Removed scripts/start-mongo.sh"
        rm -f scripts/start-redis.sh && echo "✓ Removed scripts/start-redis.sh"
        rm -f scripts/start-catalog-service.sh && echo "✓ Removed scripts/start-catalog-service.sh"
        rm -f scripts/start-marketplace.sh && echo "✓ Removed scripts/start-marketplace.sh"
        rm -f scripts/start-cache-demo.sh && echo "✓ Removed scripts/start-cache-demo.sh"
        rm -f scripts/stop-all-services.sh && echo "✓ Removed scripts/stop-all-services.sh"
        rm -f scripts/stop-catalog-service.sh && echo "✓ Removed scripts/stop-catalog-service.sh"
        rm -f scripts/stop-marketplace.sh && echo "✓ Removed scripts/stop-marketplace.sh"
        rm -f scripts/setup-local.sh && echo "✓ Removed scripts/setup-local.sh"
        rm -f scripts/setup-kafka.sh && echo "✓ Removed scripts/setup-kafka.sh"
        rm -f scripts/deploy-setup.sh && echo "✓ Removed scripts/deploy-setup.sh"
        
        # Performance testing
        rm -f scripts/run-k6-a.sh && echo "✓ Removed scripts/run-k6-a.sh"
        rm -f scripts/run-k6-b.sh && echo "✓ Removed scripts/run-k6-b.sh"
        rm -f scripts/run-k6-c.sh && echo "✓ Removed scripts/run-k6-c.sh"
        rm -f scripts/run-k6-marketplace.sh && echo "✓ Removed scripts/run-k6-marketplace.sh"
        rm -f scripts/run-all-scenarios.sh && echo "✓ Removed scripts/run-all-scenarios.sh"
        rm -f scripts/test-cache-scenarios.sh && echo "✓ Removed scripts/test-cache-scenarios.sh"
        rm -f scripts/quick-cache-test.sh && echo "✓ Removed scripts/quick-cache-test.sh"
        rm -f scripts/generate-scenario-report.py && echo "✓ Removed scripts/generate-scenario-report.py"
        rm -f scripts/summarize-metrics.py && echo "✓ Removed scripts/summarize-metrics.py"
        
        # K6 load testing configs
        if [ -d "ops/k6" ]; then
            rm -rf ops/k6 && echo "✓ Removed ops/k6/ directory"
        fi
        
        # Remove ops directory if empty
        if [ -d "ops" ] && [ -z "$(ls -A ops)" ]; then
            rmdir ops && echo "✓ Removed empty ops/ directory"
        fi
        
        echo ""
        echo "✅ Moderate cleanup complete!"
        ;;
        
    3)
        echo ""
        echo "Running AGGRESSIVE cleanup..."
        echo ""
        
        # Run moderate cleanup first
        rm -f DEPLOYMENT_GUIDE.md SIMPLE_DEPLOYMENT_GUIDE.md SEED_CLOUD_DATABASE.md
        rm -f TEST_CLOUD_SERVICES.md TESTING_GUIDE.md
        rm -f test-cloud-services.sh cleanup-project.sh Procfile railway.json
        rm -f dump.rdb scripts/dump.rdb
        rm -f scripts/start-*.sh scripts/stop-*.sh
        rm -f scripts/setup-local.sh scripts/setup-kafka.sh scripts/deploy-setup.sh
        rm -f scripts/run-k6-*.sh scripts/run-all-scenarios.sh
        rm -f scripts/test-cache-scenarios.sh scripts/quick-cache-test.sh
        rm -f scripts/generate-scenario-report.py scripts/summarize-metrics.py
        rm -rf ops/k6
        [ -d "ops" ] && [ -z "$(ls -A ops)" ] && rmdir ops
        
        # Additional aggressive removals
        rm -f scripts/seed-mongo.js && echo "✓ Removed scripts/seed-mongo.js (local seeding)"
        rm -f scripts/test-apis.sh && echo "✓ Removed scripts/test-apis.sh"
        rm -f scripts/fix-mongodb.sh && echo "✓ Removed scripts/fix-mongodb.sh"
        rm -f scripts/access-mongo.sh && echo "✓ Removed scripts/access-mongo.sh"
        
        echo ""
        echo "✅ Aggressive cleanup complete!"
        echo "⚠️  Only production-essential files remain"
        ;;
        
    4)
        echo ""
        echo "Cleanup cancelled."
        exit 0
        ;;
        
    *)
        echo ""
        echo "Invalid choice. Cleanup cancelled."
        exit 1
        ;;
esac

echo ""
echo "================================================"
echo "Cleanup Summary"
echo "================================================"
echo ""
echo "Files removed successfully!"
echo ""
echo "Next steps:"
echo "1. Review the changes: git status"
echo "2. Commit the cleanup: git add -A && git commit -m 'Clean up unnecessary files'"
echo "3. Push to GitHub: git push origin main"
echo ""
echo "Kept files:"
echo "  ✓ README.md"
echo "  ✓ RENDER_DEPLOYMENT.md"
echo "  ✓ KEEP_SERVICES_AWAKE.md"
echo "  ✓ VERCEL_DEPLOYMENT.md"
echo "  ✓ CACHE_DEMO_README.md"
echo "  ✓ wake-up-services.sh"
echo "  ✓ keep-services-awake.sh"
echo "  ✓ .github/workflows/keep-services-awake.yml"
echo "  ✓ Essential scripts in scripts/"
echo ""
