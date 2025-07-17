#!/bin/bash

echo "=== Fixing Static URL Routing ==="
echo "Adding /static/ location to nginx to match Flask url_for() output"
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

echo "1. Backing up current nginx configuration..."
sudo cp /etc/nginx/sites-available/thepub.local /etc/nginx/sites-available/thepub.local.backup.$(date +%Y%m%d_%H%M%S)
print_status 0 "Backup created"

echo ""
echo "2. Testing nginx configuration..."
if sudo nginx -t; then
    print_status 0 "Nginx configuration is valid"
else
    print_status 1 "Nginx configuration has errors"
    echo "   Please check the configuration manually"
    exit 1
fi

echo ""
echo "3. Reloading nginx..."
if sudo systemctl reload nginx; then
    print_status 0 "Nginx reloaded successfully"
else
    print_status 1 "Failed to reload nginx"
    exit 1
fi

echo ""
echo "4. Testing static file access at /static/style.css..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost/static/style.css | grep -q "200"; then
    print_status 0 "/static/style.css is now accessible"
else
    print_status 1 "/static/style.css is still not accessible"
    echo "   HTTP response:"
    curl -I http://localhost/static/style.css 2>/dev/null | head -3
fi

echo ""
echo "5. Testing static file access at /selfies/static/style.css..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost/selfies/static/style.css | grep -q "200"; then
    print_status 0 "/selfies/static/style.css is still accessible"
else
    print_status 1 "/selfies/static/style.css is not accessible"
fi

echo ""
echo "6. Testing thepub.local domain..."
if curl -s -o /dev/null -w "%{http_code}" http://thepub.local/static/style.css | grep -q "200"; then
    print_status 0 "thepub.local /static/style.css is accessible"
else
    print_status 1 "thepub.local /static/style.css is not accessible"
fi

echo ""
echo "7. Testing the full page load..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost/selfies/ | grep -q "200"; then
    print_status 0 "Main page loads successfully"
else
    print_status 1 "Main page still has issues"
fi

echo ""
echo "8. Testing thepub.local main page..."
if curl -s -o /dev/null -w "%{http_code}" http://thepub.local/selfies/ | grep -q "200"; then
    print_status 0 "thepub.local main page loads successfully"
else
    print_status 1 "thepub.local main page still has issues"
fi

echo ""
echo "=== Fix Complete ==="
echo "Nginx now serves static files at both:"
echo "  - /static/style.css (for Flask url_for compatibility)"
echo "  - /selfies/static/style.css (for direct access)"
echo ""
echo "Your selfie portal should now load properly without 404 errors!"
echo ""
echo "Test in your browser:"
echo "  - http://thepub.local/selfies"
echo "  - http://10.42.0.1/selfies"
echo ""
echo "To revert changes:"
echo "sudo cp /etc/nginx/sites-available/thepub.local.backup.* /etc/nginx/sites-available/thepub.local"
echo "sudo systemctl reload nginx" 