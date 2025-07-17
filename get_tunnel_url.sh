#!/bin/bash

echo "=== Getting Cloudflare Tunnel URL ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Get the tunnel name from the config file
if [ -f ~/.cloudflared/config.yml ]; then
    TUNNEL_NAME=$(grep "hostname:" ~/.cloudflared/config.yml | head -1 | sed 's/.*hostname: //' | sed 's/\.trycloudflare\.com//')
    if [ -n "$TUNNEL_NAME" ]; then
        TUNNEL_URL="$TUNNEL_NAME.trycloudflare.com"
        print_status 0 "Found tunnel URL: $TUNNEL_URL"
    else
        print_status 1 "Could not extract tunnel URL from config"
        exit 1
    fi
else
    print_status 1 "No cloudflared config file found"
    exit 1
fi

echo ""
echo "1. Testing tunnel connectivity..."
sleep 3

# Test the tunnel
if curl -s -o /dev/null -w "%{http_code}" "https://$TUNNEL_URL" | grep -q "200\|301\|302"; then
    print_status 0 "Tunnel is working!"
else
    print_warning "Tunnel test failed - it might still be starting up"
    print_info "Let's wait a bit more and try again..."
    sleep 5
    
    if curl -s -o /dev/null -w "%{http_code}" "https://$TUNNEL_URL" | grep -q "200\|301\|302"; then
        print_status 0 "Tunnel is now working!"
    else
        print_status 1 "Tunnel is still not responding"
        print_info "Checking tunnel status..."
        
        # Check if tunnel process is still running
        if pgrep -f cloudflared > /dev/null; then
            print_status 0 "Tunnel process is running"
            print_info "Tunnel might need more time to fully establish"
        else
            print_status 1 "Tunnel process is not running"
            print_info "You may need to restart the tunnel"
        fi
    fi
fi

echo ""
echo "2. Testing selfie portal through tunnel..."
if curl -s -o /dev/null -w "%{http_code}" "https://$TUNNEL_URL/selfies/" | grep -q "200"; then
    print_status 0 "Selfie portal accessible through tunnel!"
else
    print_warning "Selfie portal not accessible through tunnel yet"
    print_info "This might be normal if the tunnel is still starting up"
fi

echo ""
echo "3. Updating nginx configuration..."
# Check if the tunnel URL is already in nginx config
if grep -q "$TUNNEL_URL" /etc/nginx/sites-available/thepub.local; then
    print_status 0 "Tunnel URL already in nginx configuration"
else
    print_info "Adding tunnel URL to nginx configuration..."
    
    # Backup the current config
    sudo cp /etc/nginx/sites-available/thepub.local /etc/nginx/sites-available/thepub.local.backup.$(date +%Y%m%d_%H%M%S)
    
    # Add the tunnel URL to server_name
    sudo sed -i "s/server_name thepub.local www.thepub.local;/server_name thepub.local www.thepub.local $TUNNEL_URL;/" /etc/nginx/sites-available/thepub.local
    
    if grep -q "$TUNNEL_URL" /etc/nginx/sites-available/thepub.local; then
        print_status 0 "Tunnel URL added to nginx configuration"
        
        # Test and reload nginx
        if sudo nginx -t; then
            sudo systemctl reload nginx
            print_status 0 "Nginx reloaded successfully"
        else
            print_status 1 "Nginx configuration has errors"
            echo "   Restoring backup..."
            sudo cp /etc/nginx/sites-available/thepub.local.backup.* /etc/nginx/sites-available/thepub.local
        fi
    else
        print_status 1 "Failed to add tunnel URL to nginx configuration"
    fi
fi

echo ""
echo "4. Testing static files through tunnel..."
if curl -s -o /dev/null -w "%{http_code}" "https://$TUNNEL_URL/selfies/static/style.css" | grep -q "200"; then
    print_status 0 "Static files accessible through tunnel"
else
    print_warning "Static files not accessible through tunnel yet"
fi

echo ""
echo "5. Testing API endpoints through tunnel..."
if curl -s -o /dev/null -w "%{http_code}" "https://$TUNNEL_URL/selfies/api/selfies" | grep -q "200"; then
    print_status 0 "API endpoints accessible through tunnel"
else
    print_warning "API endpoints not accessible through tunnel yet"
fi

echo ""
echo "=== Setup Summary ==="
echo "Tunnel URL: https://$TUNNEL_URL"
echo "Selfie Portal: https://$TUNNEL_URL/selfies/"
echo ""
echo "=== Testing Instructions ==="
echo "1. Test the tunnel: curl https://$TUNNEL_URL"
echo "2. Test the selfie portal: curl https://$TUNNEL_URL/selfies/"
echo "3. Test camera access on iOS: Open https://$TUNNEL_URL/selfies/ in Safari"
echo ""
echo "=== Troubleshooting ==="
echo "If you have issues:"
echo "1. Check tunnel logs: cat /tmp/cloudflared.log"
echo "2. Check nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "3. Restart tunnel: pkill cloudflared && cloudflared tunnel run --url http://localhost:80"
echo "4. Restart services: sudo systemctl restart selfie-portal && sudo systemctl reload nginx"
echo ""
echo "=== Camera Testing ==="
echo "To test camera access:"
echo "1. Open https://$TUNNEL_URL/selfies/ on an iOS device"
echo "2. Allow camera permissions when prompted"
echo "3. The camera should initialize and show a live preview"
echo "4. If camera doesn't work, check browser console for errors" 