#!/bin/bash
# WiFi Dual-Mode Setup - Diagnose and Fix
# This script properly configures Pi to run both hotspot AND connect to external WiFi
# Solves the wpa_cli FAIL issue from last attempt

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIFI_CONF="${SCRIPT_DIR}/configs/wifi-networks.conf"

echo "================================================================"
echo "WiFi Dual-Mode Setup - Advanced Configuration"
echo "================================================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root (use sudo)"
    exit 1
fi

echo ""
echo "🔍 Step 1: Diagnosing current WiFi setup..."
echo ""

# Show current network status
echo "Current network interfaces:"
ip link show | grep -E "(wlan|ap)"

echo ""
echo "Current wpa_supplicant processes:"
ps aux | grep wpa_supplicant | grep -v grep || echo "No wpa_supplicant processes found"

echo ""
echo "Current hostapd status:"
systemctl status hostapd --no-pager -l || echo "hostapd not running"

echo ""
echo "🛠️  Step 2: Stopping conflicting services..."
echo ""

# Stop services that might interfere
systemctl stop wpa_supplicant || true
systemctl stop hostapd || true
sleep 2

# Kill any remaining wpa_supplicant processes
killall wpa_supplicant 2>/dev/null || true
sleep 1

echo ""
echo "📝 Step 3: Configuring wpa_supplicant for client mode..."
echo ""

# Create wpa_supplicant config if wifi-networks.conf exists
if [ ! -f "$WIFI_CONF" ]; then
    echo "ERROR: WiFi configuration file not found: $WIFI_CONF"
    echo "Please edit pi-deployment/configs/wifi-networks.conf first"
    exit 1
fi

# Backup existing config
if [ -f "/etc/wpa_supplicant/wpa_supplicant.conf" ]; then
    cp "/etc/wpa_supplicant/wpa_supplicant.conf" "/etc/wpa_supplicant/wpa_supplicant.conf.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✓ Backed up existing wpa_supplicant.conf"
fi

# Create new wpa_supplicant configuration
cat > /etc/wpa_supplicant/wpa_supplicant.conf << 'EOF'
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=DE
EOF

echo "✓ Created base wpa_supplicant.conf"

# Parse wifi-networks.conf and add networks
SSID=""
PASSWORD=""
PRIORITY=""

while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    
    if [[ "$line" =~ ^SSID=\"(.*)\"$ ]]; then
        SSID="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^PASSWORD=\"(.*)\"$ ]]; then
        PASSWORD="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^PRIORITY=(.*)$ ]]; then
        PRIORITY="${BASH_REMATCH[1]}"
        
        if [ -n "$SSID" ] && [ -n "$PASSWORD" ] && [ -n "$PRIORITY" ]; then
            echo "Adding network: $SSID (priority: $PRIORITY)"
            cat >> /etc/wpa_supplicant/wpa_supplicant.conf << NETWORK

network={
    ssid="$SSID"
    psk="$PASSWORD"
    priority=$PRIORITY
    key_mgmt=WPA-PSK
}
NETWORK
            SSID=""
            PASSWORD=""
            PRIORITY=""
        fi
    fi
done < "$WIFI_CONF"

echo ""
echo "🔧 Step 4: Configuring network interfaces..."
echo ""

# Configure dhcpcd.conf for proper dual-mode
if ! grep -q "interface wlan0" /etc/dhcpcd.conf; then
    echo "Adding wlan0 configuration to dhcpcd.conf..."
    cat >> /etc/dhcpcd.conf << 'EOF'

# WiFi Client Interface (wlan0) - gets IP via DHCP
interface wlan0
# Allow fallback to DHCP if no static config
EOF
else
    echo "✓ wlan0 already configured in dhcpcd.conf"
fi

echo ""
echo "🚀 Step 5: Starting services with proper sequence..."
echo ""

# Start wpa_supplicant manually first to test
echo "Starting wpa_supplicant manually on wlan0..."
wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf -D nl80211

sleep 3

# Check if wpa_supplicant is running
if pgrep wpa_supplicant > /dev/null; then
    echo "✓ wpa_supplicant started successfully"
    
    # Request DHCP for wlan0
    echo "Requesting DHCP for wlan0..."
    dhclient wlan0 || dhcpcd wlan0
    
    sleep 5
    
    # Check connection
    if iwgetid wlan0; then
        CONNECTED_SSID=$(iwgetid -r wlan0)
        echo "🎉 SUCCESS: Connected to WiFi network: $CONNECTED_SSID"
        
        WLAN_IP=$(ip addr show wlan0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
        if [ -n "$WLAN_IP" ]; then
            echo "📍 IP Address: $WLAN_IP"
        fi
    else
        echo "⚠️  Not connected yet, checking status..."
        wpa_cli -i wlan0 status
    fi
else
    echo "❌ wpa_supplicant failed to start"
    echo "Checking logs..."
    journalctl -u wpa_supplicant -n 20 --no-pager
fi

echo ""
echo "🏠 Step 6: Restarting hotspot (exhibition mode)..."
echo ""

# Now restart hostapd for the exhibition hotspot
systemctl start hostapd

sleep 3

if systemctl is-active --quiet hostapd; then
    echo "✓ Exhibition hotspot restored"
    AP_IP=$(ip addr show ap0 | grep "inet " | awk '{print $2}' | cut -d/ -f1 2>/dev/null)
    if [ -n "$AP_IP" ]; then
        echo "📍 Hotspot IP: $AP_IP (winzige_giganten)"
    fi
else
    echo "⚠️  Hotspot not running - checking status..."
    systemctl status hostapd --no-pager -l
fi

echo ""
echo "🔧 Step 7: Enabling services for boot..."
echo ""

# Enable wpa_supplicant service
systemctl enable wpa_supplicant

# Make sure hostapd starts on boot too
systemctl enable hostapd

echo ""
echo "================================================================"
echo "WiFi Dual-Mode Setup Complete!"
echo "================================================================"

# Final status check
echo ""
echo "📊 Final Status Summary:"
echo ""

# Check wlan0 (client mode)
if iwgetid wlan0 >/dev/null 2>&1; then
    CONNECTED_SSID=$(iwgetid -r wlan0)
    WLAN_IP=$(ip addr show wlan0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    echo "✅ WiFi Client (wlan0): Connected to '$CONNECTED_SSID' at $WLAN_IP"
    echo "   → You can now SSH via: ssh cosmic@cosmicpi.local"
else
    echo "❌ WiFi Client (wlan0): Not connected"
    echo "   → Will only be reachable via hotspot IP"
fi

# Check ap0 (hotspot mode)
if systemctl is-active --quiet hostapd; then
    AP_IP=$(ip addr show ap0 | grep "inet " | awk '{print $2}' | cut -d/ -f1 2>/dev/null)
    echo "✅ Exhibition Hotspot (ap0): Running at $AP_IP"
    echo "   → iPads can connect to 'winzige_giganten'"
else
    echo "❌ Exhibition Hotspot (ap0): Not running"
fi

echo ""
echo "🔄 Recommendation: Reboot Pi to ensure all services start properly on boot"
echo "   sudo reboot"
echo ""