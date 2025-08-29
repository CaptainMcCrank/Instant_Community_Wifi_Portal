# Selfie Portal v2 Deployment Instructions for Claude

## Project Context

You are working on the **Instant Community WiFi Portal** project - a Raspberry Pi-based WiFi access point that creates a local community network. The **Selfie Portal** is a Flask web application that runs as part of this system, allowing users to take and share selfies within the local community.

## What Was Completed in Previous Session

A **three-tier network access architecture** has been successfully implemented for the Selfie Portal (v2). Here's what was built:

### Three-Tier Access System:
1. **Full Private Access** (10.10.42.x, 127.x.x.x) - Local WiFi AP users
   - Complete original functionality: camera, upload, delete, full gallery
   - Access to `/selfies/*` routes and `/health` endpoint
   - Traditional Tibbins the WiFi Gnome experience

2. **Semi-Public Access** (192.168.6.x) - wlan0 interface users  
   - Read-only gallery access via `/gallery`
   - Sanitized health status via `/status` endpoint
   - Upload/delete operations blocked

3. **External Access** (Internet via Cloudflare tunnel) - Public viewers
   - Griffin Creek Trestle branded read-only gallery via `/gallery`
   - Modified Tibbins narrative about "tricking humans into taking selfies"
   - Only `/gallery` and `/api/public/selfies` accessible

### Files Modified/Created:
- **`app.py`** - Enhanced with IP-based tier detection and new routes
- **`templates/public_gallery.html`** - New Griffin Creek Trestle themed public gallery
- **`nginx_config_v2.conf`** - Complete nginx configuration for three-tier access
- **Test files** - `test_tiers.py`, `test_routes.py` (all tests passing ✅)
- **Documentation** - `EXECUTION_PLAN_V2.md`, `DEPLOYMENT_SUMMARY_V2.md`
- **Backup** - `selfies_backup_20250820_200624/` contains original working version

## Your Deployment Mission

You need to **integrate the Selfie Portal v2 changes into the production Raspberry Pi environment**. The Flask application code is ready, but it needs to be deployed with proper nginx configuration and service integration.

## Step-by-Step Action Plan

### Phase 1: Pre-Deployment Validation
1. **Verify current application is working** before making changes
   - Run the validation script: `/usr/local/bin/validate-ap.sh`
   - Test that users can currently access the selfie portal
   - Document current working state

2. **Check nginx configuration** structure
   - Locate main nginx site configuration (likely `/etc/nginx/sites-available/thepub.local` or similar)
   - Identify how selfie portal is currently integrated
   - Note any existing proxy configurations for the selfie app

### Phase 2: Application Deployment
3. **Deploy the updated Flask application**
   - Copy updated `app.py` to replace current version
   - Copy `templates/public_gallery.html` to templates directory
   - Ensure file permissions are correct (`www-data:www-data`)
   - **DO NOT** touch the backup directory

4. **Test Flask application independently**
   - Restart selfie-portal service: `sudo systemctl restart selfie-portal`
   - Verify service starts: `sudo systemctl status selfie-portal`
   - Test basic connectivity: `curl http://localhost:5001/status`

### Phase 3: Nginx Integration
5. **Integrate nginx configuration**
   - Use `nginx_config_v2.conf` as reference
   - **DO NOT** replace existing nginx config files entirely
   - **ADD** the new location blocks to existing nginx site configuration
   - Key location blocks to add:
     - `/gallery` - Public read-only gallery
     - `/status` - Sanitized health endpoint  
     - `/api/public/selfies` - Public API
     - Update existing `/selfies` block with IP restrictions

6. **Test nginx configuration**
   - Test config syntax: `sudo nginx -t`
   - If syntax OK, reload: `sudo systemctl reload nginx`
   - If errors, review and fix configuration

### Phase 4: Access Control Validation
7. **Test three-tier access from different network locations**
   
   **From AP WiFi network (10.10.42.x):**
   ```bash
   curl http://thepub.local/selfies  # Should work (full access)
   curl http://thepub.local/health   # Should work
   curl http://thepub.local/gallery  # Should redirect to /selfies
   ```
   
   **From wlan0 network (192.168.6.x):**
   ```bash
   curl http://thepub.local/gallery  # Should work (read-only)
   curl http://thepub.local/status   # Should work (sanitized)
   curl http://thepub.local/health   # Should be blocked (403)
   ```
   
   **From external (via Cloudflare tunnel):**
   ```bash
   curl https://selfies.griffincreektrestle.net/gallery  # Should work
   curl https://selfies.griffincreektrestle.net/status   # Should be blocked
   ```

