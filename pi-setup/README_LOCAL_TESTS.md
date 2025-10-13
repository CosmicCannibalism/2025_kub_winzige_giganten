# Quick local tests after Pi setup

After the Pi reboots and the AP is running, do these checks from a laptop or an iPad:

1) Connect to the Pi AP SSID (default `WG-Kiosk`) and confirm you get an IP in the `192.168.4.x` range.

2) Ping the Pi:

```bash
ping 192.168.4.1
```

3) Confirm nginx serves index.html:

```bash
curl -I http://192.168.4.1/
# Expect HTTP/1.1 200 OK and Content-Type: text/html
```

4) Confirm nginx supports Range requests for videos:

```bash
curl -I http://192.168.4.1/videos/teaser.mp4
# Look for: Accept-Ranges: bytes
```

5) Open Safari on iPad and go to http://192.168.4.1/ and try playing the video.

6) Add to Home Screen on each iPad using the appropriate per-iPad URL (see README.md):

  - http://192.168.4.1/index.html?video=ipad1.mp4

7) If something fails, check logs on the Pi via SSH:

```bash
sudo journalctl -u hostapd -b --no-pager
sudo journalctl -u dnsmasq -b --no-pager
sudo tail -n 200 /var/log/nginx/error.log
```

If you'd like, I can add an automated script to check these remotely and print clear diagnostics.
