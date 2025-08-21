# Selfie Portal Troubleshooting Guide

## Overview

The Selfie Portal is a Flask-based web application that allows WiFi users to take and share selfies through their device cameras. The system uses a multi-layered architecture with several interconnected components that must work together seamlessly.

## System Architecture

```
WiFi Clients (JoinMe network)
    ↓ (HTTPS via local DNS)
Local Nginx (10.10.42.1:443) ←→ SSL Certificates
    ↓ (HTTP proxy)
Flask App (localhost:5001)
    ↓ (File storage)
Local filesystem (/var/www/thepub.local/apps/selfies/)

External Access:
Internet Users
    ↓ (HTTPS)
Cloudflare Edge Servers
    ↓ (Cloudflare Tunnel)
Local Nginx (10.10.42.1:80) ←→ Flask App
```

## Feature Overview

### Core Features
- **Camera Access**: Browser-based camera API for taking selfies
- **Image Upload**: Drag-and-drop or camera capture with optional captions
- **Gallery View**: Browse community selfies with thumbnails
- **Mobile Responsive**: Optimized for phone/tablet use
- **Real-time Updates**: Gallery refreshes to show new uploads

### Technical Requirements
- **HTTPS Context**: Camera API requires secure context (HTTPS)
- **File Handling**: Image upload, resize, and storage
- **JSON Data**: Metadata storage for selfie information
- **Static Assets**: CSS, JavaScript, and image serving

---

## 1. Flask Application Layer

### Purpose
The Flask app (`app.py`) handles all backend logic: camera interface, file uploads, image processing, and gallery management.

### Key Components
- **Route Handlers**: `/`, `/upload`, `/gallery`, `/health`
- **File Upload**: Handles image processing and storage
- **Image Processing**: Resizing and format conversion
- **Data Management**: JSON-based metadata storage

### Troubleshooting Flask App

#### Check Service Status
```bash
# Check if selfie-portal service is running
sudo systemctl status selfie-portal.service

# View real-time logs
sudo journalctl -u selfie-portal.service -f

# Check if app responds on port 5001
curl http://localhost:5001/health
```

#### Common Flask Issues

**Issue: Service won't start**
```bash
# Check Python virtual environment
ls -la /var/www/thepub.local/apps/selfies/venv/

# Test app manually
cd /var/www/thepub.local/apps/selfies/
./venv/bin/python app.py

# Check dependencies
./venv/bin/pip list | grep -E "(Flask|Pillow|Werkzeug)"
```

**Issue: Upload failures**
```bash
# Check upload directory permissions
ls -la /var/www/thepub.local/apps/selfies/data/uploads/
sudo chown -R www-data:www-data /var/www/thepub.local/apps/selfies/data/

# Check disk space
df -h /var/www/

# Test upload endpoint directly
curl -X POST http://localhost:5001/upload \
  -F "file=@test.jpg" \
  -F "caption=test"
```

**Issue: Gallery not updating**
```bash
# Check data/index.json file
cat /var/www/thepub.local/apps/selfies/data/index.json

# Verify file permissions
ls -la /var/www/thepub.local/apps/selfies/data/
```

#### Flask Debug Commands
```bash
# Enable debug mode (edit service file)
sudo systemctl edit selfie-portal.service
# Add: Environment="FLASK_DEBUG=1"

# Check Python path issues
cd /var/www/thepub.local/apps/selfies/
./venv/bin/python -c "import flask; print(flask.__version__)"

# Test specific routes
curl -v http://localhost:5001/
curl -v http://localhost:5001/gallery
```

---

## 2. Nginx Proxy Layer

### Purpose
Nginx serves as a reverse proxy, handling SSL termination, static file serving, and routing between different applications.

### Key Configuration Files
- **Main site**: `/etc/nginx/sites-available/thepub.local`
- **Cloudflare domain**: `/etc/nginx/sites-available/selfies.griffincreektrestle.net`
- **Enabled sites**: `/etc/nginx/sites-enabled/`

### Troubleshooting Nginx

