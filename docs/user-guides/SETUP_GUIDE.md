# 📖 Setup Guide - Exhibition PWA System

**Complete step-by-step guide for non-technical users**

This guide will help you set up your Raspberry Pi exhibition system from start to finish. No programming knowledge required!

## 🛒 What You Need to Buy

### Required Hardware
- **Raspberry Pi Zero 2W** (~$15)
  - *Alternative: Raspberry Pi 3 or 4 also works*
- **MicroSD Card** 32GB or larger (~$10)
  - *Recommended: SanDisk or Samsung brand*
- **USB Power Supply** 5V 2.5A minimum (~$10)
  - *Official Raspberry Pi power supply recommended*
- **iPads** for visitors (you probably have these)

### Optional Hardware
- **Case** for Raspberry Pi (~$5-15)
- **Longer USB cable** if mounting Pi away from outlet

**Total Cost: ~$35-50**

---

## 📥 Step 1: Download the SD Card Image

### Option A: Download Ready-Made Image (Easiest!)

1. Go to the [Releases page](https://github.com/CosmicCannibalism/2025_kub_winzige_giganten/releases)
2. Download the latest `winzige-giganten-exhibition-vX.X.img.gz` file
3. Save it to your computer (usually goes to Downloads folder)

**File size**: About 3GB compressed, 32GB when extracted

### Option B: No Image Available Yet?

If the image isn't released yet, you can build it yourself:
- Follow [PI_SETUP_FROM_SCRATCH.md](../technical/PI_SETUP_FROM_SCRATCH.md)
- Or wait for the image release

---

## 💾 Step 2: Flash the SD Card

### Download Raspberry Pi Imager

1. Go to [raspberrypi.com/software](https://www.raspberrypi.com/software/)
2. Download for your computer:
   - **Mac**: Click "Download for macOS"
   - **Windows**: Click "Download for Windows"
   - **Linux**: Click "Download for Ubuntu"
3. Install it (just double-click and follow prompts)

### Flash the Image

**Important: This will erase everything on the SD card!**

1. Insert your microSD card into your computer
   - *You may need an SD card adapter*
   
2. Open **Raspberry Pi Imager**

3. Click **"Choose OS"**
   - Scroll down to **"Use custom"**
   - Select your downloaded `.img` or `.img.gz` file

4. Click **"Choose Storage"**
   - Select your SD card
   - **Double-check it's the right drive!**

5. Click **"Write"**
   - This takes 10-30 minutes
   - Go get a coffee ☕

6. When done, click **"Continue"**
   - Safely eject the SD card

---

## 🔌 Step 3: First Boot

### Insert Card and Power On

1. **Remove SD card** from your computer
2. **Insert SD card** into Raspberry Pi (slot on bottom/side)
3. **Connect power cable** to the Pi
4. **Wait 2-3 minutes** for first boot
   - Green LED will blink (this is normal!)
   - First boot takes longer (it's setting things up)

### Look for the WiFi Network

After 2-3 minutes:

1. **On your iPad**, open WiFi settings
2. **Look for network**: `winzige_giganten`
3. **If you see it: Success!** ✅ Go to Step 4
4. **If you don't see it**: Wait 2 more minutes, then see [Troubleshooting](TROUBLESHOOTING.md)

---

## 📱 Step 4: Connect First iPad

### Connect to WiFi

1. On your iPad, connect to: **`winzige_giganten`**
2. Enter password: **`winzigegiganten`**
   - *All lowercase, no spaces*
3. iPad will say "No Internet" - **this is normal!**
   - The Pi creates its own network without internet

### Test the Exhibition Page

After connecting to WiFi:

**Option A: Automatic (Captive Portal)**
- Safari should open automatically
- You'll see the exhibition page
- *If this doesn't work, try Option B*

**Option B: Manual**
1. Open Safari on iPad
2. Type in address bar: `192.168.4.1`
3. Press Go
4. You should see the exhibition page

### Install PWA on Homescreen

1. On the exhibition page, tap the **Share button** (box with arrow)
2. Scroll down and tap **"Add to Home Screen"**
3. Type a name (e.g., "Winzige Giganten")
4. Tap **"Add"**
5. The app icon appears on your homescreen!

### Test Offline Mode

1. **Turn off WiFi** on the iPad
2. **Tap the app icon** on homescreen
3. The app should still work!
   - *Videos might not play the first time offline*
   - *Connect to WiFi once more to cache videos*
4. **Turn WiFi back on**
5. Let videos load completely
6. Now it works offline! ✅

---

## 🎨 Step 5: Connect More iPads (Optional)

You can connect up to **5 iPads** at the same time:

### For Second iPad (iPad 2)
1. Connect to `winzige_giganten` WiFi
2. Open Safari and go to: `192.168.4.1/index01.html`
3. Add to homescreen

### For Third iPad (iPad 3)
1. Connect to `winzige_giganten` WiFi
2. Open Safari and go to: `192.168.4.1/index02.html`
3. Add to homescreen

### Why Different Pages?
Each iPad can show different content or the same content - it's up to you! Edit the corresponding HTML files to customize.

---

## ✅ Verification Checklist

Make sure everything works:

- [ ] Pi boots up (green LED blinks)
- [ ] WiFi network "winzige_giganten" appears
- [ ] iPad can connect to WiFi
- [ ] Exhibition page loads in Safari
- [ ] PWA installs to homescreen
- [ ] Videos play smoothly
- [ ] App works offline (after initial cache)
- [ ] Multiple iPads can connect (if needed)

---

## 🎯 Next Steps

### Ready for Exhibition?
- ✅ **Yes!** Mount the Pi, set up iPads, open exhibition
- 📝 **Want to customize?** See [CUSTOMIZATION_GUIDE.md](CUSTOMIZATION_GUIDE.md)
- 🐛 **Having problems?** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### For Your Visitors
- Print the [VISITOR_GUIDE.md](VISITOR_GUIDE.md) as a sign
- Or show them directly - it's very simple!

---

## 💡 Tips for Long-Term Operation

### Physical Setup
- Mount Pi in ventilated location (it gets warm)
- Secure power cable (tape it down)
- Keep Pi away from water/humidity
- Don't stack things on top of Pi

### Power
- Use official Raspberry Pi power supply if possible
- Avoid cheap USB chargers (cause problems)
- Consider UPS for critical exhibitions

### Monitoring
- Check once a week that WiFi is still visible
- System auto-recovers from most issues
- Log files are at `/var/log/exhibition/` if needed

---

## ❓ Common Questions

**Q: Do I need internet for this?**  
A: No! The Pi creates its own WiFi network. No internet needed.

**Q: How long does the battery last?**  
A: The Pi needs constant power (wall outlet). iPads are on battery.

**Q: Can visitors use their phones?**  
A: Yes! Works on iPhones, Android, any device with a web browser.

**Q: What if the Pi crashes?**  
A: Unplug power, wait 10 seconds, plug back in. It auto-recovers.

**Q: How do I turn it off?**  
A: Just unplug the power. The Pi is designed for this.

---

**🎉 Congratulations! Your exhibition system is ready!**

Need help? Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)