#!/bin/bash
#
# Device Connection Limiting Configuration
# Limits WiFi connections to 5 devices maximum for exhibition stability
#
# Usage: Run on Pi to configure connection limits

LOG_FILE="/var/log/wg-exhibition.log"

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [DEVICE-LIMIT] $1" | tee -a "$LOG_FILE"
}

log_msg "=== Configuring Device Connection Limits ==="

# Backup current configurations
log_msg "Creating backups of current configurations..."
cp /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.backup.$(date +%Y%m%d)
cp /etc/dnsmasq.d/wg-ap.conf /etc/dnsmasq.d/wg-ap.conf.backup.$(date +%Y%m%d)

# Configure hostapd for maximum 5 connections
log_msg "Configuring hostapd for maximum 5 concurrent connections..."

# Add max_num_sta parameter to hostapd.conf
if ! grep -q "max_num_sta" /etc/hostapd/hostapd.conf; then
    echo "" >> /etc/hostapd/hostapd.conf
    echo "# Exhibition device limiting - maximum 5 concurrent connections" >> /etc/hostapd/hostapd.conf
    echo "max_num_sta=5" >> /etc/hostapd/hostapd.conf
    log_msg "Added max_num_sta=5 to hostapd.conf"
else
    sed -i 's/^max_num_sta=.*/max_num_sta=5/' /etc/hostapd/hostapd.conf
    log_msg "Updated existing max_num_sta to 5"
fi

# Configure dnsmasq DHCP pool for exactly 5 addresses
log_msg "Configuring dnsmasq DHCP pool for 5 addresses..."

# Update DHCP range to provide exactly 5 IP addresses (192.168.4.10-192.168.4.14)
sed -i 's/^dhcp-range=192.168.4.10,192.168.4.50.*/dhcp-range=192.168.4.10,192.168.4.14,24h/' /etc/dnsmasq.d/wg-ap.conf

# Add DHCP lease limit if not present
if ! grep -q "dhcp-lease-max" /etc/dnsmasq.d/wg-ap.conf; then
    echo "" >> /etc/dnsmasq.d/wg-ap.conf
    echo "# Exhibition device limiting - maximum 5 DHCP leases" >> /etc/dnsmasq.d/wg-ap.conf
    echo "dhcp-lease-max=5" >> /etc/dnsmasq.d/wg-ap.conf
    log_msg "Added dhcp-lease-max=5 to dnsmasq configuration"
fi

# Create device monitoring script
log_msg "Creating device connection monitoring script..."

cat > /usr/local/sbin/wg-device-monitor.sh << 'EOF'
#!/bin/bash
#
# Device Connection Monitor
# Monitors and logs connected device count for exhibition

LOG_FILE="/var/log/wg-exhibition.log"
DEVICE_LOG="/var/log/exhibition/device-connections.log"

# Ensure log directory exists
mkdir -p /var/log/exhibition

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [DEVICE-MON] $1" | tee -a "$LOG_FILE"
}

# Count currently connected devices
CONNECTED_DEVICES=$(iw dev ap0 station dump 2>/dev/null | grep Station | wc -l)
DHCP_LEASES=$(grep "192.168.4" /var/lib/dhcp/dhcpd.leases 2>/dev/null | grep binding | wc -l)

# Log current status
echo "$(date '+%Y-%m-%d %H:%M:%S'),$CONNECTED_DEVICES,$DHCP_LEASES" >> "$DEVICE_LOG"

# Check if approaching limit
if [ "$CONNECTED_DEVICES" -ge 4 ]; then
    log_msg "WARNING: High device count - $CONNECTED_DEVICES/5 devices connected"
elif [ "$CONNECTED_DEVICES" -ge 5 ]; then
    log_msg "CRITICAL: Device limit reached - $CONNECTED_DEVICES/5 devices connected"
fi

# Check for any devices that failed to connect due to limits
HOSTAPD_REJECTS=$(journalctl -u hostapd --since="10 minutes ago" | grep -c "STA.*denied" || echo "0")
if [ "$HOSTAPD_REJECTS" -gt 0 ]; then
    log_msg "INFO: $HOSTAPD_REJECTS devices denied connection due to limits (last 10 min)"
fi
EOF

chmod +x /usr/local/sbin/wg-device-monitor.sh

# Test the configuration
log_msg "Testing configuration..."
if hostapd -t /etc/hostapd/hostapd.conf 2>/dev/null; then
    log_msg "hostapd configuration test: PASSED"
else
    log_msg "ERROR: hostapd configuration test FAILED"
    exit 1
fi

if dnsmasq --test --conf-file=/etc/dnsmasq.d/wg-ap.conf 2>/dev/null; then
    log_msg "dnsmasq configuration test: PASSED"
else
    log_msg "ERROR: dnsmasq configuration test FAILED"
    exit 1
fi

log_msg "=== Device Connection Limiting Configuration Complete ==="
log_msg "Configuration changes:"
log_msg "- hostapd: maximum 5 concurrent stations (max_num_sta=5)"
log_msg "- dnsmasq: DHCP pool limited to 5 addresses (192.168.4.10-192.168.4.14)"
log_msg "- Device monitoring: /usr/local/sbin/wg-device-monitor.sh created"
log_msg ""
log_msg "To apply changes, restart services: sudo systemctl restart hostapd dnsmasq"
log_msg "Or use: sudo /usr/local/sbin/wg-ap-up.sh"