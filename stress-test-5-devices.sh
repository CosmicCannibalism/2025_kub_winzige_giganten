#!/bin/bash
#
# Exhibition Stress Test - 5 Device Video Streaming Simulation
# Tests Pi Zero 2W under realistic exhibition load
#
# This simulates 5 devices simultaneously downloading large video files
# to determine if cooling (fan) is needed for exhibition

PI_HOST="cosmic@cosmicpi.local"

echo "=== Exhibition Stress Test - 5 Device Video Streaming ==="
echo "Testing Pi Zero 2W under realistic exhibition load"
echo "Target: $PI_HOST"
echo ""

# Check Pi connection
if ! ssh -o ConnectTimeout=5 "$PI_HOST" "echo 'Pi connection OK'" 2>/dev/null; then
    echo "ERROR: Cannot connect to $PI_HOST"
    exit 1
fi

echo "✅ Pi connection verified"

# Create stress test script on Pi
echo "Creating stress test script on Pi..."
ssh "$PI_HOST" "cat > /tmp/video-stress-test.sh << 'EOF'
#!/bin/bash
#
# Video Streaming Stress Test
# Simulates 5 concurrent clients downloading video files

LOG_FILE=\"/tmp/stress-test.log\"
VIDEO_PATH=\"/var/www/html/videos\"

log_msg() {
    echo \"\$(date '+%Y-%m-%d %H:%M:%S') [STRESS] \$1\" | tee -a \"\$LOG_FILE\"
}