#### Check Nginx Status
```bash
# Check if nginx is running
sudo systemctl status nginx

# Test configuration syntax
sudo nginx -t

# Check enabled sites
ls -la /etc/nginx/sites-enabled/

# View error logs
sudo tail -f /var/log/nginx/error.log
```

#### Common Nginx Issues

**Issue: 502 Bad Gateway**
```bash
# Check if Flask app is running
curl http://localhost:5001/health

# Check nginx error logs for proxy errors
sudo grep "proxy" /var/log/nginx/error.log

# Test proxy configuration
sudo nginx -T | grep -A 10 "proxy_pass"
```

**Issue: Static files not loading**
```bash
# Check static file paths in nginx config
grep -r "static" /etc/nginx/sites-available/

# Verify static files exist
ls -la /var/www/thepub.local/apps/selfies/static/

# Test static file access directly
curl -I http://10.10.42.1/static/style.css
```

**Issue: Server name conflicts**
```bash
# Check for conflicting server blocks
sudo nginx -T | grep -B 5 -A 5 "server_name.*thepub.local"

# Look for duplicate configurations
sudo grep -r "server_name" /etc/nginx/sites-available/
```

#### Nginx Debug Commands
```bash
# Check what nginx is actually serving
curl -H "Host: selfies.griffincreektrestle.net" http://10.10.42.1/

# Test SSL configuration
curl -k -I https://10.10.42.1/

# Check proxy headers
curl -H "Host: selfies.griffincreektrestle.net" -v http://10.10.42.1/ 2>&1 | grep -E "(Host|X-)"
```

---

## 3. SSL Certificate Configuration

### Purpose
SSL certificates enable HTTPS access, which is required for camera API functionality. The system uses self-signed certificates locally while Cloudflare provides valid certificates to external users.

### Certificate Locations
- **Certificate**: `/etc/ssl/certs/ssl-cert-snakeoil.pem`
- **Private Key**: `/etc/ssl/private/ssl-cert-snakeoil.key`
- **Nginx SSL Config**: In server blocks with `listen 443 ssl`

### Troubleshooting SSL

#### Check SSL Certificate Status
```bash
# Verify certificates exist
sudo ls -la /etc/ssl/certs/ssl-cert-snakeoil.pem
sudo ls -la /etc/ssl/private/ssl-cert-snakeoil.key

# Check certificate details
openssl x509 -in /etc/ssl/certs/ssl-cert-snakeoil.pem -text -noout

# Test SSL connection
openssl s_client -connect 10.10.42.1:443 -servername selfies.griffincreektrestle.net
```

#### Common SSL Issues

**Issue: Certificate file not found**
```bash
# Generate new self-signed certificate
sudo make-ssl-cert generate-default-snakeoil --force-overwrite

# Update nginx SSL configuration
sudo grep -r "ssl_certificate" /etc/nginx/sites-available/
```

**Issue: SSL handshake failures**
```bash
# Check SSL configuration in nginx
sudo nginx -T | grep -A 10 -B 5 "ssl"

# Test with curl ignoring certificate validation
curl -k -I https://10.10.42.1/

# Check SSL protocols and ciphers
openssl ciphers -v | head -10
```

**Issue: Mixed content warnings**
```bash
# Verify all resources load over HTTPS
curl -k https://10.10.42.1/ | grep -E "(http://|src=|href=)"

# Check nginx SSL headers
curl -k -I https://10.10.42.1/ | grep -i "strict\|security"
```

#### SSL Debug Commands
```bash
# Test SSL with specific hostname
curl -k -H "Host: selfies.griffincreektrestle.net" https://10.10.42.1/

# Check SSL cipher negotiation
nmap --script ssl-enum-ciphers -p 443 10.10.42.1

# Verify certificate chain
echo | openssl s_client -connect 10.10.42.1:443 -servername selfies.griffincreektrestle.net 2>&1 | openssl x509 -noout -text
```

---

## 4. Cloudflare Tunnel Configuration

