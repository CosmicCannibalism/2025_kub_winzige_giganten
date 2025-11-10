#!/bin/bash
# Setup WiFi Client Mode on Raspberry Pi
# This allows the Pi to connect to multiple WiFi networks while still running the exhibition hotspot
# You can then SSH via cosmicpi.local from any of the configured networks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIFI_CONF="${SCRIPT_DIR}/configs/wifi-networks.conf"
WPA_SUPPLICANT="/etc/wpa_supplicant/wpa_supplicant.conf"

echo "================================================"
echo "WiFi Client Mode Setup for Raspberry Pi"
echo "================================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root (use sudo)"
    exit 1
fi

# Check if wifi config exists
if [ ! -f "$WIFI_CONF" ]; then
    echo "ERROR: WiFi configuration file not found: $WIFI_CONF"
    echo "Please edit configs/wifi-networks.conf first"
    exit 1
fi

echo ""
echo "Reading WiFi networks from: $WIFI_CONF"
echo ""

# Backup existing wpa_supplicant.conf
if [ -f "$WPA_SUPPLICANT" ]; then
    echo "Backing up existing wpa_supplicant.conf..."
    cp "$WPA_SUPPLICANT" "${WPA_SUPPLICANT}.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Create new wpa_supplicant.conf
echo "Creating wpa_supplicant configuration..."

cat > "$WPA_SUPPLICANT" << 'EOF'
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=DE

EOF

# Parse wifi-networks.conf and add each network
SSID=""
PASSWORD=""
PRIORITY=""

while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    
    # Parse configuration
    if [[ "$line" =~ ^SSID=\"(.*)\"$ ]]; then
        SSID="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^PASSWORD=\"(.*)\"$ ]]; then
        PASSWORD="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^PRIORITY=(.*)$ ]]; then
        PRIORITY="${BASH_REMATCH[1]}"
        
        # When we have all three, add network
        if [ -n "$SSID" ] && [ -n "$PASSWORD" ] && [ -n "$PRIORITY" ]; then
            echo "Adding network: $SSID (priority: $PRIORITY)"
            cat >> "$WPA_SUPPLICANT" << NETWORK

network={
    ssid="$SSID"
    psk="$PASSWORD"
    priority=$PRIORITY
    key_mgmt=WPA-PSK
}
NETWORK
            # Reset for next network
            SSID=""
            PASSWORD=""
            PRIORITY=""
        fi
    fi
done < "$WIFI_CONF"

echo ""
echo "Configuration written to: $WPA_SUPPLICANT"
echo ""

# Configure network interfaces
echo "Configuring network interfaces..."

# Check if wlan0 config already exists in dhcpcd.conf
if grep -q "interface wlan0" /etc/dhcpcd.conf; then
    echo "wlan0 already configured in dhcpcd.conf"
else
    echo "Adding wlan0 configuration to dhcpcd.conf..."
    cat >> /etc/dhcpcd.conf << 'EOF'

# WiFi Client Interface (wlan0)
# Gets IP via DHCP from whatever network it connects to
interface wlan0
EOF
fi

# Ensure wpa_supplicant service is enabled
echo "Enabling wpa_supplicant service..."
systemctl enable wpa_supplicant
systemctl restart wpa_supplicant

# Restart dhcpcd to apply changes
echo "Restarting network services..."
systemctl restart dhcpcd

# Wait a moment for connection
echo ""
echo "Waiting for WiFi connection (10 seconds)..."
sleep 10

echo ""
echo "================================================"
echo "WiFi Client Mode Setup Complete!"
echo "================================================"
echo ""
echo "Checking connection status..."
echo ""

# Show wlan0 status
if ip addr show wlan0 | grep -q "inet "; then
    WLAN_IP=$(ip addr show wlan0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    CONNECTED_SSID=$(iwgetid -r)
    echo "✓ SUCCESS: Connected to WiFi!"
    echo "  Network: $CONNECTED_SSID"
    echo "  IP Address: $WLAN_IP"
    echo ""
    echo "You can now SSH from your Mac using:"
    echo "  ssh cosmic@cosmicpi.local"
    echo ""
else
    echo "⚠ WiFi not connected yet"
    echo "  The Pi will automatically connect when in range of configured networks"
    echo "  You can check status with: iwconfig wlan0"
    echo ""
fi

# Show ap0 status (exhibition hotspot should still be running)
if ip addr show ap0 | grep -q "inet "; then
    AP_IP=$(ip addr show ap0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    echo "✓ Exhibition hotspot still running:"
    echo "  SSID: winzige_giganten"
    echo "  IP: $AP_IP"
    echo ""
else
    echo "⚠ Exhibition hotspot not detected on ap0"
    echo "  This is OK if you haven't set it up yet"
    echo ""
fi

echo "Tips:"
echo "  - Pi will auto-connect to available WiFi networks by priority"
echo "  - Exhibition hotspot (ap0) continues to work normally"
echo "  - To add more networks, edit configs/wifi-networks.conf and run this script again"
echo "  - View WiFi status: sudo wpa_cli status"
echo "  - View saved networks: sudo wpa_cli list_networks"
echo ""
