# Handbuch für Museumsmitarbeiter
## Winzige Giganten - Interaktive Ausstellung

**Version 2.0 - November 2025**

---

## 1. Inbetriebnahme der Installation

### Erstinbetriebnahme
1. **Raspberry Pi einschalten**
   - Stromversorgung anschließen (USB-C Netzteil, min. 3A empfohlen)
   - Warten Sie ca. 3 Minuten bis System vollständig hochgefahren ist
   - Grüne LED blinkt = Systemaktivität, Rote LED leuchtet = Stromversorgung

2. **Netzwerk prüfen**
   - Pi stellt automatisch Hotspot "winzige_giganten" bereit
   - Passwort: `winzigegiganten`
   - ⏰ **WICHTIG:** Nach Neustart dauert es ca. **5 Minuten** bis Hotspot aktiv ist
   - Falls Studio-WLAN verfügbar: Pi verbindet sich automatisch für Internet-Zugang
   - Internet ist optional - Installation läuft auch ohne

3. **iPads vorbereiten**
   - iPads einschalten und entsperren
   - WLAN-Einstellungen öffnen
   - Mit "winzige_giganten" verbinden (Passwort: `winzigegiganten`)
   - PWA-App vom Homescreen starten (siehe Abschnitt 2)

### Tägliche Inbetriebnahme
1. Raspberry Pi ist bereits eingeschaltet (24/7 Betrieb empfohlen)
2. iPads entsperren
3. PWA-App vom Homescreen antippen
4. System ist sofort einsatzbereit

---

## 2. iPad Setup & PWA Installation

### Erste Installation (einmalig pro iPad)

1. **Safari öffnen** (wichtig: nur Safari unterstützt PWA!)
2. **Adresse eingeben**: 
   - iPad 1: `https://192.168.4.1/index.html` (Pasteur)
   - iPad 2: `https://192.168.4.1/index01.html` (Robert Hooke)
   - iPad 3: `https://192.168.4.1/index02.html` (Van Leeuwenhoek)
   - Alternativ: `http://cosmicpi.local` (wenn mDNS funktioniert)
3. **Warten auf Video-Caching**:
   - Overlay zeigt "Preparing exhibition, please wait…"
   - Fortschritt wird angezeigt: "Caching teaser.mp4… 25%"
   - Dann: "Caching Pasteur.mp4…", "Caching Robert_Hooke.mp4…" etc.
   - Abschluss: "Ready to start!" → Start-Button erscheint
   - **Dauer**: Ca. 2-3 Minuten (einmalig, danach alles offline verfügbar!)
   
4. **Als App installieren**:
   - Tippen auf **Teilen-Button** (Rechteck mit Pfeil nach oben)
   - Scrollen zu **"Zum Home-Bildschirm"**
   - Namen bestätigen (z.B. "WG v1" für Version 1)
   - **Fertig** App-Icon erscheint auf Homescreen

### Welche Version für welches iPad?
- **index.html** = Pasteur Video (119s)
- **index01.html** = Robert Hooke Video (154s) 
- **index02.html** = Van Leevenhoek Video (122s)

Jedes iPad braucht seine eigene Version - beim ersten Aufruf entsprechende URL verwenden.

### PWA neu installieren (bei Problemen)
1. PWA-Icon auf Homescreen **lange gedrückt halten**
2. **"App entfernen"** wählen
3. Safari öffnen und obige Schritte wiederholen
4. Videos werden neu gecacht (Fortschritt wird angezeigt)

---

## 3. iPad Ausstellungs-Konfiguration

**Hardware**: iPad Air (Model A2316), iOS 15.6.1+

### 3.1 Display-Einstellungen
- **Einstellungen** → **Anzeige & Helligkeit**
  - **Automatische Sperre** → Nie
  - **Helligkeit** → Maximum (oder gewünschter Ausstellungswert)
  - **True Tone** → Aus
  - **Night Shift** → Aus

### 3.2 Mitteilungen deaktivieren
- **Einstellungen** → **Mitteilungen**
  - **Vorschauen zeigen** → Nie
  - Alle App-Mitteilungen deaktivieren

### 3.3 Kontrollzentrum & Siri
- **Einstellungen** → **Kontrollzentrum**
  - **In Apps** → Aus
- **Einstellungen** → **Siri & Suchen**
  - **Auf "Hey Siri" achten** → Aus
  - **Standby-Taste für Siri drücken** → Aus

