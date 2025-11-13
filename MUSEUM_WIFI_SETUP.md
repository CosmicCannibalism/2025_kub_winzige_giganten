# 📶 Museums-WLAN Setup - Schnellanleitung

**Vor Ort im Museum für Brotkultur Ulm**

---

## 🎯 Ziel

Pi soll sich mit Museums-WLAN verbinden, damit du via `cosmicpi.local` remote zugreifen kannst (z.B. für Updates, Monitoring).

**Wichtig:** iPads müssen NICHTS ändern! Die bleiben auf `winzige_giganten` Hotspot.

---

## 📋 Voraussetzungen

- [ ] Pi läuft und Hotspot `winzige_giganten` ist aktiv
- [ ] Mac hat WLAN-Zugangsdaten vom Museum (SSID + Passwort)
- [ ] Mac verbunden mit `winzige_giganten` Hotspot

---

## 🚀 Setup-Schritte (5 Minuten)

### Schritt 1: Museums-WLAN-Daten eintragen

**Auf deinem Mac (BEVOR du dich mit Hotspot verbindest):**

1. Datei öffnen: `pi-deployment/configs/wifi-networks.conf`

2. Museums-WLAN hinzufügen:
```bash
# Museum für Brotkultur Ulm
SSID="MuseumsWLAN"          # ← Museums SSID eintragen
PASSWORD="museum_passwort"   # ← Museums Passwort eintragen
PRIORITY=110
```

3. Datei speichern

---

### Schritt 2: Mit Pi-Hotspot verbinden

**Auf deinem Mac:**

1. WLAN öffnen
2. Mit `winzige_giganten` verbinden
3. Passwort: `winzigegiganten`
4. Warten bis verbunden

---

### Schritt 3: WiFi-Config auf Pi kopieren

**Terminal öffnen und ins Projekt-Verzeichnis:**

```bash
cd /Users/cosmic/Desktop/art/cosmiccannibalism/kub/kub_schaukastenwinzige_giganten/01_workfiles/2025_kunst_und_brot_winzige_giganten
```

**WiFi-Config hochladen:**

```bash
scp pi-deployment/configs/wifi-networks.conf cosmic@192.168.4.1:/home/cosmic/
```

Passwort eingeben (wenn gefragt)

---

### Schritt 4: Setup-Script ausführen

**SSH auf Pi:**

```bash
ssh cosmic@192.168.4.1
```

**Setup ausführen:**

```bash
cd /home/cosmic
chmod +x setup-wifi-persistent.sh
./setup-wifi-persistent.sh
```

**Warten** bis Script fertig ist (~30 Sekunden)

**SSH beenden:**

```bash
exit
```

---

### Schritt 5: Pi neu starten

**Vom Mac aus:**

```bash
ssh cosmic@192.168.4.1 "sudo reboot"
```

**Warten:** 5 Minuten

---

### Schritt 6: Testen

**Auf deinem Mac:**

1. **Verbinde mit Museums-WLAN** (nicht mehr Hotspot!)
2. Terminal:
```bash
ping cosmicpi.local
```

3. Wenn Ping funktioniert:
```bash
ssh cosmic@cosmicpi.local
```

✅ **Fertig!** Pi ist jetzt per Museums-WLAN erreichbar.

---

## 📱 iPads - Was ändert sich?

**NICHTS!** 

- iPads bleiben auf `winzige_giganten` Hotspot verbunden
- Hotspot läuft weiter auf `ap0`
- Pi hat jetzt 2 Netzwerk-Interfaces:
  - **ap0:** `winzige_giganten` für iPads
  - **wlan0:** Museums-WLAN für dich

---

## 🆘 Troubleshooting

### Ping cosmicpi.local funktioniert nicht

**Lösung 1:** Pi mit IP erreichen
```bash
# Pi suchen im Museums-WLAN
arp -a | grep -i "b8:27:eb\|dc:a6:32\|e4:5f:01"

# Oder einfach Router-Admin-Panel checken
```

**Lösung 2:** Zurück zum Hotspot
```bash
# Mac mit winzige_giganten verbinden
ssh cosmic@192.168.4.1
# WiFi-Config nochmal prüfen
```

### Setup-Script nicht gefunden

**Lösung:**
```bash
# Setup-Script vom Repo holen (nur wenn du Zugriff hast)
cd ~/
wget https://raw.githubusercontent.com/CosmicCannibalism/2025_kub_winzige_giganten/public_download/pi-deployment/setup-wifi-persistent.sh
chmod +x setup-wifi-persistent.sh
./setup-wifi-persistent.sh
```

**Alternative:** Script ist in `pi-deployment/` auf deinem Mac, manuell hochkopieren:
```bash
scp pi-deployment/setup-wifi-persistent.sh cosmic@192.168.4.1:/home/cosmic/
```

---

## ✅ Checkliste

- [ ] wifi-networks.conf aktualisiert
- [ ] Config auf Pi kopiert
- [ ] setup-wifi-persistent.sh ausgeführt
- [ ] Pi neugestartet
- [ ] Mac mit Museums-WLAN verbunden
- [ ] `ping cosmicpi.local` erfolgreich
- [ ] iPads laufen weiter normal

---

## 💡 Backup-Plan

Falls Setup fehlschlägt: **Kein Problem!**

- Hotspot läuft weiter
- iPads funktionieren normal
- Du kannst jederzeit über `192.168.4.1` (Hotspot) auf Pi zugreifen
- Setup später wiederholen

**Die Ausstellung läuft auch OHNE Museums-WLAN!**

---

**Stand:** 13. November 2025
