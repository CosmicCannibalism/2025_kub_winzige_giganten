#!/bin/bash
#
# Emergency Reboot Script for Exhibition
# Used by watchdog when system cannot be recovered
#
# Location: /usr/local/sbin/wg-emergency-reboot.sh
# Usage: Called by software watchdog when all recovery attempts fail

LOG_FILE="/var/log/wg-exhibition.log"
EMERGENCY_LOG="/var/log/wg-emergency.log"

# Function to log with timestamp
log_emergency() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [EMERGENCY] $1" | tee -a "$EMERGENCY_LOG" "$LOG_FILE"
}

log_emergency "=== EMERGENCY REBOOT TRIGGERED ==="
log_emergency "System recovery failed - initiating emergency reboot"

# Capture final system state
log_emergency "Final system state before reboot:"
echo "$(date '+%Y-%m-%d %H:%M:%S') EMERGENCY STATE:" >> "$EMERGENCY_LOG"
echo "Load: $(cat /proc/loadavg)" >> "$EMERGENCY_LOG"
echo "Memory: $(free -h | grep Mem)" >> "$EMERGENCY_LOG"
echo "Disk: $(df -h / | tail -n1)" >> "$EMERGENCY_LOG"
echo "Temp: $(vcgencmd measure_temp 2>/dev/null || echo 'N/A')" >> "$EMERGENCY_LOG"
echo "WiFi clients: $(iw dev ap0 station dump | grep Station | wc -l)" >> "$EMERGENCY_LOG"
echo "Services:" >> "$EMERGENCY_LOG"
systemctl is-active nginx hostapd dnsmasq wg-ap --no-pager >> "$EMERGENCY_LOG" 2>&1

# Attempt graceful shutdown of services first
log_emergency "Attempting graceful service shutdown before reboot..."
systemctl stop wg-ap hostapd dnsmasq nginx 2>/dev/null &
SHUTDOWN_PID=$!

# Wait max 10 seconds for graceful shutdown
sleep 10
if kill -0 $SHUTDOWN_PID 2>/dev/null; then
    kill $SHUTDOWN_PID 2>/dev/null
    log_emergency "Graceful shutdown timed out - forcing reboot"
else
    log_emergency "Services stopped gracefully - proceeding with reboot"
fi

# Sync filesystem
sync
sleep 2

# Log reboot trigger
log_emergency "Executing emergency reboot in 3 seconds..."
sleep 3

# Reboot the system
/sbin/reboot --force

# This should not be reached
exit 1