### 3.4 Updates & Hintergrund
- **Einstellungen** → **Allgemein** → **Softwareupdate**
  - **Automatische Updates** → Aus
- **Einstellungen** → **Allgemein** → **Hintergrundaktualisierung** → Aus
- **Einstellungen** → **WLAN**
  - **Auf Netzwerke hinweisen** → Aus

### 3.5 Guided Access (App-Lock für Ausstellung)
**WICHTIG für Ausstellungsbetrieb!** Verhindert, dass Besucher die App verlassen.

1. **Aktivieren:**
   - **Einstellungen** → **Bedienungshilfen** → **Geführter Zugriff** → **Ein**
   - **Code festlegen** (6-stellig, gut merken!)
   - **Shortcuts für Bedienungshilfen** → **Ein**

2. **App sperren:**
   - PWA-App öffnen
   - **Power-Taste 3x schnell drücken**
   - Code eingeben
   - Optional: Bereiche deaktivieren (Touch-Bereiche einschränken)
   - **"Starten"** tippen
   - ✅ App ist jetzt gesperrt - Besucher können nicht zur Home Screen

3. **App entsperren:**
   - **Power-Taste 3x schnell drücken**
   - Code eingeben
   - **"Beenden"**

---

## 4. Technische Details

### 4.1 PWA Features
- **Service Worker Caching:** Alle Videos, HTML, CSS, JS werden offline gecacht (v21)
- **Vignetten-Effekte:** Cinematic Overlays auf Teaser (67% Stärke) und Main Video (63% Stärke)
- **Icons:** 
  - Pasteur: Lila Icon
  - Robert Hooke: Grünes Icon
  - Van Leeuwenhoek: Blaues Icon
  - Icon-Größen: 180px (iOS), 192px, 512px
  - Pfade: `/icons/icon-<name>-<size>.png` (absolute Pfade für iOS-Kompatibilität)

### 4.2 Bekannte Probleme & Workarounds

**Icon zeigt Screenshot statt richtiges Icon:**
- iOS cached Home Screen Icons sehr aggressiv
- **Lösung:** iPad komplett neustarten + Safari Cache löschen + PWA neu installieren
- Manchmal hilft auch: App-Name beim Hinzufügen ändern

**Hotspot nach Neustart nicht sofort verfügbar:**
- Systemd Services brauchen ca. 5 Minuten zum Starten
- **Lösung:** Einfach warten, kein Fehler!

**Schwarzer Bildschirm nach Start:**
- Videos nicht im richtigen Verzeichnis oder Service Worker Cache defekt
- **Lösung:** Safari Console öffnen, Service Worker deregistrieren (siehe Troubleshooting)

### 3.5 Geführter Zugriff (Kiosk-Modus)
**Wichtigster Schritt für Ausstellungsbetrieb!**

- **Einstellungen** → **Bedienungshilfen** → **Geführter Zugriff**
  - **Geführter Zugriff** → Ein
  - **Code-Einstellungen** → Code festlegen (merken!)
  - **Zeitlimits** → Aus
  - **Automatische Sperre des Displays** → Nie

### 3.6 Geführten Zugriff starten
**Wenn PWA im Vollbild läuft:**
1. **3× Standby-Taste drücken** (Power-Button oben rechts)
2. Menü "Geführter Zugriff" erscheint
3. Optional: Touch-Bereiche deaktivieren (nicht empfohlen, da Space-Trigger benötigt wird)
4. **"Starten"** drücken

**Ergebnis**: iPad ist jetzt im Kiosk-Modus gesperrt
- Besucher können App nicht verlassen
- Keine Home-Geste oder Kontrollzentrum
- Display bleibt dauerhaft an

### 3.7 Geführten Zugriff beenden
- **3× Standby-Taste drücken** → Code eingeben
- Oder: **"Beenden"** links oben (falls sichtbar)

---

## 4. Bedienung der Ausstellung

### Normalbetrieb
1. **Teaser-Video** läuft automatisch in Endlosschleife
2. **Besucher drückt mechanischen Knopf** (Arduino sendet Leertaste-Signal)
3. **Hauptvideo startet** (Pasteur/Robert Hooke/Van Leevenhoek je nach Installation)
4. **Relais öffnet während Video läuft** (Mikroskopeinsicht freigegeben)
5. **Nach Video-Ende**: Rückkehr zum Teaser, Relais schließt
6. **Nächster Besucher** kann erneut Knopf drücken

