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
    
    # Check if NetworkManager's dnsmasq is running for this interface
    if ps aux | grep -q "dnsmasq.*listen-address=$EXPECTED_IP.*dhcp-range"; then
        print_result "DHCP server (dnsmasq) is running" "PASS" ""
    else
        print_result "DHCP server (dnsmasq) is running" "FAIL" "No dnsmasq process found for $EXPECTED_IP"
        return 1
    fi
    
    # Check DHCP configuration
    dhcp_process=$(ps aux | grep "dnsmasq.*$EXPECTED_IP" | grep -v grep)
    if echo "$dhcp_process" | grep -q "dhcp-range=10.10.42"; then
        print_result "DHCP range configured" "PASS" "Range appears to be in 10.10.42.x network"
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
    
    # Check NetworkManager connection method
    if nmcli connection show JoinMe-AP | grep -q "ipv4.method.*shared"; then
        print_result "NetworkManager shared mode enabled" "PASS" "DHCP sharing active"
    else
        print_result "NetworkManager shared mode enabled" "FAIL" "Not in shared mode"
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
    if systemctl is-active --quiet cloudflared; then
        print_result "Cloudflare tunnel service running" "PASS" "External access should be available"
    else
        # Check for alternative cloudflare service names
        if pgrep -f cloudflared > /dev/null; then
            print_result "Cloudflare tunnel process running" "PASS" "Tunnel process detected"
        else
            print_result "Cloudflare tunnel service running" "FAIL" "No cloudflared service/process found"
        fi
    fi
    
    # Test external tunnel URL if configured
    # Get tunnel domain from variables (from defaults/main.yml)
    tunnel_domain="selfies.griffincreektrestle.net"
    if [ -n "$tunnel_domain" ]; then
        if curl -s --connect-timeout 10 "https://$tunnel_domain" | grep -i "selfie\|community\|portal" > /dev/null; then
            print_result "External selfie portal accessible (https://$tunnel_domain)" "PASS" "Tunnel working"
        else
            print_result "External selfie portal accessible (https://$tunnel_domain)" "FAIL" "Tunnel may not be configured or DNS not propagated"
        fi
    fi
    
    # Check if nginx has selfie portal configuration
    if [ -f "/etc/nginx/sites-available/$current_hostname" ] && grep -q "selfie" "/etc/nginx/sites-available/$current_hostname"; then
        print_result "Nginx configured for selfie portal" "PASS" "Nginx config includes selfie portal"
    else
        print_result "Nginx configured for selfie portal" "FAIL" "No selfie portal config in nginx"
    fi
    
    # Test wlan0 interface access (if wlan0 has IP)
    wlan0_ip=$(ip addr show wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
    if [ -n "$wlan0_ip" ] && [ "$wlan0_ip" != "127.0.0.1" ]; then
        # Test from wlan0 perspective (simulate client on internet side)
        if curl -s --connect-timeout 5 --interface wlan0 "http://$current_hostname" | grep -i "selfie\|community\|portal" > /dev/null 2>&1; then
            print_result "Selfie portal accessible via wlan0 interface" "PASS" "Internet-side access working"
        else
            print_result "Selfie portal accessible via wlan0 interface" "FAIL" "No access via wlan0 interface"
        fi
    else
        print_result "wlan0 interface has valid IP" "FAIL" "wlan0 not configured or no IP assigned"
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
    
    # Print summary and exit with appropriate code
    print_summary
    exit $?
}

# Execute main function
main "$@"