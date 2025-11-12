# Manual for Museum Staff
## Winzige Giganten - Interactive Exhibition

**Version 2.0 - November 2025**

---

## 1. Installation Startup

### Initial Setup
1. **Power on Raspberry Pi**
   - Connect power supply (USB-C adapter, min. 3A recommended)
   - Wait approx. 3 minutes for complete system boot
   - Green LED blinks = system activity, Red LED on = power supply

2. **Check Network**
   - Pi automatically provides hotspot "winzige_giganten"
   - Password: `winzigegiganten`
   - ⏰ **IMPORTANT:** After reboot it takes approx. **5 minutes** until hotspot is active
   - If studio WiFi available: Pi auto-connects for internet access
   - Internet is optional - installation works offline

3. **Prepare iPads**
   - Power on and unlock iPads
   - Open WiFi settings
   - Connect to "winzige_giganten" (Password: `winzigegiganten`)
   - Launch PWA app from homescreen (see Section 2)

### Daily Startup
1. Raspberry Pi is already on (24/7 operation recommended)
2. Unlock iPads
3. Tap PWA app from homescreen
4. System is immediately ready

---

## 2. iPad Setup & PWA Installation

### First-Time Installation (once per iPad)

1. **Open Safari** (important: only Safari supports PWA!)
2. **Enter address**: 
   - iPad 1: `https://192.168.4.1/index.html` (Pasteur)
   - iPad 2: `https://192.168.4.1/index01.html` (Robert Hooke)
   - iPad 3: `https://192.168.4.1/index02.html` (Van Leeuwenhoek)
   - Alternative: `http://cosmicpi.local` (if mDNS works)
3. **Wait for video caching**:
   - Overlay shows "Preparing exhibition, please wait…"
   - Progress displayed: "Caching teaser.mp4… 25%"
   - Then: "Caching Pasteur.mp4…", "Caching Robert_Hooke.mp4…" etc.
   - Complete: "Ready to start!" → Start button appears
   - **Duration**: Approx. 2-3 minutes (one-time, then everything offline!)
   
4. **Install as app**:
   - Tap **Share button** (rectangle with arrow pointing up)
   - Scroll to **"Add to Home Screen"**
   - Confirm name (e.g. "WG v1" for Version 1)
   - **Done** - App icon appears on homescreen

### Which Version for Which iPad?
- **index.html** = Pasteur Video (119s)
- **index01.html** = Robert Hooke Video (154s) 
- **index02.html** = Van Leevenhoek Video (122s)

Each iPad needs its own version - use corresponding URL on first access.

### Reinstall PWA (if problems occur)
1. **Long-press** PWA icon on homescreen
2. Select **"Remove App"**
3. Open Safari and repeat steps above
4. Videos will be re-cached (progress shown)

---

## 3. Exhibition Operation

### Normal Operation
1. **Teaser video** loops automatically
2. **Visitor presses mechanical button** (Arduino sends spacebar signal)
3. **Main video starts** (Pasteur/Robert Hooke/Van Leevenhoek depending on installation)
4. **Relay opens during video** (microscope view accessible)
5. **After video ends**: Return to teaser, relay closes
6. **Next visitor** can press button again

### Offline Capability
- **All videos are cached** after initial PWA installation
- **Hotspot fails?** App continues working (videos play from cache)
- **Power loss?** After Pi restart: iPads reconnect to hotspot automatically
- **No internet needed** for daily operation (only for monitoring)

---

---

## 4. Status System & Monitoring

### Telegram Status Query
- Open Telegram and message the bot `@winzige_giganten_bot`.
- Send `/status` → Receive instant system report (services, WiFi, temperature, memory, devices).

### Automatic Notifications
- In case of issues (service failure, power outage), Telegram sends a message:
  - `🚨 Alert - Services Down`
  - `🔄 Pi Hochgefahren` (Pi booted)
  - `✅ Resolved - Services OK`
- Healthchecks.io monitors the Pi and sends alerts:
  - `🔴 DOWN` (Pi offline - no internet)
  - `✅ UP` (Pi back online)

### Watchdog System (automatic self-healing)
The Pi monitors itself every 2 minutes:
- **Check hotspot**: SSID "winzige_giganten" must be broadcasting
- **Check services**: nginx, hostapd, dnsmasq must be running
- **Check internet**: Every 10 minutes, automatic reconnect on failure
- **Boot grace period**: 3 minutes after restart no intervention
- **Automatic repair**: Restarts failed services

