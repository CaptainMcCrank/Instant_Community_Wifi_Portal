#!/bin/bash

echo "=== Cloudflare Tunnel Fix Script ==="
echo "This script will help you set up and fix your Cloudflare tunnel"
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

echo "1. Checking if cloudflared is installed..."
if command -v cloudflared >/dev/null 2>&1; then
    print_status 0 "cloudflared is installed"
    cloudflared --version
else
    print_status 1 "cloudflared is not installed"
    echo "   Installing cloudflared..."
    
    # Download cloudflared for ARM (Raspberry Pi)
    cd /tmp
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm
    chmod +x cloudflared-linux-arm
    sudo mv cloudflared-linux-arm /usr/local/bin/cloudflared
    
    if command -v cloudflared >/dev/null 2>&1; then
        print_status 0 "cloudflared installed successfully"
    else
        print_status 1 "Failed to install cloudflared"
        exit 1
    fi
fi

echo ""
echo "2. Checking cloudflared authentication..."
if [ -f ~/.cloudflared/cert.pem ]; then
    print_status 0 "Cloudflared is authenticated"
else
    print_status 1 "Cloudflared is not authenticated"
    print_info "You need to authenticate with Cloudflare"
    echo "   Please run: cloudflared tunnel login"
    echo "   This will open a browser window for authentication"
    echo "   After authentication, run this script again"
    exit 1
fi

echo ""
echo "3. Checking for existing tunnels..."
if [ -f ~/.cloudflared/config.yml ]; then
    print_status 0 "Cloudflared config file exists"
    echo "   Current tunnels:"
    cloudflared tunnel list 2>/dev/null || echo "   No tunnels found or not authenticated"
else
    print_status 1 "No cloudflared config file found"
fi

echo ""
echo "4. Creating a new tunnel..."
echo "   This will create a new tunnel to your local server"
echo "   The tunnel will forward traffic to http://localhost:80"

# Create a new tunnel
TUNNEL_NAME="selfie-portal-$(date +%s)"
echo "   Creating tunnel: $TUNNEL_NAME"

cloudflared tunnel create $TUNNEL_NAME 2>/dev/null
if [ $? -eq 0 ]; then
    print_status 0 "Tunnel created successfully"
    
    # Get the tunnel ID
    TUNNEL_ID=$(cloudflared tunnel list | grep $TUNNEL_NAME | awk '{print $1}')
    echo "   Tunnel ID: $TUNNEL_ID"
    
    # Create config file
    cat > ~/.cloudflared/config.yml << EOF
tunnel: $TUNNEL_ID
credentials-file: ~/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $TUNNEL_NAME.trycloudflare.com
    service: http://localhost:80
  - service: http_status:404
EOF
    
    print_status 0 "Configuration file created"
else
    print_status 1 "Failed to create tunnel"
    print_info "You may need to authenticate first: cloudflared tunnel login"
    exit 1
fi

echo ""
echo "5. Starting the tunnel..."
echo "   Starting tunnel in background..."
nohup cloudflared tunnel run $TUNNEL_NAME > /tmp/cloudflared.log 2>&1 &
TUNNEL_PID=$!

# Wait a moment for the tunnel to start
sleep 5

if kill -0 $TUNNEL_PID 2>/dev/null; then
    print_status 0 "Tunnel started successfully (PID: $TUNNEL_PID)"
    echo "   Logs are being written to /tmp/cloudflared.log"
else
    print_status 1 "Failed to start tunnel"
    echo "   Check logs: cat /tmp/cloudflared.log"
    exit 1
fi

echo ""
echo "6. Getting the tunnel URL..."
sleep 3
TUNNEL_URL=$(grep -o '[a-z0-9-]*\.trycloudflare\.com' /tmp/cloudflared.log | head -1)

if [ -n "$TUNNEL_URL" ]; then
    print_status 0 "Tunnel URL: https://$TUNNEL_URL"
else
    print_status 1 "Could not determine tunnel URL"
    echo "   Check tunnel logs: cat /tmp/cloudflared.log"
    exit 1
fi

echo ""
echo "7. Testing the tunnel..."
sleep 2
if curl -s -o /dev/null -w "%{http_code}" "https://$TUNNEL_URL" | grep -q "200\|301\|302"; then
    print_status 0 "Tunnel is working!"
else
    print_status 1 "Tunnel test failed"
    echo "   This might be normal if the tunnel is still starting up"
fi

echo ""
echo "8. Testing the selfie portal through the tunnel..."
if curl -s -o /dev/null -w "%{http_code}" "https://$TUNNEL_URL/selfies/" | grep -q "200"; then
    print_status 0 "Selfie portal accessible through tunnel!"
else
    print_warning "Selfie portal not accessible through tunnel yet"
    print_info "This might be normal if the tunnel is still starting up"
fi

echo ""
echo "9. Updating nginx configuration..."
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
echo "10. Creating systemd service for auto-start..."
if [ ! -f /etc/systemd/system/cloudflared.service ]; then
    sudo tee /etc/systemd/system/cloudflared.service > /dev/null << EOF
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/local/bin/cloudflared tunnel run $TUNNEL_NAME
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable cloudflared
    print_status 0 "Systemd service created and enabled"
else
    print_status 0 "Systemd service already exists"
fi

echo ""
echo "=== Setup Complete ==="
echo "Your Cloudflare tunnel is now set up!"
echo ""
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
echo "3. Restart tunnel: sudo systemctl restart cloudflared"
echo "4. Restart services: sudo systemctl restart selfie-portal && sudo systemctl reload nginx"
echo ""
echo "=== Camera Testing ==="
echo "To test camera access:"
echo "1. Open https://$TUNNEL_URL/selfies/ on an iOS device"
echo "2. Allow camera permissions when prompted"
echo "3. The camera should initialize and show a live preview"
echo "4. If camera doesn't work, check browser console for errors" 