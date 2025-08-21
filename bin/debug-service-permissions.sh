#!/bin/bash

# Debug service user and file permission issues
# This script checks if the service can access the required files

set -e

SERVICE_NAME="cloudflared@selfie-portal-1750534817"
CONFIG_FILE="/etc/cloudflared/config.yml"
CERT_FILE="/home/pi/.cloudflared/cert.pem"
CREDS_FILE="/home/pi/.cloudflared/selfie-portal-1750534817.json"

echo "=== Service Permission Debug ==="
echo

# 1. Check service user
echo "1. Service User Configuration:"
echo "Service file: /etc/systemd/system/cloudflared@.service"
if [ -f "/etc/systemd/system/cloudflared@.service" ]; then
    echo "✓ Service file exists"
    echo "User configuration:"
    grep -i "user=" /etc/systemd/system/cloudflared@.service || echo "No User= directive found"
else
    echo "✗ Service file missing"
fi
echo

# 2. Check file permissions
echo "2. File Permissions:"
echo "Certificate file:"
ls -la "$CERT_FILE" 2>/dev/null || echo "Certificate file not found"

echo "Credentials file:"
ls -la "$CREDS_FILE" 2>/dev/null || echo "Credentials file not found"

echo "Config file:"
ls -la "$CONFIG_FILE" 2>/dev/null || echo "Config file not found"

echo "Cloudflared directory:"
ls -la /home/pi/.cloudflared/ 2>/dev/null || echo "Cloudflared directory not found"
echo

# 3. Check who the service runs as
echo "3. Current Service Process:"
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "Service is running, checking process user:"
    ps aux | grep cloudflared | grep -v grep || echo "No cloudflared processes found"
else
    echo "Service is not running"
fi
echo

# 4. Test file access as different users
echo "4. Testing File Access:"
echo "Testing as root:"
if sudo test -r "$CERT_FILE"; then
    echo "✓ Root can read certificate file"
else
    echo "✗ Root cannot read certificate file"
fi

echo "Testing as pi:"
if sudo -u pi test -r "$CERT_FILE"; then
    echo "✓ pi user can read certificate file"
else
    echo "✗ pi user cannot read certificate file"
fi
echo

# 5. Check service template
echo "5. Service Template Analysis:"
if [ -f "/etc/systemd/system/cloudflared@.service" ]; then
    echo "Service template contents:"
    cat /etc/systemd/system/cloudflared@.service
else
    echo "Service template not found"
fi
echo

# 6. Check if service is using correct user
echo "6. Service User Verification:"
echo "Expected user: pi"
echo "Service should run as: pi"
echo "Certificate file owner: $(stat -c '%U' "$CERT_FILE" 2>/dev/null || echo 'unknown')"
echo

echo "=== Permission Debug Complete ==="
echo
echo "Common issues:"
echo "1. Service running as wrong user (not pi)"
echo "2. File permissions too restrictive"
echo "3. Service template missing User= directive"
echo "4. Path issues in service configuration"
echo
echo "Next steps:"
echo "- Check if service template has User=pi directive"
echo "- Verify file permissions allow pi user access"
echo "- Restart service after fixing permissions" 