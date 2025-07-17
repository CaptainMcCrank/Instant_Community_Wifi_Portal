#!/bin/bash

echo "=== Testing Static File Access ==="
echo ""

# Test direct Flask app access
echo "1. Testing Flask app directly on localhost:5001"
echo "   Testing /static/style.css:"
curl -I http://localhost:5001/static/style.css 2>/dev/null | head -5

echo ""
echo "   Testing /static/upload.js:"
curl -I http://localhost:5001/static/upload.js 2>/dev/null | head -5

echo ""
echo "2. Testing through nginx proxy"
echo "   Testing /selfies/static/style.css:"
curl -I http://localhost/selfies/static/style.css 2>/dev/null | head -5

echo ""
echo "   Testing /selfies/static/upload.js:"
curl -I http://localhost/selfies/static/upload.js 2>/dev/null | head -5

echo ""
echo "3. Testing with thepub.local domain"
echo "   Testing http://thepub.local/selfies/static/style.css:"
curl -I http://thepub.local/selfies/static/style.css 2>/dev/null | head -5

echo ""
echo "4. Checking if static files exist on disk:"
if [ -f "/var/www/thepub.local/apps/selfies/static/style.css" ]; then
    echo "   ✓ style.css exists"
    ls -la /var/www/thepub.local/apps/selfies/static/style.css
else
    echo "   ✗ style.css missing"
fi

if [ -f "/var/www/thepub.local/apps/selfies/static/upload.js" ]; then
    echo "   ✓ upload.js exists"
    ls -la /var/www/thepub.local/apps/selfies/static/upload.js
else
    echo "   ✗ upload.js missing"
fi

echo ""
echo "5. Checking Flask app logs for static file errors:"
sudo journalctl -u selfie-portal --no-pager -n 20 | grep -i "static\|error" | tail -5 