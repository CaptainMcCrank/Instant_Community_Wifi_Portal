# Cloudflare Tunnel Setup for Raspberry Pi Selfie Portal

This document provides a complete guide for setting up a Cloudflare Tunnel on your Raspberry Pi selfie portal system.

## Overview

The Cloudflare Tunnel role (`cloudflare_tunnel`) automates the deployment of a secure tunnel that exposes your local selfie portal web application to the internet through Cloudflare's network. This eliminates the need for port forwarding and provides additional security benefits.

## Role Structure

```
roles/cloudflare_tunnel/
├── defaults/main.yml          # Default variables
├── tasks/main.yml             # Main tasks
├── templates/
│   ├── config.yml.j2          # Cloudflared configuration template
│   └── cloudflared@.service.j2 # Systemd service template
├── handlers/main.yml          # Service restart handlers
├── meta/main.yml              # Role metadata
└── README.md                  # Role documentation
```

## Configuration Details

### Default Variables (`defaults/main.yml`)

```yaml
cloudflare_tunnel:
  name: "selfie-portal-1750534817"
  domain: "selfies.griffincreektrestle.net"
  local_port: 80
  credentials_file: "/home/pi/.cloudflared/86c5b63c-cd74-4191-8d5a-0c6119908551.json"
  binary_url: "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm"
  binary_path: "/usr/local/bin/cloudflared"
  config_dir: "/etc/cloudflared"
  service_name: "cloudflared@{{ cloudflare_tunnel.name }}"
  user: "pi"
  group: "pi"
```

### Cloudflared Configuration (`templates/config.yml.j2`)

```yaml
tunnel: {{ cloudflare_tunnel.name }}
credentials-file: /home/{{ cloudflare_tunnel.user }}/.cloudflared/{{ cloudflare_tunnel.name }}.json

ingress:
  - hostname: {{ cloudflare_tunnel.domain }}
    service: http://localhost:{{ cloudflare_tunnel.local_port }}
  - service: http_status:404
```

### Systemd Service (`templates/cloudflared@.service.j2`)

The service template includes:
- Proper user/group execution
- Automatic restart on failure
- Security hardening (NoNewPrivileges, PrivateTmp, etc.)
- Journal logging
- Network dependency management

## Installation Steps

The role performs the following tasks:

1. **Create Directories**: Sets up `/etc/cloudflared` and `/home/pi/.cloudflared`
2. **Download Binary**: Downloads the ARM-compatible cloudflared binary
3. **Copy Credentials**: Places the tunnel credentials file in the correct location
4. **Create Configuration**: Generates the `config.yml` with your domain and tunnel settings
5. **Install Service**: Creates the systemd service template
6. **Start Service**: Enables and starts the tunnel service

## Usage Instructions

### Method 1: Include in Existing Playbook

The role is already integrated into your main system role. Add this line to `roles/system/tasks/main.yml`:

```yaml
- import_tasks: cloudflare_tunnel.yml
```

### Method 2: Use as Standalone Role

Create a playbook like `cloudflare_tunnel_example.yml`:

```yaml
---
- name: Deploy Cloudflare Tunnel on Raspberry Pi
  hosts: raspberry_pi
  become: yes
  gather_facts: yes
  
  vars:
    cloudflare_tunnel:
      name: "selfie-portal-1750534817"
      domain: "selfies.griffincreektrestle.net"
      local_port: 80
      credentials_file: "/home/pi/.cloudflared/86c5b63c-cd74-4191-8d5a-0c6119908551.json"
  
  roles:
    - cloudflare_tunnel
```

### Method 3: Override Variables

You can override any variables in your playbook:

```yaml
- hosts: raspberry_pi
  vars:
    cloudflare_tunnel:
      name: "my-custom-tunnel"
      domain: "myapp.example.com"
      local_port: 3000
  roles:
    - cloudflare_tunnel
```

## Prerequisites

1. **Cloudflare Account**: You need a Cloudflare account with a domain
2. **Tunnel Created**: Create a tunnel in Cloudflare Zero Trust dashboard
3. **Credentials File**: Download the tunnel credentials JSON file
4. **Domain Configuration**: Configure your domain to use the tunnel

## Service Management

### Check Status
```bash
sudo systemctl status cloudflared@selfie-portal-1750534817
```

### View Logs
```bash
sudo journalctl -u cloudflared@selfie-portal-1750534817 -f
```

### Restart Service
```bash
sudo systemctl restart cloudflared@selfie-portal-1750534817
```

### Enable/Disable Auto-start
```bash
sudo systemctl enable cloudflared@selfie-portal-1750534817
sudo systemctl disable cloudflared@selfie-portal-1750534817
```

## Security Features

- **Non-root Execution**: Service runs as `pi` user
- **File Permissions**: Credentials file has 600 permissions
- **Systemd Hardening**: Includes security restrictions
- **Automatic Restart**: Service restarts on failure
- **Logging**: All output goes to systemd journal

## Troubleshooting

### Common Issues

1. **Binary Download Fails**: Check internet connectivity and GitHub availability
2. **Service Won't Start**: Verify credentials file exists and has correct permissions
3. **Tunnel Not Connecting**: Check Cloudflare dashboard for tunnel status
4. **Domain Not Working**: Verify DNS configuration in Cloudflare

### Debug Commands

```bash
# Test cloudflared manually
sudo -u pi /usr/local/bin/cloudflared tunnel --config /etc/cloudflared/config.yml run

# Check configuration
sudo -u pi /usr/local/bin/cloudflared tunnel info

# View detailed logs
sudo journalctl -u cloudflared@selfie-portal-1750534817 --no-pager
```

## Integration with Existing System

The role integrates seamlessly with your existing selfie portal setup:

- Runs after web server configuration
- Uses the same `pi` user as other services
- Follows the same security practices
- Integrates with existing firewall rules

## Files Created

- `/usr/local/bin/cloudflared` - Cloudflared binary
- `/etc/cloudflared/config.yml` - Tunnel configuration
- `/etc/systemd/system/cloudflared@.service` - Service template
- `/home/pi/.cloudflared/selfie-portal-1750534817.json` - Credentials

## Next Steps

1. Ensure your Cloudflare tunnel is created and credentials are available
2. Run the playbook to deploy the tunnel
3. Verify the tunnel is working by accessing your domain
4. Monitor logs for any issues
5. Consider setting up monitoring and alerting

The tunnel will automatically start on boot and provide secure access to your selfie portal from anywhere on the internet. 