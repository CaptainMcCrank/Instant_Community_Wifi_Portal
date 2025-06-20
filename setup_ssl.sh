#!/bin/bash
# Setup SSL certificates for the selfie portal

echo "Setting up SSL certificates for thepub.local..."

# Create SSL directory if it doesn't exist
sudo mkdir -p /etc/nginx/ssl

# Generate self-signed certificate
echo "Generating self-signed SSL certificate..."
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=thepub.local"

# Set correct permissions
echo "Setting SSL file permissions..."
sudo chmod 600 /etc/ssl/private/nginx-selfsigned.key
sudo chmod 644 /etc/ssl/certs/nginx-selfsigned.crt
sudo chown root:root /etc/ssl/private/nginx-selfsigned.key
sudo chown root:root /etc/ssl/certs/nginx-selfsigned.crt

# Generate DH parameters
echo "Generating DH parameters..."
sudo openssl dhparam -out /etc/nginx/ssl/dhparams-thepub.local.pem 2048

# Test nginx configuration
echo "Testing nginx configuration..."
if sudo nginx -t; then
    echo "✓ Nginx configuration is valid"
    echo "Reloading nginx..."
    sudo systemctl reload nginx
    echo "✓ SSL setup complete!"
    echo "You can now access the selfie portal at: https://thepub.local/selfies/"
else
    echo "✗ Nginx configuration has errors"
    exit 1
fi 