### Offline-Fähigkeit
- **Alle Videos sind gecacht** nach erster PWA-Installation
- **Hotspot-Ausfall?** App funktioniert weiter (Videos laufen aus Cache)
- **Strom weg?** Nach Neustart des Pi: iPads reconnecten automatisch zum Hotspot
- **Kein Internet nötig** für täglichen Betrieb (nur für Monitoring)

---

## 4. Statussystem & Monitoring

### Telegram Statusabfrage
- Telegram öffnen und den Bot `@winzige_giganten_bot` anschreiben.
- `/status` senden → Sofort System-Report erhalten (Services, WLAN, Temperatur, Speicher, Geräte).

### Automatische Benachrichtigungen
- Bei Problemen (Service-Ausfall, Stromausfall) kommt eine Telegram-Nachricht:
  - `🚨 Alert - Services Down`
  - `🔄 Pi Hochgefahren`
  - `✅ Resolved - Services OK`
- Healthchecks.io überwacht den Pi und sendet bei Ausfall/Recovery:
  - `🔴 DOWN` (Pi offline - kein Internet)
  - `✅ UP` (Pi wieder online)

### Watchdog System (automatische Selbstheilung)
Der Pi überwacht sich selbst alle 2 Minuten:
- **Hotspot prüfen**: SSID "winzige_giganten" muss senden
- **Services prüfen**: nginx, hostapd, dnsmasq müssen laufen
- **Internet prüfen**: Alle 10 Minuten, bei Ausfall automatischer Reconnect
- **Boot Grace Period**: 3 Minuten nach Neustart keine Intervention
- **Automatische Reparatur**: Startet ausgefallene Services neu

**Logs ansehen** (optional, für Techniker):
```bash
ssh cosmic@cosmicpi.local
sudo journalctl -u wg-watchdog.service -f
```

---

## 5. Troubleshooting

### Problem: PWA zeigt schwarzen Bildschirm beim Video-Start
**Ursache**: Videos nicht vollständig gecacht  
**Lösung**:
1. PWA vom Homescreen löschen
2. Safari öffnen → `http://cosmicpi.local`
3. **Warten** bis "Ready to start!" erscheint (nicht vorher installieren!)
4. Erneut "Zum Home-Bildschirm" hinzufügen
5. Videos sind nun gecacht

### Problem: Hotspot "winzige_giganten" nicht sichtbar
**Ursache**: Pi zu weit entfernt, Stromausfall, oder Watchdog beim Reparieren  
**Lösung**:
1. Warten Sie 3-5 Minuten (Watchdog repariert automatisch)
2. Pi näher platzieren (max. 4-5m Reichweite)
3. Falls weiterhin Problem: Pi neu starten (Strom kurz trennen)
3. Falls weiterhin Problem: Pi neu starten (Strom kurz trennen)

### Problem: iPad verbindet nicht mit Hotspot
**Ursache**: WLAN-Cache oder falsches Passwort  
**Lösung**:
1. iPad: Einstellungen → WLAN → "winzige_giganten" Info-Button (i)
2. "Dieses Netzwerk ignorieren" → Bestätigen
3. Erneut verbinden mit Passwort: `giganten2025`

### Problem: Videos laden langsam oder haken
**Ursache**: Videos nicht aus Cache, sondern vom Netzwerk geladen  
**Lösung**:
1. PWA neu installieren (siehe oben)
2. Nach Installation: **Alle Videos einmal durchspielen lassen**
3. Dann sind sie vollständig im Cache

### Problem: Healthchecks.io meldet "DOWN" obwohl Hotspot läuft
**Ursache**: Pi hat kein Internet (z.B. zu weit vom Studio-Router)  
**Lösung**:
1. **Kein Problem** für Ausstellung - Hotspot funktioniert weiter!
2. Nur Monitoring betroffen
3. Pi näher zum Router platzieren wenn Internet-Monitoring gewünscht
4. Watchdog versucht automatisch alle 10 Min. Reconnect

### Problem: Mechanischer Knopf reagiert nicht
**Ursache**: Arduino nicht verbunden oder falsches Relay-Timing  
**Lösung**:
1. USB-Verbindung Arduino → iPad prüfen
2. Arduino neu starten (USB kurz trennen)
3. Prüfen ob richtiger Arduino-Code für Index verwendet (siehe Arduino-Dokumentation)

