#!/bin/bash
#
# Exhibition Scripts Deployment
# Deploy all monitoring and maintenance scripts to the Pi
#
# Usage: ./deploy-exhibition-scripts.sh

PI_HOST="cosmic@cosmicpi.local"
SCRIPT_DIR="./pi_scripts"
PI_SBIN_DIR="/usr/local/sbin"
PI_LOG_DIR="/var/log/exhibition"

echo "=== Exhibition Scripts Deployment ==="
echo "Target: $PI_HOST"
echo "Local scripts directory: $SCRIPT_DIR"
echo ""

# Check if we can connect to Pi
if ! ssh -o ConnectTimeout=5 "$PI_HOST" "echo 'Pi connection OK'" 2>/dev/null; then
    echo "ERROR: Cannot connect to $PI_HOST"
    echo "Please ensure Pi is running and accessible"
    exit 1
fi

echo "✅ Pi connection verified"

# Create necessary directories on Pi
echo "Creating directories on Pi..."
ssh "$PI_HOST" "sudo mkdir -p $PI_SBIN_DIR $PI_LOG_DIR"

# Deploy emergency reboot script
echo "Deploying emergency reboot script..."
scp "$SCRIPT_DIR/wg-emergency-reboot.sh" "$PI_HOST:/tmp/"
ssh "$PI_HOST" "sudo mv /tmp/wg-emergency-reboot.sh $PI_SBIN_DIR/ && sudo chmod +x $PI_SBIN_DIR/wg-emergency-reboot.sh"

# Deploy log manager script
echo "Deploying log manager script..."
scp "$SCRIPT_DIR/wg-log-manager.sh" "$PI_HOST:/tmp/"
ssh "$PI_HOST" "sudo mv /tmp/wg-log-manager.sh $PI_SBIN_DIR/ && sudo chmod +x $PI_SBIN_DIR/wg-log-manager.sh"

# Deploy maintenance script
echo "Deploying maintenance script..."
scp "$SCRIPT_DIR/wg-maintenance.sh" "$PI_HOST:/tmp/"
ssh "$PI_HOST" "sudo mv /tmp/wg-maintenance.sh $PI_SBIN_DIR/ && sudo chmod +x $PI_SBIN_DIR/wg-maintenance.sh"

# Deploy cron configuration
echo "Setting up cron jobs..."
scp "$SCRIPT_DIR/exhibition-crontab" "$PI_HOST:/tmp/"
ssh "$PI_HOST" "sudo crontab -u root /tmp/exhibition-crontab && rm /tmp/exhibition-crontab"

# Update software watchdog to use emergency reboot
echo "Updating software watchdog integration..."
ssh "$PI_HOST" "
# Add emergency reboot integration to existing watchdog
if [ -f '$PI_SBIN_DIR/wg-watchdog.sh' ]; then
    # Check if emergency reboot is already integrated
    if ! grep -q 'wg-emergency-reboot.sh' '$PI_SBIN_DIR/wg-watchdog.sh'; then
        echo 'Adding emergency reboot integration to watchdog...'
        sudo sed -i '/echo.*reboot.*system/a\\    /usr/local/sbin/wg-emergency-reboot.sh' '$PI_SBIN_DIR/wg-watchdog.sh'
    fi
fi
"

# Test deployment
echo ""
echo "Testing deployment..."
ssh "$PI_HOST" "
echo 'Checking deployed scripts:'
ls -la $PI_SBIN_DIR/wg-*.sh
echo ''
echo 'Testing log manager:'
sudo $PI_SBIN_DIR/wg-log-manager.sh stats
echo ''
echo 'Checking cron configuration:'
sudo crontab -l | grep wg
"

echo ""
echo "=== Deployment Summary ==="
echo "✅ Emergency reboot script deployed"
echo "✅ Log manager script deployed" 
echo "✅ Maintenance script deployed"
echo "✅ Cron jobs configured"
echo "✅ Software watchdog integration updated"
echo ""
echo "Next steps:"
echo "1. Monitor /var/log/wg-exhibition.log for system events"
echo "2. Check /var/log/exhibition/ for detailed stats and reports"
echo "3. Review cron execution: sudo tail -f /var/log/syslog | grep CRON"
echo ""
echo "Exhibition monitoring system is now fully deployed! 🚀"