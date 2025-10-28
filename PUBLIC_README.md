# 🎨 Raspberry Pi Offline Exhibition PWA Template

**Easy-to-use WiFi hotspot + web server for art exhibitions**

This template turns a Raspberry Pi into a **standalone exhibition system** that serves a Progressive Web App to iPads without requiring internet. Perfect for museums, galleries, and art installations.

## 📦 What You Get

- **Ready-to-use SD card image** for Raspberry Pi Zero 2W
- **Example PWA**: "Winzige Giganten" exhibition app with video playback
- **Complete guides** for non-technical users
- **Automatic WiFi hotspot** - visitors connect and install the app
- **Offline operation** - works for months without internet
- **Multi-device support** - up to 5 iPads simultaneously

## 🚀 Quick Start (3 Steps!)

### Step 1: Flash the SD Card
1. Download the SD card image: `winzige-giganten-exhibition.img` (link in releases)
2. Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
3. Flash the image to a 32GB+ SD card
4. Insert card into Raspberry Pi Zero 2W

### Step 2: Power On
1. Connect Raspberry Pi to power (5V 2.5A+ USB adapter)
2. Wait 2-3 minutes for boot
3. Look for WiFi network: **"winzige_giganten"**

### Step 3: Connect iPads
1. Connect iPad to "winzige_giganten" WiFi
   - Password: `winzigegiganten`
2. Open Safari, it will show the exhibition page automatically
3. Tap "Share" → "Add to Home Screen"
4. Done! The app works offline

## 📖 User Guides

### For Exhibition Organizers
- **[SETUP_GUIDE.md](docs/user-guides/SETUP_GUIDE.md)** - Complete setup from scratch
- **[CUSTOMIZATION_GUIDE.md](docs/user-guides/CUSTOMIZATION_GUIDE.md)** - Change content, videos, text
- **[TROUBLESHOOTING.md](docs/user-guides/TROUBLESHOOTING.md)** - Fix common issues
- **[VISITOR_GUIDE.md](docs/user-guides/VISITOR_GUIDE.md)** - Instructions for visitors

### For Technical Users
- **[TECHNICAL_REFERENCE.md](docs/technical/TECHNICAL_REFERENCE.md)** - Full system architecture
- **[PI_SETUP_FROM_SCRATCH.md](docs/technical/PI_SETUP_FROM_SCRATCH.md)** - Build without image
- **[DEVELOPMENT.md](docs/technical/DEVELOPMENT.md)** - Modify and extend the system

## 🎯 What Can You Customize?

### Easy Changes (No Coding)
- ✅ Replace videos (just upload new .mp4 files)
- ✅ Change WiFi name and password
- ✅ Modify text and titles
- ✅ Replace logos and icons
- ✅ Adjust colors and fonts

### Advanced Changes (Some Coding)
- Custom video controls
- Multiple exhibition pages
- Arduino hardware integration
- Analytics and monitoring

## 💾 Files You Need

### Download the SD Card Image
**Option A: Ready-to-Use Image (Recommended)**
- File: `winzige-giganten-exhibition-v1.0.img.gz` (coming soon in releases)
- Size: ~3GB compressed, 32GB when flashed
- Includes: Complete system + example exhibition content

**Option B: Build From Source**
- Follow [PI_SETUP_FROM_SCRATCH.md](docs/technical/PI_SETUP_FROM_SCRATCH.md)
- Use deployment scripts in `pi-deployment/`

## 🔧 System Features

### For Visitors
- 📱 Install PWA on iPad homescreen
- 🎬 Smooth offline video playback
- 📶 No internet required
- 🔋 Battery-friendly design

### For Organizers
- ⚡ Automatic startup (plug and play)
- 🔄 Auto-recovery from crashes
- 🌡️ Temperature monitoring
- 📊 Connection logging
- 🔒 Max 5 devices (customizable)
- ⏰ Designed for 3-5 month operation

## 📁 Project Structure

```
📦 Exhibition PWA Template
├── 📄 index.html          # Main exhibition page (iPad 1)
├── 📄 index01.html        # Exhibition page for iPad 2
├── 📄 index02.html        # Exhibition page for iPad 3
├── 📄 manifest.json       # PWA configuration
├── 📄 script.js           # JavaScript (shared)
├── 📄 style.css           # Styling (shared)
├── 🔧 sw.js              # Service Worker (offline magic)
├── 📁 videos/            # Your video content
├── 📁 icons/             # App icons
├── 📁 docs/              # All documentation
│   ├── 📁 user-guides/   # For non-technical users
│   ├── 📁 technical/     # For developers
│   └── 📁 images/        # Guide screenshots
└── 📁 pi-deployment/     # Raspberry Pi scripts
```

## 🎨 Example: Winzige Giganten Exhibition

This template includes a complete working example from the "Winzige Giganten" art exhibition at the Museum of Art and Bread, Ulm.

**What it shows:**
- Video-based art installation
- Multi-iPad support (3 iPads)
- Offline video playback
- Arduino hardware integration (optional)

**Use it as:**
- Starting template for your own exhibition
- Learning example
- Ready-to-deploy system (just change the content!)

## 💡 Use Cases

This template is perfect for:
- 🎨 **Art Exhibitions** - Video installations, interactive art
- 🏛️ **Museums** - Offline multimedia guides
- 📚 **Educational Installations** - Schools, science centers
- 🎪 **Events** - Temporary installations, festivals
- 🏢 **Corporate** - Trade show displays, product demos

## ⚙️ Technical Specs

- **Hardware**: Raspberry Pi Zero 2W (or Pi 3/4)
- **Storage**: 32GB+ microSD card
- **Power**: 5V 2.5A USB power supply
- **Network**: Built-in WiFi (no internet needed)
- **Clients**: Up to 5 iPads simultaneously
- **Videos**: H.264 MP4 format
- **Uptime**: Tested for 3-5 months continuous operation

## 📝 License

This project is open source and free to use for non-commercial exhibitions.
Credit appreciated but not required.

## 🤝 Support

- 📖 Check the [User Guides](docs/user-guides/)
- 🐛 [Report Issues](https://github.com/CosmicCannibalism/2025_kub_winzige_giganten/issues)
- 💬 Questions? See [Troubleshooting](docs/user-guides/TROUBLESHOOTING.md)

## 🎉 Quick Example

**Want to see it in action in 5 minutes?**

1. Download the SD card image
2. Flash to SD card with Raspberry Pi Imager
3. Power on the Pi
4. Connect iPad to "winzige_giganten" WiFi
5. Install PWA to homescreen
6. Watch videos offline!

---

**Made with ❤️ for the art community**  
*CosmicCannibalism for Museum of Art and Bread Ulm*