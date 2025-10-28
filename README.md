# Winzige Giganten - Exhibition Installation

**CosmicCannibalism for Museum of Art and Bread Ulm**  
Exhibition: "Winzige Giganten"

PWA-based art installation with Raspberry Pi Zero 2W offline hotspot + web server.  
Validated for 3-5 month autonomous operation.

## Project Structure

```
├── index.html              # PWA main page - iPad 1 (default)
├── index01.html            # PWA page - iPad 2
├── index02.html            # PWA page - iPad 3
├── manifest.json           # PWA manifest - iPad 1
├── manifest01.json         # PWA manifest - iPad 2
├── manifest02.json         # PWA manifest - iPad 3
├── script.js              # PWA JavaScript (shared)
├── style.css              # PWA styles (shared)
├── sw.js                  # Service Worker for offline caching (shared)
├── icons/                 # PWA icons
├── videos/                # Video content (main.mp4, teaser.mp4)
├── spec/                  # Feature specifications
├── build/                 # Arduino build artifacts
├── pi-deployment/         # Raspberry Pi deployment scripts
│   ├── deploy-exhibition-scripts.sh
│   ├── deploy-device-limits.sh
│   ├── deploy-optimization.sh
│   ├── setup_pi.sh
│   ├── scripts/          # Monitoring scripts
│   │   ├── wg-emergency-reboot.sh
│   │   ├── wg-log-manager.sh
│   │   ├── wg-maintenance.sh
│   │   ├── configure-device-limits.sh
│   │   ├── exhibition-optimization.sh
│   │   └── exhibition-crontab
│   └── testing/          # Test scripts
│       ├── exhibition-readiness-test.sh
│       ├── stress-test-5-devices.sh
│       └── power-comparison-test.sh
└── docs/                  # Documentation
    ├── EXHIBITION_HARDENING_TASKLIST.md
    └── archive/          # Old file versions
```

## System Features

### PWA (Progressive Web App)
- **3 iPad Installation**: Exhibition uses 3 iPads, each with dedicated HTML/manifest
  - iPad 1: `index.html` + `manifest.json` (default)
  - iPad 2: `index01.html` + `manifest01.json`
  - iPad 3: `index02.html` + `manifest02.json`
- Offline-capable video playback
- Install on iPad homescreen
- Service worker caching for offline operation
- H.264 MP4 video support with Range requests
- Shared resources: `script.js`, `style.css`, `sw.js`

### Raspberry Pi Infrastructure
- **WiFi Hotspot**: SSID "winzige_giganten" (password: winzigegiganten)
- **Web Server**: nginx serving PWA at 192.168.4.1
- **Device Limiting**: Max 5 concurrent connections
- **Autonomous Monitoring**: Multi-layer watchdog system
- **Power Cycle Resilient**: Validated 3+ successful power cycles

### Exhibition Hardening
- Software + Hardware watchdog
- Automatic service recovery
- Temperature monitoring (threshold: 65°C)
- Log management and rotation
- SD card longevity optimization
- Memory tuning for embedded systems

## Deployment Status

✅ **Exhibition Ready** - October 28, 2025  
- 3 successful power cycles without issues
- All systems operational
- Autonomous recovery validated
- Ready for 3-5 month deployment

## Quick Start

### Deploy to Raspberry Pi
```bash
cd pi-deployment
./deploy-exhibition-scripts.sh
./deploy-device-limits.sh
./deploy-optimization.sh
```

### Test System
```bash
cd pi-deployment/testing
./exhibition-readiness-test.sh
```

### iPad Installation
1. Connect to "winzige_giganten" WiFi
2. Open Safari and navigate to captive portal or:
   - iPad 1: http://192.168.4.1/index.html
   - iPad 2: http://192.168.4.1/index01.html
   - iPad 3: http://192.168.4.1/index02.html
3. Add PWA to homescreen (each iPad gets its own version)
4. Videos work offline after initial load

## System Requirements

- Raspberry Pi Zero 2W
- 5V 2.5A+ power supply
- SD card (32GB recommended)
- WiFi-enabled iPad for visitors

## Maintenance

All monitoring runs automatically via cron:
- Watchdog: Every 5 minutes
- Temperature: Every 10 minutes  
- Device monitoring: Every 15 minutes
- Log management: Daily at 3 AM
- System maintenance: Weekly Sunday 4 AM