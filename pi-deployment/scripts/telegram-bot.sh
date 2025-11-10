#!/bin/bash

# Telegram Bot Daemon - läuft permanent und antwortet auf Commands
# Startet automatisch beim Boot via systemd

TELEGRAM_BOT_TOKEN="8362321996:AAGRxNC5mZBtSGbQPdlzqqgMHPRQA5xfM20"
TELEGRAM_CHAT_ID="6901638335"
LOG_FILE="/var/log/telegram-bot.log"

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_msg "Telegram Bot started, waiting for commands..."

# Offset für bereits verarbeitete Nachrichten
OFFSET=0

# Endlos-Loop
while true; do
    # Hole Updates mit Long-Polling (wartet bis zu 30 Sekunden auf neue Nachrichten)
    UPDATES=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=${OFFSET}&timeout=30")
    
    # Prüfe ob Updates da sind
    if command -v python3 >/dev/null 2>&1; then
        NUM_UPDATES=$(echo "$UPDATES" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data.get('result', [])))" 2>/dev/null || echo "0")
        
        if [ "$NUM_UPDATES" -gt 0 ]; then
            log_msg "Received $NUM_UPDATES update(s)"
            
            # Verarbeite alle Updates
            for ((i=0; i<NUM_UPDATES; i++)); do
                UPDATE_ID=$(echo "$UPDATES" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['result'][$i]['update_id'])" 2>/dev/null)
                MESSAGE_TEXT=$(echo "$UPDATES" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['result'][$i].get('message', {}).get('text', ''))" 2>/dev/null)
                
                log_msg "Command: $MESSAGE_TEXT"
                
                case "$MESSAGE_TEXT" in
                    /status|/Status)
                        log_msg "Processing /status"
                        
                        # Sammle Status
                        UPTIME=$(uptime -p)
                        LOAD=$(uptime | awk -F'load average:' '{print $2}')
                        MEM_USED=$(free -m | awk 'NR==2 {printf "%.0f%%", $3*100/$2}')
                        DISK_USED=$(df -h / | awk 'NR==2 {print $5}')
                        TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "0")
                        TEMP_C=$((TEMP / 1000))
                        
                        # Services
                        SERVICES=("nginx" "hostapd" "dhcpcd" "avahi-daemon" "watchdog")
                        SERVICE_STATUS=""
                        for service in "${SERVICES[@]}"; do
                            if systemctl is-active --quiet "$service"; then
                                SERVICE_STATUS="${SERVICE_STATUS}✅ ${service}%0A"
                            else
                                SERVICE_STATUS="${SERVICE_STATUS}❌ ${service}%0A"
                            fi
                        done
                        
                        # Hotspot
                        if ip addr show ap0 | grep -q "192.168.4.1"; then
                            HOTSPOT_STATUS="✅ Online (192.168.4.1)"
                        else
                            HOTSPOT_STATUS="❌ Offline"
                        fi
                        
                        # WLAN
                        WLAN_IP=$(ip -4 addr show wlan0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "offline")
                        
                        # Verbundene Geräte
                        CONNECTED=$(arp -i ap0 -n 2>/dev/null | grep -c ":" || echo "0")
                        
                        # Status Message
                        MSG="📊 *Exhibition Status*%0A%0A"
                        MSG="${MSG}🖥 *System*%0A"
                        MSG="${MSG}${UPTIME}%0A"
                        MSG="${MSG}CPU: ${TEMP_C}°C | RAM: ${MEM_USED} | Disk: ${DISK_USED}%0A"
                        MSG="${MSG}Load:${LOAD}%0A%0A"
                        MSG="${MSG}📡 *Network*%0A"
                        MSG="${MSG}Hotspot: ${HOTSPOT_STATUS}%0A"
                        MSG="${MSG}WLAN: ${WLAN_IP}%0A"
                        MSG="${MSG}Devices: ${CONNECTED}%0A%0A"
                        MSG="${MSG}⚙️ *Services*%0A${SERVICE_STATUS}"
                        
                        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                            -d chat_id="${TELEGRAM_CHAT_ID}" \
                            -d text="${MSG}" \
                            -d parse_mode="Markdown" >/dev/null 2>&1
                        
                        log_msg "Status sent"
                        ;;
                        
                    /help|/Help)
                        HELP="🤖 *Exhibition Monitor*%0A%0A"
                        HELP="${HELP}/status - System-Status (sofort)%0A"
                        HELP="${HELP}/help - Diese Hilfe%0A%0A"
                        HELP="${HELP}Automatische Alerts bei Problemen aktiviert."
                        
                        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                            -d chat_id="${TELEGRAM_CHAT_ID}" \
                            -d text="${HELP}" \
                            -d parse_mode="Markdown" >/dev/null 2>&1
                        
                        log_msg "Help sent"
                        ;;
                esac
                
                # Update offset
                OFFSET=$((UPDATE_ID + 1))
            done
        fi
    fi
    
    # Kleine Pause wenn keine Updates (fail-safe)
    sleep 0.1
done
