#!/bin/bash
#
# Exhibition System Optimization
# Optimizes Pi Zero 2W for 3-5 month autonomous exhibition operation
#
# Focus areas:
# - SD card preservation (reduce write cycles)
# - Memory optimization 
# - Swap configuration
# - Performance tuning for video serving
# - Temperature monitoring optimization

LOG_FILE="/var/log/wg-exhibition.log"

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [OPTIMIZATION] $1" | tee -a "$LOG_FILE"
}

log_msg "=== Exhibition System Optimization Started ==="

# 1. SD Card Preservation - Reduce unnecessary writes
log_msg "1. Configuring SD card preservation..."

# Reduce journal logging to preserve SD card
if ! grep -q "Storage=volatile" /etc/systemd/journald.conf; then
    log_msg "Configuring journald for volatile (RAM-only) storage"
    cp /etc/systemd/journald.conf /etc/systemd/journald.conf.backup
    cat >> /etc/systemd/journald.conf << 'EOF'

# Exhibition optimization - reduce SD card writes
Storage=volatile
RuntimeMaxUse=32M
RuntimeMaxFileSize=8M
RuntimeMaxFiles=3
EOF
    log_msg "journald configured for volatile storage (32MB RAM limit)"
else
    log_msg "journald already configured for volatile storage"
fi

# Configure log rotation to be less aggressive but still functional
cat > /etc/logrotate.d/exhibition-optimization << 'EOF'
# Exhibition log rotation - preserve SD card
/var/log/wg-exhibition.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    maxsize 10M
}

