#!/bin/bash

# Fix service permissions issue
# This script updates the service file to allow access to the certificate

set -e

SERVICE_FILE="/etc/systemd/system/cloudflared@.service"

echo "=== Fixing Service Permissions ==="
echo

# Check current service file
echo "1. Current service configuration:"
if [ -f "$SERVICE_FILE" ]; then
    echo "✓ Service file exists"
    echo "Current ProtectHome setting:"
    grep "ProtectHome" "$SERVICE_FILE" || echo "No ProtectHome setting found"
else
    echo "✗ Service file missing"
    exit 1
fi
echo

# Backup the service file
echo "2. Creating backup..."
sudo cp "$SERVICE_FILE" "$SERVICE_FILE.backup"
echo "✓ Backup created: $SERVICE_FILE.backup"
echo

# Fix the ProtectHome setting
echo "3. Fixing ProtectHome setting..."
sudo sed -i 's/ProtectHome=true/ProtectHome=read-only/' "$SERVICE_FILE"
echo "✓ Updated ProtectHome setting"
echo

# Verify the change
echo "4. Verifying the change:"
echo "New ProtectHome setting:"
grep "ProtectHome" "$SERVICE_FILE"
echo

# Reload systemd and restart service
echo "5. Reloading systemd and restarting service..."
sudo systemctl daemon-reload
sudo systemctl restart cloudflared@selfie-portal-1750534817
echo "✓ Service restarted"
echo

# Check service status
echo "6. Checking service status:"
sleep 3
sudo systemctl status cloudflared@selfie-portal-1750534817 --no-pager -l
echo

echo "=== Fix Complete ==="
echo
echo "If the service is now running successfully, the 1033 error should be resolved."
echo "You can test by visiting: https://selfies.griffincreektrestle.net" 