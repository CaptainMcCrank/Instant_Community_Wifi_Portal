#!/bin/bash

echo "=== Fixing CSS Filename Mismatch ==="
echo "Renaming styles.css to style.css to match template expectations"
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

echo "1. Checking current files..."
ls -la /var/www/thepub.local/apps/selfies/static/

echo ""
echo "2. Renaming styles.css to style.css..."
if cd /var/www/thepub.local/apps/selfies/static && sudo mv styles.css style.css; then
    print_status 0 "File renamed successfully"
else
    print_status 1 "Failed to rename file"
    exit 1
fi

echo ""
echo "3. Verifying the rename..."
ls -la /var/www/thepub.local/apps/selfies/static/

echo ""
echo "4. Testing static file access..."
echo "   Testing /selfies/static/style.css:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost/selfies/static/style.css | grep -q "200"; then
    print_status 0 "style.css is now accessible"
else
    print_status 1 "style.css is still not accessible"
    echo "   HTTP response:"
    curl -I http://localhost/selfies/static/style.css 2>/dev/null | head -3
fi

echo ""
echo "5. Testing thepub.local domain..."
if curl -s -o /dev/null -w "%{http_code}" http://thepub.local/selfies/static/style.css | grep -q "200"; then
    print_status 0 "thepub.local style.css is now accessible"
else
    print_status 1 "thepub.local style.css is still not accessible"
fi

echo ""
echo "6. Testing the full page..."
echo "   Testing main page load:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost/selfies/ | grep -q "200"; then
    print_status 0 "Main page loads successfully"
else
    print_status 1 "Main page still has issues"
fi

echo ""
echo "7. Testing thepub.local main page..."
if curl -s -o /dev/null -w "%{http_code}" http://thepub.local/selfies/ | grep -q "200"; then
    print_status 0 "thepub.local main page loads successfully"
else
    print_status 1 "thepub.local main page still has issues"
fi

echo ""
echo "=== Fix Complete ==="
echo "The CSS filename has been corrected."
echo "Your selfie portal should now load properly with styling."
echo ""
echo "Test in your browser: http://thepub.local/selfies"
echo "Or from other devices on the network: http://10.42.0.1/selfies" 