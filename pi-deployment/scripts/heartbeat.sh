#!/bin/bash

# Heartbeat - sendet alle 10 Minuten ein Lebenszeichen
# Wenn Nachricht ausbleibt, ist Pi offline

TELEGRAM_BOT_TOKEN="8362321996:AAGRxNC5mZBtSGbQPdlzqqgMHPRQA5xfM20"
TELEGRAM_CHAT_ID="6901638335"

# Sammle Quick-Status
UPTIME=$(uptime -p | sed 's/up //')
TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
TEMP_C=$((TEMP / 1000))
LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')

# Kurze Heartbeat-Nachricht
MESSAGE="💚 Pi läuft%0A${UPTIME} | ${TEMP_C}°C | Load ${LOAD}"

curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="${TELEGRAM_CHAT_ID}" \
    -d text="${MESSAGE}" \
    -d disable_notification=true \
    >/dev/null 2>&1

exit 0
