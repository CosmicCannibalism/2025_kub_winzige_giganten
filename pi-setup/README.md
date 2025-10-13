# Raspberry Pi Zero 2 W — Standalone AP + Web Server for Winzige Giganten

This guide and script will help you create a self-contained Raspberry Pi kiosk that:

- Creates a Wi‑Fi Access Point (SSID) that iPads can join.
- Runs `nginx` to serve your PWA and video files over HTTP.
- Uses `dnsmasq` for simple DHCP and `hostapd` for the AP.

Notes and assumptions
- Target device: Raspberry Pi Zero 2 W (your 32GB SanDisk A1 card).
- The script is intended to be run on the Pi after first boot (or via SSH).
- Your site files (project) should be copied to `/home/pi/site/` on the Pi before running the script. The script will copy from there into `/var/www/html`.
- Default AP IP: `192.168.4.1` and DHCP range `192.168.4.10`–`192.168.4.50`.
- The script uses default SSID `WG-Kiosk` and passphrase `winzigegiganten` unless you provide arguments.

Security and service-worker note
- The Pi serves content over HTTP. Browsers will allow streaming from HTTP when the page is opened via normal Safari. Service workers require HTTPS to run on iOS; for exhibition reliability we do not need SW if the Pi is always on and reachable. If you want SW+HTTPS, see the README section at the end.

Quick steps

1. Flash Raspberry Pi OS Lite to the SD card (use Raspberry Pi Imager or balenaEtcher).
2. On first boot enable SSH (create empty file `ssh` in boot partition) so you can SSH from your Mac.
3. SSH into the Pi (default user: `pi`, password: `raspberry`) and copy your site to `/home/pi/site/`. Example from your Mac:

```bash
# from your Mac (replace PI_IP with the Pi's address on your network, or mount the SD and copy)
scp -r ./ /home/pi/site/ pi@PI_IP:/home/pi/site/
```

4. Run the setup script on the Pi (you can change SSID/PASS as arguments):

```bash
cd ~/pi-setup
chmod +x setup_pi.sh
sudo ./setup_pi.sh "WG-Kiosk" "winzigegiganten"
```

5. Reboot the Pi (the script reboots at the end). On reboot the AP should be visible as the SSID you provided. Connect an iPad, open `http://192.168.4.1/` in Safari and verify playback.

Per-iPad different movie
- To give each iPad a different movie: open a distinct URL on each device before adding to homescreen, e.g.

  - `http://192.168.4.1/index.html?video=ipad1.mp4`
  - `http://192.168.4.1/index.html?video=ipad2.mp4`
  - `http://192.168.4.1/index.html?video=ipad3.mp4`

  Add the exact URL to the homescreen on each iPad; the homescreen shortcut will open that URL and the app can pick the `video` query param.

Troubleshooting tips
- If the AP doesn't start, check `sudo journalctl -u hostapd` and `sudo journalctl -u dnsmasq`.
- If nginx doesn't serve video correctly, check `sudo tail -n 100 /var/log/nginx/error.log` and ensure files exist under `/var/www/html/videos/`.
- Test from a laptop first: connect to the Pi and run `curl -I http://192.168.4.1/videos/teaser.mp4` and ensure `Accept-Ranges: bytes` is present.

Optional HTTPS / Service Worker
- If you want service-worker caching on iPads, you must serve over HTTPS with a cert trusted by the device. The easiest local approach requires installing a local CA on each iPad (more work). For an exhibition, this is usually unnecessary — stream from the Pi.

If you want me to produce an automated script that also configures HTTPS via mkcert and instructions to install the mkcert CA on the iPads, tell me and I’ll add it.

---
End of README
