#!/bin/bash

echo "=== Fixing Camera Issue ==="
echo "This script will fix the navigator.mediaDevices undefined error"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
    fi
}

echo "1. Checking if thepub.local directory exists..."
if [ -d "/var/www/thepub.local" ]; then
    print_status 0 "thepub.local directory exists"
else
    print_status 1 "thepub.local directory does not exist"
    echo "   Creating directory structure..."
    sudo mkdir -p /var/www/thepub.local/apps/selfies/static
    sudo mkdir -p /var/www/thepub.local/apps/selfies/data/uploads
    sudo mkdir -p /var/www/thepub.local/apps/selfies/templates
fi

echo ""
echo "2. Checking if selfie files exist in ansibledest.local..."
if [ -d "/var/www/ansibledest.local/apps/selfies" ]; then
    print_status 0 "ansibledest.local selfies directory exists"
    echo "   Copying files to thepub.local..."
    sudo cp -r /var/www/ansibledest.local/apps/selfies/* /var/www/thepub.local/apps/selfies/
    sudo chown -R www-data:www-data /var/www/thepub.local/apps/selfies/
    sudo chmod -R 755 /var/www/thepub.local/apps/selfies/
else
    print_status 1 "ansibledest.local selfies directory does not exist"
    echo "   Please ensure the selfie portal is properly installed"
    exit 1
fi

echo ""
echo "3. Testing nginx configuration..."
if sudo nginx -t; then
    print_status 0 "Nginx configuration is valid"
else
    print_status 1 "Nginx configuration has errors"
    echo "   Errors:"
    sudo nginx -t 2>&1
    exit 1
fi

echo ""
echo "4. Reloading nginx..."
if sudo systemctl reload nginx; then
    print_status 0 "Nginx reloaded successfully"
else
    print_status 1 "Failed to reload nginx"
    exit 1
fi

echo ""
echo "5. Testing static file access..."
echo "   Testing http://localhost/selfies/static/upload.js:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost/selfies/static/upload.js | grep -q "200"; then
    print_status 0 "upload.js is accessible"
else
    print_status 1 "upload.js is not accessible"
    echo "   Response:"
    curl -I http://localhost/selfies/static/upload.js 2>/dev/null | head -5
fi

echo ""
echo "6. Testing http://localhost/selfies/static/style.css:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost/selfies/static/style.css | grep -q "200"; then
    print_status 0 "style.css is accessible"
else
    print_status 1 "style.css is not accessible"
    echo "   Response:"
    curl -I http://localhost/selfies/static/style.css 2>/dev/null | head -5
fi

echo ""
echo "7. Testing IP address access..."
echo "   Testing http://10.42.0.1/selfies/static/upload.js:"
if curl -s -o /dev/null -w "%{http_code}" http://10.42.0.1/selfies/static/upload.js | grep -q "200"; then
    print_status 0 "IP address upload.js is accessible"
else
    print_status 1 "IP address upload.js is not accessible"
fi

echo ""
echo "8. Testing main selfie portal page..."
if curl -s -o /dev/null -w "%{http_code}" http://10.42.0.1/selfies/ | grep -q "200"; then
    print_status 0 "Main selfie portal page loads successfully"
else
    print_status 1 "Main selfie portal page has issues"
    echo "   Response:"
    curl -I http://10.42.0.1/selfies/ 2>/dev/null | head -5
fi

echo ""
echo "9. Checking file permissions..."
echo "   upload.js permissions:"
ls -la /var/www/thepub.local/apps/selfies/static/upload.js 2>/dev/null || echo "   File not found"
echo "   style.css permissions:"
ls -la /var/www/thepub.local/apps/selfies/static/style.css 2>/dev/null || echo "   File not found"

echo ""
echo "10. Testing that /static/ path is NOT accessible (should be 404)..."
if curl -s -o /dev/null -w "%{http_code}" http://10.42.0.1/static/upload.js | grep -q "404"; then
    print_status 0 "/static/ path correctly returns 404"
else
    print_status 1 "/static/ path is still accessible (this is wrong)"
fi

echo ""
echo "=== Fix Complete ==="
echo "The camera issue should now be resolved. Please:"
echo ""
echo "1. Clear your browser cache (Ctrl+F5 or Cmd+Shift+R)"
echo "2. Refresh the page: http://10.42.0.1/selfies/"
echo "3. Check the browser console for any remaining errors"
echo ""
echo "The JavaScript should now load from:"
echo "  http://10.42.0.1/selfies/static/upload.js"
echo ""
echo "If you still see issues, check the browser console and look for:"
echo "  - 'Camera support detected' message"
echo "  - Any remaining navigator.mediaDevices errors"
echo ""
echo "To check logs:"
echo "  sudo journalctl -u selfie-portal -f"
echo "  sudo tail -f /var/log/nginx/error.log" 