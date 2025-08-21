#!/bin/bash

# Fix credentials file path issue
# The config file is pointing to the wrong path

set -e

CONFIG_FILE="/etc/cloudflared/config.yml"
CREDS_FILE="/home/pi/.cloudflared/selfie-portal-1750534817"
CREDS_FILE_JSON="/home/pi/.cloudflared/selfie-portal-1750534817.json"

echo "=== Fixing Credentials File Path ==="
echo

# Stop the service
echo "1. Stopping cloudflared service..."
sudo systemctl stop cloudflared@selfie-portal-1750534817
echo "✓ Service stopped"
echo

# Check current config
echo "2. Current config file:"
cat "$CONFIG_FILE"
echo

# Check what files exist
echo "3. Checking existing files:"
if [ -f "$CREDS_FILE" ]; then
    echo "✓ Found: $CREDS_FILE"
    ls -la "$CREDS_FILE"
else
    echo "✗ Missing: $CREDS_FILE"
fi

if [ -f "$CREDS_FILE_JSON" ]; then
    echo "✓ Found: $CREDS_FILE_JSON"
    ls -la "$CREDS_FILE_JSON"
else
    echo "✗ Missing: $CREDS_FILE_JSON"
fi
echo

# Fix the config file to point to the correct path
echo "4. Fixing config file..."
sudo sed -i 's|credentials-file: /home/pi/.cloudflared/selfie-portal-1750534817|credentials-file: /home/pi/.cloudflared/selfie-portal-1750534817.json|g' "$CONFIG_FILE"
echo "✓ Config file updated"
echo

# Verify the fix
echo "5. Updated config file:"
cat "$CONFIG_FILE"
echo

# Ensure the JSON file exists with correct content
echo "6. Ensuring JSON credentials file exists..."
if [ ! -f "$CREDS_FILE_JSON" ]; then
    echo "Creating JSON credentials file..."
    # Get the base64 token
    TOKEN=$(cat "$CREDS_FILE" 2>/dev/null || cloudflared tunnel token selfie-portal-1750534817)
    
    # Create JSON format
    cat > "$CREDS_FILE_JSON" << EOF
{
  "AccountTag": "6bb8710e2419d53ce4c14f2bfeb83f97",
  "TunnelSecret": "$TOKEN"
}
EOF
    echo "✓ JSON credentials file created"
else
    echo "✓ JSON credentials file already exists"
fi
echo

# Set correct permissions
echo "7. Setting file permissions..."
sudo chown pi:pi "$CREDS_FILE_JSON"
sudo chmod 600 "$CREDS_FILE_JSON"
echo "✓ Permissions set correctly"
echo

# Start the service
echo "8. Starting cloudflared service..."
sudo systemctl start cloudflared@selfie-portal-1750534817
echo "✓ Service started"
echo

# Check service status
echo "9. Checking service status..."
sleep 5
sudo systemctl status cloudflared@selfie-portal-1750534817 --no-pager -l
echo

# Check recent logs
echo "10. Recent logs:"
journalctl -u cloudflared@selfie-portal-1750534817 --no-pager -n 10
echo

echo "=== Fix Complete ==="
echo
echo "If the service is now running successfully, the path issue should be resolved."
echo "You can test by visiting: https://selfies.griffincreektrestle.net" 