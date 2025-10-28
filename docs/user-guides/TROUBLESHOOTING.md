# 🔧 Troubleshooting Guide

**Quick fixes for common problems**

---

## 🔴 WiFi Network Not Appearing

### Problem
Can't see "winzige_giganten" WiFi network on iPad.

### Solutions

**1. Wait Longer**
- First boot takes 3-5 minutes
- Green LED should be blinking
- Wait 5 full minutes before troubleshooting

**2. Check Power**
- Is the red LED on? (power indicator)
- Try different power outlet
- Try different USB cable
- Use 2.5A or higher power supply

**3. Restart the Pi**
- Unplug power
- Wait 10 seconds
- Plug back in
- Wait 3 minutes

**4. Check SD Card**
- Remove and reinsert SD card
- Make sure it clicks into place
- Try reflashing the SD card

---

## 📶 Connected to WiFi But Page Won't Load

### Problem
iPad connects to WiFi but Safari shows "Cannot Connect to Server"

### Solutions

**1. Try Manual Address**
- Open Safari
- Type exactly: `192.168.4.1`
- Press Go

**2. Forget and Reconnect**
- iPad Settings → WiFi
- Tap (i) next to "winzige_giganten"
- Tap "Forget This Network"
- Reconnect with password: `winzigegiganten`

**3. Disable Cellular Data**
- Settings → Cellular
- Turn off "Cellular Data"
- This forces iPad to use WiFi

**4. Try Different Browser**
- Use Safari (recommended)
- Chrome/Firefox might have issues with captive portals

---

## 🎬 Videos Won't Play

### Problem
Exhibition page loads but videos don't play or are black screen.

### Solutions

**1. Check Video Format**
- Videos must be MP4 (H.264 codec)
- Use HandBrake to convert videos
- Keep videos under 200MB for smooth playback

**2. Wait for Loading**
- Large videos take time to buffer
- Look for loading spinner
- Be patient on first load

**3. Check Video Files on Pi**
```bash
ssh cosmic@cosmicpi.local
ls -lh /home/cosmic/site/videos/
```
- Files should exist
- Should not be 0 bytes
- Should be .mp4 format

**4. Clear Cache**
- Safari → Clear History and Website Data
- Reconnect to WiFi
- Load page again

---

## 📱 PWA Won't Install on Homescreen

### Problem
"Add to Home Screen" option is grayed out or doesn't appear.

### Solutions

**1. Use Safari**
- Only Safari supports PWA on iOS
- Chrome/Firefox won't work

