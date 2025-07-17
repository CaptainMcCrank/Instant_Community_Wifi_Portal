#!/bin/bash

# Deploy Selfies Subdomain Configuration
# This script deploys the selfies app to work on selfies.griffincreektrestle.net

set -e

echo "=== Deploying Selfies Subdomain Configuration ==="

# Configuration
PI_HOST="pi@10.42.0.1"
SELFIE_DIR="/var/www/ansibledest.local/apps/selfies"

echo "1. Copying updated Flask app..."
scp var/www/ansibledest.local/apps/selfies/app.py $PI_HOST:$SELFIE_DIR/app.py
ssh $PI_HOST "sudo chown www-data:www-data $SELFIE_DIR/app.py && sudo chmod 755 $SELFIE_DIR/app.py"

echo "2. Copying updated templates with gnome introduction..."
scp var/www/ansibledest.local/apps/selfies/templates/index.html $PI_HOST:/tmp/index.html
scp var/www/ansibledest.local/apps/selfies/templates/view.html $PI_HOST:/tmp/view.html
ssh $PI_HOST "sudo mv /tmp/index.html $SELFIE_DIR/templates/index.html && sudo mv /tmp/view.html $SELFIE_DIR/templates/view.html"
ssh $PI_HOST "sudo chown www-data:www-data $SELFIE_DIR/templates/*.html && sudo chmod 644 $SELFIE_DIR/templates/*.html"

echo "3. Copying updated static files with gnome styles..."
scp var/www/ansibledest.local/apps/selfies/static/upload.js $PI_HOST:/tmp/upload.js
scp var/www/ansibledest.local/apps/selfies/static/style.css $PI_HOST:/tmp/style.css
ssh $PI_HOST "sudo mv /tmp/upload.js $SELFIE_DIR/static/upload.js && sudo mv /tmp/style.css $SELFIE_DIR/static/style.css"
ssh $PI_HOST "sudo chown www-data:www-data $SELFIE_DIR/static/upload.js $SELFIE_DIR/static/style.css && sudo chmod 644 $SELFIE_DIR/static/upload.js $SELFIE_DIR/static/style.css"

echo "4. Creating nginx configuration for selfies subdomain..."
scp etc/nginx/sites-available/selfies.griffincreektrestle.net $PI_HOST:/tmp/selfies.griffincreektrestle.net
ssh $PI_HOST "sudo mv /tmp/selfies.griffincreektrestle.net /etc/nginx/sites-available/selfies.griffincreektrestle.net"
ssh $PI_HOST "sudo chown root:root /etc/nginx/sites-available/selfies.griffincreektrestle.net && sudo chmod 644 /etc/nginx/sites-available/selfies.griffincreektrestle.net"

echo "5. Enabling the nginx site..."
ssh $PI_HOST "sudo ln -sf /etc/nginx/sites-available/selfies.griffincreektrestle.net /etc/nginx/sites-enabled/selfies.griffincreektrestle.net"

echo "6. Testing nginx configuration..."
if ssh $PI_HOST "sudo nginx -t"; then
    echo "   ✓ Nginx configuration is valid"
else
    echo "   ✗ Nginx configuration has errors"
    exit 1
fi

echo "7. Restarting nginx..."
ssh $PI_HOST "sudo systemctl reload nginx"

echo "8. Restarting Flask app..."
ssh $PI_HOST "sudo systemctl restart selfie-portal"

echo "9. Testing the Flask app..."
sleep 3
if ssh $PI_HOST "curl -s http://localhost:5001/health" | grep -q "healthy"; then
    echo "   ✓ Flask app is running"
else
    echo "   ✗ Flask app is not responding"
    exit 1
fi

echo "10. Testing nginx proxy..."
if ssh $PI_HOST "curl -s -H 'Host: selfies.griffincreektrestle.net' http://localhost/health" | grep -q "healthy"; then
    echo "   ✓ Nginx proxy is working"
else
    echo "   ✗ Nginx proxy is not working"
    exit 1
fi

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "The selfies app with gnome introduction should now be accessible at:"
echo "  http://selfies.griffincreektrestle.net"
echo ""
echo "To test locally, you can add this to your /etc/hosts file:"
echo "  10.42.0.1 selfies.griffincreektrestle.net"
echo ""
echo "Or test from the Pi itself:"
echo "  curl -H 'Host: selfies.griffincreektrestle.net' http://localhost/"
echo ""
echo "If you're still getting a 500 error, check the logs:"
echo "  ssh $PI_HOST 'sudo journalctl -u selfie-portal -f'"
echo "  ssh $PI_HOST 'sudo tail -f /var/log/nginx/selfies.error.log'"
echo ""
echo "To preview the gnome introduction locally, open test_gnome_intro.html in your browser" 