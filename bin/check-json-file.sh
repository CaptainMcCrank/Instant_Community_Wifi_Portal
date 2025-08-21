#!/bin/bash

# Check and fix JSON file content
# This will identify and fix JSON syntax errors

set -e

CREDS_FILE="/home/pi/.cloudflared/selfie-portal-1750534817.json"

echo "=== Checking JSON File Content ==="
echo "File: $CREDS_FILE"
echo

# Stop the service first
echo "1. Stopping cloudflared service..."
sudo systemctl stop cloudflared@selfie-portal-1750534817
echo "✓ Service stopped"
echo

# Check if file exists
if [ ! -f "$CREDS_FILE" ]; then
    echo "✗ Credentials file does not exist"
    exit 1
fi

echo "2. Current file content:"
cat "$CREDS_FILE"
echo

echo "3. File size and permissions:"
ls -la "$CREDS_FILE"
echo "File size: $(wc -c < "$CREDS_FILE") bytes"
echo

echo "4. Checking JSON syntax:"
if python3 -m json.tool "$CREDS_FILE" > /dev/null 2>&1; then
    echo "✓ JSON is valid"
    echo "Formatted JSON:"
    python3 -m json.tool "$CREDS_FILE"
else
    echo "✗ JSON is invalid"
    echo "JSON validation error:"
    python3 -m json.tool "$CREDS_FILE" 2>&1 || true
fi
echo

echo "5. Checking for common issues:"
echo "Looking for extra characters or formatting issues..."

# Check for common problems
if grep -q "AccountTag.*AccountTag" "$CREDS_FILE"; then
    echo "⚠ Found duplicate AccountTag"
fi

if grep -q "TunnelSecret.*TunnelSecret" "$CREDS_FILE"; then
    echo "⚠ Found duplicate TunnelSecret"
fi

if grep -q "EOF" "$CREDS_FILE"; then
    echo "⚠ Found EOF marker in file"
fi

# Count lines
LINE_COUNT=$(wc -l < "$CREDS_FILE")
echo "Line count: $LINE_COUNT"

# Check for trailing commas
if grep -q ",$" "$CREDS_FILE"; then
    echo "⚠ Found trailing commas"
fi
echo

echo "6. Creating a clean JSON file..."
# Get the base64 token from the original file
ORIGINAL_FILE="/home/pi/.cloudflared/selfie-portal-1750534817"
if [ -f "$ORIGINAL_FILE" ]; then
    TOKEN=$(cat "$ORIGINAL_FILE")
else
    TOKEN=$(cloudflared tunnel token selfie-portal-1750534817)
fi

# Create a clean JSON file
cat > "$CREDS_FILE" << 'EOF'
{
  "AccountTag": "6bb8710e2419d53ce4c14f2bfeb83f97",
  "TunnelSecret": "TOKEN_PLACEHOLDER"
}
EOF

# Replace the placeholder with the actual token
sed -i "s/TOKEN_PLACEHOLDER/$TOKEN/" "$CREDS_FILE"

echo "✓ Clean JSON file created"
echo

echo "7. Verifying the new JSON file:"
cat "$CREDS_FILE"
echo

echo "8. Testing JSON syntax:"
if python3 -m json.tool "$CREDS_FILE" > /dev/null 2>&1; then
    echo "✓ JSON is now valid"
else
    echo "✗ JSON is still invalid"
    python3 -m json.tool "$CREDS_FILE" 2>&1 || true
fi
echo

# Set correct permissions
echo "9. Setting file permissions..."
sudo chown pi:pi "$CREDS_FILE"
sudo chmod 600 "$CREDS_FILE"
echo "✓ Permissions set correctly"
echo

# Start the service
echo "10. Starting cloudflared service..."
sudo systemctl start cloudflared@selfie-portal-1750534817
echo "✓ Service started"
echo

# Check service status
echo "11. Checking service status..."
sleep 5
sudo systemctl status cloudflared@selfie-portal-1750534817 --no-pager -l
echo

echo "=== Fix Complete ===" 