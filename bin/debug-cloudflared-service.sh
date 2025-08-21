#!/bin/bash

# Debug script for failing cloudflared service
# This will help identify why the service is crashing

set -e

SERVICE_NAME="cloudflared@selfie-portal-1750534817"
CONFIG_FILE="/etc/cloudflared/config.yml"

echo "=== Cloudflared Service Debug ==="
echo "Service: $SERVICE_NAME"
echo

# 1. Check service status
echo "1. Service Status:"
systemctl status "$SERVICE_NAME" --no-pager -l
echo

# 2. Check recent logs
echo "2. Recent Service Logs:"
journalctl -u "$SERVICE_NAME" --no-pager -n 20
echo

# 3. Check configuration file
echo "3. Configuration File:"
if [ -f "$CONFIG_FILE" ]; then
    echo "✓ Config file exists: $CONFIG_FILE"
    echo "Contents:"
    cat "$CONFIG_FILE"
else
    echo "✗ Config file missing: $CONFIG_FILE"
fi
echo

# 4. Check credentials file
echo "4. Credentials File:"
CREDS_FILE="/home/pi/.cloudflared/selfie-portal-1750534817.json"
if [ -f "$CREDS_FILE" ]; then
    echo "✓ Credentials file exists: $CREDS_FILE"
    ls -la "$CREDS_FILE"
    echo "File size: $(wc -c < "$CREDS_FILE") bytes"
else
    echo "✗ Credentials file missing: $CREDS_FILE"
fi
echo

# 5. Check certificate file
echo "5. Certificate File:"
CERT_FILE="/home/pi/.cloudflared/cert.pem"
if [ -f "$CERT_FILE" ]; then
    echo "✓ Certificate file exists: $CERT_FILE"
    ls -la "$CERT_FILE"
else
    echo "✗ Certificate file missing: $CERT_FILE"
fi
echo

# 6. Test cloudflared manually
echo "6. Testing cloudflared manually:"
echo "Running: cloudflared tunnel --config $CONFIG_FILE run"
echo "Press Ctrl+C after a few seconds to stop the test..."
timeout 10s cloudflared tunnel --config "$CONFIG_FILE" run || echo "Command timed out or failed"
echo

# 7. Check file permissions
echo "7. File Permissions:"
echo "Config file permissions:"
ls -la "$CONFIG_FILE" 2>/dev/null || echo "Config file not found"
echo
echo "Credentials directory permissions:"
ls -la /home/pi/.cloudflared/ 2>/dev/null || echo "Credentials directory not found"
echo

# 8. Check if cloudflared binary is working
echo "8. Cloudflared Binary Test:"
if command -v cloudflared >/dev/null 2>&1; then
    echo "✓ cloudflared found in PATH"
    cloudflared version
else
    echo "✗ cloudflared not found in PATH"
    if [ -f "/usr/local/bin/cloudflared" ]; then
        echo "✓ cloudflared found at /usr/local/bin/cloudflared"
        /usr/local/bin/cloudflared version
    else
        echo "✗ cloudflared not found at /usr/local/bin/cloudflared"
    fi
fi
echo

echo "=== Debug Complete ==="
echo
echo "Common issues:"
echo "1. Missing or invalid credentials file"
echo "2. Missing or invalid certificate file"
echo "3. Incorrect file permissions"
echo "4. Invalid configuration file format"
echo "5. Network connectivity issues"
echo
echo "Next steps:"
echo "- Check the logs above for specific error messages"
echo "- Verify all required files exist and have correct permissions"
echo "- Test the configuration manually" 