#!/bin/bash

# WiFi Access Point Verification Script
# This script checks if the NetworkManager-based WiFi AP is working

echo "=== WiFi Access Point Status Check ==="

# Check if NetworkManager is running
echo "1. Checking NetworkManager status..."
if systemctl is-active --quiet NetworkManager; then
    echo "   ✓ NetworkManager is running"
else
    echo "   ✗ NetworkManager is not running"
    exit 1
fi

# Check if the AP connection exists
echo "2. Checking AP connection..."
if nmcli connection show "JoinMe-AP" >/dev/null 2>&1; then
    echo "   ✓ AP connection 'JoinMe-AP' exists"
else
    echo "   ✗ AP connection 'JoinMe-AP' not found"
    exit 1
fi

# Check if the AP is active
echo "3. Checking AP status..."
if nmcli connection show --active | grep -q "JoinMe-AP"; then
    echo "   ✓ AP is active"
else
    echo "   ✗ AP is not active"
    echo "   Attempting to activate AP..."
    nmcli connection up "JoinMe-AP"
fi

# Check if wlan1 interface exists and has IP
echo "4. Checking wlan1 interface..."
if ip link show wlan1 >/dev/null 2>&1; then
    echo "   ✓ wlan1 interface exists"
    WLAN1_IP=$(ip addr show wlan1 | grep -oP 'inet \K\S+' | head -1)
    if [ -n "$WLAN1_IP" ]; then
        echo "   ✓ wlan1 has IP: $WLAN1_IP"
    else
        echo "   ✗ wlan1 has no IP address"
    fi
else
    echo "   ✗ wlan1 interface not found (may appear after reboot with external adapter)"
fi

# Check if dnsmasq is running
echo "5. Checking dnsmasq status..."
if systemctl is-active --quiet dnsmasq; then
    echo "   ✓ dnsmasq is running"
else
    echo "   ✗ dnsmasq is not running"
fi

# Check if nodogsplash is running
echo "6. Checking nodogsplash status..."
if systemctl is-active --quiet nodogsplash; then
    echo "   ✓ nodogsplash is running"
else
    echo "   ✗ nodogsplash is not running"
fi

# Check if WiFi is broadcasting
echo "7. Checking WiFi broadcast..."
if ip link show wlan1 >/dev/null 2>&1; then
    if iw dev wlan1 info | grep -q "type AP"; then
        echo "   ✓ wlan1 is in AP mode"
    else
        echo "   ✗ wlan1 is not in AP mode"
    fi
else
    echo "   ✗ wlan1 interface not found (may appear after reboot with external adapter)"
fi

echo ""
echo "=== Summary ==="
echo "If all checks passed, your WiFi AP should be working."
echo "SSID: JoinMe"
echo "IP Range: 10.10.42.34-10.10.42.253"
echo "Gateway: 10.10.42.1"
echo ""
echo "Note: If wlan1 is not found, it may appear after reboot when the external WiFi adapter is properly initialized."
echo ""
echo "To test:"
echo "1. Look for 'JoinMe' network on your device"
echo "2. Connect to it (no password)"
echo "3. You should be redirected to the captive portal" 