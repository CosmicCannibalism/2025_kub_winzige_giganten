# 📀 Creating the SD Card Image for Public Release

**Instructions for maintainers to create the downloadable SD card image**

---

## Prerequisites

- Working Raspberry Pi with exhibition system installed
- SD card with complete, tested system
- Linux/Mac computer (or Windows with WSL)
- 32GB+ SD card in Pi
- SD card reader

---

## Step 1: Prepare the Pi for Imaging

### Clean Up Sensitive Data

```bash
ssh cosmic@cosmicpi.local

# Clear bash history
history -c
rm ~/.bash_history

# Clear logs that contain IPs/personal data
sudo rm -rf /var/log/exhibition/*.log
sudo rm -rf /var/log/syslog*
sudo rm -rf /var/log/auth.log*

# Clear WiFi connection history  
sudo rm -rf /var/lib/dhcp/*

# Clear SSH keys (users will regenerate)
sudo rm -rf /etc/ssh/ssh_host_*
```

### Reset to Defaults

```bash
# Ensure default credentials
# Username: cosmic
# Consider if you want to set a default password or leave passwordless

# Verify services are enabled
sudo systemctl enable hostapd dnsmasq nginx

# Clear any temporary files
sudo rm -rf /tmp/*
sudo rm -rf /home/cosmic/.cache/*
```

### Final Check

```bash
# Verify system works
sudo systemctl status hostapd dnsmasq nginx

# Check disk usage
df -h /

# Optimize disk space if needed
sudo apt-get clean
sudo apt-get autoremove
```

---

## Step 2: Shutdown and Remove SD Card

```bash
# Graceful shutdown
sudo shutdown -h now
```

Wait for green LED to stop blinking, then:
1. Unplug power
2. Remove SD card from Pi
3. Insert SD card into computer

---

## Step 3: Create the Image

### On Linux/Mac

```bash
# Find the SD card device
diskutil list  # Mac
lsblk         # Linux

# Note the device (e.g., /dev/disk2 on Mac, /dev/sdb on Linux)

# Create image (Mac)
sudo dd if=/dev/rdisk2 of=~/Desktop/winzige-giganten-exhibition-v1.0.img bs=4m status=progress

# Create image (Linux)
sudo dd if=/dev/sdb of=~/Desktop/winzige-giganten-exhibition-v1.0.img bs=4M status=progress

# This takes 30-60 minutes for 32GB card
```

### On Windows (with Win32 Disk Imager)

