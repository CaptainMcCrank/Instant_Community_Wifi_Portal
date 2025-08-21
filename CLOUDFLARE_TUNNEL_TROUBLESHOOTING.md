# Cloudflare Tunnel Troubleshooting Guide

## Problem Summary

The Cloudflare tunnel was failing to connect with various errors:
- `"context canceled"` errors with QUIC protocol
- `"Unauthorized: Invalid tunnel secret"` errors with HTTP/2 protocol
- Tunnel service running but no active connections

## Root Cause Analysis

### 1. **Credentials Format Issue**
**Problem**: The tunnel creation script was saving credentials in the wrong format.

**What was happening**:
- Script used: `cloudflared tunnel token tunnel-name > credentials.json`
- This saved just the base64 token: `eyJhIjoi...`
- Cloudflared expected proper JSON format with AccountTag and TunnelSecret

**Correct approach**:
```bash
cloudflared tunnel token --credentials-file /path/to/credentials.json tunnel-name
```

This creates the proper JSON format:
```json
{
  "AccountTag": "6bb8710e2419d53ce4c14f2bfeb83f97",
  "TunnelSecret": "2xeDbHh71FYlTxZA0xUJW8/eYrKZS8raVcNEjTAGdf8=",
  "TunnelID": "86c5b63c-cd74-4191-8d5a-0c6119908551",
  "Endpoint": ""
}
```

### 2. **Tunnel Recreation Without Credential Update**
**Problem**: The tunnel was recreated during an earlier Ansible run, but the credentials file wasn't updated with the new token.

**What happened**:
- Ansible playbook detected missing credentials
- Tunnel existed in Cloudflare but local credentials were stale
- Manual intervention was required but not completed in time

### 3. **Ansible Playbook Running as Wrong User**
**Problem**: The "Check if tunnel exists" task was running as root instead of the pi user.

**Issue**: 
- Task: `cloudflared tunnel list` running as root
- Certificate file owned by pi user: `/home/pi/.cloudflared/cert.pem`
- Root couldn't access the certificate, causing "Cannot determine default origin certificate path" error

**Solution**: Added `become: true` and `become_user: "{{ cloudflare_tunnel.user }}"` to the task.

## Solutions Implemented

### 1. **Fixed Tunnel Creation Script** (`bin/create-cloudflare-tunnel.sh`)

**Improvements**:
- Added pre-check for existing tunnels to avoid "already exists" errors
- Fixed credential format to use `--credentials-file` flag
- Better error message detection for various "already exists" patterns
- Improved flow control for both new and existing tunnel scenarios

**Before**:
```bash
# Wrong - saves just the token
cloudflared tunnel token tunnel-name > credentials.json
```

**After**:
```bash
# Correct - creates proper JSON format
cloudflared tunnel token --credentials-file credentials.json tunnel-name
```

### 2. **Enhanced Ansible Playbook** (`roles/cloudflare_tunnel/tasks/main.yml`)

**Improvements**:
- Added pause for manual intervention when credentials are missing
- Added automatic credential testing and refresh logic
- Added process cleanup before testing
- Better error handling and retry mechanisms

**New Features**:
- Automatic detection of invalid credentials
- Automatic refresh of stale credentials
- Better user guidance with clear instructions
- Graceful handling of existing tunnels

### 3. **Improved Error Handling**

**Added automatic credential refresh**:
```yaml
- name: Test tunnel connection with downloaded credentials
  command: "{{ cloudflare_tunnel.binary_path }} tunnel --config /etc/cloudflared/config.yml run {{ cloudflare_tunnel.name }}"
  async: 30
  poll: 0

- name: Refresh credentials if tunnel test failed
  command: "{{ cloudflare_tunnel.binary_path }} tunnel token {{ cloudflare_tunnel.name }}"
  when: "'does not have any active connection' in tunnel_info_test.stdout"
```

## Key Lessons Learned

