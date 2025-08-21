# Hostname Directory Bug Fixes & Selfie App Analysis

## Problem Summary
The Ansible playbook had hardcoded directory paths and configurations using `ansibledest.local` instead of the dynamic `{{ hostname }}` variable (`thepub.local`). This caused the selfie app and other services to fail because files were deployed to the wrong directory paths. Additionally, the playbook never completed the selfie_app role due to hanging on SSL certificate generation.

## Root Cause
1. **Static Directory Structure**: Source files in `var/www/ansibledest.local/` were copied without renaming to match the hostname variable
2. **Hardcoded Nginx Config**: The nginx configuration file had static paths to `/var/www/thepub.local` instead of using `{{ hostname }}`
3. **Missing Hostname-Aware Tasks**: No tasks existed to rename directories or update paths after deployment

## Fixes Applied

### 1. Fixed `roles/system/tasks/webservercontent.yml`
**Added new task to rename directory after copying:**
```yaml
- name: Rename ansibledest.local directory to match hostname
  command: mv /var/www/ansibledest.local /var/www/{{ hostname }}
  args:
    creates: /var/www/{{ hostname }}
  when: hostname != "ansibledest.local"
  tags: 
  - webserver
  - hostname_fix
```

### 2. Fixed `roles/system/tasks/nginx.yml`
**Added tasks to update nginx configuration with hostname variable:**
```yaml
- name: Update nginx thepub.local config to use hostname variable
  replace:
    path: /etc/nginx/sites-available/thepub.local
    regexp: '/var/www/thepub\.local'
    replace: '/var/www/{{ hostname }}'
  tags: hostname_fix

- name: Update nginx server_name to use hostname variable  
  replace:
    path: /etc/nginx/sites-available/thepub.local
    regexp: 'server_name thepub\.local www\.thepub\.local'
    replace: 'server_name {{ hostname }} www.{{ hostname }}'
  tags: hostname_fix
```

### 3. Manual Server Fix Applied
**Commands executed on target server:**
```bash
# Rename directory while preserving ownership
sudo mv /var/www/ansibledest.local /var/www/thepub.local
sudo chown -R pi:pi /var/www/thepub.local

# Update nginx configuration (was already correct after our playbook fixes)
sudo nginx -t && sudo systemctl reload nginx
```

## Verification Steps
1. ✅ Directory `/var/www/thepub.local` exists with correct ownership
2. ✅ Selfie app files present at `/var/www/thepub.local/apps/selfies/`
3. ✅ Nginx configuration syntax valid and service reloaded
4. ✅ Nginx config now references correct paths

## Impact
- **Before**: Selfie app files existed but nginx couldn't find them (404 errors)
- **After**: File paths align between nginx config and actual directory structure
- **Future deployments**: Will automatically use hostname variable throughout

## Files Modified
- `roles/system/tasks/webservercontent.yml` - Added directory rename task
- `roles/system/tasks/nginx.yml` - Added nginx config update tasks
- Server: `/var/www/ansibledest.local` → `/var/www/thepub.local` (manual fix)

## Selfie App Role Analysis

### Why selfie_app Role Didn't Complete
1. **Playbook Execution Stopped**: The main deployment hung on SSL certificate generation (`Generate Diffie-Hellman parameters` task with 10000ms timeout)
2. **Role Never Reached**: The playbook stopped before reaching the `selfie_app` and `cloudflare_tunnel` roles in the execution order
3. **No Service Created**: Because the role never ran, no systemd service, virtual environment, or Flask app was deployed

### Expected selfie_app Role Behavior
- **Install Phase**: Copy app files, create Python virtual environment, install packages from requirements.txt
- **Configure Phase**: Create systemd service file, set up nginx proxy configuration for /selfies endpoint
- **Service Phase**: Start and enable selfie-portal.service on port 5001

### Source Path Analysis
The selfie_app role source paths are **correctly configured**:
- Source: `{{ root_playbook_dir }}/var/www/ansibledest.local/apps/selfies/` (controller/playbook directory)
- Destination: `{{ selfie_app.app_root }}` = `/var/www/{{ hostname }}/apps/selfies` (managed node)

No fixes needed for selfie_app role paths - the issue was execution order.

## Next Steps
1. **Complete SSL certificate generation**: Either let the DH parameter task finish or skip it
2. **Resume playbook execution**: Continue from where it stopped to run selfie_app and cloudflare_tunnel roles  
3. **Alternative**: Run specific roles with tags: `ansible-playbook run.yml --tags selfie_app`
4. **Test full selfie app functionality** once service is running
5. **Verify Cloudflare tunnel integration** works