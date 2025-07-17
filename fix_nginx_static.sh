#!/bin/bash

echo "=== Fixing Nginx Static Path Issue ==="
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

echo "1. Backing up current nginx configuration..."
if sudo cp /etc/nginx/sites-available/thepub.local /etc/nginx/sites-available/thepub.local.backup.$(date +%Y%m%d_%H%M%S); then
    print_status 0 "Backup created"
else
    print_status 1 "Failed to create backup"
    exit 1
fi

echo ""
echo "2. Checking current nginx configuration..."
echo "   Current /static/ location blocks:"
sudo grep -n "location /static/" /etc/nginx/sites-available/thepub.local || echo "   No /static/ location found"

echo ""
echo "3. Removing global /static/ location block..."
# Create a temporary file with the corrected configuration
sudo sed '/^[[:space:]]*location \/static\/ {$/,/^[[:space:]]*}$/d' /etc/nginx/sites-available/thepub.local > /tmp/thepub.local.fixed

# Check if the sed command worked
if [ $? -eq 0 ]; then
    print_status 0 "Global /static/ location removed"
    sudo cp /tmp/thepub.local.fixed /etc/nginx/sites-available/thepub.local
    sudo chown root:root /etc/nginx/sites-available/thepub.local
    sudo chmod 644 /etc/nginx/sites-available/thepub.local
else
    print_status 1 "Failed to remove /static/ location"
    exit 1
fi

echo ""
echo "4. Testing nginx configuration..."
if sudo nginx -t; then
    print_status 0 "Nginx configuration is valid"
else
    print_status 1 "Nginx configuration has errors"
    echo "   Errors:"
    sudo nginx -t 2>&1
    echo ""
    echo "   Restoring backup..."
    sudo cp /etc/nginx/sites-available/thepub.local.backup.* /etc/nginx/sites-available/thepub.local
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
echo "6. Testing that /static/ path now returns 404..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost/static/upload.js | grep -q "404"; then
    print_status 0 "/static/ path correctly returns 404"
else
    print_status 1 "/static/ path is still accessible"
    echo "   Response code: $(curl -s -o /dev/null -w "%{http_code}" http://localhost/static/upload.js)"
fi

echo ""
echo "7. Testing that /selfies/static/ path still works..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost/selfies/static/upload.js | grep -q "200"; then
    print_status 0 "/selfies/static/ path still works"
else
    print_status 1 "/selfies/static/ path is broken"
fi

echo ""
echo "8. Testing IP address access..."
if curl -s -o /dev/null -w "%{http_code}" http://10.42.0.1/selfies/static/upload.js | grep -q "200"; then
    print_status 0 "IP address access works"
else
    print_status 1 "IP address access broken"
fi

echo ""
echo "=== Fix Complete ==="
echo "The nginx configuration has been updated to:"
echo "  - Remove the global /static/ location block"
echo "  - Keep only the /selfies/static/ location block"
echo ""
echo "Now test your browser:"
echo "1. Clear cache (Ctrl+F5)"
echo "2. Visit: http://10.42.0.1/selfies/"
echo "3. Check console for 'Camera support detected' message" 