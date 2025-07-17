#!/bin/bash

echo "=== Fixing Duplicate JavaScript Reference ==="
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

echo "1. Backing up current template..."
if sudo cp /var/www/thepub.local/apps/selfies/templates/index.html /var/www/thepub.local/apps/selfies/templates/index.html.backup.$(date +%Y%m%d_%H%M%S); then
    print_status 0 "Template backup created"
else
    print_status 1 "Failed to create backup"
    exit 1
fi

echo ""
echo "2. Checking for duplicate JavaScript references..."
echo "   Current JavaScript references in template:"
grep -n "upload.js" /var/www/thepub.local/apps/selfies/templates/index.html

echo ""
echo "3. Removing the old /static/upload.js reference..."
if sudo sed -i '/src="\/static\/upload.js"/d' /var/www/thepub.local/apps/selfies/templates/index.html; then
    print_status 0 "Old JavaScript reference removed"
else
    print_status 1 "Failed to remove old JavaScript reference"
fi

echo ""
echo "4. Removing duplicate /selfies/static/upload.js reference..."
# Remove the second occurrence of the /selfies/static/upload.js script tag
if sudo sed -i '/src="\/selfies\/static\/upload.js"/{N;N;d}' /var/www/thepub.local/apps/selfies/templates/index.html; then
    print_status 0 "Duplicate JavaScript reference removed"
else
    print_status 1 "Failed to remove duplicate JavaScript reference"
fi

echo ""
echo "5. Verifying only one reference remains..."
echo "   Remaining JavaScript references:"
grep -n "upload.js" /var/www/thepub.local/apps/selfies/templates/index.html

echo ""
echo "6. Testing the updated page..."
if curl -s http://localhost/selfies/ | grep -c "upload.js" | grep -q "1"; then
    print_status 0 "Page now has only one JavaScript reference"
else
    print_status 1 "Page still has multiple JavaScript references"
    echo "   Found $(curl -s http://localhost/selfies/ | grep -c "upload.js") references"
fi

echo ""
echo "7. Verifying the correct path is used..."
if curl -s http://localhost/selfies/ | grep -q "/selfies/static/upload.js"; then
    print_status 0 "Correct JavaScript path is used"
else
    print_status 1 "Wrong JavaScript path is still used"
fi

echo ""
echo "8. Testing that /static/upload.js no longer exists in HTML..."
if curl -s http://localhost/selfies/ | grep -q "/static/upload.js"; then
    print_status 1 "Old path still exists in HTML"
else
    print_status 0 "Old path removed from HTML"
fi

echo ""
echo "=== Fix Complete ==="
echo "The duplicate JavaScript reference has been removed."
echo ""
echo "Now test your browser:"
echo "1. Clear cache (Ctrl+F5)"
echo "2. Visit: http://10.42.0.1/selfies/"
echo "3. Check console for 'Camera support detected' message"
echo ""
echo "The page should now load only:"
echo "  /selfies/static/upload.js" 