#!/bin/bash

echo "=== Cloudflare Tunnel Troubleshooting Script ==="
echo "This script will help diagnose issues with the Cloudflare tunnel setup"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
    fi
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Get the Cloudflare tunnel URL from user
echo "Please enter your Cloudflare tunnel URL (e.g., tribunal-grass-will-dual.trycloudflare.com):"
read -p "Tunnel URL: " TUNNEL_URL

if [ -z "$TUNNEL_URL" ]; then
    echo "No tunnel URL provided. Using default for testing..."
    TUNNEL_URL="tribunal-grass-will-dual.trycloudflare.com"
fi

echo ""
echo "=== Testing Cloudflare Tunnel Setup ==="
echo "Tunnel URL: https://$TUNNEL_URL"
echo ""

echo "1. Testing HTTPS connection to Cloudflare tunnel..."
if curl -s -o /dev/null -w "%{http_code}" "https://$TUNNEL_URL" | grep -q "200\|301\|302"; then
    print_status 0 "HTTPS connection to Cloudflare tunnel successful"
else
    print_status 1 "HTTPS connection to Cloudflare tunnel failed"
    echo "   This indicates the tunnel is not working or not configured properly"
    exit 1
fi

echo ""
echo "2. Testing local Flask app directly..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:5001/ | grep -q "200"; then
    print_status 0 "Flask app responds on localhost:5001"
else
    print_status 1 "Flask app does not respond on localhost:5001"
    echo "   Checking Flask app status..."
    if systemctl is-active --quiet selfie-portal; then
        print_status 0 "Selfie portal service is running"
    else
        print_status 1 "Selfie portal service is not running"
        echo "   Starting service..."
        sudo systemctl start selfie-portal
        sleep 3
        if systemctl is-active --quiet selfie-portal; then
            print_status 0 "Service started successfully"
        else
            print_status 1 "Failed to start service"
        fi
    fi
fi

echo ""
echo "3. Testing nginx proxy to Flask app..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost/selfies/ | grep -q "200"; then
    print_status 0 "Nginx proxy to Flask app works"
else
    print_status 1 "Nginx proxy to Flask app fails"
    echo "   Checking nginx configuration..."
    if nginx -t > /dev/null 2>&1; then
        print_status 0 "Nginx configuration is valid"
    else
        print_status 1 "Nginx configuration has errors"
        echo "   Errors:"
        nginx -t 2>&1
    fi
fi

echo ""
echo "4. Testing Cloudflare tunnel to selfie portal..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$TUNNEL_URL/selfies/")
if [ "$RESPONSE" = "200" ]; then
    print_status 0 "Cloudflare tunnel serves selfie portal successfully"
elif [ "$RESPONSE" = "404" ]; then
    print_status 1 "Cloudflare tunnel returns 404 for selfie portal"
    print_warning "This suggests the tunnel is working but the route is not configured properly"
elif [ "$RESPONSE" = "000" ]; then
    print_status 1 "Cloudflare tunnel connection failed"
    print_warning "Check if the tunnel is running and the URL is correct"
else
    print_warning "Cloudflare tunnel returned HTTP $RESPONSE"
    print_info "This might indicate a configuration issue"
fi

echo ""
echo "5. Testing static files through Cloudflare tunnel..."
STATIC_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$TUNNEL_URL/selfies/static/style.css")
if [ "$STATIC_RESPONSE" = "200" ]; then
    print_status 0 "Static files accessible through Cloudflare tunnel"
else
    print_status 1 "Static files not accessible through Cloudflare tunnel (HTTP $STATIC_RESPONSE)"
fi

echo ""
echo "6. Testing API endpoints through Cloudflare tunnel..."
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$TUNNEL_URL/selfies/api/selfies")
if [ "$API_RESPONSE" = "200" ]; then
    print_status 0 "API endpoints accessible through Cloudflare tunnel"
else
    print_status 1 "API endpoints not accessible through Cloudflare tunnel (HTTP $API_RESPONSE)"
fi

echo ""
echo "7. Checking nginx server_name configuration..."
if grep -q "$TUNNEL_URL" /etc/nginx/sites-available/thepub.local; then
    print_status 0 "Cloudflare hostname found in nginx configuration"
else
    print_status 1 "Cloudflare hostname NOT found in nginx configuration"
    print_info "You need to add '$TUNNEL_URL' to the server_name directive"
fi

echo ""
echo "8. Testing full page content through Cloudflare tunnel..."
PAGE_CONTENT=$(curl -s "https://$TUNNEL_URL/selfies/" | head -20)
if echo "$PAGE_CONTENT" | grep -q "Selfie Portal"; then
    print_status 0 "Selfie portal page loads correctly through Cloudflare tunnel"
elif echo "$PAGE_CONTENT" | grep -q "html"; then
    print_warning "Page loads but may not be the correct content"
    echo "   First 20 lines of response:"
    echo "$PAGE_CONTENT"
else
    print_status 1 "Page does not load correctly through Cloudflare tunnel"
    echo "   Response: $PAGE_CONTENT"
fi

echo ""
echo "9. Checking for common issues..."

# Check if cloudflared is running
if pgrep -f cloudflared > /dev/null; then
    print_status 0 "Cloudflared tunnel process is running"
else
    print_status 1 "Cloudflared tunnel process is not running"
    print_info "You may need to start the tunnel manually or set it up as a service"
fi

# Check if the tunnel is configured correctly
if [ -f ~/.cloudflared/config.yml ]; then
    print_status 0 "Cloudflared configuration file exists"
else
    print_warning "Cloudflared configuration file not found"
    print_info "You may need to run 'cloudflared tunnel login' and create a tunnel"
fi

echo ""
echo "10. Testing camera access requirements..."
print_info "Camera access requires HTTPS and proper hostname configuration"
print_info "The Cloudflare tunnel should provide the necessary HTTPS access"

echo ""
echo "=== Summary ==="
echo "If you're seeing a blank white page, the most likely causes are:"
echo "1. Flask app not running or not accessible"
echo "2. Nginx configuration issues"
echo "3. URL path mismatches in the application"
echo "4. Cloudflare tunnel not properly configured"

echo ""
echo "=== Next Steps ==="
echo "1. If the tunnel is working but returning 404, check nginx configuration"
echo "2. If the tunnel is working but showing blank page, check Flask app logs"
echo "3. If static files are not loading, verify file paths and permissions"
echo "4. Test camera access on an iOS device using the HTTPS URL"

echo ""
echo "=== Useful Commands ==="
echo "Check Flask app logs: sudo journalctl -u selfie-portal -f"
echo "Check nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "Test local access: curl http://localhost/selfies/"
echo "Test tunnel access: curl https://$TUNNEL_URL/selfies/"
echo "Restart services: sudo systemctl restart selfie-portal && sudo systemctl reload nginx"

echo ""
echo "=== Camera Testing ==="
echo "To test camera access:"
echo "1. Open https://$TUNNEL_URL/selfies/ on an iOS device"
echo "2. Allow camera permissions when prompted"
echo "3. The camera should initialize and show a live preview"
echo "4. If camera doesn't work, check browser console for errors" 