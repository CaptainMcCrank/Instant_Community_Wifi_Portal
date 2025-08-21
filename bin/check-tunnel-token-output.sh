#!/bin/bash

# Check what cloudflared tunnel token actually outputs
# This will help us understand the expected format

set -e

TUNNEL_NAME="selfie-portal-1750534817"

echo "=== Checking Tunnel Token Output ==="
echo "Tunnel: $TUNNEL_NAME"
echo

# Check what the command outputs
echo "1. Running cloudflared tunnel token command..."
echo "Command: cloudflared tunnel token $TUNNEL_NAME"
echo "Output:"
cloudflared tunnel token "$TUNNEL_NAME"
echo

# Check if the output is JSON
echo "2. Checking if output is valid JSON..."
TOKEN_OUTPUT=$(cloudflared tunnel token "$TUNNEL_NAME")
if echo "$TOKEN_OUTPUT" | python3 -m json.tool > /dev/null 2>&1; then
    echo "✓ Output is valid JSON"
    echo "JSON structure:"
    echo "$TOKEN_OUTPUT" | python3 -m json.tool
else
    echo "✗ Output is not valid JSON"
    echo "Raw output:"
    echo "$TOKEN_OUTPUT"
fi
echo

# Check what's currently in the file
echo "3. Current credentials file content:"
CREDS_FILE="/home/pi/.cloudflared/selfie-portal-1750534817.json"
if [ -f "$CREDS_FILE" ]; then
    echo "File content:"
    cat "$CREDS_FILE"
    echo
    echo "Is this valid JSON?"
    if python3 -m json.tool "$CREDS_FILE" > /dev/null 2>&1; then
        echo "✓ Yes, it's valid JSON"
    else
        echo "✗ No, it's not valid JSON"
    fi
else
    echo "File does not exist"
fi
echo

echo "=== Analysis Complete ===" 