#!/bin/bash

# Cloudflare Tunnel Creation Script
# This script creates a tunnel and downloads the credentials file

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
AUTO_ROUTE="false"
if [[ "$1" == "--auto-route" ]]; then
    AUTO_ROUTE="true"
fi

# Default values
CLOUDFLARED_BINARY="/usr/local/bin/cloudflared"
TUNNEL_NAME="selfie-portal-working"
DOMAIN="selfies.griffincreektrestle.net"
CREDENTIALS_DIR="/home/pi/.cloudflared"

echo -e "${BLUE}========================================"
echo "Cloudflare Tunnel Creation Script"
echo "========================================${NC}"

# Check if cloudflared binary exists
if [ ! -f "$CLOUDFLARED_BINARY" ]; then
    echo -e "${RED}Error: cloudflared binary not found at $CLOUDFLARED_BINARY${NC}"
    echo "Please ensure cloudflared is installed and authenticated first."
    exit 1
fi

# Check if already authenticated
if [ ! -f "$CREDENTIALS_DIR/cert.pem" ]; then
    echo -e "${RED}Error: Cloudflare certificate not found at $CREDENTIALS_DIR/cert.pem${NC}"
    echo "Please run the authentication first:"
    echo "  ./bin/cloudflare-auth.sh"
    exit 1
fi

echo -e "${YELLOW}Creating Cloudflare tunnel: $TUNNEL_NAME${NC}"
echo "Domain: $DOMAIN"
echo ""

# Check if tunnel already exists
echo -e "${BLUE}Checking if tunnel already exists...${NC}"
TUNNEL_LIST=$(sudo -u pi "$CLOUDFLARED_BINARY" tunnel list 2>/dev/null || echo "")
if echo "$TUNNEL_LIST" | grep -q "$TUNNEL_NAME"; then
    echo -e "${YELLOW}Tunnel $TUNNEL_NAME already exists, skipping creation...${NC}"
    TUNNEL_EXIT_CODE=0
    TUNNEL_OUTPUT="Tunnel already exists"
    TUNNEL_EXISTS=true
else
        # Create the tunnel
    echo -e "${BLUE}Creating tunnel...${NC}"
    echo "Running: sudo -u pi $CLOUDFLARED_BINARY tunnel create $TUNNEL_NAME"
    TUNNEL_OUTPUT=$(sudo -u pi "$CLOUDFLARED_BINARY" tunnel create "$TUNNEL_NAME" 2>&1)
    TUNNEL_EXIT_CODE=$?

    echo "Exit code: $TUNNEL_EXIT_CODE"
    echo "Output: $TUNNEL_OUTPUT"

    if [ $TUNNEL_EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}✓ Tunnel created successfully!${NC}"
        echo "$TUNNEL_OUTPUT"
    else
        echo -e "${YELLOW}Tunnel creation output:${NC}"
        echo "$TUNNEL_OUTPUT"
        
        # Check if tunnel already exists (multiple possible error messages)
        if echo "$TUNNEL_OUTPUT" | grep -q "already exists\|tunnel with name already exists\|already exists with name"; then
            echo -e "${YELLOW}Tunnel already exists, continuing...${NC}"
        else
            echo -e "${RED}✗ Failed to create tunnel${NC}"
            echo "Please run the debug script to see more details:"
            echo "  ./debug-tunnel-creation.sh"
            exit 1
        fi
    fi
fi

# Get the tunnel credentials
echo ""
echo -e "${BLUE}Downloading tunnel credentials...${NC}"
CREDS_FILE="$CREDENTIALS_DIR/$TUNNEL_NAME.json"

# Ensure credentials directory exists
mkdir -p "$CREDENTIALS_DIR"

# First try with --credentials-file flag
echo -e "${BLUE}Trying --credentials-file method...${NC}"
CREDS_OUTPUT=$(sudo -u pi "$CLOUDFLARED_BINARY" tunnel token --credentials-file "$CREDS_FILE" "$TUNNEL_NAME" 2>&1)
CREDS_EXIT_CODE=$?

if [ $CREDS_EXIT_CODE -eq 0 ] && [ -f "$CREDS_FILE" ]; then
    echo -e "${GREEN}✓ Credentials saved to $CREDS_FILE${NC}"
    CREDS_SUCCESS=true
