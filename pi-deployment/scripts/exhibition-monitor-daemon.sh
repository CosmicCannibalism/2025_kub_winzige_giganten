#!/bin/bash

# Exhibition Monitoring Daemon - läuft permanent und prüft alle 60 Sekunden
# Sendet SOFORT Benachrichtigungen bei Problemen

TELEGRAM_BOT_TOKEN="8362321996:AAGRxNC5mZBtSGbQPdlzqqgMHPRQA5xfM20"
TELEGRAM_CHAT_ID="6901638335"
LOG_FILE="/var/log/exhibition-monitor.log"
STATUS_FILE="/var/tmp/exhibition-monitor-status"

# Check-Intervall in Sekunden (60 = jede Minute)
CHECK_INTERVAL=60

log_event() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

send_alert() {
    local TITLE="$1"
    local MESSAGE="$2"
    
    log_event "ALERT: $TITLE - $MESSAGE"
    
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="🚨 *Alert*%0A%0A*${TITLE}*%0A${MESSAGE}" \
        -d parse_mode="Markdown" >/dev/null 2>&1
}

send_recovery() {
    local TITLE="$1"
    local MESSAGE="$2"
    
    log_event "RECOVERY: $TITLE - $MESSAGE"
    
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="✅ *Resolved*%0A%0A*${TITLE}*%0A${MESSAGE}" \
        -d parse_mode="Markdown" >/dev/null 2>&1
}

# Status laden
load_status() {
    if [ -f "$STATUS_FILE" ]; then
        source "$STATUS_FILE"
    fi
}

save_status() {
    cat > "$STATUS_FILE" <<EOF
SERVICES_OK=$1
HOTSPOT_OK=$2
DISK_OK=$3
MEMORY_OK=$4
TEMP_OK=$5
EOF
}

# Initial Status
SERVICES_OK=true
HOTSPOT_OK=true
DISK_OK=true
MEMORY_OK=true
TEMP_OK=true

load_status

log_event "Exhibition Monitoring Daemon started (check every ${CHECK_INTERVAL}s)"

# Endlos-Loop
while true; do
    log_event "Running system checks..."
    
    # 1. Services prüfen
    CRITICAL_SERVICES=("nginx" "hostapd" "dhcpcd" "avahi-daemon" "watchdog")
    FAILED_SERVICES=()
    
    for service in "${CRITICAL_SERVICES[@]}"; do
        if ! systemctl is-active --quiet "$service"; then
            FAILED_SERVICES+=("$service")
            log_event "ERROR: Service $service down"
        fi
    done
    
    if [ ${#FAILED_SERVICES[@]} -gt 0 ]; then
        if [ "$SERVICES_OK" = true ]; then
            send_alert "Services Down" "Not running: ${FAILED_SERVICES[*]}"
            SERVICES_OK=false
        fi
    else
        if [ "$SERVICES_OK" = false ]; then
            send_recovery "Services OK" "All services running again"
            SERVICES_OK=true
        fi
    fi
    
    # 2. Hotspot prüfen
    if ! ip addr show ap0 | grep -q "192.168.4.1"; then
        log_event "ERROR: Hotspot offline"
        if [ "$HOTSPOT_OK" = true ]; then
            send_alert "Hotspot Offline" "192.168.4.1 not found on ap0"
            HOTSPOT_OK=false
        fi
    else
        if [ "$HOTSPOT_OK" = false ]; then
            send_recovery "Hotspot OK" "Hotspot back online"
            HOTSPOT_OK=true
        fi
    fi
    
    # 3. Disk Space (<2GB)
    DISK_FREE=$(df / | tail -1 | awk '{print $4}')
    DISK_FREE_GB=$((DISK_FREE / 1024 / 1024))
    
    if [ "$DISK_FREE_GB" -lt 2 ]; then
        log_event "WARNING: Low disk space: ${DISK_FREE_GB}GB"
        if [ "$DISK_OK" = true ]; then
            send_alert "Low Disk Space" "Only ${DISK_FREE_GB}GB free"
            DISK_OK=false
        fi
    else
        if [ "$DISK_OK" = false ]; then
            send_recovery "Disk Space OK" "Sufficient space available"
            DISK_OK=true
        fi
    fi
    
    # 4. Memory (<50MB)
    MEM_AVAILABLE=$(free -m | awk 'NR==2 {print $7}')
    
    if [ "$MEM_AVAILABLE" -lt 50 ]; then
        log_event "WARNING: Low memory: ${MEM_AVAILABLE}MB"
        if [ "$MEMORY_OK" = true ]; then
            send_alert "Low Memory" "Only ${MEM_AVAILABLE}MB available"
            MEMORY_OK=false
        fi
    else
        if [ "$MEMORY_OK" = false ]; then
            send_recovery "Memory OK" "Memory back to normal"
            MEMORY_OK=true
        fi
    fi
    
    # 5. CPU Temp (>70°C)
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
        TEMP_C=$((TEMP / 1000))
        
        if [ "$TEMP_C" -gt 70 ]; then
            log_event "WARNING: High temp: ${TEMP_C}°C"
            if [ "$TEMP_OK" = true ]; then
                send_alert "High Temperature" "CPU at ${TEMP_C}°C (limit: 70°C)"
                TEMP_OK=false
            fi
        else
            if [ "$TEMP_OK" = false ]; then
                send_recovery "Temperature OK" "CPU cooled down to ${TEMP_C}°C"
                TEMP_OK=true
            fi
        fi
    fi
    
    # 6. Watchdog Repairs
    WATCHDOG_LOG="/var/log/watchdog-repair.log"
    if [ -f "$WATCHDOG_LOG" ]; then
        LAST_REPAIR=$(tail -1 "$WATCHDOG_LOG" 2>/dev/null)
        if [ -n "$LAST_REPAIR" ]; then
            REPAIR_TIME=$(echo "$LAST_REPAIR" | cut -d' ' -f1-2)
            REPAIR_EPOCH=$(date -d "$REPAIR_TIME" +%s 2>/dev/null || echo 0)
            NOW_EPOCH=$(date +%s)
            TIME_DIFF=$((NOW_EPOCH - REPAIR_EPOCH))
            
            # Wenn Repair in letzten 2 Minuten
            if [ "$TIME_DIFF" -lt 120 ]; then
                log_event "Watchdog repair detected: $LAST_REPAIR"
                send_alert "Watchdog Repair" "Emergency repair: $(echo $LAST_REPAIR | cut -d' ' -f4-)"
            fi
        fi
    fi
    
    # Status speichern
    save_status "$SERVICES_OK" "$HOTSPOT_OK" "$DISK_OK" "$MEMORY_OK" "$TEMP_OK"
    
    log_event "Check completed - Systems: $([ "$SERVICES_OK" = true ] && [ "$HOTSPOT_OK" = true ] && echo "OK" || echo "ISSUES")"
    
    # Warte bis zum nächsten Check
    sleep $CHECK_INTERVAL
done
