# Exhibition Monitoring Setup

Automatisierte Überwachung der Exhibition Hardware mit Benachrichtigungen bei Problemen + Telegram Status-Abfrage.

## Features

Das Monitoring-Script (`exhibition-monitor.sh`) prüft alle 5 Minuten:

✅ **Kritische Services**: nginx, hostapd, dhcpcd, avahi-daemon, watchdog  
✅ **Hotspot Status**: Prüft ob ap0 interface mit 192.168.4.1 läuft  
✅ **Disk Space**: Warnung bei <2GB frei  
✅ **Memory**: Warnung bei <50MB verfügbar  
✅ **CPU Temperatur**: Warnung bei >70°C  
✅ **Watchdog Repairs**: Benachrichtigung wenn Watchdog eingreifen musste  
✅ **Telegram Commands**: `/status` für Live-Status, `/help` für Hilfe

---

## Komplette Installation (Schritt-für-Schritt)

### Schritt 1: Telegram Bot erstellen (auf deinem Handy)

1. **Öffne Telegram App**
2. **Suche nach:** `@BotFather`
3. **Starte Chat** und sende: `/newbot`
4. **Bot Name:** `Winzige Giganten Monitor` (oder wie du willst)
5. **Bot Username:** `winzige_giganten_bot` (muss auf `_bot` enden)
6. **Kopiere den Bot Token** - sieht so aus: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`
   ⚠️ Speichere ihn irgendwo, du brauchst ihn gleich!

### Schritt 2: Deine Chat ID finden

1. **Suche nach:** `@userinfobot`
2. **Starte den Bot** (Button "Start")
3. **Er antwortet mit deiner Chat ID** - eine Zahl wie `987654321`
   ⚠️ Speichere auch diese!

### Schritt 3: Bot aktivieren

1. **Suche deinen neuen Bot** (z.B. `@winzige_giganten_bot`)
2. **Klick "Start"**
3. **Sende Test-Nachricht:** `Hi!`

### Schritt 4: Script auf Pi kopieren

**Auf deinem Mac im Terminal:**

```bash
# Gehe ins Projekt-Verzeichnis
cd /Users/cosmic/Desktop/art/cosmiccannibalism/kub/kub_schaukastenwinzige_giganten/01_workfiles/2025_kunst_und_brot_winzige_giganten

# Script auf Pi kopieren
scp pi-deployment/scripts/exhibition-monitor.sh cosmic@cosmicpi.local:/home/cosmic/
```

### Schritt 5: Auf dem Pi installieren

**SSH Verbindung zum Pi:**

```bash
ssh cosmic@cosmicpi.local
```

**Dann auf dem Pi:**

```bash
# 1. Script nach /usr/local/sbin verschieben
sudo mv /home/cosmic/exhibition-monitor.sh /usr/local/sbin/
sudo chmod +x /usr/local/sbin/exhibition-monitor.sh

# 2. Script editieren - TELEGRAM CREDENTIALS eintragen
sudo nano /usr/local/sbin/exhibition-monitor.sh
```

**Im nano Editor:**
- Suche nach den Zeilen (Zeile ~13-15):
  ```bash
  TELEGRAM_BOT_TOKEN=""
  TELEGRAM_CHAT_ID=""
  SEND_TELEGRAM=false
  ```
- Ändere zu (mit DEINEN Werten):
  ```bash
  TELEGRAM_BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"  # Dein Token!
  TELEGRAM_CHAT_ID="987654321"  # Deine Chat ID!
  SEND_TELEGRAM=true  # Von false auf true!
  ```
- **Speichern:** `Ctrl+O` dann `Enter`
- **Beenden:** `Ctrl+X`

```bash
# 3. Log-Datei vorbereiten
sudo touch /var/log/exhibition-monitor.log
sudo chown cosmic:cosmic /var/log/exhibition-monitor.log

# 4. Manueller Test (sollte Telegram-Nachricht senden wenn Probleme da sind)
/usr/local/sbin/exhibition-monitor.sh

# 5. Log prüfen
cat /var/log/exhibition-monitor.log
```

### Schritt 6: Telegram Test

**Sende an deinen Bot in Telegram:**
```
/status
```

Du solltest sofort einen ausführlichen Status-Report bekommen! 📊

### Schritt 7: Cron Job einrichten (automatisch alle 5 Min)

**Auf dem Pi:**

```bash
# Crontab öffnen
crontab -e