/var/log/exhibition/*.log {
    weekly
    rotate 2
    compress
    delaycompress
    missingok
    notifempty
    maxsize 5M
}
EOF

log_msg "Exhibition log rotation configured"

# 2. Memory Optimization for Pi Zero 2W
log_msg "2. Configuring memory optimization..."

# Optimize kernel parameters for low memory system
cat > /etc/sysctl.d/99-exhibition-optimization.conf << 'EOF'
# Exhibition memory optimization for Pi Zero 2W

# Reduce swappiness (prefer RAM over swap)
vm.swappiness=10

# Memory management for limited RAM
vm.dirty_ratio=5
vm.dirty_background_ratio=2
vm.dirty_expire_centisecs=3000
vm.dirty_writeback_centisecs=500

# Network optimization for WiFi AP
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 65536 134217728
net.ipv4.tcp_wmem=4096 65536 134217728

# Reduce memory fragmentation
vm.min_free_kbytes=8192
EOF

log_msg "Kernel memory parameters optimized"

# 3. Swap Configuration
log_msg "3. Optimizing swap configuration..."

# Check current swap
CURRENT_SWAP=$(swapon --show | grep -v NAME | wc -l)
if [ "$CURRENT_SWAP" -eq 0 ]; then
    log_msg "No swap currently active - creating optimized swap file"
    
    # Create 256MB swap file for Pi Zero 2W
    fallocate -l 256M /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    
    # Add to fstab if not present
    if ! grep -q "/swapfile" /etc/fstab; then
        echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
    fi
    
    log_msg "256MB swap file created and activated"
else
    log_msg "Swap already configured: $(swapon --show | grep -v NAME)"
fi

# 4. Video Serving Optimization
log_msg "4. Optimizing nginx for video serving..."

# Create optimized nginx configuration for video
cat > /etc/nginx/conf.d/video-optimization.conf << 'EOF'
# Video serving optimization for exhibition

# Enable efficient file serving
sendfile on;
tcp_nopush on;
tcp_nodelay on;

# Optimize for video streaming
client_max_body_size 1m;
client_body_timeout 12;
client_header_timeout 12;
keepalive_timeout 15;
send_timeout 10;

# Worker processes for Pi Zero 2W (4 cores)
worker_processes 2;
worker_connections 256;

# File caching for static content
open_file_cache max=1000 inactive=20s;
open_file_cache_valid 30s;
open_file_cache_min_uses 2;
open_file_cache_errors on;

# Gzip compression for non-video files
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/css text/javascript application/javascript;
gzip_disable "msie6";
EOF

log_msg "nginx optimized for video serving"

# 5. Temperature monitoring optimization
log_msg "5. Setting up temperature monitoring thresholds..."

# Create temperature monitoring script
cat > /usr/local/sbin/wg-temp-monitor.sh << 'EOF'
#!/bin/bash
#
# Temperature Monitoring for Exhibition
# Monitors CPU temperature and takes action if overheating

LOG_FILE="/var/log/wg-exhibition.log"
TEMP_LOG="/var/log/exhibition/temperature.log"

# Ensure log directory exists
mkdir -p /var/log/exhibition

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [TEMP-MON] $1" | tee -a "$LOG_FILE"
}

# Get current temperature
TEMP=$(vcgencmd measure_temp 2>/dev/null | cut -d'=' -f2 | cut -d"'" -f1)

if [ -z "$TEMP" ]; then
    log_msg "WARNING: Could not read temperature sensor"
    exit 1
fi

# Log temperature
echo "$(date '+%Y-%m-%d %H:%M:%S'),$TEMP" >> "$TEMP_LOG"

# Temperature thresholds for Pi Zero 2W
TEMP_INT=${TEMP%.*}

if [ "$TEMP_INT" -ge 75 ]; then
    log_msg "CRITICAL: High temperature detected: ${TEMP}°C - taking action"
    
    # Reduce CPU frequency to cool down
    echo 600000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null || true
    
    # Log critical temperature event
    echo "$(date): CRITICAL TEMP ${TEMP}°C - CPU throttled" >> /var/log/exhibition/critical-events.log
    
elif [ "$TEMP_INT" -ge 70 ]; then
    log_msg "WARNING: Elevated temperature: ${TEMP}°C"
    
    # Restore normal CPU frequency if previously throttled
    echo 1000000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null || true
    
elif [ "$TEMP_INT" -le 60 ]; then
    # Temperature normal - ensure full CPU frequency
    echo 1000000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null || true
fi
EOF

chmod +x /usr/local/sbin/wg-temp-monitor.sh
log_msg "Temperature monitoring script created"

# 6. System cleanup optimization
log_msg "6. Configuring automated system cleanup..."

cat > /usr/local/sbin/wg-cleanup-optimization.sh << 'EOF'
#!/bin/bash
#
# Exhibition System Cleanup
# Automated cleanup to preserve SD card and maintain performance

LOG_FILE="/var/log/wg-exhibition.log"

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [CLEANUP] $1" | tee -a "$LOG_FILE"
}

# Clear unnecessary caches
sync
echo 1 > /proc/sys/vm/drop_caches

# Clean temporary files
find /tmp -type f -mtime +1 -delete 2>/dev/null || true
find /var/tmp -type f -mtime +1 -delete 2>/dev/null || true

# Clear old logs if disk space low
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 85 ]; then
    log_msg "Disk usage high (${DISK_USAGE}%) - cleaning old logs"
    find /var/log -name "*.log" -mtime +3 -delete 2>/dev/null || true
    journalctl --vacuum-time=7d >/dev/null 2>&1 || true
fi

log_msg "System cleanup completed - disk usage: ${DISK_USAGE}%"
EOF

chmod +x /usr/local/sbin/wg-cleanup-optimization.sh
log_msg "System cleanup script created"

# Apply optimizations
log_msg "7. Applying system optimizations..."

# Apply sysctl settings
sysctl -p /etc/sysctl.d/99-exhibition-optimization.conf >/dev/null 2>&1

# Test nginx configuration
if nginx -t >/dev/null 2>&1; then
    log_msg "nginx configuration test passed"
    systemctl reload nginx
    log_msg "nginx reloaded with optimizations"
else
    log_msg "WARNING: nginx configuration test failed - skipping reload"
fi

# Initial temperature check
/usr/local/sbin/wg-temp-monitor.sh

# Initial cleanup
/usr/local/sbin/wg-cleanup-optimization.sh

log_msg "=== Exhibition System Optimization Completed ==="
log_msg "Optimizations applied:"
log_msg "- journald: volatile storage (RAM-only, 32MB limit)"
log_msg "- Memory: optimized for Pi Zero 2W (swappiness=10)"
log_msg "- Swap: 256MB swap file configured"
log_msg "- nginx: optimized for video serving"
log_msg "- Temperature: monitoring with automatic throttling"
log_msg "- Cleanup: automated SD card preservation"
log_msg ""
log_msg "Reboot recommended to fully apply kernel optimizations"