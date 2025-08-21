#!/bin/bash

# Fix invalid JSON credentials file
# This script removes the invalid file and re-downloads valid credentials

set -e

CREDS_FILE="/home/pi/.cloudflared/selfie-portal-1750534817.json"
TUNNEL_NAME="selfie-portal-1750534817"

echo "=== Fixing Invalid Credentials File ==="
echo "File: $CREDS_FILE"
echo

# Stop the service first
echo "1. Stopping cloudflared service..."
sudo systemctl stop cloudflared@selfie-portal-1750534817
echo "✓ Service stopped"
echo

# Check current file
echo "2. Checking current credentials file..."
if [ -f "$CREDS_FILE" ]; then
    echo "Current file size: $(wc -c < "$CREDS_FILE") bytes"
    echo "First few characters:"
    head -c 50 "$CREDS_FILE"
    echo "..."
else
    echo "File does not exist"
fi
echo

# Remove invalid file
echo "3. Removing invalid credentials file..."
rm -f "$CREDS_FILE"
echo "✓ Invalid file removed"
echo

# Download new credentials
echo "4. Downloading new credentials..."
echo "Running: cloudflared tunnel token $TUNNEL_NAME"
CREDS_OUTPUT=$(sudo -u pi cloudflared tunnel token "$TUNNEL_NAME")
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ Credentials downloaded successfully"
    echo "$CREDS_OUTPUT" | sudo -u pi tee "$CREDS_FILE" > /dev/null
    echo "✓ Credentials saved to $CREDS_FILE"
else
    echo "✗ Failed to download credentials"
    echo "Exit code: $EXIT_CODE"
    exit 1
fi
echo

# Verify the new file
echo "5. Verifying new credentials file..."
if [ -f "$CREDS_FILE" ]; then
    echo "✓ File exists"
    echo "New file size: $(wc -c < "$CREDS_FILE") bytes"
    
    # Test JSON validity
    if python3 -m json.tool "$CREDS_FILE" > /dev/null 2>&1; then
        echo "✓ JSON is valid"
    else
        echo "✗ JSON is still invalid"
        echo "File content:"
        cat "$CREDS_FILE"
        exit 1
    fi
else
    echo "✗ File was not created"
    exit 1
fi
echo

# Set correct permissions
echo "6. Setting file permissions..."
sudo chown pi:pi "$CREDS_FILE"
sudo chmod 600 "$CREDS_FILE"
echo "✓ Permissions set correctly"
echo

# Start the service
echo "7. Starting cloudflared service..."
sudo systemctl start cloudflared@selfie-portal-1750534817
echo "✓ Service started"
echo

# Check service status
echo "8. Checking service status..."
sleep 3
sudo systemctl status cloudflared@selfie-portal-1750534817 --no-pager -l
echo

echo "=== Fix Complete ==="
echo
echo "If the service is now running successfully, the JSON error should be resolved."
echo "You can test by visiting: https://selfies.griffincreektrestle.net" 