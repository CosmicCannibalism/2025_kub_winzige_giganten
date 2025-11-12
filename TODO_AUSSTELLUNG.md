# 📋 TODO: Ausstellungsvorbereitung Winzige Giganten

**Stand:** 12. November 2025  
**Branch:** public_download  
**Priorität:** Sicherheit → Kritisch → Nice-to-have

---

## ✅ ERLEDIGT

- [x] Icons für iPad Home Screen konfiguriert (absolute Pfade)
- [x] Vignetten-Effekte hinzugefügt (style.css)
- [x] Alle 3 iPads installiert und getestet
- [x] Videos in korrektes Verzeichnis verschoben (/var/www/html/videos/)
- [x] Service Worker aktualisiert (180px Icons gecacht)

---

## 🔴 KRITISCH - JETZT ERLEDIGEN

### 1. 🔒 BACKUP: Kompletter aktueller Stand sichern
**Status:** ✅ ERLEDIGT  
**Abgeschlossen:** 12. Nov 2025, 19:57
**Details:** 
- Webroot: 246 MB → `pi-backups/2025-11-12/webroot/`
- Configs: 36 KB → `pi-backups/2025-11-12/configs/`
- Git committed & gepusht (commit a4f0f3c)

**Aufgaben:**
- [x] Pi-Webroot backupen: `/var/www/html/` ✅
- [x] Pi-Configs backupen: `/etc/hostapd`, `/etc/dnsmasq.conf`, `/etc/nginx` ✅
- [x] Lokale Dateien committen ✅

**Befehle:**
```bash
# Backup-Verzeichnis erstellen
mkdir -p pi-backups/$(date +%F)

# Webroot sichern
rsync -avz cosmic@cosmicpi.local:/var/www/html/ pi-backups/$(date +%F)/webroot/

# Configs sichern
rsync -avz cosmic@cosmicpi.local:/etc/hostapd/ pi-backups/$(date +%F)/configs/hostapd/
rsync -avz cosmic@cosmicpi.local:/etc/dnsmasq.conf pi-backups/$(date +%F)/configs/
rsync -avz cosmic@cosmicpi.local:/etc/nginx/ pi-backups/$(date +%F)/configs/nginx/

# Lokalen Stand committen
git add -A
git commit -m "Pre-exhibition backup: vignettes, icons, deployment ready"
```

---

### 2. 🎬 Hooke Video aktualisieren & deployen
**Status:** ⏸️ Nicht gestartet  
**Abhängigkeit:** Nach Backup!

**Aufgaben:**
- [ ] Neues `Robert_Hooke.mp4` Video bereitlegen
- [ ] Videolänge mit `ffprobe` checken
- [ ] Video auf Pi deployen
- [ ] Service Worker Cache löschen auf iPads

**Befehle:**
```bash
# Videolänge checken
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 videos/Robert_Hooke.mp4

# Video deployen
scp videos/Robert_Hooke.mp4 cosmic@cosmicpi.local:/home/cosmic/site/videos/
ssh cosmic@cosmicpi.local "sudo cp /home/cosmic/site/videos/Robert_Hooke.mp4 /var/www/html/videos/"
```

**Safari Console (iPad):**
```javascript
navigator.serviceWorker.getRegistrations().then(r => r.forEach(reg => reg.unregister())).then(() => caches.keys()).then(keys => Promise.all(keys.map(k => caches.delete(k)))).then(() => location.reload(true));
```

---

### 3. ⏱️ Video-Längen prüfen & Arduino anpassen
**Status:** ⏸️ Nicht gestartet  
**Abhängigkeit:** Nach Video-Update

**Aufgaben:**
- [ ] Alle 3 Videos mit `ffprobe` checken (Pasteur, Hooke, Leeuwenhoek)
- [ ] Arduino `.ino` Dateien anpassen: `VIDEO_DURATION_MS`
- [ ] Arduino Code compilieren & testen

**Dateien:**
- `arduino_variants/pasteur_index/pasteur_index.ino`
- `arduino_variants/robert_hooke_index01/robert_hooke_index01.ino`
- `arduino_variants/van_leevenhoek_index02/van_leevenhoek_index02.ino`

**Befehle:**
```bash
# Alle Videos checken
for video in videos/*.mp4; do
  echo "=== $video ==="
  ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video"
done
```

---

## 🟡 WICHTIG - VOR AUSSTELLUNG

### 4. 📱 iPad Settings für Ausstellung optimieren
**Status:** ⏸️ Nicht gestartet