### 1. **Always Use the Right Credential Format**
- Never manually construct JSON credentials files
- Always use `cloudflared tunnel token --credentials-file` for proper format
- The JSON format must include AccountTag, TunnelSecret, TunnelID, and Endpoint

### 2. **Check User Context**
- Ensure cloudflared commands run as the user who owns the certificate
- Use `become_user` in Ansible tasks that need certificate access
- Verify file permissions and ownership

### 3. **Handle Existing Tunnels Gracefully**
- Always check if tunnel exists before trying to create
- Handle "already exists" errors properly
- Provide clear user guidance for manual steps

### 4. **Test Credentials Automatically**
- Don't assume credentials work just because they exist
- Test tunnel connections and refresh if needed
- Provide automatic retry mechanisms

### 5. **Better User Experience**
- Add pauses for manual intervention when needed
- Provide clear, actionable error messages
- Give users time to complete manual steps

## Diagnostic Commands

### Check Tunnel Status
```bash
# Check if tunnel exists
cloudflared tunnel list

# Check tunnel info
cloudflared tunnel info tunnel-name

# Test tunnel connection
cloudflared tunnel --config /etc/cloudflared/config.yml run tunnel-name
```

### Check Service Status
```bash
# Check systemd service
sudo systemctl status cloudflared@tunnel-name

# Check service logs
sudo journalctl -u cloudflared@tunnel-name --no-pager -f
```

### Verify Credentials
```bash
# Check credentials file format
cat /home/pi/.cloudflared/tunnel-name.json

# Should contain proper JSON with AccountTag, TunnelSecret, etc.
```

### Test Web Server
```bash
# Test tunnel accessibility
curl -I https://your-domain.com
```

## Common Error Patterns

### 1. **"context canceled" with QUIC**
- Usually indicates network connectivity issues
- Try HTTP/2 protocol: `--protocol http2`
- Check firewall settings

### 2. **"Unauthorized: Invalid tunnel secret"**
- Credentials are stale or wrong format
- Refresh credentials: `cloudflared tunnel token --credentials-file credentials.json tunnel-name`
- Restart service after updating credentials

### 3. **"Cannot determine default origin certificate path"**
- Running as wrong user
- Certificate file not found
- Fix: Use `become_user` in Ansible tasks

### 4. **"tunnel with name already exists"**
- Tunnel already created in Cloudflare
- Skip creation, just download credentials
- Use pre-check before creation

## Best Practices

### 1. **Credential Management**
- Always use `--credentials-file` flag for proper JSON format
- Never manually construct credential files
- Test credentials after creation/update

### 2. **Ansible Playbook Design**
- Add pauses for manual intervention when needed
- Include automatic credential testing and refresh
- Provide clear user guidance and error messages

### 3. **Tunnel Creation Scripts**
- Check for existing tunnels before creation
- Handle various error patterns gracefully
- Use proper credential format from the start

### 4. **Monitoring and Debugging**
- Monitor tunnel connection status
- Check service logs regularly
- Test web server accessibility

## Success Indicators

✅ **Tunnel connecting successfully**:
```
2025-07-27T20:34:08Z INF Registered tunnel connection connIndex=0 connection=24bb757f-e18d-425f-950b-36a4acae5642 event=0 ip=198.41.192.27 location=sea01 protocol=quic
```

✅ **Web server accessible**:
```
HTTP/2 200
server: cloudflare
cf-cache-status: DYNAMIC
```

✅ **Service running properly**:
```
● cloudflared@tunnel-name.service - Cloudflare Tunnel for tunnel-name
     Active: active (running)
```

## Conclusion

The key to successful Cloudflare tunnel deployment is:
1. **Proper credential format** using `--credentials-file`
2. **Correct user context** for certificate access
3. **Graceful handling** of existing tunnels
4. **Automatic testing** and refresh of credentials
5. **Clear user guidance** for manual steps

These improvements make the deployment process more robust and user-friendly, reducing the need for manual troubleshooting. 