### Purpose
Cloudflare tunnels provide secure external access to the local application without exposing the Pi directly to the internet. The tunnel creates an encrypted connection between the Pi and Cloudflare's edge servers.

### Key Components
- **Tunnel Service**: `cloudflared@<tunnel-name>.service`
- **Configuration**: `/etc/cloudflared/config.yml`
- **Credentials**: `/home/pi/.cloudflared/<tunnel-id>.json`
- **DNS Routing**: Cloudflare dashboard or CLI

### Troubleshooting Cloudflare Tunnels

#### Check Tunnel Status
```bash
# List available tunnels
/usr/local/bin/cloudflared tunnel list

# Check tunnel service status
sudo systemctl status cloudflared@<tunnel-name>.service

# View tunnel logs
sudo journalctl -u cloudflared@<tunnel-name>.service -f

# Check tunnel connections
/usr/local/bin/cloudflared tunnel info <tunnel-name>
```

#### Common Tunnel Issues

**Issue: Tunnel authentication failures**
```bash
# Check credentials file
ls -la /home/pi/.cloudflared/
cat /home/pi/.cloudflared/<tunnel-id>.json

# Verify tunnel exists
/usr/local/bin/cloudflared tunnel list | grep <tunnel-name>

# Test tunnel connectivity
/usr/local/bin/cloudflared tunnel --config /etc/cloudflared/config.yml run
```

**Issue: 530 Origin unreachable errors**
```bash
# Check if nginx is accessible locally
curl -H "Host: selfies.griffincreektrestle.net" http://localhost:80/

# Verify tunnel configuration
cat /etc/cloudflared/config.yml

# Check for service conflicts
sudo ss -tlnp | grep :80
```

**Issue: DNS routing problems**
```bash
# Check DNS routes
/usr/local/bin/cloudflared tunnel route dns list

# Test external DNS resolution
nslookup selfies.griffincreektrestle.net 8.8.8.8

# Verify domain points to Cloudflare
dig selfies.griffincreektrestle.net | grep -A 5 "ANSWER SECTION"
```

#### Tunnel Debug Commands
```bash
# Test tunnel connectivity manually
/usr/local/bin/cloudflared tunnel --loglevel debug --config /etc/cloudflared/config.yml run

# Check Cloudflare edge connectivity
curl -I https://selfies.griffincreektrestle.net/cdn-cgi/trace

# Test local service that tunnel proxies to
curl -H "Host: selfies.griffincreektrestle.net" http://localhost:80/health

# Create new tunnel if needed
/usr/local/bin/cloudflared tunnel create new-tunnel-name
```

---

## 5. Nodogsplash Captive Portal Integration

### Purpose
Nodogsplash provides the captive portal experience that intercepts unauthenticated WiFi users and presents the integrated splash page featuring selfie portal preview. After authentication, users are automatically redirected to the HTTPS selfie portal.

### Integration Architecture
```
WiFi Client connects to "JoinMe" → Nodogsplash captures traffic → 
Integrated Splash Page (preview) → User authentication → 
Auto-redirect to HTTPS Selfie Portal
```

### Key Components
- **Integrated Splash Page**: `/etc/nodogsplash/htdocs/splash-with-selfie-portal.html`
- **Configuration**: `/etc/nodogsplash/nodogsplash.conf` 
- **Service**: `nodogsplash.service`
- **Web Server**: Nodogsplash internal server on port 2050

### Troubleshooting Nodogsplash Integration

#### Check Integration Status
```bash
# Verify service is running
sudo systemctl status nodogsplash

# Check configuration uses integrated splash page
grep "SplashPage.*splash-with-selfie-portal" /etc/nodogsplash/nodogsplash.conf

# Verify redirect URL points to selfie portal
grep "RedirectURL.*selfies.griffincreektrestle.net" /etc/nodogsplash/nodogsplash.conf

# Check integrated splash page exists
ls -la /etc/nodogsplash/htdocs/splash-with-selfie-portal.html
```

#### Common Integration Issues

