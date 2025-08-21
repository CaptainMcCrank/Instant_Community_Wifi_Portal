#!/bin/bash

# Debug credentials file issues
# This script checks the credentials file content and fixes JSON issues

set -e

CREDS_FILE="/home/pi/.cloudflared/selfie-portal-1750534817.json"

echo "=== Credentials File Debug ==="
echo "File: $CREDS_FILE"
echo

# Check if file exists
if [ ! -f "$CREDS_FILE" ]; then
    echo "✗ Credentials file does not exist"
    exit 1
fi

echo "1. File information:"
echo "Size: $(wc -c < "$CREDS_FILE") bytes"
echo "Permissions:"
ls -la "$CREDS_FILE"
echo

echo "2. File content (first 10 lines):"
head -10 "$CREDS_FILE"
echo

echo "3. File content (last 10 lines):"
tail -10 "$CREDS_FILE"
echo

echo "4. Checking for credentials validity:"
# Check if file contains valid base64 (which is the correct format for tunnel credentials)
if base64 -d "$CREDS_FILE" > /dev/null 2>&1; then
    echo "✓ File contains valid base64 (correct format for tunnel credentials)"
    echo "Decoded content preview:"
    base64 -d "$CREDS_FILE" | head -c 100
    echo "..."
elif command -v jq >/dev/null 2>&1 && jq empty "$CREDS_FILE" > /dev/null 2>&1; then
    echo "✓ File contains valid JSON"
else
    echo "✗ File format is invalid (neither valid base64 nor JSON)"
    echo "First 50 characters:"
    head -c 50 "$CREDS_FILE"
    echo "..."
fi
echo

echo "5. Looking for error messages in file:"
if grep -i "error\|failed\|invalid" "$CREDS_FILE"; then
    echo "Found error messages in file!"
else
    echo "No obvious error messages found"
fi
echo

echo "6. Checking if file contains command output:"
if grep -q "cloudflared\|tunnel\|token" "$CREDS_FILE"; then
    echo "File appears to contain command output"
else
    echo "File does not appear to contain command output"
fi
echo

echo "=== Debug Complete ==="
echo
echo "If the file contains invalid JSON, you can fix it by:"
echo "1. Removing the invalid file: rm $CREDS_FILE"
echo "2. Re-downloading credentials: cloudflared tunnel token selfie-portal-1750534817 > $CREDS_FILE" 