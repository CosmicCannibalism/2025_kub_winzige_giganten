#!/bin/bash
#
# Power Consumption Comparison: Download vs Playback
# Tests which scenario is more intensive for the Pi Zero 2W
#
# This will compare:
# 1. Downloading large files (network + disk writes)
# 2. Video playback simulation (CPU decoding + continuous streaming)

PI_HOST="cosmic@cosmicpi.local"

echo "=== Power/Heat Test: Download vs Video Playback ==="
echo "Testing which scenario is more intensive for Pi Zero 2W"
echo "Target: $PI_HOST"
echo ""

# Check Pi connection
if ! ssh -o ConnectTimeout=5 "$PI_HOST" "echo 'Pi connection OK'" 2>/dev/null; then
    echo "ERROR: Cannot connect to $PI_HOST"
    exit 1
fi

echo "✅ Pi connection verified"

# Create comparison test script on Pi
echo "Creating power comparison test script on Pi..."
ssh "$PI_HOST" "cat > /tmp/power-comparison-test.sh << 'EOF'
#!/bin/bash
#
# Power Consumption Comparison Test

LOG_FILE=\"/tmp/power-test.log\"
VIDEO_PATH=\"/var/www/html/videos\"

log_msg() {
    echo \"\$(date '+%Y-%m-%d %H:%M:%S') [POWER-TEST] \$1\" | tee -a \"\$LOG_FILE\"
}

