#!/bin/bash

echo "=== Restarting Flask App ==="
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

echo "1. Checking current Flask app status..."
if systemctl is-active --quiet selfie-portal; then
    print_status 0 "Flask app is running"
else
    print_status 1 "Flask app is not running"
fi

echo ""
echo "2. Restarting Flask app..."
if sudo systemctl restart selfie-portal; then
    print_status 0 "Flask app restarted successfully"
else
    print_status 1 "Failed to restart Flask app"
    exit 1
fi

echo ""
echo "3. Waiting for Flask app to start..."
sleep 3

echo ""
echo "4. Checking Flask app status..."
if systemctl is-active --quiet selfie-portal; then
    print_status 0 "Flask app is running"
else
    print_status 1 "Flask app failed to start"
    echo "   Checking logs:"
    sudo journalctl -u selfie-portal --no-pager -l | tail -10
    exit 1
fi

echo ""
echo "5. Testing Flask app directly..."
if curl -s http://localhost:5001/ > /dev/null; then
    print_status 0 "Flask app responds on port 5001"
else
    print_status 1 "Flask app does not respond on port 5001"
fi

echo ""
echo "6. Testing nginx proxy..."
if curl -s http://localhost/selfies/ > /dev/null; then
    print_status 0 "Nginx proxy works"
else
    print_status 1 "Nginx proxy does not work"
fi

echo ""
echo "7. Testing JavaScript references after restart..."
echo "   Number of upload.js references:"
curl -s http://localhost/selfies/ | grep -c "upload.js"

echo ""
echo "8. Checking specific JavaScript paths..."
echo "   upload.js references found:"
curl -s http://localhost/selfies/ | grep "upload.js"

echo ""
echo "=== Restart Complete ==="
echo "The Flask app has been restarted and should now use the updated template."
echo ""
echo "Now test your browser:"
echo "1. Clear cache (Ctrl+F5)"
echo "2. Visit: http://10.42.0.1/selfies/"
echo "3. Check console for 'Camera support detected' message" 