else
    echo -e "${YELLOW}--credentials-file method failed, trying alternative method...${NC}"
    echo "Error output: $CREDS_OUTPUT"
    
    # Try without --credentials-file flag and manually create JSON
    echo -e "${BLUE}Trying manual JSON creation...${NC}"
    CREDS_TOKEN=$(sudo -u pi "$CLOUDFLARED_BINARY" tunnel token "$TUNNEL_NAME" 2>&1)
    CREDS_TOKEN_EXIT_CODE=$?
    
    if [ $CREDS_TOKEN_EXIT_CODE -eq 0 ] && [ -n "$CREDS_TOKEN" ]; then
        # Create JSON format manually
        cat > "$CREDS_FILE" << EOF
{
  "AccountTag": "6bb8710e2419d53ce4c14f2bfeb83f97",
  "TunnelSecret": "$CREDS_TOKEN"
}
EOF
        echo -e "${GREEN}✓ Credentials saved to $CREDS_FILE (manual JSON format)${NC}"
        CREDS_SUCCESS=true
    else
        echo -e "${RED}✗ Failed to get tunnel credentials${NC}"
        echo "Token command output: $CREDS_TOKEN"
        echo "Token exit code: $CREDS_TOKEN_EXIT_CODE"
        echo "Token length: ${#CREDS_TOKEN}"
        exit 1
    fi
fi

# Verify credentials file was created and is valid
if [ -f "$CREDS_FILE" ]; then
    echo -e "${BLUE}Verifying credentials file...${NC}"
    if python3 -m json.tool "$CREDS_FILE" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Credentials file is valid JSON${NC}"
    else
        echo -e "${YELLOW}⚠ Credentials file exists but may not be valid JSON${NC}"
    fi
else
    echo -e "${RED}✗ Credentials file was not created${NC}"
    exit 1
fi

echo ""
echo "Tunnel configuration:"
echo "  Name: $TUNNEL_NAME"
echo "  Domain: $DOMAIN"
echo "  Credentials: $CREDS_FILE"
echo ""

# Check if we're in the case where tunnel already existed
if [ "${TUNNEL_EXISTS:-false}" = "true" ]; then
    echo -e "${GREEN}✓ Tunnel already existed and credentials downloaded successfully!${NC}"
else
    echo -e "${GREEN}✓ Tunnel created and credentials downloaded successfully!${NC}"
fi

echo ""
echo "You can now run the Ansible playbook:"
echo "  ansible-playbook cloudflare_setup.yml"

# Optionally route the domain
echo ""
if [[ "$AUTO_ROUTE" == "true" ]]; then
    echo "Auto-routing domain $DOMAIN to tunnel..."
    DO_ROUTE="true"
else
    read -p "Do you want to route the domain $DOMAIN to this tunnel? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        DO_ROUTE="true"
    else
        DO_ROUTE="false"
    fi
fi

if [[ "$DO_ROUTE" == "true" ]]; then
    echo -e "${BLUE}Routing domain...${NC}"
    ROUTE_OUTPUT=$(sudo -u pi "$CLOUDFLARED_BINARY" tunnel route dns "$TUNNEL_NAME" "$DOMAIN" 2>&1)
    ROUTE_EXIT_CODE=$?
    
    if [ $ROUTE_EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}✓ Domain routed successfully!${NC}"
        echo "$ROUTE_OUTPUT"
    else
        echo -e "${YELLOW}Domain routing output:${NC}"
        echo "$ROUTE_OUTPUT"
        
        # Check if it's a CNAME conflict (expected issue)
        if echo "$ROUTE_OUTPUT" | grep -qi "cname.*already exists\|record.*already exists"; then
            echo ""
            echo -e "${YELLOW}⚠ DNS record already exists - this is expected${NC}"
            echo -e "${BLUE}Manual Update Required:${NC}"
            echo "1. Go to: https://dash.cloudflare.com/"
            echo "2. Navigate to: Your Domain → DNS → Records"
            echo "3. Find: selfies.griffincreektrestle.net (Type: CNAME)"
            echo "4. Update CNAME target to: $TUNNEL_NAME.cfargotunnel.com"
            echo "5. Save and wait 1-2 minutes for DNS propagation"
            echo ""
            echo -e "${GREEN}This is normal - the tunnel was created successfully!${NC}"
        else
            echo -e "${YELLOW}You may need to manually configure DNS in your Cloudflare dashboard${NC}"
        fi
    fi
fi

echo ""
echo -e "${GREEN}Setup complete!${NC}"

# Always exit with success if tunnel was created successfully
# DNS routing failures are not critical since they can be fixed manually
exit 0 