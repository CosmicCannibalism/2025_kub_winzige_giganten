#!/bin/bash
#
# Exhibition Monitoring Log Manager
# Manages detailed logging for 3-5 month autonomous operation
#
# Location: /usr/local/sbin/wg-log-manager.sh
# Usage: Called by cron every hour to manage exhibition logs

LOG_DIR="/var/log/exhibition"
ARCHIVE_DIR="/var/log/exhibition/archive"
MAIN_LOG="/var/log/wg-exhibition.log"
STATS_LOG="$LOG_DIR/hourly-stats.log"
DAILY_SUMMARY="$LOG_DIR/daily-summary.log"

# Ensure directories exist
mkdir -p "$LOG_DIR" "$ARCHIVE_DIR"

# Function to log with timestamp
log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [LOG-MGR] $1" >> "$MAIN_LOG"
}

# Function to collect current system stats
collect_stats() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # System metrics
    local load=$(cat /proc/loadavg | cut -d' ' -f1-3)
    local memory=$(free | grep Mem | awk '{printf "%.1f", ($3/$2)*100}')
    local disk=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    local temp=$(vcgencmd measure_temp 2>/dev/null | cut -d'=' -f2 | cut -d"'" -f1 || echo "N/A")
    
    # Network metrics
    local wifi_clients=$(iw dev ap0 station dump 2>/dev/null | grep Station | wc -l)
    local wifi_tx_power=$(iw dev ap0 info 2>/dev/null | grep txpower | awk '{print $2}' || echo "N/A")
    
    # Service status (1=active, 0=inactive)
    local nginx_status=$(systemctl is-active nginx >/dev/null 2>&1 && echo 1 || echo 0)
    local hostapd_status=$(systemctl is-active hostapd >/dev/null 2>&1 && echo 1 || echo 0)
    local dnsmasq_status=$(systemctl is-active dnsmasq >/dev/null 2>&1 && echo 1 || echo 0)
    local wg_ap_status=$(systemctl is-active wg-ap >/dev/null 2>&1 && echo 1 || echo 0)
    
    # Watchdog status
    local watchdog_status="UNKNOWN"
    if [ -f "/tmp/wg-watchdog-status" ]; then
        watchdog_status=$(cat /tmp/wg-watchdog-status)
    fi
    
    # Log to hourly stats
    echo "$timestamp,$load,$memory,$disk,$temp,$wifi_clients,$wifi_tx_power,$nginx_status,$hostapd_status,$dnsmasq_status,$wg_ap_status,$watchdog_status" >> "$STATS_LOG"
}

# Function to create daily summary
create_daily_summary() {
    local date=$(date '+%Y-%m-%d')
    local yesterday=$(date -d 'yesterday' '+%Y-%m-%d')
    
    log_msg "Creating daily summary for $yesterday"
    
    # Count entries for yesterday
    local entries=$(grep "^$yesterday" "$STATS_LOG" 2>/dev/null | wc -l)
    
    if [ $entries -eq 0 ]; then
        log_msg "No stats entries found for $yesterday"
        return
    fi
    
    # Calculate daily averages and counts
    local daily_stats=$(grep "^$yesterday" "$STATS_LOG" | awk -F',' '
    {
        load_sum += $2; memory_sum += $4; disk_sum += $5; temp_sum += $6;
        clients_sum += $7; 
        nginx_up += $9; hostapd_up += $10; dnsmasq_up += $11; wg_ap_up += $12;
        if ($13 == "HEALTHY") healthy_count++;
        if ($13 == "RECOVERING") recovering_count++;
        if ($13 == "FAILED") failed_count++;
        count++;
    }
    END {
        printf "%.2f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%d,%d,%d\n",
            load_sum/count, memory_sum/count, disk_sum/count, temp_sum/count,
            clients_sum/count, (nginx_up/count)*100, (hostapd_up/count)*100,
            (dnsmasq_up/count)*100, (wg_ap_up/count)*100,
            healthy_count, recovering_count, failed_count
    }')
    
    # Write daily summary
    echo "$yesterday,$entries,$daily_stats" >> "$DAILY_SUMMARY"
    
    log_msg "Daily summary created: $entries measurements, avg load: $(echo $daily_stats | cut -d',' -f1)"
}

# Function to archive old logs
archive_logs() {
    local days_to_keep=30
    local archive_date=$(date -d "$days_to_keep days ago" '+%Y-%m-%d')
    
    log_msg "Archiving logs older than $archive_date"
    
    # Archive hourly stats older than 30 days
    if [ -f "$STATS_LOG" ]; then
        grep "^$archive_date" "$STATS_LOG" > "$ARCHIVE_DIR/stats-$archive_date.log" 2>/dev/null
        sed -i "/^$archive_date/d" "$STATS_LOG"
    fi
    
    # Compress old archives
    find "$ARCHIVE_DIR" -name "*.log" -mtime +7 -exec gzip {} \; 2>/dev/null
    
    # Remove very old archives (keep 90 days total)
    find "$ARCHIVE_DIR" -name "*.gz" -mtime +90 -delete 2>/dev/null
    
    log_msg "Log archival completed"
}

# Function to check log file sizes and rotate if needed
rotate_logs() {
    local max_size_mb=10
    
    for log_file in "$MAIN_LOG" "$STATS_LOG" "$DAILY_SUMMARY"; do
        if [ -f "$log_file" ]; then
            local size_kb=$(du -k "$log_file" | cut -f1)
            local size_mb=$((size_kb / 1024))
            
            if [ $size_mb -gt $max_size_mb ]; then
                log_msg "Rotating large log file: $log_file (${size_mb}MB)"
                
                # Keep last 1000 lines
                tail -n 1000 "$log_file" > "${log_file}.tmp"
                mv "${log_file}.tmp" "$log_file"
                
                log_msg "Log file rotated, kept last 1000 lines"
            fi
        fi
    done
}

# Main execution
case "${1:-hourly}" in
    "hourly")
        collect_stats
        rotate_logs
        ;;
    "daily")
        create_daily_summary
        archive_logs
        ;;
    "stats")
        collect_stats
        echo "Stats collected at $(date)"
        ;;
    *)
        echo "Usage: $0 [hourly|daily|stats]"
        echo "  hourly - Collect hourly stats and rotate logs (default)"
        echo "  daily  - Create daily summary and archive old logs"
        echo "  stats  - Collect stats immediately"
        exit 1
        ;;
esac

log_msg "Log management completed: $1"