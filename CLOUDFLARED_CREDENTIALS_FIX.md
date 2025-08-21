# Cloudflare Tunnel Credentials Fix

## Problem Summary

The Cloudflare tunnel service was failing to start with the error:
```
The credentials file at /home/pi/.cloudflared/selfie-portal-1750534817.json contained invalid JSON. 
This is probably caused by passing the wrong filepath. 
Reminder: the credentials file is a .json file created via `cloudflared tunnel create`.
```

## Root Cause

The issue was caused by an incorrect credentials file format. The `cloudflared tunnel token` command outputs a **base64-encoded token**, but the service expects the credentials file to be in **JSON format**.

### What Was Happening

1. `cloudflared tunnel token` outputs: `eyJhIjoiNmJiODcxMGUyNDE5ZDUzY2U0YzE0ZjJiZmViODNmOTciLCJzIjoiMnhlRGJIaDcxRllsVHhaQTB4VUpXOC9lWXJLWlM4cmFWY05FalRBR2RmOD0iLCJ0IjoiODZjNWI2M2MtY2Q3NC00MTkxLThkNWEtMGM2MTE5OTA4NTUxIn0=`

2. This base64 token was being saved directly to the `.json` file

3. The service expected JSON format but received base64, causing the "invalid JSON" error

## Solution

The credentials file must be in proper JSON format with the base64 token embedded as a field.

### Correct Format

```json
{
  "AccountTag": "6bb8710e2419d53ce4c14f2bfeb83f97",
  "TunnelSecret": "eyJhIjoiNmJiODcxMGUyNDE5ZDUzY2U0YzE0ZjJiZmViODNmOTciLCJzIjoiMnhlRGJIaDcxRllsVHhaQTB4VUpXOC9lWXJLWlM4cmFWY05FalRBR2RmOD0iLCJ0IjoiODZjNWI2M2MtY2Q3NC00MTkxLThkNWEtMGM2MTE5OTA4NTUxIn0="
}
```

### Manual Fix Steps

1. **Stop the service:**
   ```bash
   sudo systemctl stop cloudflared@selfie-portal-1750534817
   ```

2. **Get the base64 token:**
   ```bash
   cloudflared tunnel token selfie-portal-1750534817
   ```

3. **Create the JSON credentials file:**
   ```bash
   cat > /home/pi/.cloudflared/selfie-portal-1750534817.json << EOF
   {
     "AccountTag": "6bb8710e2419d53ce4c14f2bfeb83f97",
     "TunnelSecret": "eyJhIjoiNmJiODcxMGUyNDE5ZDUzY2U0YzE0ZjJiZmViODNmOTciLCJzIjoiMnhlRGJIaDcxRllsVHhaQTB4VUpXOC9lWXJLWlM4cmFWY05FalRBR2RmOD0iLCJ0IjoiODZjNWI2M2MtY2Q3NC00MTkxLThkNWEtMGM2MTE5OTA4NTUxIn0="
   }
   EOF
   ```

4. **Set correct permissions:**
   ```bash
   sudo chown pi:pi /home/pi/.cloudflared/selfie-portal-1750534817.json
   sudo chmod 600 /home/pi/.cloudflared/selfie-portal-1750534817.json
   ```

5. **Start the service:**
   ```bash
   sudo systemctl start cloudflared@selfie-portal-1750534817
   ```

6. **Verify the service is running:**
   ```bash
   sudo systemctl status cloudflared@selfie-portal-1750534817
   ```

## Ansible Role Updates

The `cloudflare_tunnel` Ansible role has been updated to automatically create the correct JSON format:

### Key Changes

1. **Credentials Validation**: Now validates both base64 and JSON formats
2. **JSON Format Creation**: Automatically wraps base64 tokens in proper JSON structure
3. **Error Handling**: Detects and fixes invalid credentials files
4. **Service Permissions**: Fixes `ProtectHome` settings that block file access

### Updated Tasks

```yaml
- name: Save tunnel credentials to file (JSON format)
  copy:
    content: |
      {
        "AccountTag": "6bb8710e2419d53ce4c14f2bfeb83f97",
        "TunnelSecret": "{{ tunnel_token_output.stdout }}"
      }
    dest: "/home/{{ cloudflare_tunnel.user }}/.cloudflared/{{ cloudflare_tunnel.name }}.json"
    owner: "{{ cloudflare_tunnel.user }}"
    group: "{{ cloudflare_tunnel.group }}"
    mode: '0600'
```

## Service Configuration Fixes

### ProtectHome Issue

The service template was updated to fix file access issues:

```ini
# Before (blocked access)
ProtectHome=true

# After (allows read access)
ProtectHome=read-only
```

### File Permissions

Ensure proper ownership and permissions:
- **Directory**: `/home/pi/.cloudflared/` - `700` (pi:pi)
- **Certificate**: `/home/pi/.cloudflared/cert.pem` - `600` (pi:pi)
- **Credentials**: `/home/pi/.cloudflared/selfie-portal-1750534817.json` - `600` (pi:pi)

## Troubleshooting Scripts

Several debugging scripts were created:

### `bin/debug-credentials-file.sh`
- Validates credentials file format
- Checks for base64 vs JSON content
- Provides detailed file analysis

### `bin/fix-credentials-json.sh`
- Automatically fixes invalid credentials files
- Downloads new credentials in correct format
- Restarts the service

### `bin/debug-service-permissions.sh`
- Checks service user configuration
- Validates file permissions
- Tests file access for different users

### `bin/test-credentials-format.sh`
- Tests different credentials file formats
- Validates which format works with the service
- Provides step-by-step debugging

## Verification

After applying the fix, verify:

1. **Service Status**: `sudo systemctl status cloudflared@selfie-portal-1750534817`
2. **Service Logs**: `journalctl -u cloudflared@selfie-portal-1750534817 --no-pager -n 20`
3. **Tunnel Connection**: `cloudflared tunnel info selfie-portal-1750534817`
4. **Website Access**: Visit `https://selfies.griffincreektrestle.net`

## Expected Results

- ✅ Service status: `active (running)`
- ✅ No "invalid JSON" errors in logs
- ✅ Tunnel connects to Cloudflare successfully
- ✅ Website accessible without 1033 errors (if local service is running)

## Prevention

To prevent this issue in the future:

1. **Always use JSON format** for credentials files
2. **Validate credentials** before starting the service
3. **Use the updated Ansible role** for automated deployments
4. **Test credentials format** with debugging scripts

## Related Issues

This fix also resolves:
- Cloudflare 1033 errors (Origin DNS error)
- Service startup failures
- File permission issues
- Authentication problems

## References

- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/)
- [Systemd Security Settings](https://www.freedesktop.org/software/systemd/man/systemd.exec.html)
- [Ansible Cloudflare Tunnel Role](roles/cloudflare_tunnel/) 