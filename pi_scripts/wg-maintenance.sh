#!/bin/bash
#
# Exhibition Maintenance Script
# Performs weekly and monthly maintenance tasks
#
# Location: /usr/local/sbin/wg-maintenance.sh
# Usage: Called by cron for automated maintenance

LOG_FILE="/var/log/wg-exhibition.log"
MAINTENANCE_LOG="/var/log/exhibition/maintenance.log"

# Ensure log directory exists
mkdir -p "/var/log/exhibition"

# Function to log with timestamp
log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [MAINTENANCE] $1" | tee -a "$MAINTENANCE_LOG" "$LOG_FILE"
}

# Function for weekly maintenance
weekly_maintenance() {
    log_msg "=== WEEKLY MAINTENANCE STARTED ==="
    
    # System cleanup
    log_msg "Cleaning temporary files..."
    find /tmp -type f -mtime +7 -delete 2>/dev/null || true
    find /var/tmp -type f -mtime +7 -delete 2>/dev/null || true
    
    # Log rotation and cleanup
    log_msg "Rotating system logs..."
    journalctl --vacuum-time=30d >/dev/null 2>&1 || true
    
    # Clear old dmesg entries
    dmesg -C 2>/dev/null || true
    
    # Network interface statistics reset
    log_msg "Checking network interface health..."
    local ap0_errors=$(cat /sys/class/net/ap0/statistics/rx_errors 2>/dev/null || echo "0")
    local wlan0_errors=$(cat /sys/class/net/wlan0/statistics/rx_errors 2>/dev/null || echo "0")
    
    if [ "$ap0_errors" -gt 1000 ] || [ "$wlan0_errors" -gt 1000 ]; then
        log_msg "WARNING: High network error count - ap0: $ap0_errors, wlan0: $wlan0_errors"
    fi
    
    # Check filesystem health
    log_msg "Checking filesystem health..."
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 80 ]; then
        log_msg "WARNING: Disk usage high: ${disk_usage}%"
        
        # Emergency cleanup if > 90%
        if [ "$disk_usage" -gt 90 ]; then
            log_msg "CRITICAL: Emergency disk cleanup - removing old logs"
            find /var/log -name "*.log" -mtime +7 -delete 2>/dev/null || true
            find /var/log -name "*.gz" -mtime +14 -delete 2>/dev/null || true
        fi
    fi
    
    # Memory usage check
    local memory_usage=$(free | grep Mem | awk '{printf "%.1f", ($3/$2)*100}')
    log_msg "Current memory usage: ${memory_usage}%"
    
    # Temperature monitoring
    local temp=$(vcgencmd measure_temp 2>/dev/null | cut -d'=' -f2 | cut -d"'" -f1 || echo "N/A")
    log_msg "Current temperature: ${temp}°C"
    
    if [ "$temp" != "N/A" ] && [ "${temp%.*}" -gt 70 ]; then
        log_msg "WARNING: High temperature detected: ${temp}°C"
    fi
    
    log_msg "=== WEEKLY MAINTENANCE COMPLETED ==="
}

# Function for monthly maintenance
monthly_maintenance() {
    log_msg "=== MONTHLY MAINTENANCE STARTED ==="
    
    # Extended system health check
    log_msg "Performing extended system health check..."
    
    # Uptime and load analysis
    local uptime_days=$(awk '{print int($1/86400)}' /proc/uptime)
    local load_avg=$(cat /proc/loadavg | cut -d' ' -f2)
    log_msg "System uptime: $uptime_days days, average load: $load_avg"
    
    # Service restart counts
    log_msg "Service restart analysis..."
    for service in nginx hostapd dnsmasq wg-ap; do
        local restarts=$(journalctl -u $service --since="30 days ago" | grep -c "Started\|Stopped" || echo "0")
        log_msg "Service $service: $restarts restart events in last 30 days"
    done
    
    # WiFi client statistics
    log_msg "WiFi usage statistics..."
    if [ -f "/var/log/exhibition/hourly-stats.log" ]; then
        local avg_clients=$(tail -n 720 /var/log/exhibition/hourly-stats.log | awk -F',' '{sum+=$7; count++} END {if(count>0) printf "%.1f", sum/count; else print "0"}')
        local max_clients=$(tail -n 720 /var/log/exhibition/hourly-stats.log | awk -F',' 'BEGIN{max=0} {if($7>max) max=$7} END{print max}')
        log_msg "Average clients last 30 days: $avg_clients, peak: $max_clients"
    fi
    
    # Disk health analysis
    log_msg "Analyzing disk health..."
    local total_size=$(df -h / | tail -1 | awk '{print $2}')
    local used_size=$(df -h / | tail -1 | awk '{print $3}')
    local available_size=$(df -h / | tail -1 | awk '{print $4}')
    log_msg "Disk space: $used_size used of $total_size total, $available_size available"
    
    # Check for SD card wear indicators
    if command -v iostat >/dev/null 2>&1; then
        local io_stats=$(iostat -d 1 2 | tail -n +4 | tail -1)
        log_msg "Disk I/O stats: $io_stats"
    fi
    
    # Network performance check
    log_msg "Network performance check..."
    if ping -c 3 8.8.8.8 >/dev/null 2>&1; then
        log_msg "Internet connectivity: AVAILABLE (fallback only)"
    else
        log_msg "Internet connectivity: OFFLINE (exhibition mode - normal)"
    fi
    
    # Generate monthly report
    log_msg "Generating monthly health report..."
    {
        echo "=== MONTHLY EXHIBITION HEALTH REPORT ==="
        echo "Generated: $(date)"
        echo "Uptime: $uptime_days days"
        echo "Average Load: $load_avg"
        echo "Current Temperature: ${temp}°C"
        echo "Disk Usage: ${disk_usage}%"
        echo "Memory Usage: ${memory_usage}%"
        echo "Average WiFi Clients: ${avg_clients:-0}"
        echo "Peak WiFi Clients: ${max_clients:-0}"
        echo ""
        echo "Service Status:"
        systemctl is-active nginx hostapd dnsmasq wg-ap --no-pager
        echo ""
        echo "Recent Critical Events:"
        grep -i "error\|critical\|warning\|emergency" "$LOG_FILE" | tail -n 10 || echo "No critical events"
    } > "/var/log/exhibition/monthly-report-$(date +%Y-%m).txt"
    
    log_msg "Monthly report saved to /var/log/exhibition/monthly-report-$(date +%Y-%m).txt"
    
    log_msg "=== MONTHLY MAINTENANCE COMPLETED ==="
}

# Main execution
case "${1:-help}" in
    "weekly")
        weekly_maintenance
        ;;
    "monthly")
        monthly_maintenance
        ;;
    "both")
        weekly_maintenance
        monthly_maintenance
        ;;
    *)
        echo "Usage: $0 [weekly|monthly|both]"
        echo "  weekly  - Perform weekly maintenance tasks"
        echo "  monthly - Perform monthly maintenance and health report"
        echo "  both    - Perform both weekly and monthly maintenance"
        exit 1
        ;;
esac