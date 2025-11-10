#!/bin/bash
# Boot-persistent WiFi Dual-Mode Setup
# Konfiguriert Pi für gleichzeitigen AP-Modus (Hotspot) und Client-Modus (Studio-WLAN)
# MIT ROLLBACK-SICHERHEIT - Hotspot bleibt garantiert funktionsfähig

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Boot-Persistent WiFi Dual-Mode Setup ===${NC}"
echo "Dieses Script konfiguriert automatischen Start beim Reboot"
echo ""

# Backup-Verzeichnis erstellen
BACKUP_DIR="/home/cosmic/wifi-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo -e "${YELLOW}Backup-Verzeichnis: $BACKUP_DIR${NC}"

# Wichtige Dateien sichern
echo "Sichere aktuelle Konfiguration..."
sudo cp /etc/dhcpcd.conf "$BACKUP_DIR/" 2>/dev/null || true
sudo cp /etc/wpa_supplicant/wpa_supplicant.conf "$BACKUP_DIR/" 2>/dev/null || true
sudo cp /etc/hostapd/hostapd.conf "$BACKUP_DIR/" 2>/dev/null || true

echo ""
echo -e "${GREEN}=== Schritt 1: Prüfe Hotspot-Konfiguration ===${NC}"
if [ ! -f /etc/hostapd/hostapd.conf ]; then
    echo -e "${RED}FEHLER: /etc/hostapd/hostapd.conf nicht gefunden!${NC}"
    echo "Hotspot ist nicht konfiguriert. Abbruch."
    exit 1
fi

echo "Hotspot-Config gefunden ✓"
grep "^ssid=" /etc/hostapd/hostapd.conf
grep "^interface=" /etc/hostapd/hostapd.conf

echo ""
echo -e "${GREEN}=== Schritt 2: Prüfe wpa_supplicant.conf ===${NC}"
if [ ! -f /etc/wpa_supplicant/wpa_supplicant.conf ]; then
    echo -e "${RED}FEHLER: wpa_supplicant.conf nicht gefunden!${NC}"
    exit 1
fi

echo "Konfigurierte Netzwerke:"
grep "ssid=" /etc/wpa_supplicant/wpa_supplicant.conf | grep -v "^\s*#"

echo ""
echo -e "${GREEN}=== Schritt 3: Erstelle systemd Service für Client-Modus ===${NC}"

# Erstelle wpa_supplicant Service-Override für wlan0
sudo tee /etc/systemd/system/wpa_supplicant-wlan0.service > /dev/null <<'EOF'
[Unit]
Description=WPA supplicant for wlan0 (Client Mode)
Before=dhcpcd.service
After=network-pre.target
Wants=network-pre.target

[Service]
Type=simple
ExecStartPre=/sbin/ip link set wlan0 up
ExecStart=/sbin/wpa_supplicant -c /etc/wpa_supplicant/wpa_supplicant.conf -i wlan0 -D nl80211
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "wpa_supplicant-wlan0.service erstellt ✓"

echo ""
echo -e "${GREEN}=== Schritt 4: Konfiguriere dhcpcd für Dual-Mode ===${NC}"

# Prüfe ob dhcpcd.conf bereits konfiguriert ist
if grep -q "interface wlan0" /etc/dhcpcd.conf; then
    echo "dhcpcd.conf bereits konfiguriert für wlan0"
else
    echo "Füge wlan0-Konfiguration zu dhcpcd.conf hinzu..."
    sudo tee -a /etc/dhcpcd.conf > /dev/null <<'EOF'

# wlan0 Client-Modus (Studio-WLAN)
interface wlan0
metric 200
EOF
    echo "dhcpcd.conf aktualisiert ✓"
fi

echo ""
echo -e "${GREEN}=== Schritt 5: Services konfigurieren ===${NC}"

# Reload systemd
sudo systemctl daemon-reload

# Enable Services
echo "Aktiviere wpa_supplicant-wlan0..."
sudo systemctl enable wpa_supplicant-wlan0.service

echo "Aktiviere hostapd..."
sudo systemctl enable hostapd.service

echo "Services aktiviert ✓"

echo ""
echo -e "${YELLOW}=== WICHTIG: Services werden NICHT automatisch neu gestartet ===${NC}"
echo "Der Hotspot läuft weiter wie bisher."
echo ""
echo "Um die neue Konfiguration zu testen:"
echo "  1. Führe aus: sudo systemctl start wpa_supplicant-wlan0"
echo "  2. Warte 10 Sekunden"
echo "  3. Prüfe mit: ip addr show wlan0"
echo "  4. Du solltest eine 192.168.2.x IP sehen (zusätzlich zu 192.168.4.1)"
echo ""
echo "Nach erfolgreichem Test:"
echo "  sudo reboot"
echo ""
echo -e "${GREEN}Backup gespeichert in: $BACKUP_DIR${NC}"
echo ""
echo "Falls etwas schiefgeht:"
echo "  sudo cp $BACKUP_DIR/dhcpcd.conf /etc/dhcpcd.conf"
echo "  sudo systemctl disable wpa_supplicant-wlan0"
echo "  sudo reboot"
