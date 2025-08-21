#!/bin/bash

# Cloudflare Tunnel Troubleshooting Script
# This script helps diagnose 1033 errors and other tunnel issues

set -e

echo "=== Cloudflare Tunnel Troubleshooting ==="
echo

# Check if cloudflared is running
echo "1. Checking cloudflared service status..."
if systemctl is-active --quiet cloudflared@selfie-portal-1750534817; then
    echo "✓ cloudflared service is running"
    systemctl status cloudflared@selfie-portal-1750534817 --no-pager -l
else
    echo "✗ cloudflared service is not running"
    echo "Attempting to start service..."
    sudo systemctl start cloudflared@selfie-portal-1750534817
    sleep 3
    systemctl status cloudflared@selfie-portal-1750534817 --no-pager -l
fi
echo

# Check cloudflared logs
echo "2. Recent cloudflared logs:"
journalctl -u cloudflared@selfie-portal-1750534817 --no-pager -n 20
echo

# Check if tunnel is connected
echo "3. Checking tunnel connection status..."
if command -v cloudflared >/dev/null 2>&1; then
    echo "Running: cloudflared tunnel info selfie-portal-1750534817"
    cloudflared tunnel info selfie-portal-1750534817 || echo "Failed to get tunnel info"
else
    echo "cloudflared binary not found in PATH"
fi
echo

# Check local service availability
echo "4. Checking local service availability..."
echo "Testing localhost:80..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80; then
    echo "✓ Local service on port 80 is responding"
else
    echo "✗ Local service on port 80 is not responding"
    echo "Checking what's listening on port 80:"
    sudo netstat -tlnp | grep :80 || echo "Nothing listening on port 80"
fi
echo

# Check configuration files
echo "5. Checking configuration files..."
echo "Config file: /etc/cloudflared/config.yml"
if [ -f /etc/cloudflared/config.yml ]; then
    echo "✓ Config file exists"
    cat /etc/cloudflared/config.yml
else
    echo "✗ Config file missing"
fi
echo

echo "Credentials file: /home/pi/.cloudflared/selfie-portal-1750534817.json"
if [ -f /home/pi/.cloudflared/selfie-portal-1750534817.json ]; then
    echo "✓ Credentials file exists"
    ls -la /home/pi/.cloudflared/selfie-portal-1750534817.json
else
    echo "✗ Credentials file missing"
fi
echo

echo "Certificate file: /home/pi/.cloudflared/cert.pem"
if [ -f /home/pi/.cloudflared/cert.pem ]; then
    echo "✓ Certificate file exists"
    ls -la /home/pi/.cloudflared/cert.pem
else
    echo "✗ Certificate file missing"
fi
echo

# Check network connectivity
echo "6. Checking network connectivity..."
echo "Testing DNS resolution:"
nslookup selfies.griffincreektrestle.net || echo "DNS resolution failed"
echo

echo "Testing Cloudflare connectivity:"
ping -c 3 1.1.1.1 || echo "Ping to Cloudflare failed"
echo

# Check tunnel routing
echo "7. Checking tunnel routing..."
if command -v cloudflared >/dev/null 2>&1; then
    echo "Running: cloudflared tunnel route dns selfie-portal-1750534817 selfies.griffincreektrestle.net"
    cloudflared tunnel route dns selfie-portal-1750534817 selfies.griffincreektrestle.net || echo "Failed to check route"
else
    echo "cloudflared binary not found in PATH"
fi
echo

echo "=== Troubleshooting Complete ==="
echo
echo "Common 1033 error causes:"
echo "1. Local service not running on port 80"
echo "2. Tunnel not properly connected to Cloudflare"
echo "3. DNS routing not configured correctly"
echo "4. Firewall blocking local connections"
echo "5. Wrong tunnel name or credentials"
echo
echo "Next steps:"
echo "- Check the logs above for specific error messages"
echo "- Ensure your local web service is running on port 80"
echo "- Verify the tunnel is connected to Cloudflare"
echo "- Check DNS routing configuration" 