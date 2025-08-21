# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is an Instant Community Wifi Portal that turns a Raspberry Pi into a WiFi access point with a captive portal hosting a local community image board. The system creates an offline network for neighbors to connect and share content.

## Build/Deploy Commands
- All commands should be run through the docker container
- attach to the container with docker exec -it AnsibleFWC bash
- the playbook directory for this project is in /home/pi/Playbooks/Instant_Community_Wifi_Portal.  You'll need to change in there to start the process.
- The recipient device is ansibledest.local.  Ping for it before running the build process.
- If you get ssh errors- stop and ask for help.  I need to copy the ssh key to the recipient and remove stale entries to old recipent devices.
- It is better to monitor a long term run of the build process than it is to exec commands in the container from outside the container.  The build process seems to take several hours.
- Deploy using Ansible: `ansible-playbook run.yml`
- Run on Raspberry Pi OS Bookworm (Debian 12).  I am deploying it onto a 32bit os for compatibility reasons. 
- Hardware: Raspberry Pi 3/4, 16GB+ Class 10 Ultra Micro SD card


## Debugging/Diagnostics
- Target system hostname: thepub.local
- SSH access available with existing key
- Key services to check:
  1. nmcli-based wifi access point should work after build.  It should be hosted on the wlan1 interface.   - WiFi access point ("Join-me" network, passwordless)
  2. nodogsplash - captive portal
  3. nginx - web server
  4. selfie portal - local network service at https://selfies.griffincreektrestle.net

## Style Guidelines
- Follow standard Ansible YAML conventions for playbooks and tasks
- Use standard Linux configuration file conventions
- Maintain organized file structure with roles in `roles/system/tasks/`
- For shell scripts, follow POSIX-compliant standards
- Document changes clearly in commit messages


## Deployment Environment
- Always run playbooks from Docker container: `docker exec -it AnsibleFWC bash`
- Target host changes from `ansibledest.local` → `thepub.local` after hostname setup
- Required Ansible collections: ansible.posix, community.general, community.crypto

## Status Monitoring Commands
- Check apt activity: `/var/log/apt/term.log` and `/var/log/apt/history.log`
- Monitor services: `systemctl status <service-name>`
- Test connectivity: Use actual hostname, not hardcoded addresses
- SSL cert verification: `sudo ls -la /etc/ssl/certs/` and `/etc/ssl/private/`

