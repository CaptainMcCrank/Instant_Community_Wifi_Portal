#!/bin/bash

# Fix Cloudflare Tunnel Service Configuration
echo "Fixing Cloudflare Tunnel service configuration..."

# Stop and disable the current service
sudo systemctl stop cloudflared.service
sudo systemctl disable cloudflared.service

# Remove the conflicting service file
sudo rm -f /etc/systemd/system/cloudflared.service

# Create the proper configuration directory
sudo mkdir -p /etc/cloudflared

# Copy the config file to the proper location
sudo cp /home/pi/.cloudflared/config.yml /etc/cloudflared/config.yml
sudo chown pi:pi /etc/cloudflared/config.yml
sudo chmod 644 /etc/cloudflared/config.yml

# Create the proper service file
sudo tee /etc/systemd/system/cloudflared@.service > /dev/null << 'EOF'
[Unit]
Description=Cloudflare Tunnel for %i
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=pi
Group=pi
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
ProtectHome=true
ReadWritePaths=/etc/cloudflared /home/pi/.cloudflared

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable the correct service
sudo systemctl daemon-reload
sudo systemctl enable cloudflared@selfie-portal-1750534817.service
sudo systemctl start cloudflared@selfie-portal-1750534817.service

echo "Cloudflare Tunnel service configuration fixed!"
echo "Checking service status..."
sudo systemctl status cloudflared@selfie-portal-1750534817.service 