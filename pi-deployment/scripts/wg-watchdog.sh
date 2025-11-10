#!/bin/bash

# Enhanced Exhibition Watchdog v2.2
# Hotspot priority + Boot grace period + Real SSID check + Internet reconnect

LOG_FILE="/var/log/exhibition/watchdog.log"
STATUS_FILE="/var/log/exhibition/watchdog-status"
RESTART_COUNT_FILE="/var/log/exhibition/restart-count"
EMERGENCY_SCRIPT="/usr/local/sbin/wg-emergency-reboot.sh"
TEMP_THRESHOLD=65
BOOT_GRACE_PERIOD=180     # 3 minutes after boot before watchdog intervenes
INTERNET_CHECK_INTERVAL=600  # Check internet every 10 minutes (not every cycle)
LAST_INTERNET_CHECK_FILE="/tmp/watchdog-last-internet-check"

# Enhanced restart limits for stress testing
MAX_RAPID_RESTARTS=5      # Increased from 3
RAPID_RESTART_WINDOW=300  # 5 minutes for rapid restart detection
MAX_DAILY_RESTARTS=15     # Daily limit

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

check_boot_grace_period() {
    # Check if system is within boot grace period
    local uptime_seconds=$(awk '{print int($1)}' /proc/uptime)
    if [[ $uptime_seconds -lt $BOOT_GRACE_PERIOD ]]; then
        log_message "INFO: Boot grace period active (${uptime_seconds}s < ${BOOT_GRACE_PERIOD}s), skipping checks"
        return 1  # Skip monitoring
    fi
    return 0  # Continue with monitoring
}