**Issue: Users see default splash page instead of integrated version**
```bash
# Check current splash page setting
grep -A1 -B1 "SplashPage" /etc/nodogsplash/nodogsplash.conf

# Should show:
# SplashPage splash-with-selfie-portal.html

# Fix if showing default
sudo sed -i 's|# SplashPage splash.html|SplashPage splash-with-selfie-portal.html|' /etc/nodogsplash/nodogsplash.conf
sudo systemctl restart nodogsplash
```

**Issue: Users not redirected to selfie portal after authentication**
```bash
# Check redirect URL configuration
grep "RedirectURL" /etc/nodogsplash/nodogsplash.conf

# Should show:
# RedirectURL https://selfies.griffincreektrestle.net/

# Fix if missing or incorrect
sudo sed -i 's|^RedirectURL.*|RedirectURL https://selfies.griffincreektrestle.net/|' /etc/nodogsplash/nodogsplash.conf
sudo systemctl restart nodogsplash
```

**Issue: Captive portal doesn't appear when connecting to WiFi**
```bash
# Check if nodogsplash is capturing traffic
sudo iptables -L -n | grep 2050

# Check WiFi interface configuration
grep -A2 -B2 "GatewayInterface" /etc/nodogsplash/nodogsplash.conf

# Test nodogsplash web server directly
curl -I http://10.10.42.1:2050/
```

**Issue: Integrated splash page has errors or doesn't load**
```bash
# Test configuration validity
sudo nodogsplash -s

# Check splash page syntax
head -20 /etc/nodogsplash/htdocs/splash-with-selfie-portal.html

# Test splash page access
curl http://10.10.42.1:2050/splash-with-selfie-portal.html | head -10

# Check file permissions
ls -la /etc/nodogsplash/htdocs/splash-with-selfie-portal.html
```

**Issue: Authentication flow breaks**
```bash
# Check nodogsplash logs for authentication errors
sudo journalctl -u nodogsplash -n 20

# Test authentication endpoint
curl -X GET "http://10.10.42.1:2050/nodogsplash_auth/?tok=test&redir=/"

# Verify firewall rules allow HTTPS
grep -A5 -B5 "443" /etc/nodogsplash/nodogsplash.conf
```

#### Nodogsplash Debug Commands
```bash
# View real-time nodogsplash logs
sudo journalctl -u nodogsplash -f

# Check client list and status
sudo ndsctl clients

# Test configuration without running service
sudo nodogsplash -s -d 3

# Check firewall rules created by nodogsplash
sudo iptables -L -n | grep -E "(2050|NDSRULE)"

# Reset client authentication (clear all authenticated users)
sudo ndsctl deauth all
```

#### End-to-End Integration Testing
```bash
# Test complete user flow simulation
echo "=== Nodogsplash Integration Test ==="

echo "1. Check service status:"
systemctl is-active nodogsplash

echo "2. Test splash page access:"
curl -s http://10.10.42.1:2050/splash-with-selfie-portal.html | grep -i "selfie portal" || echo "❌ Splash page issue"

echo "3. Check WiFi AP broadcasting:"
nmcli device wifi list | grep "JoinMe" || echo "❌ WiFi AP not found"

echo "4. Verify redirect URL:"
grep "RedirectURL.*selfies.griffincreektrestle.net" /etc/nodogsplash/nodogsplash.conf || echo "❌ Redirect not configured"

echo "5. Test HTTPS access target:"
curl -k -s -I https://10.10.42.1/ | head -1
```

#### Captive Portal User Experience Flow

**Expected Flow:**
1. **Connect to "JoinMe" WiFi** (no password)
2. **Open any website** → Browser redirected to captive portal
3. **See integrated splash page** with selfie portal preview and features
4. **Click "Connect & Start Sharing!"** → Authentication occurs
5. **Auto-redirect** → `https://selfies.griffincreektrestle.net/`
6. **Camera access works** immediately in HTTPS context