**2. Check manifest.json**
- Make sure file exists in root folder
- Check for typos in JSON syntax
- Validate at [jsonlint.com](https://jsonlint.com/)

**3. Check Icons**
- Icons must exist in `icons/` folder
- Must be exact filenames: icon-192.png, icon-512.png
- Must be valid PNG files

**4. Hard Refresh**
- In Safari, hold Reload button
- Select "Request Desktop Website"
- Then try adding to homescreen

---

## 🔄 App Won't Work Offline

### Problem
PWA works when connected but fails when WiFi is off.

### Solutions

**1. Load Everything First**
- Connect to WiFi
- Open app
- Let ALL videos buffer completely
- Play each video once
- Now turn off WiFi

**2. Check Service Worker**
- Open Safari Developer Tools (if connected to Mac)
- Check Console for errors
- Look for service worker registration

**3. Reinstall PWA**
- Delete app from homescreen
- Clear Safari cache
- Reconnect to WiFi
- Reinstall PWA
- Load all content again

---

## 🔥 Pi Gets Too Hot

### Problem
Pi case is very hot to touch, or Pi shuts down randomly.

### Solutions

**1. Improve Ventilation**
- Don't cover the Pi
- Remove from enclosed spaces
- Add ventilation holes to case

**2. Add Cooling**
- Add heatsinks (small aluminum stickers)
- Add small fan (5V USB fan)
- Available for $5-10 online

**3. Check Temperature**
```bash
ssh cosmic@cosmicpi.local
vcgencmd measure_temp
```
- Normal: 40-50°C
- Warm: 50-65°C (okay for short periods)
- Hot: 65°C+ (add cooling!)

**4. Reduce Load**
- Limit to fewer iPads
- Use lower resolution videos
- Turn off unnecessary services

---

## 💥 Pi Completely Unresponsive

### Problem
No LEDs, no WiFi, Pi seems dead.

### Solutions

**1. Power Cycle**
- Unplug power
- Wait 30 seconds
- Check SD card is inserted properly
- Plug power back in

**2. Check Power Supply**
- Red LED should light up immediately
- If no red LED: power supply problem
- Try different power supply (2.5A minimum)
- Try different USB cable

**3. Check SD Card**
- Remove SD card
- Check for physical damage
- Try reflashing the image
- Try different SD card

**4. Hardware Failure**
- If nothing works, Pi might be damaged
- Try different Raspberry Pi
- SD card might be corrupted

---

## 🐌 Slow Performance / Laggy Videos

### Problem
Videos stutter, interface is slow, long loading times.

### Solutions

**1. Reduce Video Size**
- Compress videos more
- Lower resolution (720p instead of 1080p)
- Use HandBrake with "Fast" preset

**2. Optimize Videos**
- Use H.264 codec (not H.265)
- Use "Web Optimized" option when encoding
- Keep bitrate reasonable (3-5 Mbps)

**3. Check SD Card Speed**
- Use Class 10 or UHS-I SD cards
- Cheap/slow cards cause lag
- SanDisk and Samsung are reliable

**4. Limit Concurrent Users**
- Default limit is 5 iPads
- Reduce if experiencing lag
- See [CUSTOMIZATION_GUIDE.md](CUSTOMIZATION_GUIDE.md)

---

## 🚫 Can't Connect More iPads

### Problem
"Unable to join network" after 5 iPads connected.

### Solution

**This is by design!** Default limit is 5 devices.

**To change the limit:**
```bash
ssh cosmic@cosmicpi.local
sudo nano /etc/hostapd/hostapd.conf
```

Find and change:
```
max_num_sta=5
```

To higher number (e.g., `max_num_sta=10`)

Also update DHCP range:
```bash
sudo nano /etc/dnsmasq.d/10-wg-ap.conf
```

Change:
```
dhcp-range=192.168.4.10,192.168.4.14,255.255.255.0,24h
```

To accommodate more devices:
```
dhcp-range=192.168.4.10,192.168.4.19,255.255.255.0,24h
```
(This allows 10 devices: .10 through .19)

**Reboot:**
```bash
sudo reboot
```

---

## 🔐 Forgot WiFi Password

### Problem
Can't remember the WiFi password.

### Default Credentials
- **WiFi Name**: `winzige_giganten`
- **Password**: `winzigegiganten`
(all lowercase, no spaces)

### To Change Password
```bash
ssh cosmic@cosmicpi.local
sudo nano /etc/hostapd/hostapd.conf
```

Find and change:
```
wpa_passphrase=winzigegiganten
```

Save, then reboot:
```bash
sudo reboot
```

---

## 📡 Can't SSH Into Pi

### Problem
`ssh cosmic@cosmicpi.local` doesn't work.

### Solutions

**1. Check Connection**
- Are you connected to the Pi's WiFi?
- Can't SSH from outside the network

**2. Try IP Address**
```bash
ssh cosmic@192.168.4.1
```

**3. Check SSH is Enabled**
- SSH should be enabled by default in the image
- If not, you'll need to enable it via SD card

**4. Check Username/Password**
- Default username: `cosmic`
- Default password: (set during image creation)
- Try: `raspberry` (old default)

---

## 💾 SD Card Corruption

### Problem
Pi won't boot, file system errors, strange behavior.

### Solutions

**1. Backup If Possible**
- If Pi boots at all, backup important files
- Copy `/home/cosmic/site/` folder

**2. Reflash SD Card**
- Download fresh image
- Reflash completely
- Don't try to repair corruption

**3. Prevent Future Corruption**
- Use quality SD cards (SanDisk, Samsung)
- Don't pull power during writes
- Consider read-only mode for production
- Make regular backups

---

## 🆘 Still Having Problems?

### Get Help

**1. Check Logs**
```bash
ssh cosmic@cosmicpi.local
tail -f /var/log/exhibition/watchdog.log
```

**2. System Status**
```bash
sudo systemctl status hostapd dnsmasq nginx
```

**3. Report Issue**
- Visit [GitHub Issues](https://github.com/CosmicCannibalism/2025_kub_winzige_giganten/issues)
- Include:
  - What you tried
  - Error messages
  - Log output
  - Photos of problem

**4. Start Fresh**
- Sometimes fastest solution is to reflash SD card
- Backup your customizations first!

---

## 📞 Emergency Exhibition Day Fixes

### Quick Fixes When Visitors Are Waiting

**Problem: Nothing Works**
- Unplug Pi for 30 seconds, plug back in
- Wait 3 minutes
- 90% of problems fixed by this!

**Problem: One iPad Not Working**
- Restart that iPad (hold power button)
- Forget WiFi network and reconnect
- Try different iPad

**Problem: Pi Won't Boot**
- Have spare SD card ready!
- Keep backup SD card with working image
- Swap cards in 30 seconds

**Problem: Visitors Can't Connect**
- Write WiFi name and password on a sign
- Show them exactly where to tap
- Have staff member demonstrate

---

**💡 Pro Tip: Test Everything Day Before Exhibition!**

Run through entire visitor experience:
- Connect iPad
- Install PWA
- Test offline
- Repeat with each iPad
- Leave running overnight
- Check again in morning

**🎯 Most problems happen from:**
1. Not waiting long enough for boot
2. Wrong WiFi password
3. Videos not fully buffered
4. Cheap SD cards or power supplies

**Prevention is easier than troubleshooting!**