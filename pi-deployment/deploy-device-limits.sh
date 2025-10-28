#!/bin/bash
#
# Deploy Device Connection Limiting
# Safely deploy device limiting configuration to the Pi
#
# Usage: ./deploy-device-limits.sh

PI_HOST="cosmic@cosmicpi.local"
SCRIPT_DIR="./pi_scripts"

echo "=== Device Connection Limiting Deployment ==="
echo "Target: $PI_HOST"
echo ""

# Check Pi connection
if ! ssh -o ConnectTimeout=5 "$PI_HOST" "echo 'Pi connection OK'" 2>/dev/null; then
    echo "ERROR: Cannot connect to $PI_HOST"
    echo "Please ensure Pi is running and accessible"
    exit 1
fi

echo "✅ Pi connection verified"

# Deploy configuration script
echo "Deploying device limits configuration script..."
scp "$SCRIPT_DIR/configure-device-limits.sh" "$PI_HOST:/tmp/"
ssh "$PI_HOST" "sudo mv /tmp/configure-device-limits.sh /usr/local/sbin/ && sudo chmod +x /usr/local/sbin/configure-device-limits.sh"

# Deploy updated crontab
echo "Updating cron jobs with device monitoring..."
scp "$SCRIPT_DIR/exhibition-crontab" "$PI_HOST:/tmp/"
echo "" >> /tmp/exhibition-crontab-fixed  # Ensure newline
ssh "$PI_HOST" "cat /tmp/exhibition-crontab > /tmp/exhibition-crontab-fixed && echo '' >> /tmp/exhibition-crontab-fixed && sudo crontab -u root /tmp/exhibition-crontab-fixed && rm /tmp/exhibition-crontab*"

# Run the configuration
echo ""
echo "Configuring device connection limits..."
ssh "$PI_HOST" "sudo /usr/local/sbin/configure-device-limits.sh"

echo ""
echo "=== Device Limiting Configuration Summary ==="
echo "✅ Configuration script deployed and executed"
echo "✅ Device monitoring added to cron jobs"
echo "✅ hostapd configured for maximum 5 concurrent devices"
echo "✅ dnsmasq DHCP pool limited to 5 addresses (192.168.4.10-14)"
echo ""
echo "⚠️  IMPORTANT: Services need restart to apply changes"
echo "Choose one of these options:"
echo "1. Restart services now: ssh $PI_HOST 'sudo systemctl restart hostapd dnsmasq'"
echo "2. Use AP restart script: ssh $PI_HOST 'sudo /usr/local/sbin/wg-ap-up.sh'"
echo "3. Reboot Pi for clean restart: ssh $PI_HOST 'sudo reboot'"
echo ""
echo "After restart, device connections will be limited to 5 maximum."