**Troubleshooting Flow Issues:**
```bash
# Step 1: Verify WiFi connection
# (On client device)
nmcli device wifi connect JoinMe

# Step 2: Test captive portal detection
# (On client device - open browser to any HTTP site)
curl -I http://example.com

# Step 3: Verify splash page content
curl http://10.10.42.1:2050/splash-with-selfie-portal.html | grep -A5 -B5 "selfie"

# Step 4: Test authentication
# (Check logs during user click)
sudo journalctl -u nodogsplash -f

# Step 5: Verify redirect works
# (Should see Location header pointing to HTTPS selfie portal)
```

#### Recovery Procedures for Integration Issues

**Complete Nodogsplash Reset:**
```bash
# Stop service
sudo systemctl stop nodogsplash

# Clear all authenticated clients
sudo rm -f /tmp/nodogsplash.clients 2>/dev/null

# Reset iptables rules
sudo ndsctl stop 2>/dev/null || true

# Restart with fresh state
sudo systemctl start nodogsplash

# Wait for initialization
sleep 5

# Verify service started correctly
systemctl is-active nodogsplash
```

**Redeploy Integration Files:**
```bash
# Backup existing files
sudo cp /etc/nodogsplash/htdocs/splash-with-selfie-portal.html /tmp/splash-backup-$(date +%s).html 2>/dev/null || true

# Redeploy from playbook directory
sudo cp /home/pi/Playbooks/Instant_Community_Wifi_Portal/etc/nodogsplash/htdocs/splash-with-selfie-portal.html /etc/nodogsplash/htdocs/

# Fix permissions
sudo chown root:root /etc/nodogsplash/htdocs/splash-with-selfie-portal.html
sudo chmod 644 /etc/nodogsplash/htdocs/splash-with-selfie-portal.html

# Restart service to pick up changes
sudo systemctl restart nodogsplash
```

---

## 6. DNS and Network Configuration

### Purpose
DNS configuration ensures that local WiFi clients resolve the Cloudflare domain to the local IP address, while external users resolve to Cloudflare's edge servers.

### Key Components
- **dnsmasq**: Local DNS server for WiFi clients
- **DNS Override**: `/etc/dnsmasq.conf` with `address=/selfies.griffincreektrestle.net/10.10.42.1`
- **Upstream DNS**: Pi uses router DNS for external resolution

### Troubleshooting DNS

#### Check DNS Configuration
```bash
# Verify dnsmasq is running
sudo systemctl status dnsmasq

# Check DNS overrides
grep "address=/" /etc/dnsmasq.conf

# Test local DNS resolution
# (from WiFi client perspective)
nslookup selfies.griffincreektrestle.net 10.10.42.1
```

#### Common DNS Issues

**Issue: Domain resolves to wrong IP**
```bash
# Check what Pi resolves domain to
getent hosts selfies.griffincreektrestle.net

# Check what dnsmasq resolves domain to
dig @10.10.42.1 selfies.griffincreektrestle.net

# Verify dnsmasq configuration
sudo dnsmasq --test
```

**Issue: WiFi clients can't resolve domain**
```bash
# Check DHCP DNS assignment
sudo grep "dhcp-option" /etc/dnsmasq.conf

# Test from client device
# (on connected device)
nslookup selfies.griffincreektrestle.net

# Check if dnsmasq is serving DHCP/DNS
sudo ss -tulnp | grep :53
```

---

## 6. Integrated Troubleshooting Workflows

### Complete System Health Check