## Common Issues & Fixes
- Hostname path mismatches: Always use `{{ hostname }}` variable in paths
- Missing Ansible collections: Install before running playbooks
- Host resolution changes: Update connection target from ansibledest.local to thepub.local
```

## Key Status Monitoring Insights

### 1. Apt Logs Are Goldmines
- `/var/log/apt/term.log` shows exactly where package installation stopped
- `/var/log/apt/history.log` reveals installation patterns and failures
- These logs provide definitive deployment progress markers
- More reliable than network connectivity tests

### 2. Service Status Over Ping Tests
- `systemctl status <service-name>` reveals service health better than ping
- Shows actual process state, not just network reachability
- Includes error messages and restart attempts
- Critical for diagnosing hung or failed services

### 3. Permission-Aware File Checks
- Always use `sudo` when checking system directories (`/etc/ssl/`, `/var/www/`)
- Permission denied errors mask actual file existence
- System files require elevated privileges for inspection

### 4. Process vs Task Monitoring
- Check both running processes (`ps aux | grep ansible`) AND specific task completion
- Long-running compilation tasks may appear hung but are actually progressing
- Distinguish between network timeouts and legitimate long-running operations

## Critical Reminders for Next Time

### DO:
- **Install required Ansible collections first**: `ansible-galaxy collection install ansible.posix community.general community.crypto`
- **Use hostname variables consistently** throughout playbooks instead of hardcoded paths
- **Check apt logs immediately** when deployments hang or fail mysteriously
- **Test with correct hostname** after system hostname changes during deployment
- **Use Docker container environment** for consistent, reproducible deployments
- **Monitor system logs** (`/var/log/syslog`, `/var/log/apt/`) for deployment progress
- **Verify file permissions** before assuming files don't exist

### DON'T:
- **Assume connectivity issues are network-related** - often hostname resolution changes
- **Hardcode paths with static hostnames** - use `{{ hostname }}` variables instead
- **Skip checking system logs** when tasks appear to hang indefinitely
- **Forget hostname transitions** - target changes from `ansibledest.local` to `thepub.local`
- **Ignore permission errors** - use `sudo` for system file operations
- **Rush to restart services** - check if long compilation tasks are legitimately running

## Most Valuable Discovery

### The Hostname Transition Problem
The hostname transition (`ansibledest.local` → `thepub.local`) is a fundamental deployment characteristic that affects:
- **SSH connectivity** - connection target changes mid-deployment
- **File path resolution** - directories named with old hostname persist
- **Service configuration** - nginx configs may reference wrong paths
- **Directory structures** - `/var/www/ansibledest.local/` vs `/var/www/thepub.local/`

This should be explicitly documented and handled in playbooks through:
- Dynamic hostname variable usage: `{{ hostname }}`
- Directory rename tasks after hostname changes
- Connection target updates in deployment scripts
- Clear documentation of when the transition occurs

## Deployment Flow Awareness

### Phase 1: Initial Connection (`ansibledest.local`)
- Container connects to Pi using flashed hostname
- System configuration and package installation
- Hostname change occurs during system setup

### Phase 2: Post-Hostname Change (`thepub.local`)
- Target host resolution changes
- Directory paths need updating to match new hostname
- Services configured with new hostname values
- SSL certificates generated with correct hostname

### Phase 3: Service Verification
- Test services using final hostname (`thepub.local`)
- Verify directory structures match hostname
- Confirm nginx configurations point to correct paths

## Implementation Priority

1. **High Priority**: Add Ansible collection installation to deployment prerequisites
2. **High Priority**: Document hostname transition behavior in CLAUDE.md
3. **Medium Priority**: Add log monitoring guidelines to troubleshooting section
4. **Medium Priority**: Create hostname variable usage standards
5. **Low Priority**: Document permission requirements for system file operations

These guidelines should prevent the majority of issues encountered during this session and provide clear debugging paths when problems arise.

## CRITICAL NODOGSPLASH + DHCP REQUIREMENTS

### ⚠️ MANDATORY: Standalone dnsmasq for Nodogsplash
- **nodogsplash REQUIRES a standalone dnsmasq service** to function
- **NetworkManager's built-in DHCP (shared mode) is INCOMPATIBLE** with nodogsplash
- **WiFi AP must be configured in `manual` mode**, not `shared` mode
- **dnsmasq service must be enabled and running** before nodogsplash starts

### Critical Service Startup Order
1. **NetworkManager** (manages interfaces, NO DHCP)
2. **dnsmasq** (standalone DHCP server)  
3. **nodogsplash** (depends on dnsmasq service)

### Required Configuration Files
- `/etc/dnsmasq.conf` - DHCP configuration for wlan1
- `/tmp/dnsmasq/` directory - Must exist with proper permissions
- `/etc/systemd/system/nodogsplash.service` - Must depend on dnsmasq.service

### Detection Commands
```bash
# Check if using incompatible NetworkManager DHCP
nmcli connection show JoinMe-AP | grep "ipv4.method.*shared"

# Verify standalone dnsmasq is running
systemctl status dnsmasq.service
ps aux | grep dnsmasq

