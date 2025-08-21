#!/bin/bash

# Debug script for tunnel creation
# This will help us see exactly what's failing

set -e

echo "=== Debug Tunnel Creation ==="

# Check if cloudflared exists
echo "1. Checking cloudflared binary..."
if [ -f "/usr/local/bin/cloudflared" ]; then
    echo "✓ cloudflared found at /usr/local/bin/cloudflared"
    /usr/local/bin/cloudflared version
else
    echo "✗ cloudflared not found at /usr/local/bin/cloudflared"
    echo "Looking for cloudflared in PATH..."
    which cloudflared || echo "cloudflared not found in PATH"
    exit 1
fi
echo

# Check authentication
echo "2. Checking authentication..."
if [ -f "/home/pi/.cloudflared/cert.pem" ]; then
    echo "✓ Authentication certificate exists"
    ls -la /home/pi/.cloudflared/cert.pem
else
    echo "✗ Authentication certificate missing"
    echo "You need to run: cloudflared login"
    exit 1
fi
echo

# Check if tunnel already exists
echo "3. Checking if tunnel already exists..."
TUNNEL_NAME="selfie-portal-1750534817"
if cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    echo "✓ Tunnel $TUNNEL_NAME already exists"
    cloudflared tunnel list | grep "$TUNNEL_NAME"
else
    echo "✗ Tunnel $TUNNEL_NAME does not exist"
fi
echo

# Try to create tunnel with verbose output
echo "4. Attempting to create tunnel..."
echo "Command: cloudflared tunnel create $TUNNEL_NAME"
echo "Running as pi user..."
sudo -u pi cloudflared tunnel create "$TUNNEL_NAME"
echo "Exit code: $?"
echo

# Check if credentials file was created
echo "5. Checking for credentials file..."
CREDS_FILE="/home/pi/.cloudflared/$TUNNEL_NAME.json"
if [ -f "$CREDS_FILE" ]; then
    echo "✓ Credentials file exists: $CREDS_FILE"
    ls -la "$CREDS_FILE"
else
    echo "✗ Credentials file missing: $CREDS_FILE"
    echo "Listing .cloudflared directory:"
    ls -la /home/pi/.cloudflared/
fi
echo

# Try to get tunnel token
echo "6. Attempting to get tunnel token..."
echo "Command: cloudflared tunnel token $TUNNEL_NAME"
sudo -u pi cloudflared tunnel token "$TUNNEL_NAME"
echo "Exit code: $?"
echo

echo "=== Debug Complete ===" 