#!/bin/bash

# Serve the demo.html file using a simple HTTP server
# This avoids CORS issues when opening HTML files directly

echo "Starting HTTP server for demo.html..."
echo ""
echo "Open your browser and go to:"
echo "  http://localhost:8000/demo.html"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

cd "$(dirname "$0")/.."

# Try Python 3 first, then Python 2, then use a simple Node.js server if available
if command -v python3 &> /dev/null; then
    python3 -m http.server 8000
elif command -v python &> /dev/null; then
    python -m SimpleHTTPServer 8000
elif command -v node &> /dev/null && command -v npx &> /dev/null; then
    npx http-server -p 8000
else
    echo "Error: Need Python or Node.js to run HTTP server"
    echo "Install Python: brew install python3"
    exit 1
fi


