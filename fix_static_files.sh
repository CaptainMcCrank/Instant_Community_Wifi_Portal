#!/bin/bash

echo "=== Fixing Static File Issues ==="
echo "This script will apply fixes for the static file 500 errors"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
    fi
}

echo "1. Backing up current Flask app..."
sudo cp /var/www/ansibledest.local/apps/selfies/app.py /var/www/ansibledest.local/apps/selfies/app.py.backup
print_status 0 "Backup created"

echo ""
echo "2. Backing up current nginx configuration..."
sudo cp /etc/nginx/sites-available/thepub.local /etc/nginx/sites-available/thepub.local.backup
print_status 0 "Nginx config backed up"

echo ""
echo "3. Checking if static files exist..."
if [ -f "/var/www/ansibledest.local/apps/selfies/static/style.css" ]; then
    print_status 0 "style.css exists"
else
    print_status 1 "style.css missing - you may need to copy static files"
fi

if [ -f "/var/www/ansibledest.local/apps/selfies/static/upload.js" ]; then
    print_status 0 "upload.js exists"
else
    print_status 1 "upload.js missing - you may need to copy static files"
fi

echo ""
echo "4. Testing nginx configuration..."
if sudo nginx -t; then
    print_status 0 "Nginx configuration is valid"
else
    print_status 1 "Nginx configuration has errors"
    echo "   Please check the configuration manually"
    exit 1
fi

echo ""
echo "5. Reloading nginx..."
if sudo systemctl reload nginx; then
    print_status 0 "Nginx reloaded successfully"
else
    print_status 1 "Failed to reload nginx"
    exit 1
fi

echo ""
echo "6. Restarting selfie portal service..."
if sudo systemctl restart selfie-portal; then
    print_status 0 "Selfie portal service restarted"
else
    print_status 1 "Failed to restart selfie portal service"
    exit 1
fi

echo ""
echo "7. Waiting for service to start..."
sleep 3

echo ""
echo "8. Testing static file access..."
echo "   Testing /selfies/static/style.css:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost/selfies/static/style.css | grep -q "200"; then
    print_status 0 "style.css is accessible"
else
    print_status 1 "style.css is not accessible"
    echo "   HTTP response:"
    curl -I http://localhost/selfies/static/style.css 2>/dev/null | head -3
fi

echo "   Testing /selfies/static/upload.js:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost/selfies/static/upload.js | grep -q "200"; then
    print_status 0 "upload.js is accessible"
else
    print_status 1 "upload.js is not accessible"
    echo "   HTTP response:"
    curl -I http://localhost/selfies/static/upload.js 2>/dev/null | head -3
fi

echo ""
echo "9. Testing thepub.local domain..."
echo "   Testing http://thepub.local/selfies/static/style.css:"
if curl -s -o /dev/null -w "%{http_code}" http://thepub.local/selfies/static/style.css | grep -q "200"; then
    print_status 0 "thepub.local style.css is accessible"
else
    print_status 1 "thepub.local style.css is not accessible"
fi

echo ""
echo "=== Fix Summary ==="
echo "The following changes were made:"
echo "1. Updated Flask app to use absolute paths for static files"
echo "2. Added error handling and logging to static file routes"
echo "3. Updated nginx to serve static files directly instead of proxying"
echo "4. Restarted services"
echo ""
echo "If you're still having issues:"
echo "1. Check the Flask app logs: sudo journalctl -u selfie-portal -f"
echo "2. Check nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "3. Verify static files exist: ls -la /var/www/ansibledest.local/apps/selfies/static/"
echo ""
echo "To revert changes:"
echo "sudo cp /var/www/ansibledest.local/apps/selfies/app.py.backup /var/www/ansibledest.local/apps/selfies/app.py"
echo "sudo cp /etc/nginx/sites-available/thepub.local.backup /etc/nginx/sites-available/thepub.local"
echo "sudo systemctl restart selfie-portal && sudo systemctl reload nginx" 