# Test nodogsplash dependency
systemctl status nodogsplash.service
```

## CRITICAL SAFETY GUARDRAILS

### Network Configuration Changes
- ⚠️ **NEVER modify wlan0 (gateway) interface without explicit user approval**
- ⚠️ **ALWAYS backup NetworkManager connections before deletion**
- ⚠️ **NEVER run `nmcli connection delete` without user confirmation**
- ⚠️ **ALWAYS test network connectivity after interface changes**
- ⚠️ **NEVER assume systemd-networkd vs NetworkManager vs dhcpcd roles**

### Service Management  
- ⚠️ **NEVER stop/disable essential services (NetworkManager, dhcpcd) without fallback**
- ⚠️ **ALWAYS check service dependencies before making changes**
- ⚠️ **NEVER restart services during active client connections without warning**
- ⚠️ **VERIFY nginx configuration conflicts before enabling multiple sites**

### Hostname/DNS Changes
- ⚠️ **ALWAYS coordinate hostname changes with all dependent services**
- ⚠️ **NEVER change hostname during active deployments**
- ⚠️ **UPDATE all configuration files when hostname changes**
- ⚠️ **REMEMBER: hostname changes happen AFTER roles complete (post_tasks)**

### Container Operations
- ⚠️ **ALWAYS verify container is running before exec commands**
- ⚠️ **NEVER make changes outside container that affect container workflow**
- ⚠️ **CONFIRM recipient device connectivity before long-running deployments**

## MANDATORY TESTING PROTOCOL

### Before Any Changes
1. **Run validation script**: `/usr/local/bin/validate-ap.sh`
2. **Document current working state**
3. **Test changes in isolated environment when possible**

### After Any Configuration Changes
1. **Run validation script again** to verify functionality
2. **Test from client device perspective** (connect to JoinMe WiFi)
3. **Verify all core services respond**: WiFi AP, DHCP, Selfie Portal, Captive Portal
4. **Check nginx configuration conflicts** - multiple sites can interfere

### Before Deployment
- **Test in development environment**
- **Validate Ansible syntax**: `ansible-playbook --syntax-check run.yml`
- **Run with check flag**: `ansible-playbook --check run.yml`
- **Use tags for partial deployment**: `ansible-playbook run.yml --tags validation`

## NETWORK ARCHITECTURE UNDERSTANDING

### Interface Roles (CRITICAL)
- **wlan0**: Internet gateway interface (DHCP client via NetworkManager)
- **wlan1**: WiFi access point interface (static IP 10.10.42.1, NO NetworkManager DHCP)
- **eth0**: Backup wired connection (DHCP via dhcpcd)

### Service Dependencies
- **NetworkManager**: Manages wlan0 (internet) and wlan1 (AP interface - NO DHCP)
- **dnsmasq**: Standalone DHCP server for wlan1 (REQUIRED for nodogsplash)
- **dhcpcd**: Manages eth0, excludes wlan0 (`denyinterfaces wlan0`)
- **nginx**: Proxies selfie portal from port 5001 to port 80
- **nodogsplash**: Captive portal (REQUIRES standalone dnsmasq service)
- **cloudflared**: External tunnel access (optional)

### IP Architecture
- **wlan1 AP network**: 10.10.42.0/24
- **wlan1 gateway**: 10.10.42.1
- **DHCP range**: 10.10.42.10 - 10.10.42.254
- **Selfie portal**: Runs on port 5001, proxied via nginx

## VALIDATION SCRIPT USAGE

The validation script `/usr/local/bin/validate-ap.sh` tests:
1. **wlan1 interface status** (UP, connected, correct IP)
2. **WiFi broadcasting** (JoinMe SSID, AP mode)
3. **DHCP functionality** (NetworkManager shared mode)
4. **Captive portal** (nodogsplash service)
5. **Selfie portal** (direct port 5001 + nginx proxy)
6. **External access** (cloudflare tunnel)

**Always run this script before and after changes!**

## TROUBLESHOOTING QUICK REFERENCE

### WiFi AP Not Working
1. Check NetworkManager: `nmcli device status`
2. Verify shared mode: `nmcli connection show JoinMe-AP | grep ipv4.method`
3. Check DHCP process: `ps aux | grep dnsmasq`

### Selfie Portal Not Accessible
1. Test direct access: `curl http://localhost:5001`
2. Check nginx proxy: `curl http://10.10.42.1`
3. Verify nginx configs: `ls /etc/nginx/sites-enabled/`
4. Check for conflicting sites