1. Download [Win32 Disk Imager](https://sourceforge.net/projects/win32diskimager/)
2. Select SD card drive
3. Choose output file location
4. Click "Read" to create image

---

## Step 4: Shrink the Image (Optional but Recommended)

Full 32GB image is huge. Shrink it to actual used space:

### Using PiShrink (Linux)

```bash
# Install PiShrink
wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
chmod +x pishrink.sh

# Shrink the image
sudo ./pishrink.sh winzige-giganten-exhibition-v1.0.img

# This reduces 32GB image to ~3-5GB!
```

---

## Step 5: Compress the Image

```bash
# Compress with gzip (best compatibility)
gzip -9 winzige-giganten-exhibition-v1.0.img

# Or compress with xz (better compression, slower)
xz -9 winzige-giganten-exhibition-v1.0.img

# Result: winzige-giganten-exhibition-v1.0.img.gz
# Size: ~2-3GB compressed
```

---

## Step 6: Create Checksum

```bash
# Generate SHA256 checksum
sha256sum winzige-giganten-exhibition-v1.0.img.gz > winzige-giganten-exhibition-v1.0.img.gz.sha256

# Or on Mac
shasum -a 256 winzige-giganten-exhibition-v1.0.img.gz > winzige-giganten-exhibition-v1.0.img.gz.sha256
```

---

## Step 7: Test the Image

### Critical: Always test before releasing!

```bash
# Extract the compressed image
gunzip -k winzige-giganten-exhibition-v1.0.img.gz

# Flash to a test SD card using Raspberry Pi Imager
# Boot test Pi
# Verify:
# - Boots successfully
# - WiFi appears
# - Can connect iPads
# - Videos play
# - PWA installs
# - No personal data visible
```

---

## Step 8: Create Release Notes

Create `RELEASE_NOTES_v1.0.md`:

```markdown
# Winzige Giganten Exhibition System v1.0

## What's Included
- Raspberry Pi OS Lite (Debian 12)
- nginx web server
- hostapd WiFi access point
- dnsmasq DHCP/DNS server
- Complete PWA exhibition system
- Monitoring and recovery scripts
- Example exhibition: "Winzige Giganten"

## System Configuration
- WiFi SSID: `winzige_giganten`
- WiFi Password: `winzigegiganten`
- IP Address: `192.168.4.1`
- SSH Username: `cosmic`
- SSH Enabled: Yes
- Max Devices: 5

## Default Credentials
- SSH: cosmic / [no password set - use SSH keys]

## First Boot
- Takes 3-5 minutes
- Services start automatically
- WiFi hotspot appears as "winzige_giganten"

## Tested On
- Raspberry Pi Zero 2W
- Raspberry Pi 3 Model B+
- Raspberry Pi 4 Model B

## File Size
- Compressed: 2.8 GB
- Uncompressed: 32 GB
- Minimum SD Card: 32GB

## SHA256 Checksum
[paste checksum here]

## Installation
See SETUP_GUIDE.md for complete instructions.

## Version History
- v1.0 (2025-10-28): Initial public release
```

---

## Step 9: Upload to GitHub Release

1. Go to GitHub repository
2. Click "Releases" → "Create a new release"
3. Tag: `v1.0`
4. Title: "Exhibition System v1.0 - SD Card Image"
5. Description: Paste release notes
6. Upload files:
   - `winzige-giganten-exhibition-v1.0.img.gz`
   - `winzige-giganten-exhibition-v1.0.img.gz.sha256`
   - `RELEASE_NOTES_v1.0.md`
7. Publish release

---

## Alternative: Large File Hosting

If GitHub release file size limit is an issue (2GB+):

### Options:
1. **Google Drive** - Free, easy sharing
2. **Dropbox** - Free tier sufficient
3. **Archive.org** - Free, permanent hosting
4. **Self-hosted** - Your own server

Update README with download link.

---

## Step 10: Update Documentation

Update `PUBLIC_README.md`:

```markdown
## 📥 Download SD Card Image

**Current Version: v1.0 (October 2025)**

- [Download Image (2.8GB)](https://github.com/CosmicCannibalism/2025_kub_winzige_giganten/releases/latest)
- [SHA256 Checksum](link)
- [Release Notes](link)
```

---

## Maintenance: Creating Update Images

For version 1.1, 1.2, etc.:

1. Start with clean v1.0 system
2. Apply updates and improvements
3. Test thoroughly
4. Repeat imaging process
5. Increment version number
6. Document changes in release notes

---

## Size Optimization Tips

### Before Imaging:

```bash
# Remove unnecessary packages
sudo apt-get autoremove --purge
sudo apt-get clean

# Remove old kernels
sudo apt-get remove --purge $(dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d')

# Clear package cache
sudo rm -rf /var/cache/apt/archives/*.deb

# Clear logs
sudo journalctl --vacuum-time=1d
```

---

## Security Considerations

### What to Remove:
- SSH host keys (regenerate on first boot)
- Personal WiFi credentials
- Command history
- Log files with IPs
- Any test/debug data

### What to Keep:
- System configuration
- Exhibition content
- Service configurations
- Monitoring scripts

### Optional Hardening:
- Set up SSH keys only (disable password auth)
- Configure firewall rules
- Set up fail2ban
- Enable automatic security updates

---

## Checklist Before Release

- [ ] System boots cleanly
- [ ] WiFi hotspot works
- [ ] All services start automatically
- [ ] Web server serves content
- [ ] iPads can connect and install PWA
- [ ] Videos play smoothly
- [ ] No personal data in image
- [ ] Default credentials documented
- [ ] Image compressed
- [ ] Checksum generated
- [ ] Tested on clean SD card
- [ ] Release notes written
- [ ] Documentation updated

---

**Ready to share with the world! 🎉**