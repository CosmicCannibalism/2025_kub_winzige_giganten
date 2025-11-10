#!/bin/bash

# Heartbeat mit healthchecks.io
# Pingt Cloud-Service alle 10 Min
# Service alarmiert automatisch wenn Ping ausbleibt

HEALTHCHECK_URL="https://hc-ping.com/5af2c303-173b-4317-be5a-0b08cecccbab"

# Quick Status für Logs
UPTIME=$(uptime -p | sed 's/up //')
TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
TEMP_C=$((TEMP / 1000))
LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')

# Ping healthchecks.io mit Status-Info
curl -fsS --retry 3 --max-time 10 \
    "${HEALTHCHECK_URL}" \
    --data-raw "Uptime: ${UPTIME}, Temp: ${TEMP_C}°C, Load: ${LOAD}" \
    > /dev/null 2>&1

exit 0