#### Quick Status Check
```bash
#!/bin/bash
echo "=== Selfie Portal Health Check ==="

echo "1. Flask App Status:"
systemctl is-active selfie-portal.service
curl -s http://localhost:5001/health | head -1

echo "2. Nginx Status:"
systemctl is-active nginx.service
nginx -t 2>&1 | grep -E "(syntax|test)"

echo "3. SSL Certificate:"
ls /etc/ssl/certs/ssl-cert-snakeoil.pem >/dev/null 2>&1 && echo "✓ Exists" || echo "✗ Missing"

echo "4. Nodogsplash Integration:"
systemctl is-active nodogsplash.service
grep -q "splash-with-selfie-portal" /etc/nodogsplash/nodogsplash.conf && echo "✓ Integrated" || echo "✗ Default"

echo "5. Cloudflare Tunnel:"
systemctl is-active cloudflared@*.service 2>/dev/null || echo "Not running"

echo "6. DNS Configuration:"
grep -c "address=/selfies.griffincreektrestle.net" /etc/dnsmasq.conf

echo "7. WiFi AP Broadcasting:"
nmcli device wifi list | grep -q "JoinMe" && echo "✓ Broadcasting" || echo "✗ Not found"

echo "8. Local HTTPS Access:"
curl -k -s -o /dev/null -w "%{http_code}" https://10.10.42.1/

echo "9. Captive Portal Flow:"
curl -s http://10.10.42.1:2050/splash-with-selfie-portal.html | grep -q "selfie" && echo "✓ Integration active" || echo "✗ Issue detected"
```

#### End-to-End Testing

**Test Local WiFi Client Experience:**
```bash
# Simulate WiFi client accessing domain
curl -k -H "Host: selfies.griffincreektrestle.net" https://10.10.42.1/ | head -5

# Test camera page loads
curl -k -s https://10.10.42.1/ | grep -i camera

# Test static assets
curl -k -I https://10.10.42.1/static/style.css

# Test upload endpoint
curl -k -X POST https://10.10.42.1/upload \
  -F "file=@test.jpg" \
  -F "caption=Test from CLI"
```

**Test External Access:**
```bash
# Test external domain resolution
dig selfies.griffincreektrestle.net | grep -A 5 "ANSWER SECTION"

# Test external HTTPS access
curl -I https://selfies.griffincreektrestle.net/

# Test tunnel connectivity from edge
curl -I https://selfies.griffincreektrestle.net/cdn-cgi/trace
```

### Integration-Specific Error Patterns and Solutions

#### Pattern: Captive portal shows default splash instead of integrated version
**Symptoms**: Users see basic nodogsplash splash page, no selfie portal preview
**Diagnosis**:
```bash
# Check configuration
grep "SplashPage" /etc/nodogsplash/nodogsplash.conf

# Check file exists
ls -la /etc/nodogsplash/htdocs/splash-with-selfie-portal.html
```
**Solution**: Update nodogsplash configuration and restart service

#### Pattern: Users authenticated but not redirected to selfie portal
**Symptoms**: Authentication works but users stay on success page or go to default redirect
**Diagnosis**:
```bash
# Check redirect URL
grep "RedirectURL" /etc/nodogsplash/nodogsplash.conf

# Test HTTPS selfie portal accessibility
curl -k -I https://10.10.42.1/
```
**Solution**: Configure correct RedirectURL and ensure HTTPS selfie portal is accessible

#### Pattern: Integration page loads but preview features don't work
**Symptoms**: Splash page displays but interactive elements fail, JavaScript errors
**Diagnosis**:
```bash
# Check splash page content
curl http://10.10.42.1:2050/splash-with-selfie-portal.html | grep -E "(error|script)"

# Check CSS/JS dependencies
curl -I http://10.10.42.1:2050/splash.css
```
**Solution**: Ensure all static assets are accessible and page HTML is valid

#### Pattern: Captive portal doesn't trigger on WiFi connection
**Symptoms**: Users connect to JoinMe but browser doesn't redirect to captive portal
**Diagnosis**:
```bash
# Check nodogsplash service status
systemctl status nodogsplash

# Check firewall rules
sudo iptables -L -n | grep 2050

# Check interface configuration
grep "GatewayInterface" /etc/nodogsplash/nodogsplash.conf
```
**Solution**: Restart nodogsplash service and verify network configuration

### Common Error Patterns and Solutions

#### Pattern: Camera not working
**Symptoms**: Camera interface shows "Camera not available" or permission errors
**Diagnosis**:
```bash
# Check if HTTPS is working
curl -k -I https://10.10.42.1/

# Verify client is using HTTPS
# (Check browser dev tools for mixed content errors)
```
**Solution**: Ensure clients access via HTTPS context

