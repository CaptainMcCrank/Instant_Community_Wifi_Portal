#!/bin/bash

# Check tunnel connection status
# This will help diagnose the context canceled errors

set -e

echo "=== Checking Tunnel Connection Status ==="
echo

# Check if service is running
echo "1. Service Status:"
if systemctl is-active --quiet cloudflared@selfie-portal-1750534817; then
    echo "✓ Service is running"
else
    echo "✗ Service is not running"
    exit 1
fi
echo

# Check recent logs for connection attempts
echo "2. Recent Connection Attempts:"
journalctl -u cloudflared@selfie-portal-1750534817 --no-pager -n 20 | grep -E "(INF|ERR|WARN)" | tail -10
echo

# Check if tunnel is actually connected
echo "3. Checking Tunnel Info:"
if command -v cloudflared >/dev/null 2>&1; then
    echo "Running: cloudflared tunnel info selfie-portal-1750534817"
    cloudflared tunnel info selfie-portal-1750534817 || echo "Failed to get tunnel info"
else
    echo "cloudflared not found in PATH"
fi
echo

# Check network connectivity
echo "4. Network Connectivity:"
echo "Testing connection to Cloudflare:"
ping -c 3 1.1.1.1 || echo "Ping to Cloudflare failed"
echo

# Check if local service is available
echo "5. Local Service Check:"
echo "Testing localhost:80..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80; then
    echo "✓ Local service on port 80 is responding"
else
    echo "✗ Local service on port 80 is not responding"
    echo "This might be causing the context canceled errors"
fi
echo

# Check what's listening on port 80
echo "6. Services on Port 80:"
sudo netstat -tlnp | grep :80 || echo "Nothing listening on port 80"
echo

# Check if the tunnel is working by testing the domain
echo "7. Testing Tunnel Domain:"
echo "Testing: https://selfies.griffincreektrestle.net"
if curl -s -o /dev/null -w "%{http_code}" https://selfies.griffincreektrestle.net; then
    echo "✓ Domain is accessible"
else
    echo "✗ Domain is not accessible"
fi
echo

# Check for any firewall issues
echo "8. Firewall Check:"
echo "Checking if port 80 is accessible from outside:"
sudo iptables -L | grep -E "(80|http)" || echo "No specific port 80 rules found"
echo

# Check system resources
echo "9. System Resources:"
echo "Memory usage:"
free -h
echo
echo "Disk space:"
df -h /
echo

echo "=== Analysis Complete ==="
echo
echo "The tunnel is connecting to Cloudflare but getting 'context canceled' errors."
echo "This usually means:"
echo "1. The local service on port 80 is not running"
echo "2. Network connectivity issues"
echo "3. Firewall blocking connections"
echo "4. System resource constraints"
echo
echo "Next steps:"
echo "- Ensure a web service is running on port 80"
echo "- Check if the tunnel domain is accessible"
echo "- Monitor the logs for more specific error patterns" 