#!/bin/bash

# EDS-Lite Project Cleanup Script
# Removes unnecessary files and organizes project structure

set -e

echo "🧹 Starting EDS-Lite project cleanup..."

# 1. Remove temporary/generated files
echo "Removing temporary files..."
rm -f eds-lite/cache-test-results-*.txt
rm -f eds-lite/EXECUTIVE_SUMMARY_*.txt
rm -f eds-lite/dump.rdb
rm -f eds-lite/scripts/dump.rdb
rm -f eds-lite/demo.html

# 2. Remove log files (will be regenerated)
echo "Removing log files..."
rm -rf eds-lite/logs/

# 3. Remove Maven target directories
echo "Removing Maven target directories..."
rm -rf eds-lite/*/target/

# 4. Remove redundant documentation
echo "Removing redundant documentation..."
rm -f eds-lite/QUICKSTART.md
rm -f eds-lite/QUICK_START_TESTING.md
rm -f eds-lite/TESTING_SCRIPTS_SUMMARY.md
rm -f eds-lite/MONGODB_ACCESS.md
rm -f eds-lite/API_TEST_EXAMPLES.md
rm -f eds-lite/TROUBLESHOOTING.md
rm -f eds-lite/METRICS_EXPLANATION.md

# 5. Remove redundant/outdated scripts
echo "Removing redundant scripts..."
rm -f eds-lite/scripts/quick-test.sh
rm -f eds-lite/scripts/test-cache-invalidation.sh
rm -f eds-lite/scripts/test-scenarios-simple.sh
rm -f eds-lite/scripts/run-scenarios-manual.sh
rm -f eds-lite/scripts/current-metrics-report.py
rm -f eds-lite/scripts/generate-latest-report.py
rm -f eds-lite/scripts/save-current-report.py
rm -f eds-lite/scripts/start-redpanda.sh
rm -f eds-lite/scripts/serve-demo.sh
rm -f eds-lite/scripts/debug-services.sh
rm -f eds-lite/scripts/diagnose-ports.sh
rm -f eds-lite/scripts/manage-ports.sh
rm -f eds-lite/scripts/test-update-endpoint.sh
rm -f eds-lite/scripts/test-metrics.sh
rm -f eds-lite/scripts/verify-endpoints.sh

# 6. Remove unused k6 files (if they exist)
echo "Removing unused k6 files..."
rm -f eds-lite/ops/k6/load-mixed.js

# 7. Update .gitignore to prevent future clutter
echo "Updating .gitignore..."
cat >> eds-lite/.gitignore << 'EOF'

# Temporary files
*.tmp
*.temp
dump.rdb
cache-test-results-*.txt
*-report-*.txt

# Log files
logs/
*.log
*.pid

# Maven
target/
*.jar
!**/src/main/**/target/
!**/src/test/**/target/

# Node modules (already there but ensuring)
node_modules/
npm-debug.log*

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db
EOF

echo "✅ Cleanup completed!"
echo ""
echo "📊 Project structure summary:"
echo "  📁 Services: 4 (api-gateway, catalog-service, order-service, user-service)"
echo "  📁 Frontend: 1 (marketplace-ui)"  
echo "  📜 Scripts: $(ls eds-lite/scripts/*.sh 2>/dev/null | wc -l | tr -d ' ') shell scripts"
echo "  📜 Python: $(ls eds-lite/scripts/*.py 2>/dev/null | wc -l | tr -d ' ') Python scripts"
echo "  📚 Docs: $(ls eds-lite/*.md 2>/dev/null | wc -l | tr -d ' ') markdown files"
echo ""
echo "🎯 Key files kept:"
echo "  • README.md - Main project documentation"
echo "  • CACHE_DEMO_README.md - Cache demo documentation"
echo "  • TESTING_GUIDE.md - Testing instructions"
echo "  • Essential scripts for infrastructure, testing, and demos"
echo ""
echo "🚀 Your project is now clean and organized!"