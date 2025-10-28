# 🎨 Raspberry Pi Offline Exhibition PWA Template

**Easy-to-use WiFi hotspot + web server for interactive art exhibitions**

This is a **flexible template system** that turns a Raspberry Pi into a standalone exhibition server. It serves a Progressive Web App to visitor devices without requiring internet. The included "Winzige Giganten" app demonstrates the capabilities, but you can adapt it for **any interactive exhibition** use case.

## 🎯 This Is a Template, Not Just an App!

**Important:** This repository provides a **complete template system** for building offline exhibition PWAs. The "Winzige Giganten" art installation is included as a **working example** to demonstrate:
- Video-based interactive installations
- Hardware integration (Arduino/HID devices)
- Multi-device coordination
- Offline operation for months

**Customize it for your own exhibition!** Use the same infrastructure with your own:
- Videos, images, or audio content
- Interactive elements and controls
- Custom branding and styling
- Hardware triggers and sensors

## 🎬 Example App: "Winzige Giganten" Interactive Video Installation

The included example demonstrates an **interactive video exhibition** with physical hardware control:

### How It Works
1. **Teaser Loop**: A short video plays continuously on loop to attract visitors
2. **Physical Trigger**: Visitor presses a button (Arduino or any HID device like a spacebar)
3. **Main Video**: The main exhibition video plays in full
4. **Return to Teaser**: After completion, returns to teaser loop

### Hardware Integration
- **Arduino**: Connected to physical exhibition button/sensor
- **HID Device**: Any keyboard/spacebar/custom HID controller works
- **Spacebar Trigger**: Press Space (or custom key) to start main video
- **Flexible**: Replace with motion sensors, pressure pads, RFID readers, etc.

### Use Case Examples
This interaction pattern is perfect for:
- 🎨 **Art Galleries**: Visitor-activated video art pieces
- 🏛️ **Museums**: Press button to hear curator commentary
- 🎪 **Interactive Installations**: Motion-activated displays
- 🎓 **Educational Exhibits**: Student-triggered demonstrations
- 🏢 **Trade Shows**: Product demos on demand
- 🎮 **Gaming Museums**: "Press Start" retro gaming displays

## 📦 What You Get

- **Complete Template System** - Adapt for your own exhibition
- **Ready-to-use SD card image** for Raspberry Pi Zero 2W
- **Working Example**: "Winzige Giganten" interactive video app
- **Hardware Integration**: Arduino code for physical controls (optional)
- **Step-by-step Guides** for non-technical users
- **Automatic WiFi hotspot** - visitors connect and install the app
- **Offline operation** - works for months without internet
- **Multi-device support** - up to 5 iPads/devices simultaneously

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
- ✅ Replace videos (teaser + main video)
- ✅ Change trigger key (spacebar, Enter, or custom)
- ✅ Change WiFi name and password
- ✅ Modify text and titles
- ✅ Replace logos and icons
- ✅ Adjust colors and fonts
- ✅ Configure loop behavior

### Advanced Changes (Some Coding)
- Custom video controls and transitions
- Multiple exhibition pages (already includes 3-iPad setup!)
- Arduino/hardware integration (code included!)
- Different trigger types (motion sensor, RFID, etc.)
- Custom animations and effects
- Analytics and visitor tracking
- Multi-language support

### Hardware Integration Options
The template supports various physical triggers:
- 🎮 **Arduino** (example code included)
- ⌨️ **Keyboard/Spacebar** (works out of the box)
- 🕹️ **Custom HID devices** (game controllers, custom buttons)
- 📡 **Sensors** (motion, proximity, pressure)
- 💳 **RFID readers** (for personalized experiences)
- 🔘 **Physical buttons** (arcade-style, museum-grade)

## 💾 Files You Need

### Download the SD Card Image
**Option A: Ready-to-Use Template (Recommended)**
- File: `winzige-giganten-exhibition-v1.0.img.gz` (coming soon in releases)
- Size: ~3GB compressed, 32GB when flashed
- Includes: Complete system + "Winzige Giganten" example app
- Includes: Complete system + example exhibition content

**Option B: Build From Source**
- Follow [PI_SETUP_FROM_SCRATCH.md](docs/technical/PI_SETUP_FROM_SCRATCH.md)
- Use deployment scripts in `pi-deployment/`

## 🔧 System Features

### For Visitors
- 📱 Install PWA on device homescreen (iPad, iPhone, Android)
- 🎬 Smooth offline video playback with hardware triggers
- 🎮 Physical interaction (button press, spacebar, etc.)
- 📶 No internet required
- 🔋 Battery-friendly design
- 🔁 Automatic teaser loop when idle

### For Organizers
- ⚡ Automatic startup (plug and play)
- 🔄 Auto-recovery from crashes and power outages
- 🌡️ Temperature monitoring (no cooling needed!)
- 📊 Connection logging and visitor tracking
- 🔒 Device limits (default: 5, easily adjustable)
- ⏰ Designed for 3-5 month unattended operation
- 🛠️ Remote SSH access for updates
- 📝 Comprehensive logs for troubleshooting

