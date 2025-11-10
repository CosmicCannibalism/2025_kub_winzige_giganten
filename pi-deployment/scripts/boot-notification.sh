#!/bin/bash

# Boot Notification - sendet Telegram Nachricht beim Systemstart
# Zeigt an: Pi ist hochgefahren (nach Stromausfall, Reboot, Crash)

TELEGRAM_BOT_TOKEN="8362321996:AAGRxNC5mZBtSGbQPdlzqqgMHPRQA5xfM20"
TELEGRAM_CHAT_ID="6901638335"

# Warte bis Internet verfügbar ist (max 60 Sekunden)
for i in {1..12}; do
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        break
    fi
    sleep 5
done

# Hole System-Infos
UPTIME=$(uptime -s)
BOOT_TIME=$(uptime -p)
LAST_BOOT=$(who -b | awk '{print $3, $4}')

# Prüfe ob vorheriger Shutdown sauber war
LAST_SHUTDOWN=$(journalctl -b -1 | grep -i "shutdown\|reboot" | tail -1 | cut -d' ' -f1-3 || echo "Unknown")

# Prüfe auf Kernel Panic oder Crash
CRASH_DETECTED=false
if journalctl -b -1 | grep -qi "kernel panic\|oops\|segfault"; then
    CRASH_DETECTED=true
fi

# Erstelle Nachricht
MESSAGE="🔄 *Pi Hochgefahren*%0A%0A"
MESSAGE="${MESSAGE}Der Pi ist wieder online.%0A%0A"
MESSAGE="${MESSAGE}Boot: ${LAST_BOOT}%0A"
MESSAGE="${MESSAGE}Uptime: ${BOOT_TIME}%0A"

if [ "$CRASH_DETECTED" = true ]; then
    MESSAGE="${MESSAGE}%0A⚠️ Möglicher Crash/Kernel Panic erkannt!"
fi

# Sende Benachrichtigung
curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="${TELEGRAM_CHAT_ID}" \
    -d text="${MESSAGE}" \
    -d parse_mode="Markdown" >/dev/null 2>&1

# Sende auch Heartbeat an healthchecks.io damit es sofort UP zeigt
curl -fsS --retry 3 --max-time 10 \
    "https://hc-ping.com/5af2c303-173b-4317-be5a-0b08cecccbab" \
    >/dev/null 2>&1

exit 0
