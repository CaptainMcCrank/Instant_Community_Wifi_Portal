#!/bin/bash

# Fix nested JSON issue in credentials file
# The TunnelSecret field contains JSON instead of just the base64 token

set -e

CREDS_FILE="/home/pi/.cloudflared/selfie-portal-1750534817.json"
ORIGINAL_FILE="/home/pi/.cloudflared/selfie-portal-1750534817"

echo "=== Fixing Nested JSON Issue ==="
echo

# Stop the service
echo "1. Stopping cloudflared service..."
sudo systemctl stop cloudflared@selfie-portal-1750534817
echo "✓ Service stopped"
echo

# Check what's in the original file
echo "2. Checking original file content:"
if [ -f "$ORIGINAL_FILE" ]; then
    echo "Original file content:"
    cat "$ORIGINAL_FILE"
    echo
else
    echo "Original file not found"
fi
echo

# Get the actual base64 token from cloudflared
echo "3. Getting fresh base64 token from cloudflared..."
FRESH_TOKEN=$(cloudflared tunnel token selfie-portal-1750534817)
echo "Fresh token: $FRESH_TOKEN"
echo

# Create a clean JSON file with the correct structure
echo "4. Creating clean JSON file..."
cat > "$CREDS_FILE" << EOF
{
  "AccountTag": "6bb8710e2419d53ce4c14f2bfeb83f97",
  "TunnelSecret": "$FRESH_TOKEN"
}
EOF

echo "✓ Clean JSON file created"
echo

# Verify the JSON is valid
echo "5. Verifying JSON syntax:"
if python3 -m json.tool "$CREDS_FILE" > /dev/null 2>&1; then
    echo "✓ JSON is valid"
    echo "Formatted JSON:"
    python3 -m json.tool "$CREDS_FILE"
else
    echo "✗ JSON is still invalid"
    python3 -m json.tool "$CREDS_FILE" 2>&1 || true
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
sleep 5
sudo systemctl status cloudflared@selfie-portal-1750534817 --no-pager -l
echo

# Check recent logs
echo "9. Recent logs:"
journalctl -u cloudflared@selfie-portal-1750534817 --no-pager -n 10
echo

echo "=== Fix Complete ==="
echo
echo "If the service is now running successfully, the nested JSON issue should be resolved."
echo "You can test by visiting: https://selfies.griffincreektrestle.net" 