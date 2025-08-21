#!/bin/bash

# Fix double .json extension issue
# The config file has the wrong path with double .json extension

set -e

CONFIG_FILE="/etc/cloudflared/config.yml"
CREDS_FILE="/home/pi/.cloudflared/selfie-portal-1750534817.json"

echo "=== Fixing Double .json Extension ==="
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
ls -la /home/pi/.cloudflared/selfie-portal-1750534817*
echo

# Fix the config file - remove the double .json extension
echo "4. Fixing config file..."
sudo sed -i 's|\.json\.json|\.json|g' "$CONFIG_FILE"
echo "✓ Config file updated"
echo

# Verify the fix
echo "5. Updated config file:"
cat "$CONFIG_FILE"
echo

# Ensure the credentials file exists
echo "6. Checking credentials file..."
if [ -f "$CREDS_FILE" ]; then
    echo "✓ Credentials file exists"
    ls -la "$CREDS_FILE"
else
    echo "✗ Credentials file missing"
    exit 1
fi
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
echo "If the service is now running successfully, the double extension issue should be resolved."
echo "You can test by visiting: https://selfies.griffincreektrestle.net" 