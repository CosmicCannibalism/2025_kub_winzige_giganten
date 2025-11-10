#!/bin/bash

# Exhibition Monitoring & Notification Script
# Überwacht kritische Services und sendet Benachrichtigungen bei Problemen
# Wird per Cron alle 5 Minuten ausgeführt

# ============================================================================
# KONFIGURATION - Hier anpassen!
# ============================================================================

# Email-Benachrichtigung (benötigt mailutils/sendmail)
NOTIFY_EMAIL="deine-email@example.com"
SEND_EMAIL=false  # Auf 'true' setzen wenn Email konfiguriert ist

# Telegram-Benachrichtigung (optional)
TELEGRAM_BOT_TOKEN=""  # Dein Bot Token von @BotFather
TELEGRAM_CHAT_ID=""    # Deine Chat ID von @userinfobot
SEND_TELEGRAM=false    # Auf 'true' setzen wenn Telegram konfiguriert ist

# Telegram Command Handler (für Status-Abfrage)
TELEGRAM_OFFSET_FILE="/var/tmp/telegram-offset"

# Pushover-Benachrichtigung (optional, sehr zuverlässig)
PUSHOVER_USER_KEY=""   # Von pushover.net
PUSHOVER_APP_TOKEN=""  # Von pushover.net
SEND_PUSHOVER=false    # Auf 'true' setzen wenn Pushover konfiguriert ist

# Status-Datei (verhindert Spam)
STATUS_FILE="/var/tmp/exhibition-monitor-status"
LOG_FILE="/var/log/exhibition-monitor.log"

# ============================================================================
# AB HIER NICHTS ÄNDERN
# ============================================================================

