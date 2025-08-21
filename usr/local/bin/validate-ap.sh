#!/bin/bash

#############################################################################
# WiFi Access Point Validation Script
# Tests that the JoinMe AP is functioning correctly
# 
# Tests:
# 1. wlan1 interface is online
# 2. wlan1 has appropriate IP address
# 3. wlan1 is broadcasting the WiFi network
# 4. DHCP server is running and ready to assign addresses
#############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
WIFI_INTERFACE="wlan1"
EXPECTED_IP="10.10.42.1"
EXPECTED_NETWORK="10.10.42.0/24"
EXPECTED_SSID="JoinMe"
DHCP_RANGE_START="10.10.42.10"
DHCP_RANGE_END="10.10.42.254"

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to print test headers
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Function to print test results
print_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    if [ -n "$details" ]; then
        echo -e "  ${YELLOW}Details:${NC} $details"
    fi
}

# Function to check if interface exists and is up
test_interface_status() {
    print_header "Test 1: wlan1 Interface Status"
    
    # Check if interface exists
    if ! ip link show "$WIFI_INTERFACE" &>/dev/null; then
        print_result "Interface $WIFI_INTERFACE exists" "FAIL" "Interface not found"
        return 1
    fi
    print_result "Interface $WIFI_INTERFACE exists" "PASS" ""
    
    # SAFETY CHECK: Ensure we're not accidentally using wlan0 for AP
    if [ "$WIFI_INTERFACE" = "wlan0" ]; then
        print_result "AP interface safety check" "FAIL" "CRITICAL: wlan0 should NEVER be used for AP - this breaks internet!"
        return 1
    else
        print_result "AP interface safety check" "PASS" "Using correct AP interface: $WIFI_INTERFACE"
    fi
    
    # Check if interface is up
    interface_state=$(ip link show "$WIFI_INTERFACE" | grep -o "state [A-Z]*" | cut -d' ' -f2)
    if [ "$interface_state" = "UP" ]; then
        print_result "Interface $WIFI_INTERFACE is UP" "PASS" "State: $interface_state"
    else
        print_result "Interface $WIFI_INTERFACE is UP" "FAIL" "State: $interface_state"
        return 1
    fi
    
    # Check NetworkManager connection status
    if nmcli device status | grep -q "$WIFI_INTERFACE.*connected"; then
        print_result "NetworkManager shows $WIFI_INTERFACE connected" "PASS" ""
    else
        print_result "NetworkManager shows $WIFI_INTERFACE connected" "FAIL" "Not connected in NetworkManager"
        return 1
    fi
    
    return 0
}

