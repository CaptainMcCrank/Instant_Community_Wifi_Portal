#!/bin/bash

# Fix Cloudflare certificate issues
# This script diagnoses and fixes certificate problems

set -e

CERT_FILE="/home/pi/.cloudflared/cert.pem"

echo "=== Cloudflare Certificate Fix ==="
echo

# Check certificate file
echo "1. Checking certificate file..."
if [ -f "$CERT_FILE" ]; then
    echo "✓ Certificate file exists"
    echo "File size: $(wc -c < "$CERT_FILE") bytes"
    echo "File permissions:"
    ls -la "$CERT_FILE"
    
    # Check if file is empty
    if [ ! -s "$CERT_FILE" ]; then
        echo "✗ Certificate file is empty!"
        echo "This is the problem - the certificate file has no content."
    else
        echo "✓ Certificate file has content"
        
        # Try to validate the certificate
        echo "Certificate content (first few lines):"
        head -5 "$CERT_FILE"
        echo "..."
    fi
else
    echo "✗ Certificate file missing"
fi
echo

# Check if we need to re-authenticate
echo "2. Checking authentication status..."
if [ ! -s "$CERT_FILE" ]; then
    echo "Certificate file is empty or invalid. Need to re-authenticate."
    echo
    echo "Running cloudflared login..."
    echo "This will open a browser window for authentication."
    echo "Please complete the authentication process."
    echo
    
    # Remove the invalid certificate
    rm -f "$CERT_FILE"
    
    # Run cloudflared login
    cloudflared login
    
    # Verify the certificate was created
    if [ -f "$CERT_FILE" ] && [ -s "$CERT_FILE" ]; then
        echo "✓ Certificate created successfully!"
        echo "Certificate size: $(wc -c < "$CERT_FILE") bytes"
    else
        echo "✗ Certificate creation failed"
        exit 1
    fi
else
    echo "Certificate file appears to be valid"
fi
echo

# Test the certificate
echo "3. Testing certificate with cloudflared..."
if command -v cloudflared >/dev/null 2>&1; then
    echo "Running: cloudflared tunnel list"
    cloudflared tunnel list
    echo "✓ Certificate is working!"
else
    echo "cloudflared not found in PATH"
fi
echo

echo "=== Certificate Fix Complete ==="
echo
echo "If the certificate was recreated, you may need to:"
echo "1. Restart the cloudflared service:"
echo "   sudo systemctl restart cloudflared@selfie-portal-1750534817"
echo
echo "2. Check the service status:"
echo "   sudo systemctl status cloudflared@selfie-portal-1750534817" 