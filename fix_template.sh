#!/bin/bash

echo "=== Fixing HTML Template ==="
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
echo "2. Updating CSS reference..."
if sudo sed -i 's|href="{{ url_for('\''static'\'', filename='\''style.css'\'') }}"|href="/selfies/static/style.css"|g' /var/www/thepub.local/apps/selfies/templates/index.html; then
    print_status 0 "CSS reference updated"
else
    print_status 1 "Failed to update CSS reference"
fi

echo ""
echo "3. Updating JavaScript reference..."
if sudo sed -i 's|src="{{ url_for('\''static'\'', filename='\''upload.js'\'') }}"|src="/selfies/static/upload.js"|g' /var/www/thepub.local/apps/selfies/templates/index.html; then
    print_status 0 "JavaScript reference updated"
else
    print_status 1 "Failed to update JavaScript reference"
fi

echo ""
echo "4. Verifying changes..."
if grep -q "/selfies/static/style.css" /var/www/thepub.local/apps/selfies/templates/index.html; then
    print_status 0 "CSS path is correct"
else
    print_status 1 "CSS path is still wrong"
fi

if grep -q "/selfies/static/upload.js" /var/www/thepub.local/apps/selfies/templates/index.html; then
    print_status 0 "JavaScript path is correct"
else
    print_status 1 "JavaScript path is still wrong"
fi

echo ""
echo "5. Testing the updated page..."
if curl -s http://localhost/selfies/ | grep -q "/selfies/static/upload.js"; then
    print_status 0 "Page now serves correct JavaScript path"
else
    print_status 1 "Page still serves wrong JavaScript path"
fi

echo ""
echo "6. Testing static file access..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost/selfies/static/upload.js | grep -q "200"; then
    print_status 0 "JavaScript file is accessible"
else
    print_status 1 "JavaScript file is not accessible"
fi

echo ""
echo "=== Fix Complete ==="
echo "The template has been updated to use the correct static file paths."
echo ""
echo "Now test your browser:"
echo "1. Clear cache (Ctrl+F5)"
echo "2. Visit: http://10.42.0.1/selfies/"
echo "3. Check console for 'Camera support detected' message"
echo ""
echo "The JavaScript should now load from:"
echo "  http://10.42.0.1/selfies/static/upload.js" 