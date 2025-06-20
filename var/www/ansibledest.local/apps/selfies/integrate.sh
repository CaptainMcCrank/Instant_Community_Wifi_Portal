#!/bin/bash
# Integration script for Selfie Portal
# Adds selfie portal link to the main community site

SITE_DIR="/var/www/ansibledest.local/sites"
HOSTNAME=$(hostname)

echo "Integrating Selfie Portal into community site..."

# Check if site directory exists
if [ ! -d "$SITE_DIR/$HOSTNAME" ]; then
    echo "Site directory not found: $SITE_DIR/$HOSTNAME"
    exit 1
fi

# Find the main index file
INDEX_FILE="$SITE_DIR/$HOSTNAME/index.html"
if [ ! -f "$INDEX_FILE" ]; then
    echo "Index file not found: $INDEX_FILE"
    exit 1
fi

# Add selfie portal link to navigation
echo "Adding selfie portal link to navigation..."

# Create backup
cp "$INDEX_FILE" "$INDEX_FILE.backup.$(date +%Y%m%d_%H%M%S)"

# Add selfie portal link (look for nav-links or similar navigation element)
if grep -q "nav-links" "$INDEX_FILE"; then
    # Insert after nav-links opening tag
    sed -i '/<ul class="nav-links">/a \                    <li><a href="/selfies" class="btn btn-primary"><i class="fas fa-camera"></i> Selfie Portal</a></li>' "$INDEX_FILE"
elif grep -q "navigation" "$INDEX_FILE"; then
    # Insert after navigation opening tag
    sed -i '/<nav/a \                    <li><a href="/selfies" class="btn btn-primary"><i class="fas fa-camera"></i> Selfie Portal</a></li>' "$INDEX_FILE"
else
    # Add to body if no specific navigation found
    sed -i '/<body>/a \        <div class="selfie-portal-link" style="text-align: center; margin: 20px 0;"><a href="/selfies" class="btn btn-primary"><i class="fas fa-camera"></i> Selfie Portal</a></div>' "$INDEX_FILE"
fi

echo "Selfie Portal integration complete!"
echo "Portal accessible at: http://$HOSTNAME/selfies"
echo "Backup created at: $INDEX_FILE.backup.$(date +%Y%m%d_%H%M%S)" 