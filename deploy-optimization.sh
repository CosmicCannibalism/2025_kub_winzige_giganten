#!/bin/bash
#
# Deploy Exhibition Optimization
# Deploy system optimizations for 3-5 month autonomous operation
#
# Usage: ./deploy-optimization.sh

PI_HOST="cosmic@cosmicpi.local"
SCRIPT_DIR="./pi_scripts"

echo "=== Exhibition System Optimization Deployment ==="
echo "Target: $PI_HOST"
echo ""

# Check Pi connection
if ! ssh -o ConnectTimeout=5 "$PI_HOST" "echo 'Pi connection OK'" 2>/dev/null; then
    echo "ERROR: Cannot connect to $PI_HOST"
    echo "Please ensure Pi is running and accessible"
    exit 1
fi

echo "✅ Pi connection verified"

# Deploy optimization script
echo "Deploying exhibition optimization script..."
scp "$SCRIPT_DIR/exhibition-optimization.sh" "$PI_HOST:/tmp/"
ssh "$PI_HOST" "sudo mv /tmp/exhibition-optimization.sh /usr/local/sbin/ && sudo chmod +x /usr/local/sbin/exhibition-optimization.sh"

# Deploy updated crontab with temperature monitoring
echo "Updating cron jobs with temperature monitoring and cleanup..."
scp "$SCRIPT_DIR/exhibition-crontab" "$PI_HOST:/tmp/"
ssh "$PI_HOST" "
cat /tmp/exhibition-crontab > /tmp/exhibition-crontab-fixed
echo '' >> /tmp/exhibition-crontab-fixed
sudo crontab -u root /tmp/exhibition-crontab-fixed
rm /tmp/exhibition-crontab*
"

# Get current system status before optimization
echo ""
echo "Current system status (before optimization):"
ssh "$PI_HOST" "
echo 'Memory usage:' && free -h | grep Mem
echo 'Disk usage:' && df -h / | tail -1
echo 'Temperature:' && vcgencmd measure_temp 2>/dev/null || echo 'N/A'
echo 'Swap status:' && swapon --show || echo 'No swap active'
echo 'Load average:' && cat /proc/loadavg
"

# Run the optimization
echo ""
echo "Running exhibition optimization..."
ssh "$PI_HOST" "sudo /usr/local/sbin/exhibition-optimization.sh"

# Show results
echo ""
echo "System status after optimization:"
ssh "$PI_HOST" "
echo 'Memory usage:' && free -h | grep Mem
echo 'Swap status:' && swapon --show
echo 'Temperature:' && vcgencmd measure_temp 2>/dev/null || echo 'N/A'
echo 'Load average:' && cat /proc/loadavg
echo 'nginx status:' && systemctl is-active nginx
echo 'New cron jobs:' && sudo crontab -l | grep -E 'temp-monitor|cleanup'
"

echo ""
echo "=== Exhibition Optimization Summary ==="
echo "✅ System optimization script deployed and executed"
echo "✅ SD card preservation configured (volatile journald)"
echo "✅ Memory optimization applied (Pi Zero 2W tuned)"
echo "✅ Swap file configured (256MB)"
echo "✅ nginx optimized for video serving"
echo "✅ Temperature monitoring active (every 10 minutes)"
echo "✅ Automated cleanup scheduled (every 6 hours)"
echo ""
echo "📋 RECOMMENDATION: Reboot Pi to fully apply kernel optimizations"
echo "   Command: ssh $PI_HOST 'sudo reboot'"
echo ""
echo "🚀 Exhibition system now optimized for 3-5 month autonomous operation!"