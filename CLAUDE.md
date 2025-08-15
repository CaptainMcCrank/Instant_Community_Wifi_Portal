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
- **wlan1**: WiFi access point interface (static IP 10.10.42.1, serves DHCP via NetworkManager shared mode)
- **eth0**: Backup wired connection (DHCP via dhcpcd)

### Service Dependencies
- **NetworkManager**: Manages wlan0 (internet) and wlan1 (AP with built-in DHCP)
- **dhcpcd**: Manages eth0, excludes wlan0 (`denyinterfaces wlan0`)
- **nginx**: Proxies selfie portal from port 5001 to port 80
- **nodogsplash**: Captive portal (may have dependency issues)
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
1. Verify NetworkManager shared mode enabled
2. Check for dnsmasq process on correct interface
3. Ensure no dhcpcd conflicts

### Hostname Transition Issues
1. Remember hostname changes in post_tasks (after roles)
2. Update all service configs to use `{{ hostname }}` variable
3. Check directory structures match new hostname