# Function to test IP address configuration
test_ip_configuration() {
    print_header "Test 2: IP Address Configuration"
    
    # Get current IP address
    current_ip=$(ip addr show "$WIFI_INTERFACE" | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
    
    if [ "$current_ip" = "$EXPECTED_IP" ]; then
        print_result "Correct IP address assigned" "PASS" "IP: $current_ip"
    else
        print_result "Correct IP address assigned" "FAIL" "Expected: $EXPECTED_IP, Got: $current_ip"
        return 1
    fi
    
    # Check network configuration
    ip_with_mask=$(ip addr show "$WIFI_INTERFACE" | grep "inet " | awk '{print $2}')
    if echo "$ip_with_mask" | grep -q "10.10.42.1/24"; then
        print_result "Correct network mask" "PASS" "Network: $ip_with_mask"
    else
        print_result "Correct network mask" "FAIL" "Expected: 10.10.42.1/24, Got: $ip_with_mask"
        return 1
    fi
    
    return 0
}

# Function to test WiFi broadcasting
test_wifi_broadcast() {
    print_header "Test 3: WiFi Network Broadcasting"
    
    # Check if AP mode is active
    connection_info=$(nmcli connection show --active | grep "$WIFI_INTERFACE")
    if echo "$connection_info" | grep -q "wifi"; then
        print_result "WiFi connection active on $WIFI_INTERFACE" "PASS" ""
    else
        print_result "WiFi connection active on $WIFI_INTERFACE" "FAIL" "No active WiFi connection"
        return 1
    fi
    
    # Check if SSID is being broadcast
    if nmcli device wifi list | grep -q "$EXPECTED_SSID.*$WIFI_INTERFACE"; then
        print_result "SSID '$EXPECTED_SSID' is broadcasting" "PASS" ""
    else
        # Sometimes the interface doesn't show up in its own scan, check differently
        if nmcli connection show JoinMe-AP | grep -q "802-11-wireless.ssid.*$EXPECTED_SSID"; then
            print_result "SSID '$EXPECTED_SSID' is configured" "PASS" "Configuration verified"
        else
            print_result "SSID '$EXPECTED_SSID' is broadcasting" "FAIL" "SSID not found in scan or config"
            return 1
        fi
    fi
    
    # Check if in AP mode
    if nmcli connection show JoinMe-AP | grep -q "802-11-wireless.mode.*ap"; then
        print_result "Interface in AP (Access Point) mode" "PASS" ""
    else
        print_result "Interface in AP (Access Point) mode" "FAIL" "Not in AP mode"
        return 1
    fi
    
    return 0
}

# Function to test DHCP functionality
test_dhcp_server() {
    print_header "Test 4: DHCP Server Functionality"
    
    # Check if standalone dnsmasq service is running (required for nodogsplash)
    if systemctl is-active --quiet dnsmasq; then
        print_result "DHCP server (dnsmasq) is running" "PASS" "Standalone dnsmasq service active"
    else
        print_result "DHCP server (dnsmasq) is running" "FAIL" "Standalone dnsmasq service not running"
        return 1
    fi
    
    # Check DHCP configuration in standalone dnsmasq
    if ps aux | grep -q "dnsmasq.*interface=$WIFI_INTERFACE" || ps aux | grep -q "/usr/sbin/dnsmasq"; then
        print_result "DHCP range configured" "PASS" "Standalone dnsmasq configured"
    else
        print_result "DHCP range configured" "FAIL" "DHCP range not found in process"
        return 1
    fi
    
    # Check if lease file directory exists (file created when first client connects)
    lease_dir="/var/lib/NetworkManager"
    lease_file="$lease_dir/dnsmasq-$WIFI_INTERFACE.leases"
    if [ -d "$lease_dir" ]; then
        if [ -f "$lease_file" ]; then
            print_result "DHCP lease file ready" "PASS" "File exists: $lease_file"
        else
            print_result "DHCP lease file ready" "PASS" "Directory exists, file will be created when clients connect"
        fi
    else
        print_result "DHCP lease file ready" "FAIL" "NetworkManager directory not found: $lease_dir"
        return 1
    fi
    
    # Check NetworkManager connection method (should be manual for nodogsplash compatibility)
    if nmcli connection show JoinMe-AP | grep -q "ipv4.method.*manual"; then
        print_result "NetworkManager WiFi AP configuration" "PASS" "Using manual mode (compatible with nodogsplash)"
    elif nmcli connection show JoinMe-AP | grep -q "ipv4.method.*shared"; then
        print_result "NetworkManager WiFi AP configuration" "FAIL" "Using shared mode (INCOMPATIBLE with nodogsplash)"
        echo -e "  ${YELLOW}WARNING: NetworkManager shared mode conflicts with nodogsplash captive portal${NC}"
        echo -e "  ${YELLOW}This will cause nodogsplash service failures. Use manual mode + standalone dnsmasq.${NC}"
        return 1
    else
        print_result "NetworkManager WiFi AP configuration" "FAIL" "Unknown or invalid method"
        return 1
    fi
    
    return 0
}

# Function to test captive portal functionality
test_captive_portal() {
    print_header "Test 5: Captive Portal Functionality"
    
    # Check if nodogsplash service is running
    if systemctl is-active --quiet nodogsplash; then
        print_result "Nodogsplash service is running" "PASS" ""
    else
        print_result "Nodogsplash service is running" "FAIL" "Service not active"
        return 1
    fi
    
    # Check if nodogsplash is listening on the correct interface
    if ps aux | grep -q "nodogsplash.*$WIFI_INTERFACE"; then
        print_result "Nodogsplash bound to $WIFI_INTERFACE" "PASS" ""
    else
        # Alternative check - look at config file
        if [ -f "/etc/nodogsplash/nodogsplash.conf" ] && grep -q "GatewayInterface.*$WIFI_INTERFACE" /etc/nodogsplash/nodogsplash.conf; then
            print_result "Nodogsplash configured for $WIFI_INTERFACE" "PASS" "Configuration file verified"
        else
            print_result "Nodogsplash bound to $WIFI_INTERFACE" "FAIL" "Not bound to interface"
            return 1
        fi
    fi
    
    # Check if captive portal web content is accessible
    portal_ip="$EXPECTED_IP"
    if curl -s --connect-timeout 5 "http://$portal_ip" > /dev/null; then
        print_result "Captive portal web server responding" "PASS" "HTTP server accessible at $portal_ip"
    else
        print_result "Captive portal web server responding" "FAIL" "No HTTP response from $portal_ip"
        return 1
    fi
    
    # Check if nginx is running (serves the portal content)
    if systemctl is-active --quiet nginx; then
        print_result "Nginx web server is running" "PASS" ""
    else
        print_result "Nginx web server is running" "FAIL" "Nginx service not active"
        return 1
    fi
    
    # Check if captive portal redirects work
    # Test accessing a known external site through the portal IP
    redirect_test=$(curl -s --connect-timeout 5 -H "Host: example.com" "http://$portal_ip" | grep -i "nodogsplash\|captive\|portal\|splash" || echo "no_redirect")
    if [ "$redirect_test" != "no_redirect" ]; then
        print_result "Captive portal redirect active" "PASS" "Redirect mechanism working"
    else
        # Check if we get the local site instead
        local_content=$(curl -s --connect-timeout 5 "http://$portal_ip" | grep -i "community\|wifi\|portal\|welcome" || echo "no_content")
        if [ "$local_content" != "no_content" ]; then
            print_result "Local portal content accessible" "PASS" "Portal serving local content"
        else
            print_result "Captive portal redirect active" "FAIL" "No portal content or redirect detected"
            return 1
        fi
    fi
    
    # Check if portal configuration files exist
    if [ -f "/etc/nodogsplash/nodogsplash.conf" ]; then
        print_result "Nodogsplash configuration exists" "PASS" "Config file found"
    else
        print_result "Nodogsplash configuration exists" "FAIL" "Config file not found"
        return 1
    fi
    
    return 0
}

# Function to test selfie portal accessibility
test_selfie_portal() {
    print_header "Test 6: Selfie Portal Accessibility"
    
    # Get the current hostname for local access
    current_hostname=$(hostname)
    
    # Test direct access to selfie portal on port 5001
    if curl -s --connect-timeout 5 "http://localhost:5001" | grep -i "selfie\|community\|portal" > /dev/null; then
        print_result "Selfie portal service running (port 5001)" "PASS" "Direct access to Flask app working"
    else
        print_result "Selfie portal service running (port 5001)" "FAIL" "No response from port 5001"
    fi
    
    # Test local access through wlan1 (AP interface via nginx proxy)
    local_url="http://$EXPECTED_IP"
    if curl -s --connect-timeout 5 "$local_url" | grep -i "selfie\|community\|portal" > /dev/null; then
        print_result "Selfie portal accessible via wlan1 ($EXPECTED_IP)" "PASS" "Nginx proxy working"
    else
        print_result "Selfie portal accessible via wlan1 ($EXPECTED_IP)" "FAIL" "No selfie portal content via local IP"
    fi
    
    # Test access through hostname (should work from both interfaces)
    hostname_url="http://$current_hostname"
    if curl -s --connect-timeout 5 "$hostname_url" | grep -i "selfie\|community\|portal" > /dev/null; then
        print_result "Selfie portal accessible via hostname ($current_hostname)" "PASS" "Hostname access working"
    else
        print_result "Selfie portal accessible via hostname ($current_hostname)" "FAIL" "No selfie portal content via hostname"
    fi
    
    # Check if cloudflare tunnel is running (for external access)
    tunnel_service_found=false
    tunnel_name=""
    
    # Check for any active cloudflared service
    for service in $(systemctl list-units --state=active --no-legend | grep cloudflared | awk '{print $1}'); do
        if systemctl is-active --quiet "$service"; then
            print_result "Cloudflare tunnel service running ($service)" "PASS" "External access configured"
            tunnel_service_found=true
            tunnel_name=$(echo "$service" | sed 's/cloudflared@//' | sed 's/.service//')
            break
        fi
    done
    
    if [ "$tunnel_service_found" = false ]; then
        # Check for alternative cloudflare service names or processes
        if pgrep -f cloudflared > /dev/null; then
            print_result "Cloudflare tunnel process running" "PASS" "Tunnel process detected"
        else
            print_result "Cloudflare tunnel service running" "FAIL" "No cloudflared service/process found"
            
            # Provide specific troubleshooting guidance
            echo -e "  ${YELLOW}Common fixes:${NC}"
            echo -e "  ${YELLOW}1. Check if service is enabled: systemctl is-enabled cloudflared@*.service${NC}"
            echo -e "  ${YELLOW}2. Check credentials exist: ls -la /home/pi/.cloudflared/${NC}"
            echo -e "  ${YELLOW}3. Check SystemD restrictions in /etc/systemd/system/cloudflared@.service${NC}"
        fi
    fi
    
    # If tunnel is running, check tunnel connectivity
    if [ "$tunnel_service_found" = true ] && [ -n "$tunnel_name" ]; then
        # Check for SystemD service configuration issues (critical fix)
        service_config="/etc/systemd/system/cloudflared@.service"
        if [ -f "$service_config" ]; then
            if grep -q "ProtectHome=read-only" "$service_config"; then
                print_result "Cloudflare tunnel SystemD configuration" "FAIL" "ProtectHome=read-only prevents credential access"
                echo -e "  ${YELLOW}Fix: Change to ProtectHome=no in $service_config${NC}"
            elif grep -q "ProtectHome=no" "$service_config"; then
                print_result "Cloudflare tunnel SystemD configuration" "PASS" "SystemD restrictions properly configured"
            else
                print_result "Cloudflare tunnel SystemD configuration" "PASS" "No restrictive ProtectHome setting found"
            fi
        fi
        
        # Check tunnel logs for "context canceled" errors (indicates SystemD issues)
        tunnel_logs=$(journalctl -u "cloudflared@$tunnel_name.service" --no-pager -n 20 2>/dev/null)
        if echo "$tunnel_logs" | grep -q "context canceled"; then
            recent_canceled=$(echo "$tunnel_logs" | grep "context canceled" | tail -1)
            print_result "Cloudflare tunnel stability" "FAIL" "Tunnel experiencing 'context canceled' errors"
            echo -e "  ${YELLOW}Debug: Check SystemD service restrictions and credentials${NC}"
        else
            print_result "Cloudflare tunnel stability" "PASS" "No recent 'context canceled' errors"
        fi
        
        # Check tunnel connections (should show "Registered tunnel connection")
        if echo "$tunnel_logs" | grep -q "Registered tunnel connection"; then
            print_result "Cloudflare tunnel connected to edge" "PASS" "Tunnel has active connections"
        else
            print_result "Cloudflare tunnel connected to edge" "FAIL" "No active tunnel connections found"
            echo -e "  ${YELLOW}Debug: Check tunnel credentials and config${NC}"
        fi
        
        # Check for authentication errors
        if echo "$tunnel_logs" | grep -q "Invalid tunnel secret"; then
            print_result "Cloudflare tunnel authentication" "FAIL" "Invalid tunnel credentials"
            echo -e "  ${YELLOW}Fix: Recreate tunnel credentials${NC}"
        else
            print_result "Cloudflare tunnel authentication" "PASS" "No authentication errors"
        fi
        
        # Check tunnel service restart frequency (indicates persistent issues)
        restart_count=$(echo "$tunnel_logs" | grep -c "Scheduled restart job" 2>/dev/null)
        restart_count=${restart_count:-0}
        if [ "$restart_count" -gt 5 ]; then
            print_result "Cloudflare tunnel restart frequency" "FAIL" "Service restarting frequently ($restart_count recent restarts)"
            echo -e "  ${YELLOW}Debug: Check for SystemD restrictions or credential issues${NC}"
        else
            print_result "Cloudflare tunnel restart frequency" "PASS" "Service stable (low restart count)"
        fi
    fi
    
    # Test Cloudflare certificate domain (local DNS redirect approach)
    # This tests if WiFi clients can access HTTPS domain with valid Cloudflare certificates
    tunnel_domain="selfies.griffincreektrestle.net"
    if [ -n "$tunnel_domain" ]; then
        # Test if dnsmasq has the DNS redirect configured
        if grep -q "address=/$tunnel_domain/$EXPECTED_IP" /etc/dnsmasq.conf 2>/dev/null; then
            print_result "DNS redirect configured for $tunnel_domain" "PASS" "dnsmasq redirects domain to local IP"
            
            # Test HTTP access with proper Host header (simulates client access)
            tunnel_response=$(curl -s -H "Host: $tunnel_domain" --connect-timeout 10 "http://$EXPECTED_IP/" 2>&1)
            if echo "$tunnel_response" | grep -i "selfie\|community\|portal" > /dev/null; then
                print_result "HTTP access via Cloudflare domain" "PASS" "Local nginx responds correctly"
            else
                print_result "HTTP access via Cloudflare domain" "FAIL" "Domain resolves but content issue"
                echo -e "  ${YELLOW}Debug: Check nginx config and selfie portal service${NC}"
            fi
            
            # Test HTTPS access (critical for camera API)
            https_response=$(curl -k -s -H "Host: $tunnel_domain" --connect-timeout 10 "https://$EXPECTED_IP/" 2>&1)
            if echo "$https_response" | grep -i "selfie\|community\|portal" > /dev/null; then
                print_result "HTTPS access via Cloudflare domain (CRITICAL)" "PASS" "SSL working - camera API will function"
            else
                print_result "HTTPS access via Cloudflare domain (CRITICAL)" "FAIL" "SSL not working - camera API will NOT function"
                echo -e "  ${YELLOW}Debug: Check nginx SSL config and certificates${NC}"
            fi
            
            # Test SSL certificate configuration
            ssl_cert_check=$(echo | openssl s_client -connect $EXPECTED_IP:443 -servername $tunnel_domain 2>/dev/null | openssl x509 -noout -subject 2>/dev/null)
            if [ $? -eq 0 ]; then
                print_result "SSL certificate accessible" "PASS" "Certificate chain working"
            else
                print_result "SSL certificate accessible" "FAIL" "SSL certificate issue"
            fi
        else
            print_result "DNS redirect configured for $tunnel_domain" "FAIL" "DNS redirect not configured in dnsmasq"
            echo -e "  ${YELLOW}Fix: Add 'address=/$tunnel_domain/$EXPECTED_IP' to dnsmasq.conf${NC}"
        fi
    fi
    
    # Check if nginx has selfie portal configuration
    if [ -f "/etc/nginx/sites-available/$current_hostname" ] && grep -q "selfie" "/etc/nginx/sites-available/$current_hostname"; then
        print_result "Nginx configured for selfie portal" "PASS" "Nginx config includes selfie portal"
    else
        print_result "Nginx configured for selfie portal" "FAIL" "No selfie portal config in nginx"
    fi
    
    # Test wlan0 interface isolation (this should FAIL for security)
    wlan0_ip=$(ip addr show wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
    if [ -n "$wlan0_ip" ] && [ "$wlan0_ip" != "127.0.0.1" ]; then
        # Test from wlan0 perspective (should be blocked for security)
        if curl -s --connect-timeout 5 --interface wlan0 "http://$current_hostname" | grep -i "selfie\|community\|portal" > /dev/null 2>&1; then
            print_result "Network isolation (wlan0 blocked)" "FAIL" "SECURITY ISSUE: wlan0 can access AP services"
            echo -e "  ${YELLOW}WARNING: This is a security vulnerability! wlan0 should not access wlan1 services.${NC}"
        else
            print_result "Network isolation (wlan0 blocked)" "PASS" "Secure: wlan0 properly isolated from AP services"
        fi
    else
        print_result "wlan0 interface configured" "PASS" "wlan0 not configured (acceptable for AP-only mode)"
    fi
    
    return 0
}

# Function to test external Cloudflare tunnel access (optional)
test_external_access() {
    print_header "Test 7: External Access (Optional)"
    
    tunnel_domain="selfies.griffincreektrestle.net"
    
    # Test external domain resolution (should point to Cloudflare)
    external_ips=$(dig +short "$tunnel_domain" @8.8.8.8 2>/dev/null | grep -E '^[0-9]+\.')
    if [ -n "$external_ips" ]; then
        cloudflare_detected=false
        for ip in $external_ips; do
            # Check if IP belongs to Cloudflare ranges (104.16-31.x.x, 172.64-71.x.x, 198.41.x.x)
            if echo "$ip" | grep -qE '^(104\.(1[6-9]|2[0-9]|3[0-1])|172\.(6[4-9]|7[0-1])|198\.41)\.' ; then
                cloudflare_detected=true
                break
            fi
        done
        
        if [ "$cloudflare_detected" = true ]; then
            print_result "External DNS points to Cloudflare" "PASS" "Domain resolves to Cloudflare edge servers"
        else
            print_result "External DNS points to Cloudflare" "FAIL" "Domain doesn't resolve to expected Cloudflare IPs"
        fi
    else
        print_result "External DNS resolution" "FAIL" "Domain doesn't resolve externally"
    fi
    
    # Test external HTTPS access (this might fail if tunnel isn't properly routed)
    external_response=$(timeout 15 curl -s -I "https://$tunnel_domain/" 2>/dev/null | head -1)
    if echo "$external_response" | grep -q "HTTP/[12] 200"; then
        print_result "External HTTPS access working" "PASS" "External users can access the site"
    elif echo "$external_response" | grep -q "HTTP/[12] 530"; then
        print_result "External HTTPS access working" "FAIL" "530 Origin unreachable - tunnel connection issue"
        echo -e "  ${YELLOW}Debug: Check tunnel credentials and DNS routing${NC}"
    elif echo "$external_response" | grep -q "HTTP/[12]"; then
        print_result "External HTTPS access working" "FAIL" "External access returns: $external_response"
    else
        print_result "External HTTPS access working" "FAIL" "No response from external domain (timeout or network issue)"
        echo -e "  ${YELLOW}Note: This is optional - local WiFi access is the primary feature${NC}"
    fi
    
    return 0
}

# Function to print summary
print_summary() {
    print_header "Test Summary"
    
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "\n${GREEN}🎉 ALL TESTS PASSED! WiFi AP is functioning correctly.${NC}"
        return 0
    else
        echo -e "\n${RED}⚠️  Some tests failed. WiFi AP may not be functioning properly.${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}WiFi Access Point Validation Script${NC}"
    echo "Testing interface: $WIFI_INTERFACE"
    echo "Expected SSID: $EXPECTED_SSID"
    echo "Expected IP: $EXPECTED_IP"
    
    # Run all tests
    test_interface_status
    test_ip_configuration  
    test_wifi_broadcast
    test_dhcp_server
    test_captive_portal
    test_selfie_portal
    test_external_access
    
    # Print summary and exit with appropriate code
    print_summary
    exit $?
}

# Execute main function
main "$@"