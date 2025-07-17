# Selfie App Role

This Ansible role deploys the Selfie Portal Flask application for the Instant Community WiFi Portal.

## Overview

The Selfie Portal is a mobile-friendly web application that allows users to:
- Take selfies using their device camera
- Upload photos with optional captions
- Browse a gallery of community selfies
- View individual selfies with metadata

## Dependencies

This role depends on the `system` role which provides:
- Python 3 and pip
- Python development libraries (python3-dev, libjpeg-dev, zlib1g-dev)
- nginx web server

## Role Variables

### Default Variables

```yaml
selfie_app:
  # Application settings
  app_name: "selfie-portal"
  app_port: 5001
  app_user: "www-data"
  app_group: "www-data"
  
  # Directory paths
  app_root: "/var/www/ansibledest.local/apps/selfies"
  upload_dir: "data/uploads"
  static_dir: "static"
  templates_dir: "templates"
  
  # File settings
  max_file_size: "10M"
  max_selfies: 100
  cleanup_days: 30
  
  # Python virtual environment
  venv_path: "venv"
  python_version: "python3"
  
  # Service settings
  service_name: "selfie-portal"
  service_description: "Selfie Portal Flask Application"
  
  # Nginx settings
  nginx_site_name: "selfie-portal"
  nginx_proxy_path: "/selfies"
  
  # Allowed file extensions
  allowed_extensions:
    - "png"
    - "jpg" 
    - "jpeg"
    - "gif"
    - "webp"
```

## Usage

### Basic Usage

```yaml
- hosts: all
  roles:
    - selfie_app
```

### With Custom Variables

```yaml
- hosts: all
  vars:
    selfie_app:
      app_port: 5002
      max_selfies: 200
      cleanup_days: 60
      nginx_proxy_path: "/photos"
  roles:
    - selfie_app
```

## Tasks

The role is organized into three main task files:

### install.yml
- Creates directory structure
- Copies application files (app.py, templates, static files)
- Creates Python virtual environment
- Installs Python dependencies
- Creates initial data files

### configure.yml
- Creates systemd service file
- Sets proper file permissions
- **Configures nginx site and proxy settings**
- **Adds selfie portal link to main community site**

### service.yml
- Enables and starts the systemd service
- Waits for application to be ready
- Tests health endpoint

## Tags

The role uses the following tags:
- `selfie_app` - All tasks in this role
- `install` - Installation tasks only
- `configure` - Configuration tasks only
- `service` - Service management tasks only

## Files Created

- `/var/www/ansibledest.local/apps/selfies/` - Application root directory
- `/var/www/ansibledest.local/apps/selfies/app.py` - Flask application
- `/var/www/ansibledest.local/apps/selfies/venv/` - Python virtual environment
- `/etc/systemd/system/selfie-portal.service` - Systemd service file
- `/var/www/ansibledest.local/apps/selfies/data/index.json` - Initial data file
- `/etc/nginx/sites-available/selfie-portal` - Nginx site configuration
- `/etc/nginx/sites-enabled/selfie-portal` - Nginx site symlink

## Service Management

The application runs as a systemd service named `selfie-portal`:

```bash
# Check status
sudo systemctl status selfie-portal

# Start service
sudo systemctl start selfie-portal

# Stop service
sudo systemctl stop selfie-portal

# Restart service
sudo systemctl restart selfie-portal

# View logs
sudo journalctl -u selfie-portal -f
```

## Health Check

The application provides a health check endpoint at:
- `http://localhost:5001/health`

## Nginx Integration

This role includes complete nginx configuration:
- Creates nginx site configuration with proxy settings
- Enables the nginx site
- Tests nginx configuration
- Reloads nginx service
- Adds selfie portal link to the main community site

## Migration from selfie_portal.yml

This role is a complete replacement for the `roles/system/tasks/selfie_portal.yml` file. It includes all the same functionality but with:
- Better organization and modularity
- Configurable variables
- Health checks and validation
- Proper error handling
- Improved maintainability

## Notes

- The application runs on port 5001 by default
- File uploads are limited to 10MB by default
- Selfies are automatically cleaned up after 30 days by default
- The application uses a Python virtual environment for dependency isolation
- Nginx configuration is included and handles proxy forwarding to the Flask app 