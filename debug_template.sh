#!/bin/bash

echo "=== Debugging Template Issue ==="
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

echo "1. Checking template file content..."
echo "   Template file: /var/www/thepub.local/apps/selfies/templates/index.html"
echo "   File size: $(ls -lh /var/www/thepub.local/apps/selfies/templates/index.html | awk '{print $5}')"
echo "   Last modified: $(ls -l /var/www/thepub.local/apps/selfies/templates/index.html | awk '{print $6, $7, $8}')"

echo ""
echo "2. Checking for JavaScript references in template file..."
echo "   Lines with 'upload.js':"
grep -n "upload.js" /var/www/thepub.local/apps/selfies/templates/index.html

echo ""
echo "3. Checking if there are multiple template files..."
echo "   All template files:"
find /var/www/thepub.local/apps/selfies/templates/ -name "*.html" -exec ls -la {} \;

echo ""
echo "4. Testing what Flask serves directly..."
echo "   Testing Flask app on port 5001:"
curl -s http://localhost:5001/ | grep -n "upload.js" || echo "   No upload.js references found"

echo ""
echo "5. Testing what nginx serves..."
echo "   Testing nginx proxy:"
curl -s http://localhost/selfies/ | grep -n "upload.js"

echo ""
echo "6. Checking Flask app configuration..."
echo "   Flask app template folder:"
grep -r "template_folder\|STATIC_FOLDER" /var/www/thepub.local/apps/selfies/app.py || echo "   No template folder config found"

echo ""
echo "7. Checking if Flask app needs restart..."
echo "   Flask app process:"
ps aux | grep "app.py" | grep -v grep || echo "   No Flask app process found"

echo ""
echo "8. Testing with different user agent..."
echo "   Testing with curl user agent:"
curl -s -H "User-Agent: curl/7.88.1" http://localhost/selfies/ | grep -c "upload.js"

echo ""
echo "9. Checking nginx cache headers..."
echo "   Nginx response headers:"
curl -I http://localhost/selfies/ 2>/dev/null | grep -E "(Cache-Control|ETag|Last-Modified)"

echo ""
echo "=== Debug Complete ==="
echo "This will help identify why the template and served content differ." 