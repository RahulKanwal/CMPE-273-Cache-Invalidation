#!/bin/bash

# Simple Fix for Git Large Log Files
# This uses BFG Repo-Cleaner or git filter-branch

echo "================================================"
echo "Simple Fix: Remove Large Log Files from Git"
echo "================================================"
echo ""

# Check current status
echo "Checking for large files in git history..."
echo ""

# Method 1: Quick fix using filter-branch (works everywhere)
echo "Removing log files from git history..."
echo ""

# Remove logs directory and all .log files from history
git filter-branch --force --index-filter \
  'git rm -rf --cached --ignore-unmatch logs/ eds-lite/logs/ *.log **/*.log' \
  --prune-empty --tag-name-filter cat -- --all

echo ""
echo "Cleaning up git repository..."
echo ""

# Force garbage collection
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo ""
echo "================================================"
echo "✅ Done! Log files removed from git history"
echo "================================================"
echo ""
echo "Now you can push:"
echo "  git push origin main --force"
echo ""