# Function to get detailed system stats
get_detailed_stats() {
    local temp=\$(vcgencmd measure_temp 2>/dev/null | cut -d'=' -f2 | cut -d\"'\" -f1 || echo \"N/A\")
    local cpu_freq=\$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo \"N/A\")
    local cpu_usage=\$(top -bn1 | grep \"Cpu(s)\" | awk '{print \$2}' | cut -d'%' -f1 || echo \"N/A\")
    local load=\$(cat /proc/loadavg | cut -d' ' -f1)
    local mem=\$(free | grep Mem | awk '{printf \"%.1f\", (\$3/\$2)*100}')
    local network_tx=\$(cat /sys/class/net/ap0/statistics/tx_bytes 2>/dev/null || echo 0)
    
    echo \"Temp: \${temp}°C, CPU: \${cpu_usage}%, Freq: \${cpu_freq}Hz, Load: \$load, Mem: \${mem}%, TX: \$network_tx bytes\"
}

# Test 1: Baseline (idle system)
log_msg \"=== BASELINE TEST (Idle System) ===\"
log_msg \"Measuring idle system for 30 seconds...\"

BASELINE_TEMPS=()
for i in {1..6}; do
    STATS=\$(get_detailed_stats)
    log_msg \"Baseline [\$i]: \$STATS\"
    TEMP=\$(echo \"\$STATS\" | grep -o 'Temp: [0-9.]*' | cut -d' ' -f2)
    BASELINE_TEMPS+=(\$TEMP)
    sleep 5
done

# Calculate baseline average
BASELINE_AVG=\$(echo \"\${BASELINE_TEMPS[@]}\" | tr ' ' '\n' | awk '{sum+=\$1} END {printf \"%.1f\", sum/NR}')
log_msg \"Baseline average temperature: \${BASELINE_AVG}°C\"

# Test 2: Download scenario (5 concurrent downloads)
log_msg \"=== DOWNLOAD TEST (5 Concurrent Downloads) ===\"
log_msg \"Starting 5 concurrent downloads...\"

# Start downloads
DOWNLOAD_PIDS=()
for i in {1..5}; do
    (
        cd /tmp
        curl -o \"download_test_\${i}.mp4\" \\
             --limit-rate 2M \\
             --connect-timeout 10 \\
             --max-time 120 \\
             \"http://192.168.4.1/videos/main_02.mp4\" \\
             >/dev/null 2>&1
    ) &
    DOWNLOAD_PIDS+=(\$!)
    sleep 1
done

# Monitor downloads for 60 seconds
DOWNLOAD_TEMPS=()
for i in {1..12}; do
    STATS=\$(get_detailed_stats)
    log_msg \"Download [\$i]: \$STATS\"
    TEMP=\$(echo \"\$STATS\" | grep -o 'Temp: [0-9.]*' | cut -d' ' -f2)
    DOWNLOAD_TEMPS+=(\$TEMP)
    sleep 5
done

# Stop downloads
for pid in \"\${DOWNLOAD_PIDS[@]}\"; do
    kill \$pid 2>/dev/null || true
done

# Calculate download average
DOWNLOAD_AVG=\$(echo \"\${DOWNLOAD_TEMPS[@]}\" | tr ' ' '\n' | awk '{sum+=\$1} END {printf \"%.1f\", sum/NR}')
DOWNLOAD_MAX=\$(echo \"\${DOWNLOAD_TEMPS[@]}\" | tr ' ' '\n' | sort -n | tail -1)
log_msg \"Download average temperature: \${DOWNLOAD_AVG}°C\"
log_msg \"Download maximum temperature: \${DOWNLOAD_MAX}°C\"

# Wait for system to cool down
log_msg \"Cooling down system for 30 seconds...\"
sleep 30

# Test 3: Video playback simulation (continuous streaming)
log_msg \"=== PLAYBACK TEST (Continuous Video Streaming) ===\"
log_msg \"Simulating continuous video playback with HTTP range requests...\"

# Simulate video playback with range requests (like progressive download)
PLAYBACK_PIDS=()
for client in {1..5}; do
    (
        # Simulate video player making range requests (progressive streaming)
        VIDEO_SIZE=\$(stat -c%s \"\$VIDEO_PATH/main_02.mp4\" 2>/dev/null || echo 913661952)
        CHUNK_SIZE=524288  # 512KB chunks
        
        for offset in \$(seq 0 \$CHUNK_SIZE \$VIDEO_SIZE | head -20); do
            END_OFFSET=\$((offset + CHUNK_SIZE - 1))
            if [ \$END_OFFSET -gt \$VIDEO_SIZE ]; then
                END_OFFSET=\$VIDEO_SIZE
            fi
            
            curl -H \"Range: bytes=\${offset}-\${END_OFFSET}\" \\
                 -o /dev/null \\
                 \"http://192.168.4.1/videos/main_02.mp4\" \\
                 >/dev/null 2>&1
            
            # Simulate playback timing (not just downloading)
            sleep 0.5
        done
    ) &
    PLAYBACK_PIDS+=(\$!)
    sleep 1
done

# Monitor playback for 60 seconds
PLAYBACK_TEMPS=()
for i in {1..12}; do
    STATS=\$(get_detailed_stats)
    log_msg \"Playback [\$i]: \$STATS\"
    TEMP=\$(echo \"\$STATS\" | grep -o 'Temp: [0-9.]*' | cut -d' ' -f2)
    PLAYBACK_TEMPS+=(\$TEMP)
    sleep 5
done

# Stop playback simulation
for pid in \"\${PLAYBACK_PIDS[@]}\"; do
    kill \$pid 2>/dev/null || true
done

# Calculate playback average
PLAYBACK_AVG=\$(echo \"\${PLAYBACK_TEMPS[@]}\" | tr ' ' '\n' | awk '{sum+=\$1} END {printf \"%.1f\", sum/NR}')
PLAYBACK_MAX=\$(echo \"\${PLAYBACK_TEMPS[@]}\" | tr ' ' '\n' | sort -n | tail -1)
log_msg \"Playback average temperature: \${PLAYBACK_AVG}°C\"
log_msg \"Playback maximum temperature: \${PLAYBACK_MAX}°C\"

# Final comparison
log_msg \"=== POWER CONSUMPTION COMPARISON RESULTS ===\"
log_msg \"Baseline (Idle):     Avg: \${BASELINE_AVG}°C\"
log_msg \"Download Scenario:   Avg: \${DOWNLOAD_AVG}°C, Max: \${DOWNLOAD_MAX}°C\"
log_msg \"Playback Scenario:   Avg: \${PLAYBACK_AVG}°C, Max: \${PLAYBACK_MAX}°C\"

# Determine which is more intensive
DOWNLOAD_INCREASE=\$(echo \"\$DOWNLOAD_AVG - \$BASELINE_AVG\" | bc -l 2>/dev/null || echo \"0\")
PLAYBACK_INCREASE=\$(echo \"\$PLAYBACK_AVG - \$BASELINE_AVG\" | bc -l 2>/dev/null || echo \"0\")

log_msg \"Temperature increase from baseline:\"
log_msg \"Download: +\${DOWNLOAD_INCREASE}°C\"
log_msg \"Playback: +\${PLAYBACK_INCREASE}°C\"

if (( \$(echo \"\$PLAYBACK_AVG > \$DOWNLOAD_AVG\" | bc -l 2>/dev/null || echo 0) )); then
    log_msg \"CONCLUSION: Video PLAYBACK is more power intensive than downloading\"
    INTENSIVE_SCENARIO=\"playback\"
    TEMP_DIFF=\$(echo \"\$PLAYBACK_AVG - \$DOWNLOAD_AVG\" | bc -l 2>/dev/null || echo \"0\")
elif (( \$(echo \"\$DOWNLOAD_AVG > \$PLAYBACK_AVG\" | bc -l 2>/dev/null || echo 0) )); then
    log_msg \"CONCLUSION: DOWNLOADING is more power intensive than playback\"
    INTENSIVE_SCENARIO=\"download\"
    TEMP_DIFF=\$(echo \"\$DOWNLOAD_AVG - \$PLAYBACK_AVG\" | bc -l 2>/dev/null || echo \"0\")
else
    log_msg \"CONCLUSION: Download and playback have similar power consumption\"
    INTENSIVE_SCENARIO=\"similar\"
    TEMP_DIFF=\"0\"
fi

log_msg \"Most intensive scenario: \$INTENSIVE_SCENARIO (difference: \${TEMP_DIFF}°C)\"

# Exhibition recommendation
MAX_TEMP=\$(echo -e \"\$DOWNLOAD_MAX\n\$PLAYBACK_MAX\" | sort -n | tail -1)
log_msg \"Maximum temperature during any test: \${MAX_TEMP}°C\"

if (( \$(echo \"\$MAX_TEMP >= 75\" | bc -l 2>/dev/null || echo 0) )); then
    log_msg \"EXHIBITION RECOMMENDATION: Fan/cooling REQUIRED\"
elif (( \$(echo \"\$MAX_TEMP >= 70\" | bc -l 2>/dev/null || echo 0) )); then
    log_msg \"EXHIBITION RECOMMENDATION: Fan/cooling RECOMMENDED\"
elif (( \$(echo \"\$MAX_TEMP >= 65\" | bc -l 2>/dev/null || echo 0) )); then
    log_msg \"EXHIBITION RECOMMENDATION: Fan/cooling OPTIONAL\"
else
    log_msg \"EXHIBITION RECOMMENDATION: No cooling needed\"
fi

log_msg \"=== Power Comparison Test Completed ===\"

# Cleanup
rm /tmp/download_test_*.mp4 2>/dev/null || true
EOF

chmod +x /tmp/power-comparison-test.sh"

echo "✅ Power comparison test script created on Pi"

echo ""
echo "🔋 STARTING POWER CONSUMPTION COMPARISON 🔋"
echo ""
echo "This comprehensive test will compare:"
echo "1. 📊 BASELINE: Idle system power consumption"
echo "2. ⬇️  DOWNLOAD: 5 devices downloading large files"
echo "3. ▶️  PLAYBACK: 5 devices streaming video (progressive download)"
echo ""
echo "We'll measure temperature, CPU usage, and network activity"
echo "to determine which scenario uses more power."
echo ""
echo "Press ENTER to start the comprehensive test, or Ctrl+C to cancel"
read

echo "Starting power consumption comparison test..."
ssh "$PI_HOST" "sudo /tmp/power-comparison-test.sh"

echo ""
echo "📊 FINAL ANALYSIS"
echo "Getting final system status..."
ssh "$PI_HOST" "
echo '=== FINAL SYSTEM STATUS ==='
echo 'Current temperature:' && vcgencmd measure_temp 2>/dev/null || echo 'N/A'
echo 'System load:' && cat /proc/loadavg
echo 'Memory usage:' && free -h | grep Mem
echo ''
echo '=== TEST RESULTS SUMMARY ==='
grep -E 'CONCLUSION|EXHIBITION RECOMMENDATION|Most intensive|Maximum temperature' /tmp/power-test.log || echo 'No results found'
"