#!/bin/bash

# WiFi Driver Caching Script
# Captures compiled 8812au driver from target Pi for future deployments
# Author: Automated Build System
# Usage: ./cache-wifi-driver.sh [target_ip]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CACHE_DIR="$PROJECT_DIR/drivers_cache/8812au"
LOG_FILE="$CACHE_DIR/driver_cache.log"
TARGET_IP="${1:-192.168.6.106}"
TARGET_USER="pi"
CONTAINER_NAME="AnsibleFWC"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if Docker container is running
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        error_exit "Docker container $CONTAINER_NAME is not running"
    fi
    
    # Check connectivity to target Pi
    if ! docker exec "$CONTAINER_NAME" ping -c 1 "$TARGET_IP" >/dev/null 2>&1; then
        error_exit "Cannot reach target Pi at $TARGET_IP"
    fi
    
    log "Prerequisites check passed"
}

# Get system information from target Pi
get_target_info() {
    log "Gathering target system information..."
    
    TARGET_KERNEL=$(docker exec "$CONTAINER_NAME" ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" "uname -r" 2>/dev/null || echo "unknown")
    TARGET_ARCH=$(docker exec "$CONTAINER_NAME" ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" "uname -m" 2>/dev/null || echo "unknown")
    TARGET_OS=$(docker exec "$CONTAINER_NAME" ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" "cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"'" 2>/dev/null || echo "unknown")
    BUILD_DATE=$(date '+%Y-%m-%d %H:%M:%S')
    
    log "Target kernel: $TARGET_KERNEL"
    log "Target architecture: $TARGET_ARCH"
    log "Target OS: $TARGET_OS"
    log "Cache date: $BUILD_DATE"
}

# Check if driver exists and is compiled
check_driver_exists() {
    log "Checking if compiled driver exists on target..."
    
    if docker exec "$CONTAINER_NAME" ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" "test -f /home/pi/8812au_src/8812au.ko" 2>/dev/null; then
        DRIVER_SIZE=$(docker exec "$CONTAINER_NAME" ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" "stat -c%s /home/pi/8812au_src/8812au.ko" 2>/dev/null || echo "0")
        log "Found compiled driver (size: $DRIVER_SIZE bytes)"
        return 0
    else
        error_exit "Compiled driver 8812au.ko not found on target Pi"
    fi
}

# Create versioned cache directory
create_cache_structure() {
    log "Creating cache directory structure..."
    
    VERSION_DIR="$CACHE_DIR/$TARGET_KERNEL-$(date '+%Y%m%d_%H%M%S')"
    mkdir -p "$VERSION_DIR"
    mkdir -p "$VERSION_DIR/firmware"
    mkdir -p "$VERSION_DIR/source"
    
    log "Created version directory: $VERSION_DIR"
    echo "$VERSION_DIR" > /tmp/cache_version_dir
}

# Copy driver files from Pi
copy_driver_files() {
    VERSION_DIR=$(cat /tmp/cache_version_dir)
    log "Copying driver files from target Pi..."
    
    # Copy main driver file
    log "Copying 8812au.ko..."
    docker exec "$CONTAINER_NAME" scp -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP:/home/pi/8812au_src/8812au.ko" /tmp/8812au.ko || error_exit "Failed to copy driver file"
    docker cp "$CONTAINER_NAME:/tmp/8812au.ko" "$VERSION_DIR/"
    
    # Copy source directory for reference
    log "Copying source directory..."
    docker exec "$CONTAINER_NAME" ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" "tar -czf /tmp/8812au_src.tar.gz -C /home/pi 8812au_src" || log "WARNING: Failed to copy source directory"
    if docker exec "$CONTAINER_NAME" test -f /tmp/8812au_src.tar.gz; then
        docker cp "$CONTAINER_NAME:/tmp/8812au_src.tar.gz" "$VERSION_DIR/source/"
    fi
    
    # Copy firmware files if they exist
    log "Copying firmware files..."
    docker exec "$CONTAINER_NAME" ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" "tar -czf /tmp/rtl_firmware.tar.gz -C /lib/firmware rtl* 2>/dev/null || true"
    if docker exec "$CONTAINER_NAME" test -f /tmp/rtl_firmware.tar.gz; then
        docker cp "$CONTAINER_NAME:/tmp/rtl_firmware.tar.gz" "$VERSION_DIR/firmware/"
        log "Firmware files copied"
    else
        log "No firmware files found"
    fi
    
    # Copy installed driver from modules directory
    log "Copying installed driver module..."
    docker exec "$CONTAINER_NAME" ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" "sudo find /lib/modules/$TARGET_KERNEL -name '*8812au*' -type f | head -5" | while read -r module_path; do
        if [ -n "$module_path" ]; then
            module_name=$(basename "$module_path")
            docker exec "$CONTAINER_NAME" scp -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP:$module_path" "/tmp/$module_name" 2>/dev/null || true
            docker cp "$CONTAINER_NAME:/tmp/$module_name" "$VERSION_DIR/" 2>/dev/null || true
            log "Copied installed module: $module_name"
        fi
    done
}

# Create metadata file
create_metadata() {
    VERSION_DIR=$(cat /tmp/cache_version_dir)
    METADATA_FILE="$VERSION_DIR/driver_metadata.json"
    
    log "Creating metadata file..."
    
    cat > "$METADATA_FILE" << EOF
{
    "cache_info": {
        "build_date": "$BUILD_DATE",
        "cache_version": "1.0",
        "script_version": "$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
    },
    "target_system": {
        "kernel_version": "$TARGET_KERNEL",
        "architecture": "$TARGET_ARCH",
        "os_version": "$TARGET_OS",
        "ip_address": "$TARGET_IP"
    },
    "driver_info": {
        "driver_name": "8812au",
        "driver_type": "WiFi USB Adapter",
        "source_location": "/home/pi/8812au_src/",
        "compiled_size_bytes": $DRIVER_SIZE
    },
    "files_cached": [
        "8812au.ko",
        "source/8812au_src.tar.gz",
        "firmware/rtl_firmware.tar.gz"
    ]
}
EOF
    
    log "Metadata file created: $METADATA_FILE"
}

# Create symlink to latest version
create_latest_symlink() {
    VERSION_DIR=$(cat /tmp/cache_version_dir)
    LATEST_LINK="$CACHE_DIR/latest"
    
    log "Creating 'latest' symlink..."
    
    # Remove existing symlink
    rm -f "$LATEST_LINK"
    
    # Create new symlink
    ln -s "$(basename "$VERSION_DIR")" "$LATEST_LINK"
    
    log "Latest symlink created: $LATEST_LINK -> $(basename "$VERSION_DIR")"
}

# Verify cached files
verify_cache() {
    VERSION_DIR=$(cat /tmp/cache_version_dir)
    log "Verifying cached files..."
    
    # Check main driver file
    if [ -f "$VERSION_DIR/8812au.ko" ]; then
        CACHED_SIZE=$(stat -c%s "$VERSION_DIR/8812au.ko")
        log "Cached driver size: $CACHED_SIZE bytes"
        
        if [ "$CACHED_SIZE" -eq "$DRIVER_SIZE" ]; then
            log "Driver file verification: PASSED"
        else
            log "WARNING: Driver file size mismatch"
        fi
    else
        error_exit "Driver file not found in cache"
    fi
    
    # Check metadata
    if [ -f "$VERSION_DIR/driver_metadata.json" ]; then
        log "Metadata file verification: PASSED"
    else
        log "WARNING: Metadata file missing"
    fi
}

# Cleanup temporary files
cleanup() {
    log "Cleaning up temporary files..."
    docker exec "$CONTAINER_NAME" rm -f /tmp/8812au.ko /tmp/8812au_src.tar.gz /tmp/rtl_firmware.tar.gz 2>/dev/null || true
    rm -f /tmp/cache_version_dir
}

# Display cache summary
show_summary() {
    VERSION_DIR=$(cat /tmp/cache_version_dir 2>/dev/null || echo "$CACHE_DIR/latest")
    
    log "=== WiFi Driver Cache Summary ==="
    log "Cache location: $VERSION_DIR"
    log "Kernel version: $TARGET_KERNEL"
    log "Build date: $BUILD_DATE"
    log "Driver size: $DRIVER_SIZE bytes"
    log "Latest symlink: $CACHE_DIR/latest"
    log "=== Cache Complete ==="
    
    echo ""
    echo "To use cached driver in future builds:"
    echo "1. Check if cache exists: ls -la $CACHE_DIR/latest/"
    echo "2. Copy to target: scp $CACHE_DIR/latest/8812au.ko pi@target:/home/pi/8812au_src/"
    echo "3. Skip compilation steps in Ansible playbook"
}

# Main execution
main() {
    log "Starting WiFi driver caching process..."
    log "Target: $TARGET_USER@$TARGET_IP"
    log "Container: $CONTAINER_NAME"
    
    check_prerequisites
    get_target_info
    check_driver_exists
    create_cache_structure
    copy_driver_files
    create_metadata
    create_latest_symlink
    verify_cache
    cleanup
    show_summary
    
    log "WiFi driver caching completed successfully"
}

# Handle script interruption
trap cleanup EXIT INT TERM

# Execute main function
main "$@"