### Problem: Relais öffnet nicht/schließt nicht rechtzeitig
**Ursache**: Falsches Arduino-Sketch für Video-Länge  
**Lösung**:
- **Pasteur** (119s): `arduino_variants/pasteur_index/` verwenden
- **Robert Hooke** (154s): `arduino_variants/robert_hooke_index01/` verwenden  
- **Van Leevenhoek** (122s): `arduino_variants/van_leevenhoek_index02/` verwenden
- Richtiges Sketch auf Arduino hochladen (siehe `arduino_variants/README.md`)

---

## 6. Wartung & Updates

### Regelmäßige Checks (wöchentlich empfohlen)
- [ ] Telegram `/status` abfragen - alle Services UP?
- [ ] Hotspot-Reichweite testen (mit Smartphone)
- [ ] Jedes iPad: PWA starten und Video-Knopf testen
- [ ] Relais-Funktion prüfen (öffnet/schließt während Video?)

### System-Updates (nur durch Techniker)
Updates sollten nur außerhalb Öffnungszeiten durchgeführt werden:
```bash
ssh cosmic@cosmicpi.local
sudo apt update && sudo apt upgrade -y
sudo reboot
```

### PWA-Updates deployen
Bei neuen App-Versionen:
1. Files auf Pi deployen (SSH)
2. **Alle iPads**: PWA neu installieren (alte löschen, neu hinzufügen)
3. Videos werden neu gecacht

---

## 7. Technische Spezifikationen

### Hardware
- **Raspberry Pi 4** (4GB RAM empfohlen)
- **Arduino Leonardo** (oder kompatibel mit Keyboard-Library)
- **Relais-Modul** (5V, gesteuert über Pin 7)
- **Mechanischer Taster** (Pull-up an Pin 6)
- **iPads** (iOS 13+ für PWA-Support)

### Software
- **OS**: Raspberry Pi OS Lite (Debian-basiert)
- **Webserver**: nginx
- **Hotspot**: hostapd + dnsmasq
- **Monitoring**: Telegram Bot, healthchecks.io, exhibition-monitor.service
- **Watchdog**: wg-watchdog.service (2min Intervall)
- **PWA**: Service Worker v4 mit vollständigem Video-Precaching

### Netzwerk
- **Hotspot SSID**: `winzige_giganten`
- **Passwort**: `giganten2025`
- **IP-Range**: 192.168.4.1 - 192.168.4.254
- **Pi Hotspot-IP**: 192.168.4.1
- **mDNS**: cosmicpi.local (funktioniert nur im Studio-WLAN)

### Video-Assets
- **teaser.mp4**: 12s, 15MB (Loop)
- **Pasteur.mp4**: 119s, 45MB (index.html)
- **Robert_Hooke.mp4**: 154s, 67MB (index01.html)
- **Van_Leevenhoek.mp4**: 122s, 80MB (index02.html)

---

## 8. Kontakt & Support

## 8. Kontakt & Support

### Erste Hilfe
1. **Telegram-Bot** nutzen: `/status` an @winzige_giganten_bot
2. Dieses Handbuch durchlesen (Abschnitt 5 - Troubleshooting)
3. Pi neu starten (oft löst dies das Problem)

### Technischer Support
- **E-Mail**: [Ihre Support-Email]
- **Telefon**: [Ihre Support-Nummer]
- **Vor Kontaktaufnahme bereithalten**:
  - Welches iPad (welche Version: index/index01/index02)?
  - Fehlerbeschreibung
  - Telegram `/status` Output (Screenshot)

---

## Anhang: Quick Reference Cheatsheet

### 🚀 Schnellstart
1. Pi einschalten (3 Min warten)
2. iPad mit "winzige_giganten" verbinden (PW: `giganten2025`)
3. PWA vom Homescreen starten

### 📱 PWA Installation
Safari → `http://cosmicpi.local` → Teilen → "Zum Home-Bildschirm"

### 🔧 Wichtigste Befehle (Techniker)
```bash
# Status prüfen
sudo systemctl status wg-watchdog.service
sudo journalctl -u wg-watchdog.service -n 50

# Services neu starten
sudo systemctl restart nginx
sudo systemctl restart hostapd
sudo systemctl restart dnsmasq

# Hotspot SSID prüfen
sudo iw dev ap0 info | grep ssid
```

### 📞 Notfall-Kontakte
- Telegram: `/status` an @winzige_giganten_bot
- Healthchecks: [Healthchecks.io Dashboard URL]
- Techniker: [Kontaktdaten]

---

**Dieses Handbuch kann als PDF ausgedruckt und beim Ausstellungsort bereitgelegt werden.**  
**Version 2.0 - November 2025 - CosmicCannibalism**
