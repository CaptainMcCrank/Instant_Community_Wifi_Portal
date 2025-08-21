# New Prompt-Driven Execution Guidelines

Based on lessons learned from deployment troubleshooting sessions, these guidelines should be incorporated into the CLAUDE.md preprompt file to improve future automation and debugging processes.

## Preprompt File Improvements (CLAUDE.md)

**Add these sections:**

```markdown
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