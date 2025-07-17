Summary
I've successfully created a complete Ansible role for automating Cloudflare Tunnel setup on your Raspberry Pi selfie portal system. Here's what I've delivered:
🎯 Complete Role Structure
roles/cloudflare_tunnel/ with all necessary components:
defaults/main.yml - Configurable variables with your specific tunnel settings
tasks/main.yml - Complete automation tasks
templates/config.yml.j2 - Cloudflared configuration template
templates/cloudflared@.service.j2 - Systemd service template with security hardening
handlers/main.yml - Service restart handlers
meta/main.yml - Role metadata
README.md - Comprehensive documentation
🔧 Key Features Implemented
ARMv7l Binary Download: Downloads the correct cloudflared-linux-arm binary
Secure Configuration: Proper file permissions and ownership
Systemd Integration: Auto-start service with security hardening
Fallback Routing: 404 response for unmatched requests
Error Handling: Automatic restart on failure
Logging: Full journal integration
📋 Configuration Details
Tunnel Settings:
Name: selfie-portal-1750534817
Domain: selfies.griffincreektrestle.net
Local Port: 80
Credentials: /home/pi/.cloudflared/86c5b63c-cd74-4191-8d5a-0c6119908551.json
Generated Config:
🚀 Integration Options
Already Integrated: Added to your existing roles/system/tasks/main.yml
Standalone Usage: Created cloudflare_tunnel_example.yml playbook
Variable Override: Easy customization through playbook variables
🛡️ Security Features
Non-root execution (runs as pi user)
Credentials file with 600 permissions
Systemd security hardening
Automatic restart on failure
Comprehensive logging
📚 Documentation
Created comprehensive documentation including:
CLOUDFLARE_TUNNEL_SETUP.md - Complete setup guide
roles/cloudflare_tunnel/README.md - Role-specific documentation
Service management commands
Troubleshooting guide
🎯 Usage Instructions
To use the role:
Ensure prerequisites: Cloudflare tunnel created, credentials file available
Run your existing playbook: The role is already integrated
Or run standalone: ansible-playbook cloudflare_tunnel_example.yml
Service management:
Apply to index.html
Run
The role follows Ansible best practices and integrates seamlessly with your existing selfie portal infrastructure. It will automatically download the correct ARM binary, configure the tunnel with your domain, and set up a secure, auto-starting service that exposes your local web app to the internet through Cloudflare's network.