### For Developers
- 🎨 Modern PWA with service worker
- 🎮 Hardware integration via Arduino/HID
- 📱 Responsive design (works on any screen size)
- 🔧 Easy to extend and customize
- 📦 All source code included
- 🐧 Standard Linux server (nginx, systemd)

## 📁 Project Structure

```
📦 Exhibition PWA Template
├── 📄 index.html          # Main exhibition page (iPad 1)
├── 📄 index01.html        # Exhibition page for iPad 2
├── 📄 index02.html        # Exhibition page for iPad 3
├── 📄 manifest.json       # PWA configuration (iPad 1)
├── 📄 manifest01.json     # PWA configuration (iPad 2)
├── 📄 manifest02.json     # PWA configuration (iPad 3)
├── 📄 script.js           # JavaScript (shared)
├── 📄 style.css           # Styling (shared)
├── 🔧 sw.js              # Service Worker (offline magic)
├── 📁 videos/            # Your video content (teaser + main)
├── 📁 icons/             # App icons
├── 📁 build/             # Arduino build files (optional hardware)
├── 📄 2025_kunst_und_brot_winzige_giganten.ino  # Arduino code
├── 📁 docs/              # All documentation
│   ├── 📁 user-guides/   # For non-technical users
│   ├── 📁 technical/     # For developers
│   └── 📁 images/        # Guide screenshots
└── 📁 pi-deployment/     # Raspberry Pi deployment scripts
```

## 🎨 Example: "Winzige Giganten" Interactive Video Installation

This template includes a complete working example from the "Winzige Giganten" art exhibition at the Museum of Art and Bread, Ulm. It demonstrates the **teaser-to-main video interaction pattern** with hardware triggers.

### What It Demonstrates

**Interaction Flow:**
1. **Idle State**: Teaser video loops continuously (attracts visitors)
2. **Trigger**: Visitor presses physical button or spacebar
3. **Main Content**: Full exhibition video plays
4. **Return**: Automatically returns to teaser loop

**Technical Features:**
- 🎬 **Dual Video System**: Teaser loop + full-length main video
- 🎮 **Physical Controls**: Arduino button press triggers main video
- ⌨️ **Keyboard Control**: Spacebar also works (great for testing!)
- 🔁 **Automatic Loop**: Returns to teaser after main video ends
- 📱 **Multi-Device**: 3 iPads showing synchronized content
- 🔌 **Hardware Integration**: Arduino code included (optional)
- 💾 **Offline First**: Works for months without internet

**Included Arduino Code:**
The repository includes working Arduino code that:
- Connects as USB HID device (acts like a keyboard)
- Sends spacebar keypress when button is pressed
- Can be adapted for any sensor or trigger type
- Example uses simple pushbutton, but works with anything

### Adaptation Ideas

**Change the Hardware Trigger:**
- Motion sensor → Video plays when visitor approaches
- Pressure pad → Video plays when visitor stands on pad
- RFID reader → Personalized videos per visitor badge
- Multiple buttons → Choose from several videos
- Rotary encoder → Scrub through video timeline
- Proximity sensor → Different videos at different distances

**Change the Content Pattern:**
- Museum audio guide (teaser intro + full curator commentary)
- Product demo (teaser features + full detailed explanation)
- Story installation (chapter previews + full chapters)
- Educational exhibit (question teaser + answer video)
- Art piece variations (thumbnail + full resolution)

**Use It As:**
- 🎓 **Learning Example**: Study how teaser-main pattern works
- 🏗️ **Starting Template**: Replace videos and customize styling
- 🚀 **Ready System**: Deploy as-is, just change content
- 🔧 **Development Base**: Extend with your own features

## 💡 Template Use Cases

This flexible template system is perfect for:

### Art & Culture
- 🎨 **Interactive Video Art** - Visitor-activated installations
- 🏛️ **Museum Exhibits** - Button-triggered curator commentary
- 🎭 **Theater Lobbies** - Preview/full performance recordings
- 📸 **Photo Exhibitions** - Teaser slideshow + behind-the-scenes video
- 🎵 **Music Installations** - Sample loop + full track playback

### Education
- 🎓 **Science Centers** - Demo teaser + full experiment
- 🏫 **School Exhibits** - Preview + detailed explanations
- 📚 **Library Displays** - Book previews + author readings
- 🔬 **Research Showcases** - Quick summary + full presentation

### Commercial
- 🏢 **Trade Shows** - Product teaser + detailed demo
- 🏪 **Retail Displays** - Feature highlights + usage videos
- 🏗️ **Real Estate** - Property teaser + full virtual tour
- 🚗 **Showrooms** - Quick specs + detailed walkaround

### Interactive Installations
- 🎮 **Gaming Museums** - "Press Start" retro game trailers
- 🤖 **Tech Demos** - Teaser + interactive tutorial
- 🎪 **Event Installations** - Attract loop + full experience
- 🎬 **Film Festivals** - Trailer + director's cut
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