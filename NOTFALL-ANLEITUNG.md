# 🚨 NOTFALL-ANLEITUNG: Winzige Giganten Exhibition

## Problem: System ist ausgefallen / iPads zeigen keine Videos

### Symptome:
- iPads zeigen "Keine Verbindung" oder schwarzen Screen
- Exhibition-App lädt nicht
- Videos spielen nicht ab

---

## ✅ LÖSUNG - Schritt für Schritt

### 1. Raspberry Pi prüfen

**Wo steht der Pi?**
- Kleiner Computer in schwarzem Gehäuse
- Sollte rotes LED-Licht zeigen (Power)
- Grünes LED blinkt (Activity)

**Was tun:**
- ✅ Ist das Stromkabel eingesteckt?
- ✅ Leuchtet das rote LED?
- ❌ **Kein Licht:** Stecker prüfen, evtl. Sicherung ausgefallen

**Falls Pi aus ist:**
1. Stromkabel einstecken
2. **2 Minuten warten** bis Pi hochgefahren ist
3. Weiter mit Schritt 2

---

### 2. iPads neu verbinden

**Auf JEDEM iPad einzeln:**

1. **Home-Button** drücken (Hauptbildschirm)

2. **Einstellungen** öffnen (Zahnrad-Symbol)

3. **WLAN** antippen

4. Netzwerk **"winzige_giganten"** suchen und antippen

5. Falls Passwort gefragt: `winzigegiganten` (alles kleingeschrieben, zusammen)

6. **Warten** bis Häkchen erscheint (verbunden)

7. **Zurück zum Home-Screen**

8. **Exhibition-App öffnen** (Icon "Winzige Giganten")

9. **"Start" Button** drücken wenn er erscheint

10. Teaser-Video sollte jetzt laufen ✅

---

### 3. Wenn es immer noch nicht funktioniert

**iPad komplett neu starten:**

1. **Power-Button** gedrückt halten (oben oder seitlich)
2. "Ausschalten" schieben
3. Warten bis iPad aus ist
4. **Power-Button** erneut drücken bis Apple-Logo erscheint
5. Nach Start: Schritt 2 wiederholen

---

## 📞 Kontakt bei anhaltenden Problemen

**Künstler:** [Deine Kontaktdaten hier einfügen]
- Telefon: 
- Email:

**Bitte folgende Infos bereithalten:**
- Welche iPads betroffen? (1, 2, 3 oder alle?)
- Leuchtet der Pi? (rotes LED?)
- Fehlermeldung auf iPads? (Screenshot wenn möglich)

---

## 🔧 Technische Details (für IT-Personal)

**System-Architektur:**
- Raspberry Pi 4 mit WiFi Hotspot "winzige_giganten"
- 3 iPads als Display-Terminals
- PWA-basierte Exhibition App (offline-fähig)
- Hardware Watchdog für Auto-Recovery

**Häufigste Ausfallursachen:**
1. **Stromausfall** → Pi startet automatisch neu (2-3 Min)
2. **WiFi-Überlastung** → Watchdog rebootet System
3. **iPad-Sleep** → App muss neu geöffnet werden

**SSH-Zugang (für Maintenance):**
```bash
# Via Hotspot
ssh cosmic@192.168.4.1

# Via Studio-WLAN (wenn konfiguriert)
ssh cosmic@cosmicpi.local

Passwort: winzigegiganten
```

**Wichtige Services prüfen:**
```bash
sudo systemctl status hostapd nginx watchdog
```

**System-Logs:**
```bash
sudo journalctl -xe
sudo tail -50 /var/log/nginx/access.log
sudo tail -50 /var/log/watchdog-repair.log
```

---

## ⚡ Prävention: USV empfohlen

**Empfehlung:** Unterbrechungsfreie Stromversorgung (USV) für den Raspberry Pi

**Vorteile:**
- Überbrückt kurze Stromausfälle (5-30 Min)
- Verhindert Filesystem-Corruption
- Kosten: ~50-150€

**Geeignete Modelle:**
- APC Back-UPS ES 400
- CyberPower CP425SLG
- Jeder USB-Power-Bank mit 5V/3A Output

---

## ✅ System-Status Check (täglich empfohlen)

**Schnellcheck (2 Minuten):**
1. ✅ Pi LED leuchtet rot
2. ✅ Alle 3 iPads zeigen Videos
3. ✅ Spacebar-Trigger funktioniert auf jedem iPad
4. ✅ Videos laufen flüssig ohne Ruckler

**Bei Problemen:** Diese Anleitung befolgen oder Künstler kontaktieren

---

**Stand:** November 2025  
**Version:** 1.0
