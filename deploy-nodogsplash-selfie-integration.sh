#!/bin/bash

#############################################################################
# Nodogsplash + Selfie Portal Integration Deployment Script
# 
# This script deploys the integrated captive portal experience that showcases
# the selfie portal directly in the nodogsplash splash page.
#
# Usage: ./deploy-nodogsplash-selfie-integration.sh
#############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Nodogsplash + Selfie Portal Integration${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}This script should not be run as root${NC}"
   echo "Run as regular user with sudo privileges"
   exit 1
fi

# Function to check if we're on the Pi
check_environment() {
    echo -e "${YELLOW}Checking environment...${NC}"
    
    if [[ ! -f /etc/nodogsplash/nodogsplash.conf ]]; then
        echo -e "${RED}Error: Nodogsplash not found. Install the base system first.${NC}"
        exit 1
    fi
    
    if [[ ! -d /etc/nodogsplash/htdocs ]]; then
        echo -e "${RED}Error: Nodogsplash htdocs directory not found.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Environment check passed${NC}"
}

# Function to backup existing files
backup_files() {
    echo -e "${YELLOW}Creating backups...${NC}"
    
    # Backup nodogsplash config
    if [[ -f /etc/nodogsplash/nodogsplash.conf ]]; then
        sudo cp /etc/nodogsplash/nodogsplash.conf /etc/nodogsplash/nodogsplash.conf.backup.$(date +%Y%m%d_%H%M%S)
        echo -e "${GREEN}✓ Backed up nodogsplash.conf${NC}"
    fi
    
    # Backup original splash page
    if [[ -f /etc/nodogsplash/htdocs/splash.html ]]; then
        sudo cp /etc/nodogsplash/htdocs/splash.html /etc/nodogsplash/htdocs/splash.html.backup.$(date +%Y%m%d_%H%M%S)
        echo -e "${GREEN}✓ Backed up original splash.html${NC}"
    fi
}

# Function to deploy integrated splash page
deploy_splash_page() {
    echo -e "${YELLOW}Deploying integrated splash page...${NC}"
    
    # Copy the integrated splash page
    sudo cp "$(dirname "$0")/etc/nodogsplash/htdocs/splash-with-selfie-portal.html" /etc/nodogsplash/htdocs/
    sudo chown root:root /etc/nodogsplash/htdocs/splash-with-selfie-portal.html
    sudo chmod 644 /etc/nodogsplash/htdocs/splash-with-selfie-portal.html
    
    echo -e "${GREEN}✓ Integrated splash page deployed${NC}"
}

# Function to update nodogsplash configuration
update_nodogsplash_config() {
    echo -e "${YELLOW}Updating nodogsplash configuration...${NC}"
    
    # Update splash page setting
    sudo sed -i 's|^#\?SplashPage.*|SplashPage splash-with-selfie-portal.html|' /etc/nodogsplash/nodogsplash.conf
    
    # Update redirect URL to HTTPS selfie portal
    sudo sed -i 's|^RedirectURL.*|RedirectURL https://selfies.griffincreektrestle.net/|' /etc/nodogsplash/nodogsplash.conf
    
    # Ensure HTTPS is allowed in firewall rules
    if ! grep -q "FirewallRule allow tcp port 443" /etc/nodogsplash/nodogsplash.conf; then
        sudo sed -i '/FirewallRule allow tcp port 80/a\  FirewallRule allow tcp port 443' /etc/nodogsplash/nodogsplash.conf
    fi
    
    echo -e "${GREEN}✓ Nodogsplash configuration updated${NC}"
}

# Function to restart services
restart_services() {
    echo -e "${YELLOW}Restarting services...${NC}"
    
    # Test nodogsplash configuration
    if sudo nodogsplash -s; then
        echo -e "${GREEN}✓ Nodogsplash configuration is valid${NC}"
    else
        echo -e "${RED}✗ Nodogsplash configuration has errors${NC}"
        exit 1
    fi
    
    # Restart nodogsplash
    sudo systemctl restart nodogsplash
    
    # Wait for service to start
    sleep 3
    
    # Check service status
    if systemctl is-active --quiet nodogsplash; then
        echo -e "${GREEN}✓ Nodogsplash service restarted successfully${NC}"
    else
        echo -e "${RED}✗ Nodogsplash service failed to start${NC}"
        echo "Check logs: sudo journalctl -u nodogsplash -n 20"
        exit 1
    fi
}

# Function to verify deployment
verify_deployment() {
    echo -e "${YELLOW}Verifying deployment...${NC}"
    
    # Check if integrated splash page exists
    if [[ -f /etc/nodogsplash/htdocs/splash-with-selfie-portal.html ]]; then
        echo -e "${GREEN}✓ Integrated splash page: OK${NC}"
    else
        echo -e "${RED}✗ Integrated splash page: MISSING${NC}"
    fi
    
    # Check nodogsplash configuration
    if grep -q "splash-with-selfie-portal.html" /etc/nodogsplash/nodogsplash.conf; then
        echo -e "${GREEN}✓ Splash page configuration: OK${NC}"
    else
        echo -e "${RED}✗ Splash page configuration: NOT SET${NC}"
    fi
    
    if grep -q "https://selfies.griffincreektrestle.net/" /etc/nodogsplash/nodogsplash.conf; then
        echo -e "${GREEN}✓ Redirect URL configuration: OK${NC}"
    else
        echo -e "${RED}✗ Redirect URL configuration: NOT SET${NC}"
    fi
    
    # Check service status
    if systemctl is-active --quiet nodogsplash; then
        echo -e "${GREEN}✓ Nodogsplash service: RUNNING${NC}"
    else
        echo -e "${RED}✗ Nodogsplash service: NOT RUNNING${NC}"
    fi
}

# Function to display testing instructions
display_testing_instructions() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}TESTING INSTRUCTIONS${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    echo -e "${GREEN}1. Connect to JoinMe WiFi${NC}"
    echo "   - SSID: JoinMe"
    echo "   - No password required"
    echo
    echo -e "${GREEN}2. Open any website in browser${NC}"
    echo "   - You should see the integrated selfie portal splash page"
    echo "   - Preview of selfie portal features"
    echo "   - Gnome story from Chief Gnarlbark"
    echo
    echo -e "${GREEN}3. Click 'Connect & Start Sharing!'${NC}"
    echo "   - Authenticates you to the captive portal"
    echo "   - Should redirect to: https://selfies.griffincreektrestle.net/"
    echo "   - Camera access should work immediately"
    echo
    echo -e "${GREEN}4. Test selfie portal features${NC}"
    echo "   - Take selfies using device camera"
    echo "   - Upload photos with captions"
    echo "   - Browse community gallery"
    echo
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "   - Service logs: sudo journalctl -u nodogsplash -f"
    echo "   - Test config: sudo nodogsplash -s"
    echo "   - Validation script: /usr/local/bin/validate-ap.sh"
    echo
    echo -e "${BLUE}🎉 Integration deployment complete!${NC}"
}

# Main execution
main() {
    echo -e "${YELLOW}Starting nodogsplash + selfie portal integration deployment...${NC}"
    echo
    
    check_environment
    backup_files
    deploy_splash_page
    update_nodogsplash_config
    restart_services
    verify_deployment
    
    echo
    display_testing_instructions
}

# Execute main function
main "$@"