### Phase 5: Cloudflare Tunnel Integration
8. **Update Cloudflare tunnel configuration**
   - Ensure Cloudflare tunnel routes to `/gallery` endpoint instead of root
   - Test that external users see Griffin Creek Trestle gallery
   - Verify external users cannot access upload/delete functions

### Phase 6: Final Validation
9. **Run comprehensive validation**
   - Execute `/usr/local/bin/validate-ap.sh` again
   - Test user experience from each network tier:
     - **Local AP users:** Full selfie portal functionality
     - **Semi-public users:** Read-only gallery access
     - **External users:** Griffin Creek Trestle gallery only
   - Verify no unauthorized access to modification functions

10. **Monitor and troubleshoot**
    - Check logs: `journalctl -u selfie-portal -f`
    - Monitor nginx logs: `tail -f /var/log/nginx/access.log`
    - Test mobile access from actual devices on each network tier

## Critical Safety Guidelines

### ⚠️ **BACKUP FIRST**
- The working application backup exists at `selfies_backup_20250820_200624/`
- **DO NOT** delete or modify this backup
- If deployment fails, restore from backup immediately

### ⚠️ **NETWORK SAFETY**
- **NEVER** modify nginx configuration without testing syntax first
- **ALWAYS** verify current WiFi AP functionality before changes
- **TEST** incrementally - Flask app first, then nginx integration
- **ROLLBACK** immediately if any core functionality breaks

### ⚠️ **EXPECTED BEHAVIORS**
- **Local WiFi users** should see NO change in their experience
- **External users** should see branded Griffin Creek Trestle gallery
- **All users** should be appropriately restricted from unauthorized actions

## Key Files Reference

**Application Files (in `/var/www/ansibledest.local/apps/selfies/`):**
- `app.py` - Main Flask application with three-tier logic
- `templates/public_gallery.html` - Public gallery template
- `nginx_config_v2.conf` - Reference nginx configuration
- `DEPLOYMENT_SUMMARY_V2.md` - Complete technical summary

**System Configuration:**
- Main nginx site config (likely `/etc/nginx/sites-available/thepub.local`)
- Selfie portal service (`/etc/systemd/system/selfie-portal.service`)
- Validation script (`/usr/local/bin/validate-ap.sh`)

## Success Criteria

✅ **Local AP users (10.10.42.x):** Unchanged full functionality
✅ **Semi-public users (192.168.6.x):** Read-only gallery + health status
✅ **External users (Internet):** Griffin Creek Trestle branded gallery only
✅ **Security:** No unauthorized access to upload/delete functions
✅ **Performance:** No degradation in response times
✅ **Validation:** All tests in `/usr/local/bin/validate-ap.sh` pass

## Rollback Plan

If anything goes wrong:
1. **Stop services:** `sudo systemctl stop selfie-portal nginx`
2. **Restore Flask app:** Copy from `selfies_backup_20250820_200624/`
3. **Restore nginx config:** Revert to previous working configuration
4. **Restart services:** `sudo systemctl start nginx selfie-portal`
5. **Validate:** Run `/usr/local/bin/validate-ap.sh`

## Expected Timeline

- **Phase 1-2:** 30 minutes (validation + Flask deployment)
- **Phase 3:** 45 minutes (nginx integration)
- **Phase 4-5:** 30 minutes (testing + Cloudflare)
- **Phase 6:** 15 minutes (final validation)

**Total: ~2 hours** for careful, systematic deployment

---

## Final Notes

This deployment transforms the Selfie Portal from a simple local tool into a sophisticated multi-tier system that safely showcases community activity to the internet while preserving full functionality for local users. Take your time, test thoroughly, and don't hesitate to rollback if anything seems wrong.

The Griffin Creek Trestle community is counting on you to make their WiFi gnome's gallery visible to the world! 🧙‍♂️📸