**View logs** (optional, for technicians):
```bash
ssh cosmic@cosmicpi.local
sudo journalctl -u wg-watchdog.service -f
```

---

## 5. Troubleshooting

### Problem: PWA shows black screen when starting video
**Cause**: Videos not fully cached  
**Solution**:
1. Delete PWA from homescreen
2. Open Safari → `http://cosmicpi.local`
3. **Wait** until "Ready to start!" appears (don't install before!)
4. Add to Home Screen again
5. Videos are now cached

### Problem: Hotspot "winzige_giganten" not visible
**Cause**: Pi booting (takes ~5min), power outage, or watchdog repairing  
**Solution**:
1. **After reboot:** Wait 5 minutes (normal startup time!)
2. Check Pi LEDs: Green blinking = active, Red solid = power
3. If still not visible after 10min: Restart Pi (briefly disconnect power)
4. Range: max. 4-5m depending on obstacles

### Problem: iPad won't connect to hotspot
**Cause**: WiFi cache or wrong password  
**Solution**:
1. iPad: Settings → WiFi → "winzige_giganten" info button (i)
2. "Forget This Network" → Confirm
3. Reconnect with password: `winzigegiganten`

### Problem: Videos load slowly or stutter
**Cause**: Videos loaded from network, not from cache  
**Solution**:
1. Reinstall PWA (see above)
2. After installation: **Play through all videos once**
3. They are now fully cached

### Problem: Healthchecks.io reports "DOWN" but hotspot works
**Cause**: Pi has no internet (e.g. too far from studio router)  
**Solution**:
1. **Not a problem** for exhibition - hotspot continues working!
2. Only monitoring affected
3. Move Pi closer to router if internet monitoring desired
4. Watchdog automatically attempts reconnect every 10 min

### Problem: Mechanical button doesn't respond
**Cause**: Arduino not connected or wrong relay timing  
**Solution**:
1. Check USB connection Arduino → iPad
2. Restart Arduino (briefly disconnect USB)
3. Verify correct Arduino code for index (see Arduino documentation)

### Problem: Relay doesn't open/close on time
**Cause**: Wrong Arduino sketch for video length  
**Solution**:
- **Pasteur** (119s): Use `arduino_variants/pasteur_index/`
- **Robert Hooke** (154s): Use `arduino_variants/robert_hooke_index01/`  
- **Van Leevenhoek** (122s): Use `arduino_variants/van_leevenhoek_index02/`
- Upload correct sketch to Arduino (see `arduino_variants/README.md`)

---

## 6. Maintenance & Updates

### Regular Checks (weekly recommended)
- [ ] Query Telegram `/status` - all services UP?
- [ ] Test hotspot range (with smartphone)
- [ ] Each iPad: Launch PWA and test video button
- [ ] Check relay function (opens/closes during video?)

### System Updates (technician only)
Updates should only be performed outside opening hours:
```bash
ssh cosmic@cosmicpi.local
sudo apt update && sudo apt upgrade -y
sudo reboot
```

### Deploy PWA Updates
For new app versions:
1. Deploy files to Pi (SSH)
2. **All iPads**: Reinstall PWA (delete old, add new)
3. Videos will be re-cached

---

## 3.5 Guided Access (App-Lock for Exhibition)

To lock iPads in single-app mode (prevents visitors from accessing Settings, Home, etc.):

### Setup Guided Access Code (once)
1. iPad: **Settings** → **Accessibility** → **Guided Access**
2. Enable **Guided Access**
3. Set **Passcode Settings** → Create 4-digit code (e.g., `1234`)

### Start Guided Access (before exhibition)
1. Open PWA from homescreen (full-screen mode)
2. **Press Power button 3 times quickly** → Guided Access menu appears
3. Optional: **Options** → Disable **Touch** (if button-only interaction)
4. Tap **Start** (top right)
5. iPad is now locked to this app!

### End Guided Access (after exhibition)
1. **Press Power button 3 times quickly**
2. Enter passcode
3. Tap **End** (top left)

**Important:** Test this before opening hours! Without the passcode, you cannot exit the app.

---

## 4. Technical Details

### 4.1 PWA Features
- **Vignette Effects**: Cinematic darkening at edges
  - Teaser: 67% transparent → 21% black radial gradient
  - Main video: 63% transparent → 27% black radial gradient
- **Icons**: 180x180px (iPad), 192x192px, 512x512px for each scientist
  - Absolute paths: `/icons/icon-pasteur-180.png` etc.
  - Cached by Service Worker v21
- **Offline Support**: Videos fully cached after first load
- **Auto-Replay**: Videos loop automatically

### 4.2 Known Problems & Workarounds

#### Icon shows screenshot instead of logo (iOS bug)
**Cause**: iOS caches icon screenshots aggressively  
**Workaround**:
1. iPad: Settings → Safari → Clear History and Website Data
2. Restart iPad (hold Power + Volume, slide to power off)
3. Reconnect to hotspot
4. Reinstall PWA (delete old, Safari → URL → Share → Add to Home Screen)
⚠️ May not work 100% - iOS icon cache persists sometimes

#### Hotspot takes 5 minutes after boot
**Cause**: systemd service startup delays (hostapd, dnsmasq)  
**Solution**: Wait patiently, this is normal behavior after power cycle

#### PWA shows black screen
**Cause**: Service Worker cache corrupted or video path wrong  
**Solution**:
1. Safari: Open developer console (Settings → Safari → Advanced → Web Inspector)
2. Run: `navigator.serviceWorker.getRegistrations().then(r => r.forEach(reg => reg.unregister()))`
3. Run: `caches.keys().then(keys => Promise.all(keys.map(k => caches.delete(k))))`
4. Reload page: `location.reload(true)`
5. Reinstall PWA

---

## 7. Technical Specifications

### Hardware
- **Raspberry Pi 4** (4GB RAM recommended)
- **Arduino Leonardo** (or compatible with Keyboard library)
- **Relay module** (5V, controlled via Pin 7)
- **Mechanical button** (pull-up on Pin 6)
- **iPads** (iOS 13+ for PWA support)

### Software
- **OS**: Raspberry Pi OS Lite (Debian-based)
- **Webserver**: nginx
- **Hotspot**: hostapd + dnsmasq
- **Monitoring**: Telegram Bot, healthchecks.io, exhibition-monitor.service
- **Watchdog**: wg-watchdog.service (2min interval)
- **PWA**: Service Worker v21 with full video precaching

### Network
- **Hotspot SSID**: `winzige_giganten`
- **Password**: `winzigegiganten`
- **IP Range**: 192.168.4.1 - 192.168.4.254
- **Pi Hotspot IP**: 192.168.4.1
- **mDNS**: cosmicpi.local (works only in studio WiFi)
- **Boot Delay**: ~5 minutes until hotspot active after power on

### Video Assets
- **teaser.mp4**: 12s, 15MB (loop)
- **Pasteur.mp4**: 119s, 45MB (index.html)
- **Robert_Hooke.mp4**: 154s, 67MB (index01.html)
- **Van_Leevenhoek.mp4**: 122s, 80MB (index02.html)

---

## 8. Contact & Support

### First Aid
1. Use **Telegram bot**: `/status` to @winzige_giganten_bot
2. Read this manual (Section 5 - Troubleshooting)
3. Restart Pi (often solves the problem)

### Technical Support
- **Email**: [Your Support Email]
- **Phone**: [Your Support Number]
- **Have ready before contact**:
  - Which iPad (which version: index/index01/index02)?
  - Error description
  - Telegram `/status` output (screenshot)

---

## Appendix: Quick Reference Cheatsheet

### 🚀 Quick Start
1. Power on Pi (wait 5 min)
2. Connect iPad to "winzige_giganten" (PW: `winzigegiganten`)
3. Launch PWA from homescreen

### 📱 PWA Installation
Safari → `https://192.168.4.1/index.html` (or index01/index02) → Share → "Add to Home Screen"

### 🔧 Essential Commands (Technician)
```bash
# Check status
sudo systemctl status wg-watchdog.service
sudo journalctl -u wg-watchdog.service -n 50

# Restart services
sudo systemctl restart nginx
sudo systemctl restart hostapd
sudo systemctl restart dnsmasq

# Check hotspot SSID
sudo iw dev ap0 info | grep ssid
```

### 📞 Emergency Contacts
- Telegram: `/status` to @winzige_giganten_bot
- Healthchecks: [Healthchecks.io Dashboard URL]
- Technician: [Contact Details]

---

**This manual can be printed as PDF and kept at the exhibition location.**  
**Version 2.0 - November 2025 - CosmicCannibalism**
