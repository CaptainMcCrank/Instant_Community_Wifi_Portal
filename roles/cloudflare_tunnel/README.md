# Cloudflare Tunnel Role

This Ansible role sets up a Cloudflare Tunnel on Raspberry Pi OS (armv7l) to expose local services securely through Cloudflare's network.

## Features

- Downloads and installs the correct `cloudflared` binary for Raspberry Pi OS armv7l
- Configures tunnel with specified domain and local service
- Sets up systemd service for automatic startup
- Includes fallback 404 route for unmatched requests
- Implements security best practices

## Requirements

- Raspberry Pi OS (armv7l architecture)
- Valid Cloudflare Tunnel credentials file
- Ansible 2.9+

## Role Variables

All variables are defined in `defaults/main.yml` and can be overridden:

```yaml
cloudflare_tunnel:
  name: "selfie-portal-1750534817"                    # Tunnel name
  domain: "selfies.griffincreektrestle.net"          # Public domain
  local_port: 80                                      # Local service port
  credentials_file: "/path/to/credentials.json"       # Credentials file path
  binary_url: "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm"
  binary_path: "/usr/local/bin/cloudflared"           # Binary installation path
  config_dir: "/etc/cloudflared"                      # Configuration directory
  service_name: "cloudflared@{{ cloudflare_tunnel.name }}"
  user: "pi"                                          # Service user
  group: "pi"                                         # Service group
```

## Usage

### Basic Usage

Include the role in your playbook:

```yaml
- hosts: raspberry_pi
  roles:
    - cloudflare_tunnel
```

### With Custom Variables

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

### Including in Existing Playbook

Add to your existing playbook:

```yaml
- hosts: all
  roles:
    - system
    - cloudflare_tunnel  # Add this line
```

## Files Created

- `/usr/local/bin/cloudflared` - Cloudflared binary
- `/etc/cloudflared/config.yml` - Tunnel configuration
- `/etc/systemd/system/cloudflared@.service` - Systemd service template
- `/home/pi/.cloudflared/` - Credentials directory

## Service Management

The tunnel runs as a systemd service named `cloudflared@selfie-portal-1750534817`.

```bash
# Check status
sudo systemctl status cloudflared@selfie-portal-1750534817

# View logs
sudo journalctl -u cloudflared@selfie-portal-1750534817 -f

# Restart service
sudo systemctl restart cloudflared@selfie-portal-1750534817
```

## Security Notes

- Credentials file is stored with 600 permissions
- Service runs as non-root user (pi)
- Systemd service includes security hardening
- Configuration files have appropriate ownership and permissions 