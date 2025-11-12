#!/bin/bash
# Deploy Website Files to Raspberry Pi
# Syncs HTML, CSS, JS, icons, videos to Pi and restarts nginx

set -euo pipefail

PI_HOST=${1:-cosmic@cosmicpi.local}
SITE_FILES=(
    "index.html"
    "index01.html"
    "index02.html"
    "manifest.json"
    "manifest01.json"
    "manifest02.json"
    "script.js"
    "style.css"
    "sw.js"
    "icons/"
    "videos/"
)

echo "=== Deploying Website to ${PI_HOST} ==="
echo ""

# Check if Pi is reachable
if ! ping -c 1 -W 2 cosmicpi.local &>/dev/null; then
    echo "⚠️  Warning: cosmicpi.local not reachable. Make sure Pi is on."
    echo "Continue anyway? (y/n)"
    read -r answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create site directory if it doesn't exist
echo "Ensuring ~/site directory exists..."
ssh "${PI_HOST}" "mkdir -p ~/site"

# Sync each file/folder
for item in "${SITE_FILES[@]}"; do
    echo "Syncing ${item}..."
    if [[ "${item}" == */ ]]; then
        # Directory - use rsync with trailing slash
        rsync -avz --delete "${item}" "${PI_HOST}:~/site/"
    else
        # Single file
        rsync -avz "${item}" "${PI_HOST}:~/site/"
    fi
done

echo ""
echo "Deploying to web root (/var/www/html)..."
ssh "${PI_HOST}" "sudo rm -rf /var/www/html/* && sudo cp -r ~/site/* /var/www/html/ && sudo chown -R www-data:www-data /var/www/html"

echo "Restarting nginx..."
ssh "${PI_HOST}" "sudo systemctl restart nginx"

echo ""
echo "✅ Website deployed successfully!"
echo ""
echo "Access points:"
echo "  - iPad 1: http://192.168.4.1/index.html"
echo "  - iPad 2: http://192.168.4.1/index01.html"
echo "  - iPad 3: http://192.168.4.1/index02.html"
echo ""
