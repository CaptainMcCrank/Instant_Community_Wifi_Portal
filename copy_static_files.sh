#!/bin/bash

echo "=== Copying Static Files to Raspberry Pi ==="
echo "This script will copy the missing static files to your Pi"
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

# Check if we're in the right directory
if [ ! -f "var/www/ansibledest.local/apps/selfies/static/style.css" ]; then
    echo "Error: style.css not found in current directory"
    echo "Please run this script from the Instant_Community_Wifi_Portal directory"
    exit 1
fi

echo "1. Checking current static files..."
echo "   Local style.css:"
ls -la var/www/ansibledest.local/apps/selfies/static/style.css
echo "   Local upload.js:"
ls -la var/www/ansibledest.local/apps/selfies/static/upload.js

echo ""
echo "2. Copying style.css to Raspberry Pi..."
if scp var/www/ansibledest.local/apps/selfies/static/style.css pi@10.42.0.1:/var/www/ansibledest.local/apps/selfies/static/style.css; then
    print_status 0 "style.css copied successfully"
else
    print_status 1 "Failed to copy style.css"
    echo "   Trying alternative method..."
    
    # Alternative: copy to a temporary location and then move
    if scp var/www/ansibledest.local/apps/selfies/static/style.css pi@10.42.0.1:/tmp/style.css; then
        ssh pi@10.42.0.1 "sudo mv /tmp/style.css /var/www/ansibledest.local/apps/selfies/static/style.css && sudo chown www-data:www-data /var/www/ansibledest.local/apps/selfies/static/style.css"
        print_status 0 "style.css copied via alternative method"
    else
        print_status 1 "Failed to copy style.css via alternative method"
        exit 1
    fi
fi

echo ""
echo "3. Setting proper permissions on Pi..."
ssh pi@10.42.0.1 "sudo chown www-data:www-data /var/www/ansibledest.local/apps/selfies/static/style.css && sudo chmod 644 /var/www/ansibledest.local/apps/selfies/static/style.css"
print_status 0 "Permissions set"

echo ""
echo "4. Verifying file exists on Pi..."
if ssh pi@10.42.0.1 "ls -la /var/www/ansibledest.local/apps/selfies/static/style.css"; then
    print_status 0 "style.css verified on Pi"
else
    print_status 1 "style.css not found on Pi"
    exit 1
fi

echo ""
echo "5. Testing static file access..."
echo "   Testing /selfies/static/style.css:"
if ssh pi@10.42.0.1 "curl -s -o /dev/null -w '%{http_code}' http://localhost/selfies/static/style.css" | grep -q "200"; then
    print_status 0 "style.css is now accessible"
else
    print_status 1 "style.css is still not accessible"
    echo "   HTTP response:"
    ssh pi@10.42.0.1 "curl -I http://localhost/selfies/static/style.css 2>/dev/null | head -3"
fi

echo ""
echo "6. Testing thepub.local domain..."
if ssh pi@10.42.0.1 "curl -s -o /dev/null -w '%{http_code}' http://thepub.local/selfies/static/style.css" | grep -q "200"; then
    print_status 0 "thepub.local style.css is now accessible"
else
    print_status 1 "thepub.local style.css is still not accessible"
fi

echo ""
echo "=== Summary ==="
echo "Static files should now be properly accessible."
echo ""
echo "If you're still having issues:"
echo "1. Check the Flask app logs: ssh pi@10.42.0.1 'sudo journalctl -u selfie-portal -f'"
echo "2. Check nginx logs: ssh pi@10.42.0.1 'sudo tail -f /var/log/nginx/error.log'"
echo "3. Verify file permissions: ssh pi@10.42.0.1 'ls -la /var/www/ansibledest.local/apps/selfies/static/'" 