**Checkliste pro iPad:**
- [ ] **Auto-Lock:** Aus (Einstellungen → Anzeige & Helligkeit → Automatische Sperre → Nie)
- [ ] **Notifications:** Alle aus (Einstellungen → Mitteilungen → Alle Apps aus)
- [ ] **Guided Access:** Aktivieren (Einstellungen → Bedienungshilfen → Geführter Zugriff)
- [ ] **Helligkeit:** 80-100% fest einstellen
- [ ] **Nicht stören:** Permanent an
- [ ] **App-Updates:** Automatisch aus
- [ ] **Safari Autofill:** Aus
- [ ] **Safari History:** Löschen vor Installation

**Dokumentieren in:** `MANUAL_DE.md` + `CHEATSHEET.md`

---

### 5. 📋 CHEATSHEET.md erstellen (Museumspersonal)
**Status:** ⏸️ Nicht gestartet

**Inhalt (1 Seite!):**
- WiFi-Name & Passwort
- Pi neustarten: Stecker ziehen, 10 Sek warten, einstecken
- iPad neustarten: Power + Home Button
- PWA neu installieren: Kurz-Anleitung
- Notfall-Kontakte
- **KEINE** technischen Details!

**Datei:** `CHEATSHEET.md` (Root-Verzeichnis)

---

### 6. 📖 MANUAL_DE.md aktualisieren
**Status:** ⏸️ Nicht gestartet

**Zu aktualisieren:**
- [ ] Icon-Pfade (jetzt absolute Pfade `/icons/...`)
- [ ] Vignetten-Effekte erwähnen
- [ ] iPad Settings Checkliste einfügen
- [ ] Service Worker Cache-Lösch-Befehle
- [ ] Troubleshooting: Hotspot-Delay ~5min nach Power Cycle

---

### 7. 📖 MANUAL_EN.md aktualisieren
**Status:** ⏸️ Nicht gestartet  
**Abhängigkeit:** Nach MANUAL_DE.md

Synchron mit deutscher Version aktualisieren.

---

## 🟢 OPTIONAL - Nice-to-have

### 8. ⚡ Hotspot-Verzögerung dokumentieren/testen
**Status:** ⏸️ Nicht gestartet

**Problem:** Nach Power Cycle dauert es ~5min bis Hotspot aktiv ist.

**Aufgaben:**
- [ ] Test: Pi neustarten, Zeit messen bis WiFi sichtbar
- [ ] In Troubleshooting dokumentieren
- [ ] Optional: Boot-Script checken (`/etc/rc.local`, systemd services)

---

### 9. 💾 SD-Card Image erstellen
**Status:** ⏸️ Nicht gestartet  
**Abhängigkeit:** Alle Updates fertig!

**Anleitung:** `docs/SD_CARD_IMAGE_CREATION.md`

**Schritte:**
1. Pi aufräumen (Logs löschen, Cache leeren)
2. SSH-Keys entfernen
3. Shutdown
4. SD-Karte rausnehmen
5. `dd` Image erstellen
6. Komprimieren & Checksumme

---

### 10. 🧹 Repo aufräumen
**Status:** ⏸️ Nicht gestartet

**Aufgaben:**
- [ ] `build/` artifacts löschen (oder in .gitignore)
- [ ] Alte Backups entfernen
- [ ] Unnötige Dateien löschen
- [ ] Git commit: "Exhibition ready - cleaned repo"

---

## 📝 NOTIZEN

### Bekannte Probleme
- **Icons:** iOS zeigt trotz korrekter Verlinkung manchmal Screenshots statt Icons. Neustart hilft manchmal, manchmal nicht. Dokumentiert in TROUBLESHOOTING.md
- **Hotspot Delay:** ~5min nach Neustart ist normal (systemd service startup)

### Deployment-Befehle (Referenz)
```bash
# Website deployen
./pi-deployment/deploy-website.sh

# Nur HTML-Dateien
scp index*.html cosmic@cosmicpi.local:/home/cosmic/site/
ssh cosmic@cosmicpi.local "sudo cp /home/cosmic/site/index*.html /var/www/html/"

# Service Worker refreshen (Safari Console)
navigator.serviceWorker.getRegistrations().then(r => r.forEach(reg => reg.unregister())).then(() => caches.keys()).then(keys => Promise.all(keys.map(k => caches.delete(k)))).then(() => location.reload(true));
```

---

**Zuletzt aktualisiert:** 12. November 2025, 20:00
