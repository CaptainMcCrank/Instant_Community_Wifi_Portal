#!/bin/bash

echo "=== Checking Nginx Configuration ==="
echo ""

echo "1. Current nginx configuration for thepub.local:"
echo "----------------------------------------"
sudo cat /etc/nginx/sites-available/thepub.local
echo "----------------------------------------"

echo ""
echo "2. Looking for /static/ location blocks:"
sudo grep -n "location /static/" /etc/nginx/sites-available/thepub.local || echo "   No /static/ location found"

echo ""
echo "3. Looking for /selfies/static/ location blocks:"
sudo grep -n "location /selfies/static/" /etc/nginx/sites-available/thepub.local || echo "   No /selfies/static/ location found"

echo ""
echo "4. Testing current behavior:"
echo "   /static/upload.js response:"
curl -s -o /dev/null -w "%{http_code}" http://localhost/static/upload.js
echo ""

echo "   /selfies/static/upload.js response:"
curl -s -o /dev/null -w "%{http_code}" http://localhost/selfies/static/upload.js
echo ""

echo ""
echo "5. If /static/ returns 200, we need to remove that location block."
echo "   If /selfies/static/ returns 200, that's correct." 