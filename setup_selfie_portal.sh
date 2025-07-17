#!/bin/bash
# Setup script for Selfie Portal (HTTP testing)

echo "Setting up Selfie Portal for HTTP testing..."

# Set the directory
SELFIE_DIR="/var/www/ansibledest.local/apps/selfies"

# Create directory if it doesn't exist
sudo mkdir -p "$SELFIE_DIR"

# Copy files from the playbook directory
echo "Copying selfie portal files..."
sudo cp -r var/www/ansibledest.local/apps/selfies/* "$SELFIE_DIR/"

# Set proper ownership
echo "Setting file permissions..."
sudo chown -R www-data:www-data "$SELFIE_DIR"
sudo chmod -R 755 "$SELFIE_DIR"

# Create Python virtual environment
echo "Setting up Python virtual environment..."
cd "$SELFIE_DIR"
sudo python3 -m venv venv

# Install dependencies
echo "Installing Python dependencies..."
sudo -u www-data bash -c "source venv/bin/activate && pip install -r requirements.txt"

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/selfie-portal.service > /dev/null <<EOF
[Unit]
Description=Selfie Portal Flask Application
After=network.target
Wants=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=$SELFIE_DIR
Environment=PATH=$SELFIE_DIR/venv/bin
ExecStart=$SELFIE_DIR/venv/bin/python app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
echo "Starting selfie portal service..."
sudo systemctl daemon-reload
sudo systemctl enable selfie-portal
sudo systemctl start selfie-portal

# Test nginx configuration
echo "Testing nginx configuration..."
if sudo nginx -t; then
    echo "✓ Nginx configuration is valid"
    echo "Reloading nginx..."
    sudo systemctl reload nginx
else
    echo "✗ Nginx configuration has errors"
    exit 1
fi

# Check if services are running
echo "Checking service status..."
if sudo systemctl is-active --quiet selfie-portal; then
    echo "✓ Selfie portal service is running"
else
    echo "✗ Selfie portal service is not running"
    sudo systemctl status selfie-portal
fi

if sudo systemctl is-active --quiet nginx; then
    echo "✓ Nginx service is running"
else
    echo "✗ Nginx service is not running"
    sudo systemctl status nginx
fi

echo ""
echo "=== Setup Complete ==="
echo "Selfie portal should now be accessible at:"
echo "http://thepub.local/selfies/"
echo ""
echo "To test:"
echo "curl http://thepub.local/selfies/health"
echo ""
echo "To check logs:"
echo "sudo journalctl -u selfie-portal -f" 