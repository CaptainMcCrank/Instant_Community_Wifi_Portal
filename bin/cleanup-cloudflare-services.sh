#!/bin/bash

# Cleanup script for duplicate cloudflared services
# This script stops and disables all cloudflared services except the intended one

set -e

INTENDED_SERVICE="cloudflared@selfie-portal-1750534817"

echo "=== Cloudflare Services Cleanup ==="
echo "Intended service: $INTENDED_SERVICE"
echo

# List all cloudflared services
echo "Current cloudflared services:"
systemctl list-units --type=service --state=active | grep cloudflared || echo "No active cloudflared services found"
echo

# Stop and disable all cloudflared services except the intended one
echo "Stopping and disabling duplicate services..."

# Get all cloudflared services
SERVICES=$(systemctl list-units --type=service --state=active | grep cloudflared | awk '{print $1}' | sed 's/\.service$//')

for service in $SERVICES; do
    if [ "$service" != "$INTENDED_SERVICE" ]; then
        echo "Stopping and disabling: $service"
        sudo systemctl stop "$service" || echo "Failed to stop $service"
        sudo systemctl disable "$service" || echo "Failed to disable $service"
    else
        echo "Keeping intended service: $service"
    fi
done

echo
echo "Final status:"
systemctl list-units --type=service --state=active | grep cloudflared || echo "No active cloudflared services found"

echo
echo "Cleanup complete!" 