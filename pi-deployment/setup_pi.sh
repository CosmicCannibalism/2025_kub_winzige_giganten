#!/bin/bash
# Minimal automated setup for Raspberry Pi Zero 2 W standalone AP + nginx web server
# Usage: sudo ./setup_pi.sh "SSID" "PASSPHRASE"

set -euo pipefail

SSID=${1:-WG-Kiosk}
PSK=${2:-winzigegiganten}

echo "Setting up Pi as AP with SSID='${SSID}'"

echo "Updating packages..."
apt update && apt upgrade -y

echo "Installing required packages: nginx, hostapd, dnsmasq"
apt install -y nginx hostapd dnsmasq

echo "Stopping services temporarily"
systemctl stop hostapd || true
systemctl stop dnsmasq || true

echo "Configuring static IP for wlan0 in /etc/dhcpcd.conf"
cat >> /etc/dhcpcd.conf <<'EOF'

interface wlan0
    static ip_address=192.168.4.1/24
    nohook wpa_supplicant

EOF

echo "Writing /etc/hostapd/hostapd.conf"
cat > /etc/hostapd/hostapd.conf <<EOF
interface=wlan0
driver=nl80211
ssid=${SSID}
hw_mode=g
channel=6
ieee80211n=1
wmm_enabled=1
auth_algs=1
wpa=2
wpa_passphrase=${PSK}
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF

echo "Pointing /etc/default/hostapd to config"
sed -i.bak 's|#DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd || echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' >> /etc/default/hostapd

echo "Configuring dnsmasq (backup original)"
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig || true
cat > /etc/dnsmasq.conf <<'EOF'
interface=wlan0
dhcp-range=192.168.4.10,192.168.4.50,12h
dhcp-option=3,192.168.4.1
domain-needed
bogus-priv
EOF

echo "Enabling services"
systemctl unmask hostapd
systemctl enable hostapd
systemctl enable dnsmasq

echo "Deploying site from /home/pi/site -> /var/www/html"
if [ -d /home/pi/site ]; then
  rm -rf /var/www/html/*
  cp -r /home/pi/site/* /var/www/html/
  chown -R www-data:www-data /var/www/html
else
  echo "/home/pi/site not found — please copy your site files to /home/pi/site before running this script. Exiting."
  exit 1
fi

echo "Enabling and restarting services"
systemctl restart dhcpcd
systemctl restart hostapd
systemctl restart dnsmasq
systemctl enable nginx
systemctl restart nginx

echo "Setup complete — rebooting in 5 seconds"
sleep 5
reboot
