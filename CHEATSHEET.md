# 🎯 QUICK REFERENCE CHEATSHEET
## Winzige Giganten - Installation

---

## 📋 DAILY CHECKLIST

- [ ] Pi läuft (LEDs leuchten)
- [ ] Hotspot "winzige_giganten" sichtbar
- [ ] iPads connected
- [ ] PWA startet vom Homescreen
- [ ] Knopf-Test: Video startet + Relais öffnet

---

## 🚨 TROUBLESHOOTING (1-MINUTE-FIXES)

| Problem | Lösung |
|---------|--------|
| **Hotspot nicht sichtbar** | Warten 3-5 Min (Watchdog repariert) |
| **iPad verbindet nicht** | WLAN vergessen → neu verbinden |
| **Schwarzer Bildschirm** | PWA löschen → neu installieren → **warten bis "Ready to start!"** |
| **Knopf reagiert nicht** | Arduino USB prüfen → neu starten |
| **Video ruckelt** | PWA neu installieren (Videos neu cachen) |
| **Relais öffnet nicht** | Falsches Arduino-Sketch? (siehe unten) |

---

## 🔌 POWER CYCLE (wenn nichts hilft)

1. ⚡ **Pi**: Strom 10 Sek trennen → wieder anschließen
2. ⏰ **Warten**: 3-5 Minuten (System bootet)
3. 📱 **iPad**: WLAN neu verbinden
4. ✅ **Testen**: PWA starten + Knopf drücken

---

## 📱 PWA INSTALLATION (iPad)

```
Safari öffnen
│
├→ http://cosmicpi.local eintippen
│
├→ ⏳ WARTEN bis "Ready to start!" 
│   (Videos werden gecacht, 2-3 Min)
│
├→ Teilen-Button 📤
│
└→ "Zum Home-Bildschirm" 📲
```

**WICHTIG**: Nicht installieren bevor "Ready to start!" erscheint!

---

## 🎬 WELCHE VERSION FÜR WELCHES iPAD?

| iPad | URL | Video | Dauer |
|------|-----|-------|-------|
| **1** | `cosmicpi.local` | Pasteur | 119s |
| **2** | `cosmicpi.local/index01.html` | Robert Hooke | 154s |
| **3** | `cosmicpi.local/index02.html` | Van Leevenhoek | 122s |

---

## 🤖 ARDUINO-SKETCHES (pro Installation)

| Video | Sketch | Relay-Timer |
|-------|--------|-------------|
| Pasteur | `arduino_variants/pasteur_index/` | 120s |
| Robert Hooke | `arduino_variants/robert_hooke_index01/` | 155s |
| Van Leevenhoek | `arduino_variants/van_leevenhoek_index02/` | 125s |

**Falsche Sketch?** → Arduino IDE öffnen → richtiges Sketch hochladen

---

## 📡 NETZWERK INFO

| Item | Value |
|------|-------|
| **Hotspot SSID** | `winzige_giganten` |
| **Passwort** | `giganten2025` |
| **Pi IP (Hotspot)** | `192.168.4.1` |
| **Pi Hostname** | `cosmicpi.local` (nur Studio-WLAN) |
| **Reichweite** | ~4-5 Meter |

---

## 💬 TELEGRAM MONITORING

```
1. Telegram öffnen
2. Bot suchen: @winzige_giganten_bot
3. Senden: /status
4. Erhalten: System-Report
```

**Automatische Alerts**:
- 🚨 Services Down
- 🔄 Pi Reboot
- ✅ Services OK
- 🔴 Healthchecks DOWN (kein Internet)

---

## ⚙️ WATCHDOG (Selbstheilung)

**Überwacht alle 2 Minuten**:
- ✅ Hotspot sendet
- ✅ Services laufen (nginx, hostapd, dnsmasq)
- ✅ Internet (alle 10 Min, auto-reconnect)

**Boot Grace**: Erste 3 Min nach Neustart keine Intervention

**Logs anschauen** (optional):
```bash
ssh cosmic@cosmicpi.local
sudo journalctl -u wg-watchdog.service -f
```

---

## 🛠️ TECHNIKER-COMMANDS (SSH)

```bash
# Status-Check
sudo systemctl status wg-watchdog.service
sudo systemctl status nginx
sudo systemctl status hostapd

# Hotspot-Check
sudo iw dev ap0 info | grep ssid

# Services neu starten
sudo systemctl restart nginx
sudo systemctl restart hostapd
sudo systemctl restart dnsmasq

# Watchdog Logs (live)
sudo journalctl -u wg-watchdog.service -f

# System neu starten
sudo reboot
```

---

## 📞 NOTFALL-KONTAKTE

| Wer | Wie |
|-----|-----|
| **Telegram Bot** | `/status` an @winzige_giganten_bot |
| **Techniker** | [Telefon] / [E-Mail] |
| **Healthchecks** | [Dashboard URL] |

---

## 📝 WÖCHENTLICHE WARTUNG

- [ ] Telegram `/status` → alle Services UP?
- [ ] Hotspot-Reichweite testen
- [ ] Alle iPads: PWA + Knopf testen
- [ ] Relais-Funktion prüfen
- [ ] Pi Temperatur checken (via `/status`)

---

**💡 TIPP**: Dieses Sheet ausdrucken und laminieren für schnellen Zugriff!  
**Version 2.0 - November 2025**
