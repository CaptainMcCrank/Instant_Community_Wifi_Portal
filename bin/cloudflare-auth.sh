#!/bin/bash

# Cloudflare Tunnel Authentication Helper Script
# This script helps with the manual authentication process for cloudflared

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
CLOUDFLARED_BINARY="/usr/local/bin/cloudflared"
CERT_PATH="/home/pi/.cloudflared/cert.pem"

echo -e "${BLUE}========================================"
echo "Cloudflare Tunnel Authentication Helper"
echo "========================================${NC}"

# Check if cloudflared binary exists
if [ ! -f "$CLOUDFLARED_BINARY" ]; then
    echo -e "${RED}Error: cloudflared binary not found at $CLOUDFLARED_BINARY${NC}"
    echo "Please ensure cloudflared is installed first."
    exit 1
fi

# Check if already authenticated
if [ -f "$CERT_PATH" ]; then
    echo -e "${GREEN}✓ Cloudflare certificate already exists at $CERT_PATH${NC}"
    echo "You are already authenticated with Cloudflare."
    exit 0
fi

echo -e "${YELLOW}Starting Cloudflare authentication process...${NC}"
echo ""
echo "This will:"
echo "1. Run 'cloudflared login'"
echo "2. Display a URL for you to visit in your browser"
echo "3. Wait for you to complete the authentication"
echo "4. Verify the certificate was created"
echo ""

# Create .cloudflared directory if it doesn't exist
mkdir -p "$(dirname "$CERT_PATH")"

# Run cloudflared login
echo -e "${BLUE}Running cloudflared login...${NC}"
echo ""

# Run the login command and capture output
LOGIN_OUTPUT=$(sudo -u pi "$CLOUDFLARED_BINARY" login 2>&1)
LOGIN_EXIT_CODE=$?

# Display the output
echo "$LOGIN_OUTPUT"

if [ $LOGIN_EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Cloudflare authentication completed successfully!${NC}"
    
    # Verify certificate was created
    if [ -f "$CERT_PATH" ]; then
        echo -e "${GREEN}✓ Certificate file created at $CERT_PATH${NC}"
        echo ""
        echo "You can now continue with your Ansible playbook."
    else
        echo -e "${YELLOW}Warning: Certificate file not found at expected location${NC}"
        echo "Please check if the authentication completed properly."
    fi
else
    echo ""
    echo -e "${RED}✗ Cloudflare authentication failed${NC}"
    echo ""
    echo "If you see a URL in the output above, try visiting it manually in your browser."
    echo "If the browser download the certificate, you may need to manually copy it to:"
    echo "  $CERT_PATH"
    exit 1
fi 