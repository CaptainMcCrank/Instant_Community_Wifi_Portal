#!/bin/bash

# Cloudflare Tunnel Authentication Reset Script
# This script removes the certificate to force re-authentication

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CERT_PATH="/home/pi/.cloudflared/cert.pem"
CLOUDFLARED_DIR="/home/pi/.cloudflared"

echo -e "${BLUE}========================================"
echo "Cloudflare Tunnel Authentication Reset"
echo "========================================${NC}"

# Check if certificate exists
if [ -f "$CERT_PATH" ]; then
    echo -e "${YELLOW}Found existing certificate at $CERT_PATH${NC}"
    echo "This will be removed to force re-authentication."
    echo ""
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Reset cancelled.${NC}"
        exit 0
    fi
    
    # Remove the certificate
    rm -f "$CERT_PATH"
    echo -e "${GREEN}✓ Certificate removed.${NC}"
else
    echo -e "${YELLOW}No existing certificate found.${NC}"
fi

# Optionally remove the entire .cloudflared directory
if [ -d "$CLOUDFLARED_DIR" ]; then
    echo ""
    echo -e "${YELLOW}Found .cloudflared directory at $CLOUDFLARED_DIR${NC}"
    read -p "Do you want to remove the entire directory? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$CLOUDFLARED_DIR"
        echo -e "${GREEN}✓ .cloudflared directory removed.${NC}"
    fi
fi

echo ""
echo -e "${GREEN}Reset complete!${NC}"
echo "You can now run the Ansible playbook again to start fresh:"
echo "  ansible-playbook cloudflare_setup.yml"
echo ""
echo "Or run the authentication helper:"
echo "  ./bin/cloudflare-auth.sh" 