### DHCP Not Working
1. **CRITICAL**: Verify standalone dnsmasq service is running (NOT NetworkManager DHCP)
2. Check `/tmp/dnsmasq/` directory exists with proper permissions
3. Ensure no dhcpcd conflicts on wlan1
4. Verify NetworkManager connection is in `manual` mode (NOT `shared`)

### Nodogsplash Service Failing
1. **Check dnsmasq dependency**: `systemctl status dnsmasq.service`
2. **Verify log directory**: `ls -la /tmp/dnsmasq/`
3. **Check service dependency chain**: `systemctl list-dependencies nodogsplash.service`
4. **Review nodogsplash logs**: `journalctl -u nodogsplash.service -f`

### Hostname Transition Issues
1. Remember hostname changes in post_tasks (after roles)
2. Update all service configs to use `{{ hostname }}` variable
3. Check directory structures match new hostname

### Nginx Configuration Conflicts
1. **Check for multiple nginx site configurations**: `ls /etc/nginx/sites-enabled/`
2. **Look for conflicting server blocks** with same hostname/port
3. **Common issue**: selfie_app role creates conflicting standalone nginx configuration
4. **Solution**: Use `blockinfile` to integrate selfie portal into main nginx config
5. **Remove duplicate configurations**: Check both sites-available and sites-enabled

## NGINX CONFIGURATION MANAGEMENT

### Critical Nginx Architecture
- **Main site**: `/etc/nginx/sites-available/{{ hostname }}` (e.g., `thepub.local`)
- **Cloudflare domain site**: `/etc/nginx/sites-available/selfies.griffincreektrestle.net`
- **NO standalone selfie portal sites** - integrated into main site

### Nginx Role Responsibilities
- **system role**: Creates main hostname-based nginx configuration
- **selfie_app role**: Adds selfie portal blocks to existing main configuration (NOT separate site)
- **cloudflare_tunnel role**: Creates separate HTTPS site for external domain

### Avoiding Nginx Conflicts
```yaml
# CORRECT: Add to existing main site
- name: Add selfie portal configuration to main nginx site
  blockinfile:
    path: "/etc/nginx/sites-available/{{ hostname }}"
    insertbefore: "location / {"
    block: |
      location /selfies {
          proxy_pass http://127.0.0.1:5001;
          # ... proxy configuration
      }

# WRONG: Create conflicting standalone site
- name: Create conflicting nginx site
  copy:
    dest: "/etc/nginx/sites-available/selfie-portal"
    content: |
      server {
          listen 80;
          server_name {{ hostname }};  # CONFLICT!
          location / {
              proxy_pass http://127.0.0.1:8080;  # NON-EXISTENT!
          }
      }
```

### Nginx Debugging Commands
```bash
# Test nginx configuration
sudo nginx -t

# Check enabled sites
ls -la /etc/nginx/sites-enabled/

# Find conflicting server blocks
grep -r "server_name.*{{ hostname }}" /etc/nginx/sites-*

# Check for port 8080 proxy (usually wrong)
grep -r "proxy_pass.*8080" /etc/nginx/sites-*

# Verify selfie portal integration
grep -A5 -B5 "location /selfies" /etc/nginx/sites-available/{{ hostname }}
```

## ROLE COORDINATION AND DEPENDENCIES

### Role Execution Order (CRITICAL)
1. **system role**: Base system setup, nginx, dnsmasq, NetworkManager
2. **cloudflare_tunnel role**: External domain access (optional)
3. **selfie_app role**: Selfie portal application + integration with existing nginx

### Inter-Role Dependencies
- **selfie_app** depends on **system** role's nginx configuration existing
- **selfie_app** MUST NOT create competing nginx server blocks
- **cloudflare_tunnel** creates separate HTTPS site (no conflict with main HTTP site)

