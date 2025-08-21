#!/bin/bash

# Download credentials for existing tunnel
# This script downloads the credentials file for an already-created tunnel

set -e

TUNNEL_NAME="selfie-portal-1750534817"
CREDENTIALS_DIR="/home/pi/.cloudflared"
CREDENTIALS_FILE="$CREDENTIALS_DIR/$TUNNEL_NAME.json"

echo "=== Downloading Tunnel Credentials ==="
echo "Tunnel: $TUNNEL_NAME"
echo "Target file: $CREDENTIALS_FILE"
echo

# Check if tunnel exists
echo "1. Checking if tunnel exists..."
if cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    echo "✓ Tunnel $TUNNEL_NAME exists"
    cloudflared tunnel list | grep "$TUNNEL_NAME"
else
    echo "✗ Tunnel $TUNNEL_NAME does not exist"
    exit 1
fi
echo

# Download credentials
echo "2. Downloading credentials..."
echo "Running: cloudflared tunnel token $TUNNEL_NAME"
CREDS_OUTPUT=$(sudo -u pi cloudflared tunnel token "$TUNNEL_NAME")
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ Credentials downloaded successfully"
    echo "$CREDS_OUTPUT" | sudo -u pi tee "$CREDENTIALS_FILE" > /dev/null
    echo "✓ Credentials saved to $CREDENTIALS_FILE"
    
    # Verify file was created
    if [ -f "$CREDENTIALS_FILE" ]; then
        echo "✓ File exists and has correct permissions"
        ls -la "$CREDENTIALS_FILE"
    else
        echo "✗ File was not created"
        exit 1
    fi
else
    echo "✗ Failed to download credentials"
    echo "Exit code: $EXIT_CODE"
    exit 1
fi

echo
echo "=== Success! ==="
echo "Credentials file: $CREDENTIALS_FILE"
echo "You can now run the Ansible playbook:"
echo "  ansible-playbook cloudflare_setup.yml" 