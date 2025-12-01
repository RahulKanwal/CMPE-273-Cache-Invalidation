#!/bin/bash

# Fix Git Large Files Issue
# This removes large log files from git history

echo "================================================"
echo "Fix Git Large Files - Remove Logs from History"
echo "================================================"
echo ""
echo "⚠️  WARNING: This will rewrite git history!"
echo "This is safe for your local repo, but if others have cloned"
echo "your repo, they'll need to re-clone after you force push."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Cancelled."
    exit 1
fi

echo ""
echo "Step 1: Removing log files from git tracking..."
echo ""

# Remove log files from git index (but keep them on disk)
git rm -r --cached logs/ 2>/dev/null || echo "logs/ already removed from tracking"
git rm --cached logs/*.log 2>/dev/null || echo "No log files in root to remove"
git rm --cached **/*.log 2>/dev/null || echo "No nested log files to remove"

echo ""
echo "Step 2: Removing log files from git history..."
echo ""

# Use git filter-repo if available, otherwise use filter-branch
if command -v git-filter-repo &> /dev/null; then
    echo "Using git-filter-repo (recommended)..."
    git filter-repo --path logs/ --invert-paths --force
    git filter-repo --path '*.log' --invert-paths --force
else
    echo "Using git filter-branch (slower)..."
    echo "Tip: Install git-filter-repo for faster operation: brew install git-filter-repo"
    echo ""
    
    # Remove logs directory from all commits
    git filter-branch --force --index-filter \
        'git rm -r --cached --ignore-unmatch logs/' \
        --prune-empty --tag-name-filter cat -- --all
    
    # Remove all .log files from all commits
    git filter-branch --force --index-filter \
        'git rm --cached --ignore-unmatch "*.log"' \
        --prune-empty --tag-name-filter cat -- --all
fi

echo ""
echo "Step 3: Cleaning up..."
echo ""

# Clean up refs and garbage collect
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo ""
echo "Step 4: Verifying .gitignore..."
echo ""

# Make sure .gitignore has the right entries
if ! grep -q "^logs/" .gitignore; then
    echo "logs/" >> .gitignore
    echo "Added logs/ to .gitignore"
fi

if ! grep -q "^\*.log" .gitignore; then
    echo "*.log" >> .gitignore
    echo "Added *.log to .gitignore"
fi

echo ""
echo "================================================"
echo "✅ Large files removed from git history!"
echo "================================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Commit the .gitignore changes:"
echo "   git add .gitignore"
echo "   git commit -m 'Update .gitignore to exclude logs'"
echo ""
echo "2. Force push to GitHub (this rewrites history):"
echo "   git push origin main --force"
echo ""
echo "⚠️  Note: Anyone who has cloned your repo will need to re-clone it"
echo "   or run: git fetch origin && git reset --hard origin/main"
echo ""
