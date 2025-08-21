# WiFi Driver Caching System

## Overview
The WiFi driver caching system captures compiled 8812au drivers from target Raspberry Pi devices to avoid lengthy recompilation on subsequent deployments.

## Files
- `cache-wifi-driver.sh` - Main caching script
- `drivers_cache/8812au/` - Cache storage directory
- `drivers_cache/8812au/latest/` - Symlink to most recent cached version

## Usage

### 1. Cache Driver After Successful Compilation
```bash
# Cache from default IP (192.168.6.106)
./bin/cache-wifi-driver.sh

# Cache from specific IP
./bin/cache-wifi-driver.sh 192.168.6.200
```

### 2. Check Available Cached Drivers
```bash
# List all cached versions
ls -la drivers_cache/8812au/

# View latest cached version
ls -la drivers_cache/8812au/latest/

# Check metadata
cat drivers_cache/8812au/latest/driver_metadata.json
```

### 3. Use Cached Driver in Deployment
Modify Ansible tasks to check for cached driver:

```yaml
- name: Check for cached WiFi driver
  local_action:
    module: stat
    path: "{{ playbook_dir }}/drivers_cache/8812au/latest/8812au.ko"
  register: cached_driver

- name: Copy cached driver to target
  copy:
    src: "{{ playbook_dir }}/drivers_cache/8812au/latest/8812au.ko"
    dest: "/home/pi/8812au_src/8812au.ko"
    mode: '0644'
  when: cached_driver.stat.exists

- name: Skip compilation if cached driver available
  set_fact:
    skip_driver_build: "{{ cached_driver.stat.exists }}"

# Existing compilation tasks
- include_tasks: compile_wifi_driver.yml
  when: not (skip_driver_build | default(false))
```

## Cache Directory Structure
```
drivers_cache/8812au/
├── latest -> 6.12.41-v7+-20250804_220315/
├── 6.12.41-v7+-20250804_220315/
│   ├── 8812au.ko                    # Main compiled driver
│   ├── driver_metadata.json         # Build information
│   ├── source/
│   │   └── 8812au_src.tar.gz       # Source code archive
│   └── firmware/
│       └── rtl_firmware.tar.gz     # Firmware files
└── driver_cache.log                 # Operation log
```

## Metadata Fields
Each cached driver includes:
- **Build date and time**
- **Target kernel version** (e.g., 6.12.41-v7+)
- **Target architecture** (e.g., armv7l)
- **Target OS version**
- **Driver file size**
- **Source location**
- **Cached files list**

## Benefits
- **Time Savings**: Skip 20-45 minute compilation
- **Consistency**: Same driver binary across deployments
- **Reliability**: Avoid compilation failures
- **Traceability**: Full metadata and versioning

## Version Compatibility
- Drivers are kernel-specific (e.g., 6.12.41-v7+)
- Architecture-specific (ARM 32-bit)
- Must match target system exactly

## Maintenance
- **Clean old versions**: Remove outdated kernel versions
- **Rebuild when needed**: New kernel or driver source updates
- **Monitor logs**: Check `driver_cache.log` for issues

## Troubleshooting

### Driver Not Found
```bash
# Check if driver compiled successfully on target
ssh pi@192.168.6.106 "ls -la /home/pi/8812au_src/8812au.ko"
```

### Kernel Version Mismatch
```bash
# Check target kernel version
ssh pi@192.168.6.106 "uname -r"

# List available cached versions
ls drivers_cache/8812au/*/driver_metadata.json | xargs grep kernel_version
```

### Permission Issues
```bash
# Fix cache directory permissions
chmod -R 755 drivers_cache/
```