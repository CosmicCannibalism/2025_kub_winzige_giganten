#!/bin/bash

# External Pi Monitor - läuft auf Mac und prüft ob Pi erreichbar ist
# Benachrichtigt bei Stromausfall (Pi offline) und beim Wiederhochfahren

TELEGRAM_BOT_TOKEN="8362321996:AAGRxNC5mZBtSGbQPdlzqqgMHPRQA5xfM20"
TELEGRAM_CHAT_ID="6901638335"
PI_HOST="cosmicpi.local"
STATUS_FILE="/tmp/pi-monitor-status"
LOG_FILE="/tmp/pi-monitor.log"

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

send_telegram() {
    local MESSAGE="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="${MESSAGE}" \
        -d parse_mode="Markdown" >/dev/null 2>&1
}

# Lade letzten Status
PI_WAS_ONLINE=true
if [ -f "$STATUS_FILE" ]; then
    source "$STATUS_FILE"
fi

# Prüfe ob Pi erreichbar ist (mehrere Versuche)
PI_ONLINE=false
for i in {1..3}; do
    if ping -c 1 -W 2 "$PI_HOST" >/dev/null 2>&1; then
        PI_ONLINE=true
        break
    fi
    sleep 2
done

# Zustandsänderung erkennen
if [ "$PI_ONLINE" = true ]; then
    if [ "$PI_WAS_ONLINE" = false ]; then
        # Pi ist wieder online!
        log_msg "Pi back online!"
        
        # Warte kurz bis Services hochgefahren sind
        sleep 10
        
        send_telegram "✅ *Pi Online*%0A%0APi ist wieder erreichbar nach Stromausfall/Reboot.%0A%0AHost: ${PI_HOST}"
        PI_WAS_ONLINE=true
    fi
else
    if [ "$PI_WAS_ONLINE" = true ]; then
        # Pi ist offline gegangen!
        log_msg "Pi went offline!"
        send_telegram "⚠️ *Pi Offline*%0A%0APi ist nicht mehr erreichbar!%0AMögliche Ursache: Stromausfall, Netzwerk-Problem, System-Crash%0A%0AHost: ${PI_HOST}"
        PI_WAS_ONLINE=false
    fi
fi

# Status speichern
echo "PI_WAS_ONLINE=$PI_WAS_ONLINE" > "$STATUS_FILE"

exit 0
