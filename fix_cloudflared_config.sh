#!/bin/bash

# Fix Cloudflare Tunnel Configuration
echo "Fixing Cloudflare Tunnel configuration..."

# Stop the current service
sudo systemctl stop cloudflared@selfie-portal-1750534817.service

# Update the config file to include the origincert path
sudo tee /etc/cloudflared/config.yml > /dev/null << 'EOF'
tunnel: selfie-portal-1750534817
credentials-file: /home/pi/.cloudflared/selfie-portal-1750534817.json
origincert: /home/pi/.cloudflared/cert.pem

ingress:
  - hostname: selfies.griffincreektrestle.net
    service: http://localhost:80
  - service: http_status:404
EOF

# Set proper permissions
sudo chown pi:pi /etc/cloudflared/config.yml
sudo chmod 644 /etc/cloudflared/config.yml

# Also update the user's config file
sudo tee /home/pi/.cloudflared/config.yml > /dev/null << 'EOF'
tunnel: selfie-portal-1750534817
credentials-file: /home/pi/.cloudflared/selfie-portal-1750534817.json
origincert: /home/pi/.cloudflared/cert.pem

ingress:
  - hostname: selfies.griffincreektrestle.net
    service: http://localhost:80
  - service: http_status:404
EOF

# Set proper permissions for user config
sudo chown pi:pi /home/pi/.cloudflared/config.yml
sudo chmod 644 /home/pi/.cloudflared/config.yml

# Update the service file to use the working directory
sudo tee /etc/systemd/system/cloudflared@.service > /dev/null << 'EOF'
[Unit]
Description=Cloudflare Tunnel for %i
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=pi
Group=pi
WorkingDirectory=/home/pi/.cloudflared
ExecStart=/usr/local/bin/cloudflared tunnel --config /etc/cloudflared/config.yml run
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=cloudflared-%i

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=false
ReadWritePaths=/etc/cloudflared /home/pi/.cloudflared

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and restart the service
sudo systemctl daemon-reload
sudo systemctl start cloudflared@selfie-portal-1750534817.service

echo "Cloudflare Tunnel configuration fixed!"
echo "Checking service status..."
sudo systemctl status cloudflared@selfie-portal-1750534817.service

echo ""
echo "Testing the tunnel manually..."
echo "Press Ctrl+C to stop the manual test"
sudo -u pi /usr/local/bin/cloudflared tunnel --config /etc/cloudflared/config.yml run 