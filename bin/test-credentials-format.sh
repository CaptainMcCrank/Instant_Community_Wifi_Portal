#!/bin/bash

# Test different credentials file formats
# This will help determine the correct format for cloudflared

set -e

TUNNEL_NAME="selfie-portal-1750534817"
CREDS_FILE="/home/pi/.cloudflared/selfie-portal-1750534817.json"

echo "=== Testing Credentials File Formats ==="
echo

# Stop the service first
echo "1. Stopping cloudflared service..."
sudo systemctl stop cloudflared@selfie-portal-1750534817
echo "✓ Service stopped"
echo

# Backup current file
echo "2. Backing up current credentials file..."
sudo cp "$CREDS_FILE" "$CREDS_FILE.backup"
echo "✓ Backup created: $CREDS_FILE.backup"
echo

# Test 1: Base64 format (current)
echo "3. Testing base64 format (current)..."
echo "Current file content:"
cat "$CREDS_FILE"
echo

# Test 2: Try JSON format
echo "4. Testing JSON format..."
# Create a JSON wrapper around the base64 token
TOKEN=$(cat "$CREDS_FILE")
JSON_CONTENT="{\"AccountTag\":\"6bb8710e2419d53ce4c14f2bfeb83f97\",\"TunnelSecret\":\"$TOKEN\"}"
echo "$JSON_CONTENT" | sudo -u pi tee "$CREDS_FILE" > /dev/null
echo "JSON content created:"
cat "$CREDS_FILE"
echo

# Test if this JSON is valid
if python3 -m json.tool "$CREDS_FILE" > /dev/null 2>&1; then
    echo "✓ JSON is valid"
else
    echo "✗ JSON is invalid"
fi
echo

# Start service and test
echo "5. Starting service with JSON format..."
sudo systemctl start cloudflared@selfie-portal-1750534817
sleep 5
echo "Service status:"
sudo systemctl status cloudflared@selfie-portal-1750534817 --no-pager -l
echo

# Check logs
echo "6. Recent logs:"
journalctl -u cloudflared@selfie-portal-1750534817 --no-pager -n 10
echo

# If JSON didn't work, try another format
if ! systemctl is-active --quiet cloudflared@selfie-portal-1750534817; then
    echo "7. JSON format failed, trying alternative format..."
    sudo systemctl stop cloudflared@selfie-portal-1750534817
    
    # Try just the base64 token without .json extension
    sudo mv "$CREDS_FILE" "${CREDS_FILE%.json}"
    echo "Moved to: ${CREDS_FILE%.json}"
    echo "Content:"
    cat "${CREDS_FILE%.json}"
    echo
    
    # Start service again
    sudo systemctl start cloudflared@selfie-portal-1750534817
    sleep 5
    echo "Service status:"
    sudo systemctl status cloudflared@selfie-portal-1750534817 --no-pager -l
    echo
fi

echo "=== Test Complete ==="
echo
echo "If the service is now running, we found the correct format."
echo "If not, we may need to check the cloudflared documentation for the correct format." 