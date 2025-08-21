#!/bin/bash

echo "=== Cloudflare Tunnel Fix Script ==="
echo "This script will help fix the Cloudflare tunnel configuration."

# Check if we're running on the Pi
if [ "$(hostname)" != "thepub" ]; then
    echo "This script should be run on the Pi system (thepub.local)"
    echo "Please SSH to pi@10.42.0.1 and run this script there"
    exit 1
fi

echo "1. Stopping the cloudflared service..."
sudo systemctl stop cloudflared@selfie-portal-1750534817.service

echo "2. Checking if credentials file exists..."
if [ -f "/home/pi/.cloudflared/selfie-portal-1750534817.json" ]; then
    echo "   ✓ Credentials file exists"
    ls -la /home/pi/.cloudflared/selfie-portal-1750534817.json
else
    echo "   ✗ Credentials file missing!"
    echo "   You need to create the tunnel credentials file."
    echo "   Run: cloudflared tunnel create selfie-portal-1750534817"
    echo "   Then copy the credentials file to /home/pi/.cloudflared/"
    exit 1
fi

echo "3. Updating configuration file..."
sudo tee /etc/cloudflared/config.yml > /dev/null <<EOF
tunnel: selfie-portal-1750534817
credentials-file: /home/pi/.cloudflared/selfie-portal-1750534817.json

ingress:
  - hostname: selfies.griffincreektrestle.net
    service: http://localhost:80
  - service: http_status:404
EOF

echo "4. Setting correct permissions..."
sudo chown pi:pi /etc/cloudflared/config.yml
sudo chmod 644 /etc/cloudflared/config.yml

echo "5. Starting the cloudflared service..."
sudo systemctl start cloudflared@selfie-portal-1750534817.service

echo "6. Checking service status..."
sleep 3
sudo systemctl status cloudflared@selfie-portal-1750534817.service --no-pager

echo "7. Checking recent logs..."
echo "Recent logs:"
sudo journalctl -u cloudflared@selfie-portal-1750534817.service --no-pager -n 10

echo ""
echo "=== Tunnel Status ==="
if sudo systemctl is-active --quiet cloudflared@selfie-portal-1750534817.service; then
    echo "✓ Tunnel is running"
    echo "You can now test: https://selfies.griffincreektrestle.net/"
else
    echo "✗ Tunnel is not running"
    echo "Check the logs above for errors"
fi 