### Role Configuration Patterns
```yaml
# roles/system/tasks/nginx.yml - Creates main site
- name: Create main nginx site configuration
  template:
    src: nginx_site.conf.j2
    dest: "/etc/nginx/sites-available/{{ hostname }}"

# roles/selfie_app/tasks/configure.yml - Integrates with main site
- name: Add selfie portal to main nginx site  
  blockinfile:
    path: "/etc/nginx/sites-available/{{ hostname }}"
    # Integration, not replacement

# roles/cloudflare_tunnel/ - Separate HTTPS site
- name: Create Cloudflare domain nginx site
  template:
    src: cloudflare_site.conf.j2  
    dest: "/etc/nginx/sites-available/selfies.griffincreektrestle.net"
```

## DNS AND DOMAIN RESOLUTION

### DNS Resolution Architecture
- **Pi system DNS**: Uses upstream DNS (192.168.6.1) for external resolution
- **WiFi client DNS**: Uses dnsmasq (10.10.42.1) for local domain redirection
- **IPv6**: Should be disabled to avoid resolution conflicts

### Cloudflare Certificate Approach
- **Client perspective**: `selfies.griffincreektrestle.net` → 10.10.42.1 (via dnsmasq)
- **Pi perspective**: `selfies.griffincreektrestle.net` → Cloudflare IPs (via upstream DNS)
- **This is correct behavior** - different DNS for different network roles

### DNS Configuration Files
```bash
# dnsmasq configuration for WiFi clients
/etc/dnsmasq.conf:
address=/selfies.griffincreektrestle.net/10.10.42.1

# Pi system DNS (managed by NetworkManager)
/etc/resolv.conf:
nameserver 192.168.6.1  # Upstream router
nameserver 10.10.42.1   # Local dnsmasq (secondary)
```

### DNS Testing Commands
```bash
# Test from Pi (should get Cloudflare IPs)
getent hosts selfies.griffincreektrestle.net

# Test dnsmasq configuration
grep "address=/selfies.griffincreektrestle.net" /etc/dnsmasq.conf

# Simulate client access
curl -H "Host: selfies.griffincreektrestle.net" http://10.10.42.1/selfies/
```

## VALIDATION SCRIPT INSIGHTS

### IPv6 Resolution Issues
- `getent hosts` may return IPv6 addresses even with IPv6 disabled
- This indicates upstream DNS returning AAAA records
- **Not a problem** as long as IPv6 is disabled at network level
- Validation script should test HTTP access, not DNS resolution from Pi

### Correct Testing Approach
```bash
# WRONG: Test DNS from Pi perspective
resolved_ip=$(nslookup selfies.griffincreektrestle.net 127.0.0.1)

# CORRECT: Test HTTP access with proper Host header (simulates client)
curl -H "Host: selfies.griffincreektrestle.net" http://10.10.42.1/selfies/

# CORRECT: Verify dnsmasq configuration exists
grep -q "address=/selfies.griffincreektrestle.net/10.10.42.1" /etc/dnsmasq.conf
```

## LATEST DEBUGGING SESSION LEARNINGS

### Critical Discovery: selfie_app Role Nginx Conflict
- **Issue**: `roles/selfie_app/tasks/configure.yml` created standalone nginx site
- **Problem**: Conflicted with main site, included non-existent port 8080 proxy
- **Solution**: Modified to use `blockinfile` integration instead of separate site
- **Result**: 502 errors eliminated, selfie portal accessible

### Key Files Modified
- `roles/selfie_app/tasks/configure.yml` - Fixed nginx integration approach
- `usr/local/bin/validate-ap.sh` - Improved Cloudflare domain testing
- `roles/selfie_app/handlers/main.yml` - Removed duplicate nginx handler

### Validation Success Metrics  
- **Before fix**: Multiple test failures, 502 nginx errors
- **After fix**: 25/26 tests passing, only optional Cloudflare tunnel failing
- **Accessibility confirmed**: Both main site and selfie portal return HTTP 200

### Prevention Guidelines
1. **Never create multiple nginx sites with same hostname**
2. **Always integrate additional services into existing nginx configuration**
3. **Test nginx configuration after any role modifications**
4. **Use validation script to catch configuration conflicts early**
5. **Remove conflicting configurations when found**