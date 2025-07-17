#!/bin/bash

echo "=== Testing Template and Static Files ==="
echo ""

echo "1. Checking if the HTML template was updated..."
if grep -q "/selfies/static/style.css" /var/www/thepub.local/apps/selfies/templates/index.html; then
    echo "✓ Template has correct CSS path"
else
    echo "✗ Template still has old CSS path"
fi

if grep -q "/selfies/static/upload.js" /var/www/thepub.local/apps/selfies/templates/index.html; then
    echo "✓ Template has correct JS path"
else
    echo "✗ Template still has old JS path"
fi

echo ""
echo "2. Testing what the Flask app serves for /static/upload.js:"
curl -v http://localhost/static/upload.js 2>&1 | head -10

echo ""
echo "3. Testing what the Flask app serves for /selfies/static/upload.js:"
curl -v http://localhost/selfies/static/upload.js 2>&1 | head -10

echo ""
echo "4. Testing the main page HTML source:"
curl -s http://localhost/selfies/ | grep -E "(style\.css|upload\.js)" | head -5

echo ""
echo "5. If the template wasn't updated, we need to copy the fixed version." 