# Logging-Funktion
log_event() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Benachrichtigungs-Funktion
send_notification() {
    local TITLE="$1"
    local MESSAGE="$2"
    local PRIORITY="${3:-0}"  # 0=normal, 1=high
    
    log_event "ALERT: $TITLE - $MESSAGE"
    
    # Email senden
    if [ "$SEND_EMAIL" = true ] && command -v mail >/dev/null 2>&1; then
        echo "$MESSAGE" | mail -s "[Exhibition Alert] $TITLE" "$NOTIFY_EMAIL"
        log_event "Email sent to $NOTIFY_EMAIL"
    fi
    
    # Telegram senden
    if [ "$SEND_TELEGRAM" = true ] && [ -n "$TELEGRAM_BOT_TOKEN" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="${TELEGRAM_CHAT_ID}" \
            -d text="🚨 *Winzige Giganten Alert*%0A%0A*${TITLE}*%0A${MESSAGE}" \
            -d parse_mode="Markdown" >/dev/null 2>&1
        log_event "Telegram notification sent"
    fi
    
    # Pushover senden
    if [ "$SEND_PUSHOVER" = true ] && [ -n "$PUSHOVER_USER_KEY" ]; then
        curl -s -X POST "https://api.pushover.net/1/messages.json" \
            -d token="${PUSHOVER_APP_TOKEN}" \
            -d user="${PUSHOVER_USER_KEY}" \
            -d title="Exhibition Alert" \
            -d message="${TITLE}: ${MESSAGE}" \
            -d priority="${PRIORITY}" >/dev/null 2>&1
        log_event "Pushover notification sent"
    fi
}

# Status laden/speichern (verhindert wiederholte Benachrichtigungen)
load_status() {
    if [ -f "$STATUS_FILE" ]; then
        source "$STATUS_FILE"
    fi
}

save_status() {
    cat > "$STATUS_FILE" <<EOF
LAST_CHECK=$(date +%s)
SERVICES_OK=$1
HOTSPOT_OK=$2
DISK_OK=$3
MEMORY_OK=$4
TEMP_OK=$5
EOF
}

# Status initialisieren
SERVICES_OK=true
HOTSPOT_OK=true
DISK_OK=true
MEMORY_OK=true
TEMP_OK=true

load_status

# ============================================================================
# CHECKS
# ============================================================================

log_event "Starting exhibition monitoring check"

# 1. Kritische Services prüfen
CRITICAL_SERVICES=("nginx" "hostapd" "dhcpcd" "avahi-daemon" "watchdog")
FAILED_SERVICES=()

for service in "${CRITICAL_SERVICES[@]}"; do
    if ! systemctl is-active --quiet "$service"; then
        FAILED_SERVICES+=("$service")
        log_event "ERROR: Service $service is not running"
    fi
done

if [ ${#FAILED_SERVICES[@]} -gt 0 ]; then
    if [ "$SERVICES_OK" = true ]; then
        send_notification \
            "Services Down" \
            "Following services are not running: ${FAILED_SERVICES[*]}" \
            1
        SERVICES_OK=false
    fi
else
    if [ "$SERVICES_OK" = false ]; then
        send_notification \
            "Services Recovered" \
            "All critical services are running again" \
            0
    fi
    SERVICES_OK=true
fi

# 2. Hotspot Connectivity prüfen
if ! ip addr show ap0 | grep -q "192.168.4.1"; then
    log_event "ERROR: Hotspot IP 192.168.4.1 not found on ap0"
    if [ "$HOTSPOT_OK" = true ]; then
        send_notification \
            "Hotspot Down" \
            "WiFi Hotspot 'winzige_giganten' is not responding. IP 192.168.4.1 not found on ap0." \
            1
        HOTSPOT_OK=false
    fi
else
    if [ "$HOTSPOT_OK" = false ]; then
        send_notification \
            "Hotspot Recovered" \
            "WiFi Hotspot is back online" \
            0
    fi
    HOTSPOT_OK=true
fi

# 3. Disk Space prüfen (Warnung bei <2GB frei)
DISK_FREE=$(df / | tail -1 | awk '{print $4}')
DISK_FREE_GB=$((DISK_FREE / 1024 / 1024))

if [ "$DISK_FREE_GB" -lt 2 ]; then
    log_event "WARNING: Low disk space: ${DISK_FREE_GB}GB free"
    if [ "$DISK_OK" = true ]; then
        send_notification \
            "Low Disk Space" \
            "Only ${DISK_FREE_GB}GB free on root filesystem" \
            0
        DISK_OK=false
    fi
else
    DISK_OK=true
fi

# 4. Memory prüfen (Warnung bei <50MB frei)
MEM_AVAILABLE=$(free -m | awk 'NR==2 {print $7}')

if [ "$MEM_AVAILABLE" -lt 50 ]; then
    log_event "WARNING: Low memory: ${MEM_AVAILABLE}MB available"
    if [ "$MEMORY_OK" = true ]; then
        send_notification \
            "Low Memory" \
            "Only ${MEM_AVAILABLE}MB RAM available" \
            0
        MEMORY_OK=false
    fi
else
    MEMORY_OK=true
fi

# 5. CPU Temperature prüfen (Warnung bei >70°C)
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
    TEMP_C=$((TEMP / 1000))
    
    if [ "$TEMP_C" -gt 70 ]; then
        log_event "WARNING: High temperature: ${TEMP_C}°C"
        if [ "$TEMP_OK" = true ]; then
            send_notification \
                "High Temperature" \
                "CPU temperature is ${TEMP_C}°C (critical threshold: 70°C)" \
                1
            TEMP_OK=false
        fi
    else
        TEMP_OK=true
    fi
fi

# 6. Watchdog Repair Log prüfen (neue Einträge?)
WATCHDOG_LOG="/var/log/watchdog-repair.log"
if [ -f "$WATCHDOG_LOG" ]; then
    RECENT_REPAIRS=$(tail -20 "$WATCHDOG_LOG" | grep -c "HARDWARE_WATCHDOG_REPAIR" || echo 0)
    if [ "$RECENT_REPAIRS" -gt 0 ]; then
        LAST_REPAIR=$(tail -1 "$WATCHDOG_LOG")
        log_event "INFO: Watchdog repair detected: $LAST_REPAIR"
        # Nur benachrichtigen wenn Repair in letzten 10 Minuten
        REPAIR_TIME=$(echo "$LAST_REPAIR" | cut -d' ' -f1-2)
        REPAIR_EPOCH=$(date -d "$REPAIR_TIME" +%s 2>/dev/null || echo 0)
        NOW_EPOCH=$(date +%s)
        TIME_DIFF=$((NOW_EPOCH - REPAIR_EPOCH))
        
        if [ "$TIME_DIFF" -lt 600 ]; then  # 10 Minuten = 600 Sekunden
            send_notification \
                "Watchdog Repair Triggered" \
                "System performed emergency repair: $LAST_REPAIR" \
                1
        fi
    fi
fi

# Status speichern
save_status "$SERVICES_OK" "$HOTSPOT_OK" "$DISK_OK" "$MEMORY_OK" "$TEMP_OK"

log_event "Monitoring check completed - All systems: $([ "$SERVICES_OK" = true ] && [ "$HOTSPOT_OK" = true ] && echo "OK" || echo "ISSUES DETECTED")"

# ============================================================================
# TELEGRAM COMMAND HANDLER (Status-Abfrage)
# ============================================================================

if [ "$SEND_TELEGRAM" = true ] && [ -n "$TELEGRAM_BOT_TOKEN" ]; then
    # Hole neue Nachrichten
    OFFSET=0
    if [ -f "$TELEGRAM_OFFSET_FILE" ]; then
        OFFSET=$(cat "$TELEGRAM_OFFSET_FILE")
    fi
    
    UPDATES=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=${OFFSET}&timeout=1")
    
    # Prüfe ob neue Nachrichten da sind
    MESSAGE_COUNT=$(echo "$UPDATES" | grep -o '"update_id"' | wc -l)
    
    if [ "$MESSAGE_COUNT" -gt 0 ]; then
        # Verarbeite jede Nachricht
        echo "$UPDATES" | grep -o '"update_id":[0-9]*' | while read -r line; do
            UPDATE_ID=$(echo "$line" | cut -d':' -f2)
            
            # Extrahiere Text der Nachricht
            MESSAGE_TEXT=$(echo "$UPDATES" | grep -A 20 "\"update_id\":$UPDATE_ID" | grep -m1 '"text"' | cut -d'"' -f4)
            
            # Reagiere auf Commands
            case "$MESSAGE_TEXT" in
                /status|/Status)
                    # Sammle System-Status
                    UPTIME=$(uptime -p)
                    LOAD=$(uptime | awk -F'load average:' '{print $2}')
                    MEM_USED=$(free -m | awk 'NR==2 {printf "%.0f%%", $3*100/$2}')
                    DISK_USED=$(df -h / | awk 'NR==2 {print $5}')
                    TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "0")
                    TEMP_C=$((TEMP / 1000))
                    
                    # Service Status
                    SERVICE_STATUS=""
                    for service in "${CRITICAL_SERVICES[@]}"; do
                        if systemctl is-active --quiet "$service"; then
                            SERVICE_STATUS="${SERVICE_STATUS}✅ ${service}%0A"
                        else
                            SERVICE_STATUS="${SERVICE_STATUS}❌ ${service}%0A"
                        fi
                    done
                    
                    # Hotspot Status
                    if ip addr show ap0 | grep -q "192.168.4.1"; then
                        HOTSPOT_STATUS="✅ Online (192.168.4.1)"
                    else
                        HOTSPOT_STATUS="❌ Offline"
                    fi
                    
                    # WLAN Status
                    WLAN_IP=$(ip -4 addr show wlan0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "nicht verbunden")
                    
                    # Anzahl verbundene Geräte
                    CONNECTED_DEVICES=$(arp -i ap0 -n | grep -c ":" || echo "0")
                    
                    # Letzte Fehler
                    RECENT_ERRORS=$(grep -c "ERROR" "$LOG_FILE" 2>/dev/null || echo "0")
                    
                    # Status-Report zusammenstellen
                    STATUS_MSG="📊 *Exhibition Status Report*%0A%0A"
                    STATUS_MSG="${STATUS_MSG}🖥 *System*%0A"
                    STATUS_MSG="${STATUS_MSG}Uptime: ${UPTIME}%0A"
                    STATUS_MSG="${STATUS_MSG}CPU Temp: ${TEMP_C}°C%0A"
                    STATUS_MSG="${STATUS_MSG}Memory: ${MEM_USED}%0A"
                    STATUS_MSG="${STATUS_MSG}Disk: ${DISK_USED}%0A"
                    STATUS_MSG="${STATUS_MSG}Load:${LOAD}%0A%0A"
                    STATUS_MSG="${STATUS_MSG}📡 *Network*%0A"
                    STATUS_MSG="${STATUS_MSG}Hotspot: ${HOTSPOT_STATUS}%0A"
                    STATUS_MSG="${STATUS_MSG}WLAN: ${WLAN_IP}%0A"
                    STATUS_MSG="${STATUS_MSG}Connected Devices: ${CONNECTED_DEVICES}%0A%0A"
                    STATUS_MSG="${STATUS_MSG}⚙️ *Services*%0A"
                    STATUS_MSG="${STATUS_MSG}${SERVICE_STATUS}%0A"
                    STATUS_MSG="${STATUS_MSG}📋 *Log*%0A"
                    STATUS_MSG="${STATUS_MSG}Recent errors: ${RECENT_ERRORS}%0A%0A"
                    STATUS_MSG="${STATUS_MSG}_Use /status for update_"
                    
                    # Sende Status
                    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                        -d chat_id="${TELEGRAM_CHAT_ID}" \
                        -d text="${STATUS_MSG}" \
                        -d parse_mode="Markdown" >/dev/null 2>&1
                    
                    log_event "Status report sent via Telegram"
                    ;;
                    
                /help|/Help)
                    HELP_MSG="🤖 *Exhibition Monitor Commands*%0A%0A"
                    HELP_MSG="${HELP_MSG}/status - Vollständiger System-Status%0A"
                    HELP_MSG="${HELP_MSG}/help - Diese Hilfe%0A%0A"
                    HELP_MSG="${HELP_MSG}Du erhältst automatisch Benachrichtigungen bei Problemen."
                    
                    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                        -d chat_id="${TELEGRAM_CHAT_ID}" \
                        -d text="${HELP_MSG}" \
                        -d parse_mode="Markdown" >/dev/null 2>&1
                    ;;
            esac
        done
        
        # Update offset (markiere Nachrichten als verarbeitet)
        LAST_UPDATE_ID=$(echo "$UPDATES" | grep -o '"update_id":[0-9]*' | tail -1 | cut -d':' -f2)
        if [ -n "$LAST_UPDATE_ID" ]; then
            echo $((LAST_UPDATE_ID + 1)) > "$TELEGRAM_OFFSET_FILE"
        fi
    fi
fi

exit 0
