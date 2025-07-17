#!/bin/bash

echo "=== Selfie Portal Troubleshooting Script ==="
echo "This script will help diagnose issues with the selfie portal"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
    fi
}

echo "1. Checking if selfie-portal service is running..."
if systemctl is-active --quiet selfie-portal; then
    print_status 0 "Selfie portal service is running"
else
    print_status 1 "Selfie portal service is NOT running"
    echo "   Attempting to start service..."
    sudo systemctl start selfie-portal
    sleep 2
    if systemctl is-active --quiet selfie-portal; then
        print_status 0 "Service started successfully"
    else
        print_status 1 "Failed to start service"
        echo "   Checking service status:"
        sudo systemctl status selfie-portal --no-pager -l
    fi
fi

echo ""
echo "2. Checking if port 5001 is listening..."
if netstat -tlnp 2>/dev/null | grep :5001 > /dev/null; then
    print_status 0 "Port 5001 is listening"
    netstat -tlnp 2>/dev/null | grep :5001
else
    print_status 1 "Port 5001 is not listening"
fi

echo ""
echo "3. Checking Flask app directly..."
if curl -s http://localhost:5001/ > /dev/null; then
    print_status 0 "Flask app responds on localhost:5001"
else
    print_status 1 "Flask app does not respond on localhost:5001"
    echo "   Response:"
    curl -v http://localhost:5001/ 2>&1 | head -20
fi

echo ""
echo "4. Checking nginx configuration..."
if nginx -t > /dev/null 2>&1; then
    print_status 0 "Nginx configuration is valid"
else
    print_status 1 "Nginx configuration has errors"
    echo "   Errors:"
    nginx -t 2>&1
fi

echo ""
echo "5. Checking if nginx is running..."
if systemctl is-active --quiet nginx; then
    print_status 0 "Nginx is running"
else
    print_status 1 "Nginx is NOT running"
fi

echo ""
echo "6. Testing nginx proxy to Flask app..."
if curl -s http://localhost/selfies/ > /dev/null; then
    print_status 0 "Nginx proxy to Flask app works"
else
    print_status 1 "Nginx proxy to Flask app fails"
    echo "   Response:"
    curl -v http://localhost/selfies/ 2>&1 | head -20
fi

echo ""
echo "7. Checking DNS resolution for thepub.local..."
if nslookup thepub.local > /dev/null 2>&1; then
    print_status 0 "thepub.local resolves"
    nslookup thepub.local
else
    print_status 1 "thepub.local does not resolve"
fi

echo ""
echo "8. Testing thepub.local/selfies..."
if curl -s http://thepub.local/selfies/ > /dev/null; then
    print_status 0 "thepub.local/selfies responds"
else
    print_status 1 "thepub.local/selfies does not respond"
    echo "   Response:"
    curl -v http://thepub.local/selfies/ 2>&1 | head -20
fi

echo ""
echo "9. Checking Flask app logs..."
if [ -f /var/log/syslog ]; then
    echo "   Recent Flask app errors from syslog:"
    sudo grep -i "selfie\|flask\|5001" /var/log/syslog | tail -10
else
    echo "   No syslog found"
fi

echo ""
echo "10. Checking nginx error logs..."
if [ -f /var/log/nginx/error.log ]; then
    echo "   Recent nginx errors:"
    sudo tail -10 /var/log/nginx/error.log
else
    echo "   No nginx error log found"
fi

echo ""
echo "11. Checking file permissions and structure..."
if [ -d "/var/www/ansibledest.local/apps/selfies" ]; then
    print_status 0 "Selfie portal directory exists"
    echo "   Directory permissions:"
    ls -la /var/www/ansibledest.local/apps/selfies/
    
    if [ -f "/var/www/ansibledest.local/apps/selfies/app.py" ]; then
        print_status 0 "app.py exists"
    else
        print_status 1 "app.py missing"
    fi
    
    if [ -d "/var/www/ansibledest.local/apps/selfies/templates" ]; then
        print_status 0 "templates directory exists"
        ls -la /var/www/ansibledest.local/apps/selfies/templates/
    else
        print_status 1 "templates directory missing"
    fi
    
    if [ -d "/var/www/ansibledest.local/apps/selfies/static" ]; then
        print_status 0 "static directory exists"
        ls -la /var/www/ansibledest.local/apps/selfies/static/
    else
        print_status 1 "static directory missing"
    fi
    
    if [ -d "/var/www/ansibledest.local/apps/selfies/venv" ]; then
        print_status 0 "Virtual environment exists"
    else
        print_status 1 "Virtual environment missing"
    fi
else
    print_status 1 "Selfie portal directory does not exist"
fi

echo ""
echo "12. Checking Python dependencies..."
if [ -f "/var/www/ansibledest.local/apps/selfies/venv/bin/python" ]; then
    echo "   Testing Flask import:"
    /var/www/ansibledest.local/apps/selfies/venv/bin/python -c "import flask; print('Flask version:', flask.__version__)" 2>/dev/null
    if [ $? -eq 0 ]; then
        print_status 0 "Flask is properly installed"
    else
        print_status 1 "Flask import failed"
    fi
else
    print_status 1 "Virtual environment Python not found"
fi

echo ""
echo "13. Checking network connectivity..."
echo "   Testing localhost connectivity:"
if ping -c 1 localhost > /dev/null 2>&1; then
    print_status 0 "localhost is reachable"
else
    print_status 1 "localhost is not reachable"
fi

echo ""
echo "14. Checking firewall status..."
if command -v ufw > /dev/null 2>&1; then
    if ufw status | grep -q "inactive"; then
        print_status 0 "UFW firewall is inactive"
    else
        print_status 1 "UFW firewall is active - may block connections"
        ufw status
    fi
else
    echo "   UFW not installed"
fi

echo ""
echo "=== Troubleshooting Summary ==="
echo "If the selfie portal is not working, common issues are:"
echo "1. Flask app not running (check service status)"
echo "2. Port 5001 not listening (check if app started properly)"
echo "3. Nginx configuration issues (check nginx -t)"
echo "4. DNS resolution problems (check /etc/hosts)"
echo "5. File permission issues (check ownership and permissions)"
echo "6. Missing Python dependencies (check virtual environment)"
echo ""
echo "To restart everything:"
echo "sudo systemctl restart selfie-portal"
echo "sudo systemctl restart nginx"
echo ""
echo "To check real-time logs:"
echo "sudo journalctl -u selfie-portal -f"
echo "sudo tail -f /var/log/nginx/error.log" 