get_restart_count() {
    local now=$(date +%s)
    local count_file="$RESTART_COUNT_FILE"
    
    # Read existing restart timestamps
    if [[ -f "$count_file" ]]; then
        # Remove old entries (older than rapid restart window)
        local temp_file=$(mktemp)
        while read -r timestamp; do
            if [[ $((now - timestamp)) -lt $RAPID_RESTART_WINDOW ]]; then
                echo "$timestamp" >> "$temp_file"
            fi
        done < "$count_file"
        mv "$temp_file" "$count_file"
        
        # Count remaining entries
        wc -l < "$count_file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

add_restart_timestamp() {
    local now=$(date +%s)
    echo "$now" >> "$RESTART_COUNT_FILE"
}

check_daily_restart_limit() {
    local today=$(date '+%Y-%m-%d')
    local daily_count=$(grep "$(date '+%Y-%m-%d')" "$LOG_FILE" 2>/dev/null | grep -c "RECOVERY: Starting enhanced service restart" || echo "0")
    
    if [[ $daily_count -ge $MAX_DAILY_RESTARTS ]]; then
        log_message "CRITICAL: Daily restart limit ($MAX_DAILY_RESTARTS) reached"
        return 1
    fi
    return 0
}

check_services() {
    local failed_services=()
    for service in hostapd dnsmasq nginx; do
        if ! systemctl is-active --quiet "$service"; then
            failed_services+=("$service")
        fi
    done
    
    if [[ ${#failed_services[@]} -eq 0 ]]; then
        echo "ALL_ACTIVE"
        return 0
    else
        echo "FAILED: ${failed_services[*]}"
        return 1
    fi
}

check_network_enhanced() {
    # Priority 1: Check if SSID is actually broadcasting (real hotspot check)
    local ssid_check=$(iw dev ap0 info 2>/dev/null | grep -c "ssid")
    if [[ $ssid_check -eq 0 ]]; then
        echo "HOTSPOT_NOT_BROADCASTING"
        return 1
    fi
    
    # Priority 2: Check ap0 interface exists and has correct IP
    if ip addr show ap0 2>/dev/null | grep -q "inet 192.168.4.1"; then
        echo "WIFI_OK"
        return 0
    elif ip link show ap0 2>/dev/null | grep -q "state UP"; then
        echo "WIFI_NO_IP"
        return 1
    else
        echo "WIFI_DOWN"
        return 1
    fi
}

check_web_server() {
    if curl -s --connect-timeout 5 http://192.168.4.1/ >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

monitor_client_activity() {
    local connected_clients=$(iw dev ap0 station dump 2>/dev/null | grep -c "Station" || echo "0")
    echo "$connected_clients"
}

check_internet_connection() {
    # Check if we need to test internet (not every cycle, to avoid overhead)
    local now=$(date +%s)
    local last_check=0
    
    if [[ -f "$LAST_INTERNET_CHECK_FILE" ]]; then
        last_check=$(cat "$LAST_INTERNET_CHECK_FILE")
    fi
    
    # Only check if interval passed
    if [[ $((now - last_check)) -lt $INTERNET_CHECK_INTERVAL ]]; then
        return 2  # Skip check this cycle
    fi
    
    # Update last check time
    echo "$now" > "$LAST_INTERNET_CHECK_FILE"
    
    # Quick ping test to Google DNS
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        return 0  # Internet OK
    else
        return 1  # No internet
    fi
}

reconnect_internet() {
    log_message "RECONNECT: Internet connection lost, attempting to reconnect wlan0..."
    
    # Release and renew DHCP lease on wlan0 only (not touching ap0)
    dhclient -r wlan0 >/dev/null 2>&1
    sleep 2
    dhclient wlan0 >/dev/null 2>&1
    sleep 5
    
    # Verify reconnection
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        log_message "RECONNECT: Successfully restored internet connection"
        return 0
    else
        log_message "RECONNECT: Failed to restore internet, will retry next cycle"
        return 1
    fi
}

restart_services() {
    log_message "RECOVERY: Starting enhanced service restart sequence..."
    
    # Check restart limits
    local restart_count=$(get_restart_count)
    if [[ $restart_count -ge $MAX_RAPID_RESTARTS ]]; then
        log_message "EMERGENCY: Max rapid restarts ($MAX_RAPID_RESTARTS) exceeded in ${RAPID_RESTART_WINDOW}s window"
        if ! check_daily_restart_limit; then
            log_message "CRITICAL: Daily restart limit also exceeded, initiating emergency reboot"
            bash "$EMERGENCY_SCRIPT" &
            return 1
        fi
        log_message "WARNING: Waiting 60 seconds before restart attempt"
        sleep 60
    fi
    
    add_restart_timestamp
    
    # Graceful shutdown
    log_message "RECOVERY: Stopping services gracefully..."
    systemctl stop nginx dnsmasq hostapd 2>/dev/null
    sleep 5
    
    # Clean stale processes
    pkill -f hostapd 2>/dev/null || true
    pkill -f dnsmasq 2>/dev/null || true
    pkill -f nginx 2>/dev/null || true
    sleep 2
    
    # Start services in correct order
    log_message "RECOVERY: Starting hostapd..."
    systemctl start hostapd
    sleep 3
    
    log_message "RECOVERY: Starting dnsmasq..."
    systemctl start dnsmasq
    sleep 3
    
    log_message "RECOVERY: Starting nginx..."
    systemctl start nginx
    sleep 3
    
    # Verify ap0 interface
    if ! ip addr show ap0 2>/dev/null | grep -q "inet 192.168.4.1"; then
        log_message "RECOVERY: Fixing ap0 IP address..."
        ip addr add 192.168.4.1/24 dev ap0 2>/dev/null || true
    fi
    
    log_message "RECOVERY: Service restart sequence completed"
}

# Main monitoring loop function
run_monitoring_cycle() {
    # Check if within boot grace period
    if ! check_boot_grace_period; then
        echo "BOOT_GRACE" > "$STATUS_FILE"
        return 0  # Skip this cycle
    fi
    
    # Get system metrics
    local temp=$(vcgencmd measure_temp | cut -d= -f2 | cut -d\' -f1)
    local temp_int=${temp%.*}
    local mem_usage=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    local load_avg=$(uptime | awk -F'load average:' '{ print $2 }' | awk '{ print $1 }' | sed 's/,//')
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    # Temperature check
    if [[ $temp_int -gt $TEMP_THRESHOLD ]]; then
        log_message "WARNING: High temperature: ${temp}°C (threshold: ${TEMP_THRESHOLD}°C)"
    else
        log_message "INFO: Temperature normal: ${temp}°C"
    fi
    
    # Service checks
    local service_status=$(check_services)
    local network_status=$(check_network_enhanced)
    local web_ok=true
    check_web_server || web_ok=false
    
    local connected_clients=$(monitor_client_activity)
    
    # Check internet connection (periodic, not every cycle)
    check_internet_connection
    local internet_status=$?
    if [[ $internet_status -eq 1 ]]; then
        log_message "WARNING: Internet connection lost, attempting reconnect..."
        reconnect_internet
    fi
    
    # Count failures
    local failure_count=0
    
    if [[ "$service_status" != "ALL_ACTIVE" ]]; then
        log_message "ALERT: Service issues detected: $service_status"
        ((failure_count++))
    fi
    
    if [[ "$network_status" != "WIFI_OK" ]]; then
        log_message "ALERT: Network issues detected: $network_status"
        ((failure_count++))
    fi
    
    if [[ "$web_ok" != "true" ]]; then
        log_message "ALERT: Web server not responding"
        ((failure_count++))
    fi
    
    # Enhanced recovery logic
    if [[ $failure_count -ge 2 ]]; then
        log_message "ALERT: $failure_count critical failures detected"
        
        # Check if we can attempt restart
        local restart_count=$(get_restart_count)
        if [[ $restart_count -lt $MAX_RAPID_RESTARTS ]] && check_daily_restart_limit; then
            restart_services
            sleep 15
            
            # Verify recovery
            if check_services && check_network_enhanced && check_web_server; then
                log_message "SUCCESS: Enhanced recovery completed successfully"
                echo "RECOVERED" > "$STATUS_FILE"
            else
                log_message "PARTIAL: Recovery incomplete, will retry on next check"
                echo "RECOVERING" > "$STATUS_FILE"
            fi
        else
            log_message "EMERGENCY: Max restart attempts exceeded"
            echo "FAILED" > "$STATUS_FILE"
            
            # Emergency reboot if daily limit not exceeded
            if check_daily_restart_limit; then
                log_message "EMERGENCY: Initiating emergency reboot..."
                bash "$EMERGENCY_SCRIPT" &
            else
                log_message "CRITICAL: Daily restart limit exceeded, manual intervention required"
            fi
        fi
    else
        # System healthy
        echo "HEALTHY" > "$STATUS_FILE"
        if [[ $failure_count -eq 0 ]]; then
            log_message "INFO: All systems operational (Clients: $connected_clients, Temp: ${temp}°C, Mem: ${mem_usage}%, Load: $load_avg)"
        else
            log_message "INFO: Minor issues detected but within tolerance"
        fi
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Ensure log directory
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Single cycle execution
    run_monitoring_cycle
fi