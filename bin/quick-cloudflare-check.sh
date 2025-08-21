#!/bin/bash

# Quick Cloudflare Tunnel Check
# Fast diagnostic for 1033 errors

echo "=== Quick Cloudflare Check ==="

# 1. Service status
echo "1. Service Status:"
if systemctl is-active --quiet cloudflared@selfie-portal-1750534817; then
    echo "✓ Service running"
else
    echo "✗ Service not running"
    exit 1
fi

# 2. Local service check
echo "2. Local Service (port 80):"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 | grep -q "200\|301\|302"; then
    echo "✓ Local service responding"
else
    echo "✗ Local service not responding"
    echo "   This is likely the cause of the 1033 error!"
fi

# 3. Tunnel connection
echo "3. Tunnel Connection:"
if journalctl -u cloudflared@selfie-portal-1750534817 --no-pager -n 5 | grep -q "Connected"; then
    echo "✓ Tunnel connected to Cloudflare"
else
    echo "✗ Tunnel not connected"
fi

# 4. Recent errors
echo "4. Recent Errors:"
journalctl -u cloudflared@selfie-portal-1750534817 --no-pager -n 10 | grep -i "error\|failed" || echo "No recent errors found"

echo
echo "Most likely cause of 1033 error: Local service not running on port 80" 