#### Pattern: Images not uploading
**Symptoms**: Upload button doesn't work, or uploads fail silently
**Diagnosis**:
```bash
# Check Flask app logs
journalctl -u selfie-portal.service -n 20

# Test upload endpoint directly
curl -X POST http://localhost:5001/upload -F "file=@test.jpg"

# Check file permissions
ls -la /var/www/thepub.local/apps/selfies/data/uploads/
```
**Solution**: Fix file permissions or Flask app errors

#### Pattern: External access fails
**Symptoms**: Domain returns 530 errors or timeouts
**Diagnosis**:
```bash
# Check tunnel status
systemctl status cloudflared@*.service

# Test local nginx accessibility
curl -H "Host: selfies.griffincreektrestle.net" http://localhost:80/

# Verify DNS routing
dig selfies.griffincreektrestle.net
```
**Solution**: Fix tunnel authentication or DNS routing

### Recovery Procedures

#### Complete Service Restart
```bash
# Restart all related services in correct order
sudo systemctl restart dnsmasq.service
sudo systemctl restart nodogsplash.service
sudo systemctl restart nginx.service
sudo systemctl restart selfie-portal.service
sudo systemctl restart cloudflared@*.service

# Wait for services to start
sleep 10

# Run comprehensive validation
/usr/local/bin/validate-ap.sh

# Run health check
curl -k https://10.10.42.1/health
```

### Using the Validation Script with Integration

The system validation script (`/usr/local/bin/validate-ap.sh`) now includes comprehensive testing for the nodogsplash integration:

#### Enhanced Validation Features
```bash
# Run full validation (includes all integration tests)
/usr/local/bin/validate-ap.sh

# Focus on captive portal integration tests
/usr/local/bin/validate-ap.sh | grep -A5 -B5 -E "(nodogsplash|captive|splash)"

# Check specific integration components
/usr/local/bin/validate-ap.sh | grep -E "(✓|✗)" | grep -v "PASS"
```

#### What the Validation Script Now Tests
1. **WiFi AP Broadcasting** - JoinMe network availability
2. **Nodogsplash Service** - Captive portal service status
3. **Integrated Splash Page** - Custom splash page deployment
4. **Authentication Flow** - Redirect URL configuration
5. **HTTPS Selfie Portal** - Final destination accessibility
6. **DNS Resolution** - Local domain override for WiFi clients
7. **Camera API Requirements** - HTTPS context for camera access
8. **File Upload Functionality** - End-to-end upload testing
9. **Gallery Access** - Community gallery functionality
10. **External Access** - Cloudflare tunnel connectivity

#### Interpreting Validation Results
```bash
# All tests passing (expected)
Total Tests: 26
Passed: 26
Failed: 0
🎉 ALL TESTS PASSED! WiFi AP is functioning correctly.

# Integration specific test failures to watch for:
❌ Nodogsplash service not running
❌ Integrated splash page not configured
❌ Authentication redirect not working
❌ HTTPS selfie portal inaccessible
```

#### Validation Troubleshooting Workflow
```bash
# Step 1: Run validation and identify failures
/usr/local/bin/validate-ap.sh > /tmp/validation_results.txt

# Step 2: Focus on failed tests
grep -E "(✗|FAIL)" /tmp/validation_results.txt

# Step 3: Run targeted troubleshooting based on failures
# For nodogsplash issues:
sudo journalctl -u nodogsplash -n 20

# For integration issues:
ls -la /etc/nodogsplash/htdocs/splash-with-selfie-portal.html
grep "SplashPage\|RedirectURL" /etc/nodogsplash/nodogsplash.conf

# For WiFi AP issues:
nmcli device status | grep wlan1
systemctl status dnsmasq

# Step 4: Re-run validation after fixes
/usr/local/bin/validate-ap.sh
```