# Falls nach Editor gefragt wird: Wähle "1" (nano)
```

**Am Ende der Datei hinzufügen:**
```bash
# Exhibition Monitoring - alle 5 Minuten
*/5 * * * * /usr/local/sbin/exhibition-monitor.sh
```

**Speichern:** `Ctrl+O` dann `Enter`, **Beenden:** `Ctrl+X`

### Schritt 8: Finaler Test

```bash
# Simuliere Problem (Vorsicht: Hotspot geht kurz offline!)
sudo systemctl stop hostapd

# Warte 5 Minuten oder führe Script manuell aus
/usr/local/sbin/exhibition-monitor.sh

# Du solltest Telegram-Benachrichtigung bekommen: "Services Down: hostapd"

# Service wieder starten
sudo systemctl start hostapd

# Noch ein Check
/usr/local/sbin/exhibition-monitor.sh

# Du solltest bekommen: "Services Recovered"
```

**Fertig! 🎉**

---

## Verwendung

### Telegram Commands

Schreibe deinem Bot in Telegram:

- **`/status`** - Zeigt vollständigen System-Status
  - Uptime, CPU Temp, Memory, Disk
  - Hotspot Status + IP
  - WLAN Verbindung
  - Alle Services (✅/❌)
  - Anzahl verbundene Geräte
  - Letzte Fehler

- **`/help`** - Zeigt verfügbare Commands

### Automatische Benachrichtigungen

Du bekommst automatisch Push-Benachrichtigungen wenn:
- Ein Service ausfällt (nginx, hostapd, dhcpcd, avahi, watchdog)
- Hotspot offline geht
- Disk Space <2GB
- RAM <50MB
- CPU Temperatur >70°C
- Watchdog Repair durchgeführt wurde

Wenn das Problem behoben ist, bekommst du "Recovered" Nachricht.

---

## Beispiel Status-Report

Wenn du `/status` sendest, bekommst du:

```
📊 Exhibition Status Report

🖥 System
Uptime: up 3 days, 4 hours
CPU Temp: 42°C
Memory: 38%
Disk: 18%
Load: 0.15, 0.18, 0.12

📡 Network
Hotspot: ✅ Online (192.168.4.1)
WLAN: 192.168.2.179
Connected Devices: 3

⚙️ Services
✅ nginx
✅ hostapd
✅ dhcpcd
✅ avahi-daemon
✅ watchdog

📋 Log
Recent errors: 0

Use /status for update
```

---

## Beispiel Problem-Benachrichtigungen

**Service ausgefallen:**
```
🚨 Winzige Giganten Alert

Services Down
Following services are not running: hostapd
```

**Service wiederhergestellt:**
```
✅ Winzige Giganten Alert

Services Recovered
All critical services are running again
```

**Watchdog Eingriff:**
```
🚨 Winzige Giganten Alert

Watchdog Repair Triggered
System performed emergency repair: 2024-11-09 14:23:15 - restarting hostapd
```

**Kritische Temperatur:**
```
🚨 Winzige Giganten Alert

High Temperature
CPU temperature is 73°C (critical threshold: 70°C)
```

---

## Monitoring Logs prüfen

```bash
# Letzte 50 Einträge
tail -50 /var/log/exhibition-monitor.log

# Nur Fehler/Warnungen
grep -E "(ERROR|WARNING|ALERT)" /var/log/exhibition-monitor.log

# Letzte 24 Stunden
grep "$(date '+%Y-%m-%d')" /var/log/exhibition-monitor.log

# Live-Monitoring
tail -f /var/log/exhibition-monitor.log
```

## Deaktivieren

```bash
# Cron Job entfernen
crontab -e
# Zeile mit exhibition-monitor.sh auskommentieren oder löschen

# Script deaktivieren
sudo chmod -x /usr/local/sbin/exhibition-monitor.sh
```

## Troubleshooting

**"mail: command not found"**
```bash
sudo apt-get install mailutils
```

**Telegram funktioniert nicht:**
- Prüfe Bot Token und Chat ID
- Teste manuell: `curl -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" -d chat_id=<CHAT_ID> -d text="Test"`

**Keine Benachrichtigungen:**
- Prüfe ob Cron Job läuft: `systemctl status cron`
- Prüfe Cron Logs: `grep CRON /var/log/syslog`
- Führe Script manuell aus: `/usr/local/sbin/exhibition-monitor.sh`

## Status-Datei

Das Script speichert Status in `/var/tmp/exhibition-monitor-status` um wiederholte Benachrichtigungen zu vermeiden. Nur bei Zustandsänderungen wird benachrichtigt.

Status zurücksetzen (um neue Benachrichtigung zu erzwingen):
```bash
sudo rm /var/tmp/exhibition-monitor-status
```
