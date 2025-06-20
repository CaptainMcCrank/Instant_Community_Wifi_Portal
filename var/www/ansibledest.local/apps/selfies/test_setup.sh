#!/bin/bash
# Test script for Selfie Portal setup

echo "=== Selfie Portal Setup Test ==="
echo

# Check if Flask app is running
echo "1. Checking Flask application status..."
if pgrep -f "python.*app.py" > /dev/null; then
    echo "   ✓ Flask app is running"
else
    echo "   ✗ Flask app is not running"
    echo "   Starting Flask app..."
    cd /var/www/thepub.local/apps/selfies
    nohup python3 app.py > /var/log/selfie-portal.log 2>&1 &
    sleep 2
    if pgrep -f "python.*app.py" > /dev/null; then
        echo "   ✓ Flask app started successfully"
    else
        echo "   ✗ Failed to start Flask app"
    fi
fi

# Check if port 5001 is listening
echo
echo "2. Checking if port 5001 is listening..."
if netstat -tlnp 2>/dev/null | grep :5001 > /dev/null; then
    echo "   ✓ Port 5001 is listening"
else
    echo "   ✗ Port 5001 is not listening"
fi

# Test Flask app directly
echo
echo "3. Testing Flask app directly..."
if curl -s http://localhost:5001/ > /dev/null; then
    echo "   ✓ Flask app responds on localhost:5001"
else
    echo "   ✗ Flask app does not respond on localhost:5001"
fi

# Check nginx configuration
echo
echo "4. Checking nginx configuration..."
if nginx -t > /dev/null 2>&1; then
    echo "   ✓ Nginx configuration is valid"
else
    echo "   ✗ Nginx configuration has errors"
    echo "   Running nginx -t for details:"
    nginx -t
fi

# Test nginx proxy
echo
echo "5. Testing nginx proxy..."
if curl -s -k https://thepub.local/selfies/ > /dev/null; then
    echo "   ✓ Nginx proxy works for /selfies/"
else
    echo "   ✗ Nginx proxy does not work for /selfies/"
fi

# Check file permissions
echo
echo "6. Checking file permissions..."
SELFIE_DIR="/var/www/thepub.local/apps/selfies"
if [ -d "$SELFIE_DIR" ]; then
    echo "   ✓ Selfie directory exists"
    if [ -w "$SELFIE_DIR/data" ]; then
        echo "   ✓ Data directory is writable"
    else
        echo "   ✗ Data directory is not writable"
        echo "   Fixing permissions..."
        chown -R www-data:www-data "$SELFIE_DIR"
        chmod -R 755 "$SELFIE_DIR"
    fi
else
    echo "   ✗ Selfie directory does not exist"
fi

# Check Python dependencies
echo
echo "7. Checking Python dependencies..."
cd /var/www/thepub.local/apps/selfies
if [ -f "venv/bin/activate" ]; then
    echo "   ✓ Virtual environment exists"
    source venv/bin/activate
    if python -c "import flask" 2>/dev/null; then
        echo "   ✓ Flask is installed"
    else
        echo "   ✗ Flask is not installed"
        echo "   Installing dependencies..."
        pip install -r requirements.txt
    fi
else
    echo "   ✗ Virtual environment does not exist"
    echo "   Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
fi

# Check SSL certificate
echo
echo "8. Checking SSL certificate..."
if [ -f "/etc/ssl/certs/nginx-selfsigned.crt" ]; then
    echo "   ✓ SSL certificate exists"
else
    echo "   ✗ SSL certificate does not exist"
fi

# Browser compatibility info
echo
echo "9. Browser compatibility information:"
echo "   - Camera access requires HTTPS (which you have)"
echo "   - Modern browsers require user permission for camera"
echo "   - Some browsers may block camera access on self-signed certificates"
echo "   - Try accessing https://thepub.local/selfies/ directly"

# Troubleshooting tips
echo
echo "=== Troubleshooting Tips ==="
echo "If camera is still unavailable:"
echo "1. Make sure you're accessing via HTTPS: https://thepub.local/selfies/"
echo "2. Check browser permissions - allow camera access when prompted"
echo "3. Try refreshing the page after allowing permissions"
echo "4. Some browsers may not work with self-signed certificates"
echo "5. Test with Chrome or Firefox on mobile devices"
echo "6. Check browser console for JavaScript errors"

echo
echo "=== Test Complete ===" 