#### Recreate Cloudflare Tunnel
```bash
# Stop existing tunnel
sudo systemctl stop cloudflared@*.service

# Create new tunnel
/usr/local/bin/cloudflared tunnel create selfie-portal-new

# Update configuration
sudo nano /etc/cloudflared/config.yml
# Update tunnel name and credentials file

# Test new tunnel
/usr/local/bin/cloudflared tunnel --config /etc/cloudflared/config.yml run

# Start service
sudo systemctl start cloudflared@selfie-portal-new.service
```

#### Update DNS Record in Cloudflare Dashboard
When you create a new tunnel or the tunnel ID changes, you **must** update the DNS record:

```bash
# Get the new tunnel ID
/usr/local/bin/cloudflared tunnel list

# Note the tunnel ID (36-character UUID)
```

Then manually update in Cloudflare Dashboard:

1. **Go to**: https://dash.cloudflare.com/
2. **Navigate to**: Your Domain → DNS → Records  
3. **Find**: `selfies.griffincreektrestle.net` (Type: CNAME)
4. **Get Tunnel ID**: Run `cloudflared tunnel list` and copy the 36-character tunnel ID
   ```
   Example output:
   ID                                   NAME                     CREATED
   3fce67f6-1d3b-4ef4-b2de-1297ec9d08f5 selfie-portal-new       2025-08-19T22:26:33Z
   ```
   Copy: `3fce67f6-1d3b-4ef4-b2de-1297ec9d08f5`
5. **Update CNAME target to**: `[YOUR-TUNNEL-ID].cfargotunnel.com`
   Example: `3fce67f6-1d3b-4ef4-b2de-1297ec9d08f5.cfargotunnel.com`
6. **Save** and wait 1-2 minutes for DNS propagation

**Why Manual Update is Required**: The `cloudflared tunnel route dns` command fails when a CNAME record already exists. You must update the existing record to point to the new tunnel.

#### Reset Flask Application
```bash
# Stop service
sudo systemctl stop selfie-portal.service

# Clear data (backup first!)
sudo cp -r /var/www/thepub.local/apps/selfies/data/ /tmp/selfie-backup/

# Reset permissions
sudo chown -R www-data:www-data /var/www/thepub.local/apps/selfies/

# Restart service
sudo systemctl start selfie-portal.service

# Test functionality
curl http://localhost:5001/health
```

---

## Understanding the Overall System

### Why This Architecture?

1. **Flask App (Port 5001)**: Handles complex Python logic, image processing, and file management
2. **Nginx Proxy**: Provides SSL termination, static file serving, and load balancing capabilities
3. **SSL Certificates**: Required for camera API access in modern browsers
4. **Cloudflare Tunnel**: Secure external access without port forwarding or exposing Pi directly
5. **DNS Override**: Allows same domain to work locally and externally with different backends

### Common Misconceptions

- **"Why not serve Flask directly with SSL?"**: Flask's built-in server isn't production-ready for SSL or high concurrency
- **"Why not just use HTTP?"**: Camera API requires HTTPS security context
- **"Why both local and external access?"**: Local provides fast, private access; external enables remote administration
- **"Why Cloudflare tunnels instead of port forwarding?"**: More secure, handles SSL certificates, provides DDoS protection

### Performance Considerations

- **Image Size**: Large uploads can overwhelm the system - consider implementing resize on upload
- **Storage**: Monitor disk usage in `/var/www/thepub.local/apps/selfies/data/uploads/`
- **Memory**: Flask app may need memory limits if processing many large images
- **Network**: Local access is much faster than external tunnel access

### Security Notes

- **Self-signed Certificates**: Only for local access - Cloudflare provides valid certs externally
- **File Upload Validation**: Ensure only image files are accepted to prevent exploits
- **Directory Permissions**: Restrict write access to necessary directories only
- **Tunnel Security**: Cloudflare tunnels are more secure than opening ports, but monitor access logs

---

This guide should help you systematically diagnose and resolve issues with the selfie portal system. Remember that the components are interdependent, so issues in one layer often manifest as symptoms in another layer.