# Function to get system stats
get_stats() {
    local temp=\$(vcgencmd measure_temp 2>/dev/null | cut -d'=' -f2 | cut -d\"'\" -f1 || echo \"N/A\")
    local cpu=\$(cat /proc/loadavg | cut -d' ' -f1)
    local mem=\$(free | grep Mem | awk '{printf \"%.1f\", (\$3/\$2)*100}')
    local disk_io=\$(iostat -d 1 2 2>/dev/null | tail -n +4 | tail -1 | awk '{print \$4}' || echo \"N/A\")
    
    echo \"Temp: \${temp}°C, Load: \$cpu, Memory: \${mem}%, Disk I/O: \$disk_io\"
}

log_msg \"=== Starting 5-Device Video Streaming Stress Test ===\"
log_msg \"Initial stats: \$(get_stats)\"

# Check available video files
if [ ! -d \"\$VIDEO_PATH\" ]; then
    log_msg \"ERROR: Video directory \$VIDEO_PATH not found\"
    exit 1
fi

VIDEOS=(\$(ls \$VIDEO_PATH/*.mp4 2>/dev/null))
if [ \${#VIDEOS[@]} -eq 0 ]; then
    log_msg \"ERROR: No MP4 files found in \$VIDEO_PATH\"
    exit 1
fi

log_msg \"Found \${#VIDEOS[@]} video files\"
for video in \"\${VIDEOS[@]}\"; do
    size=\$(du -h \"\$video\" | cut -f1)
    log_msg \"Video: \$(basename \"\$video\") - Size: \$size\"
done

# Start 5 concurrent downloads (simulating devices)
log_msg \"Starting 5 concurrent video downloads...\"

PIDS=()
for i in {1..5}; do
    # Pick a video file (cycle through available videos)
    VIDEO_INDEX=\$(((\$i - 1) % \${#VIDEOS[@]}))
    VIDEO_FILE=\"\${VIDEOS[\$VIDEO_INDEX]}\"
    
    log_msg \"Client \$i: Starting download of \$(basename \"\$VIDEO_FILE\")\"
    
    # Simulate realistic download speed (not max speed)
    # Use curl with rate limiting to simulate mobile device download
    (
        cd /tmp
        curl -o \"client\${i}_video.mp4\" \\
             --limit-rate 2M \\
             --connect-timeout 10 \\
             --max-time 300 \\
             \"http://192.168.4.1/videos/\$(basename \"\$VIDEO_FILE\")\" \\
             >/dev/null 2>&1
        echo \"Client \$i download completed at \$(date)\"
    ) &
    
    PIDS+=(\$!)
    sleep 2  # Stagger the starts slightly
done

log_msg \"All 5 clients started. PIDs: \${PIDS[*]}\"

# Monitor system during stress test
log_msg \"Monitoring system performance during stress test...\"
MONITORING=true
MONITOR_COUNT=0
MAX_TEMP=0
TEMP_WARNINGS=0

while \$MONITORING; do
    sleep 10
    MONITOR_COUNT=\$((MONITOR_COUNT + 1))
    
    # Get current stats
    CURRENT_STATS=\$(get_stats)
    log_msg \"[\$MONITOR_COUNT] \$CURRENT_STATS\"
    
    # Extract temperature for analysis
    TEMP=\$(echo \"\$CURRENT_STATS\" | grep -o 'Temp: [0-9.]*' | cut -d' ' -f2)
    if [ \"\$TEMP\" != \"N/A\" ]; then
        TEMP_INT=\${TEMP%.*}
        if [ \"\$TEMP_INT\" -gt \"\$MAX_TEMP\" ]; then
            MAX_TEMP=\$TEMP_INT
        fi
        
        if [ \"\$TEMP_INT\" -ge 70 ]; then
            TEMP_WARNINGS=\$((TEMP_WARNINGS + 1))
            log_msg \"WARNING: High temperature detected: \${TEMP}°C\"
        fi
    fi
    
    # Check if any downloads are still running
    RUNNING=0
    for pid in \"\${PIDS[@]}\"; do
        if kill -0 \$pid 2>/dev/null; then
            RUNNING=\$((RUNNING + 1))
        fi
    done
    
    if [ \$RUNNING -eq 0 ]; then
        log_msg \"All downloads completed\"
        MONITORING=false
    elif [ \$MONITOR_COUNT -gt 60 ]; then  # 10 minutes max
        log_msg \"Test timeout reached - stopping remaining downloads\"
        for pid in \"\${PIDS[@]}\"; do
            kill \$pid 2>/dev/null || true
        done
        MONITORING=false
    fi
done

# Final analysis
log_msg \"=== Stress Test Results ===\"
log_msg \"Maximum temperature reached: \${MAX_TEMP}°C\"
log_msg \"Temperature warnings (>=70°C): \$TEMP_WARNINGS\"
log_msg \"Final stats: \$(get_stats)\"

# Downloaded file analysis
TOTAL_SIZE=0
for i in {1..5}; do
    if [ -f \"/tmp/client\${i}_video.mp4\" ]; then
        SIZE=\$(du -m \"/tmp/client\${i}_video.mp4\" 2>/dev/null | cut -f1 || echo 0)
        TOTAL_SIZE=\$((TOTAL_SIZE + SIZE))
        log_msg \"Client \$i: Downloaded \${SIZE}MB\"
        rm \"/tmp/client\${i}_video.mp4\" 2>/dev/null || true
    else
        log_msg \"Client \$i: Download failed or incomplete\"
    fi
done

log_msg \"Total data served: \${TOTAL_SIZE}MB\"

# Cooling recommendation
if [ \"\$MAX_TEMP\" -ge 75 ]; then
    log_msg \"RECOMMENDATION: Fan/cooling REQUIRED - Max temp \${MAX_TEMP}°C\"
elif [ \"\$MAX_TEMP\" -ge 70 ]; then
    log_msg \"RECOMMENDATION: Fan/cooling RECOMMENDED - Max temp \${MAX_TEMP}°C\"
elif [ \"\$MAX_TEMP\" -ge 65 ]; then
    log_msg \"RECOMMENDATION: Fan/cooling OPTIONAL - Max temp \${MAX_TEMP}°C\"
else
    log_msg \"RECOMMENDATION: No cooling needed - Max temp \${MAX_TEMP}°C\"
fi

log_msg \"=== Stress Test Completed ===\"
EOF

chmod +x /tmp/video-stress-test.sh"

echo "✅ Stress test script created on Pi"

echo ""
echo "🔥 STARTING 5-DEVICE VIDEO STREAMING STRESS TEST 🔥"
echo ""
echo "This will:"
echo "- Simulate 5 devices simultaneously downloading video files"
echo "- Monitor temperature, CPU load, memory usage"
echo "- Determine if cooling/fan is needed"
echo "- Test realistic exhibition load"
echo ""
echo "Press ENTER to start the stress test, or Ctrl+C to cancel"
read

echo "Starting stress test..."
ssh "$PI_HOST" "sudo /tmp/video-stress-test.sh"

echo ""
echo "📊 STRESS TEST ANALYSIS"
echo "Getting final system status..."
ssh "$PI_HOST" "
echo 'Final temperature:' && vcgencmd measure_temp 2>/dev/null || echo 'N/A'
echo 'System load:' && cat /proc/loadavg
echo 'Memory usage:' && free -h | grep Mem
echo 'Disk I/O:' && iostat -d 1 1 2>/dev/null | tail -1 || echo 'iostat not available'
echo ''
echo 'Stress test log summary:'
grep -E 'RECOMMENDATION|Maximum temperature|Temperature warnings' /tmp/stress-test.log || echo 'No log found'
"