#!/bin/bash
#
# Exhibition Readiness Test Suite
# Comprehensive testing for 3-5 month autonomous operation
#
# This script performs:
# 1. Service failure simulation and recovery testing
# 2. Network interface stress testing  
# 3. Temperature stress testing
# 4. Memory/disk stress testing
# 5. Watchdog failure recovery testing
# 6. Complete system validation

PI_HOST="cosmic@cosmicpi.local"

echo "=== EXHIBITION READINESS TEST SUITE ==="
echo "Comprehensive testing for 3-5 month autonomous operation"
echo "Target: $PI_HOST"
echo ""

# Check Pi connection
if ! ssh -o ConnectTimeout=5 "$PI_HOST" "echo 'Pi connection OK'" 2>/dev/null; then
    echo "ERROR: Cannot connect to $PI_HOST"
    exit 1
fi

echo "✅ Pi connection verified"

# Create comprehensive test script on Pi
echo "Creating exhibition readiness test script on Pi..."
ssh "$PI_HOST" "cat > /tmp/exhibition-readiness-test.sh << 'EOF'
#!/bin/bash
#
# Exhibition Readiness Test Suite
# Comprehensive failure simulation and recovery testing

TEST_LOG=\"/tmp/readiness-test.log\"
RESULTS_LOG=\"/tmp/readiness-results.log\"

log_test() {
    echo \"\$(date '+%Y-%m-%d %H:%M:%S') [TEST] \$1\" | tee -a \"\$TEST_LOG\"
}

log_result() {
    echo \"\$(date '+%Y-%m-%d %H:%M:%S') [RESULT] \$1\" | tee -a \"\$RESULTS_LOG\"
}

# Function to get system status
get_system_status() {
    local temp=\$(vcgencmd measure_temp 2>/dev/null | cut -d'=' -f2 | cut -d\"'\" -f1 || echo \"N/A\")
    local mem=\$(free | grep Mem | awk '{printf \"%.1f\", (\$3/\$2)*100}')
    local load=\$(cat /proc/loadavg | cut -d' ' -f1)
    local disk=\$(df / | tail -1 | awk '{print \$5}' | sed 's/%//')
    
    echo \"Temp: \${temp}°C, Mem: \${mem}%, Load: \$load, Disk: \${disk}%\"
}

# Function to check service status
check_services() {
    local services=(\"hostapd\" \"dnsmasq\" \"nginx\" \"wg-ap\" \"watchdog\")
    local failed_services=()
    
    for service in \"\${services[@]}\"; do
        if ! systemctl is-active --quiet \"\$service\" 2>/dev/null; then
            failed_services+=(\"\$service\")
        fi
    done
    
    if [ \${#failed_services[@]} -eq 0 ]; then
        echo \"ALL_ACTIVE\"
    else
        echo \"FAILED: \${failed_services[*]}\"
    fi
}

# Function to test WiFi connectivity
test_wifi() {
    # Check if ap0 interface has IP
    if ip addr show ap0 | grep -q \"192.168.4.1\"; then
        # Test internal connectivity
        if ping -c 1 192.168.4.1 >/dev/null 2>&1; then
            echo \"WIFI_OK\"
        else
            echo \"WIFI_IP_FAIL\"
        fi
    else
        echo \"WIFI_NO_IP\"
    fi
}

log_test \"=== EXHIBITION READINESS TEST SUITE STARTED ===\"
log_test \"Initial system status: \$(get_system_status)\"

# Test 1: Baseline System Health Check
log_test \"=== TEST 1: BASELINE SYSTEM HEALTH ===\"
INITIAL_SERVICES=\$(check_services)
INITIAL_WIFI=\$(test_wifi)
INITIAL_STATUS=\$(get_system_status)

log_test \"Services: \$INITIAL_SERVICES\"
log_test \"WiFi: \$INITIAL_WIFI\"
log_test \"System: \$INITIAL_STATUS\"

if [[ \"\$INITIAL_SERVICES\" == \"ALL_ACTIVE\" ]] && [[ \"\$INITIAL_WIFI\" == \"WIFI_OK\" ]]; then
    log_result \"✅ BASELINE: System healthy - all services active, WiFi operational\"
    BASELINE_PASS=true
else
    log_result \"❌ BASELINE: System issues detected - Services: \$INITIAL_SERVICES, WiFi: \$INITIAL_WIFI\"
    BASELINE_PASS=false
fi

# Test 2: Service Failure and Recovery Simulation
log_test \"=== TEST 2: SERVICE FAILURE RECOVERY ===\"

# Test hostapd recovery
log_test \"Simulating hostapd failure...\"
systemctl stop hostapd
sleep 5
AFTER_HOSTAPD_STOP=\$(check_services)
log_test \"After hostapd stop: \$AFTER_HOSTAPD_STOP\"

# Wait for watchdog to detect and recover
log_test \"Waiting 30 seconds for watchdog recovery...\"
sleep 30
AFTER_RECOVERY=\$(check_services)
WIFI_RECOVERY=\$(test_wifi)
log_test \"After recovery wait: Services=\$AFTER_RECOVERY, WiFi=\$WIFI_RECOVERY\"

if [[ \"\$AFTER_RECOVERY\" == \"ALL_ACTIVE\" ]] && [[ \"\$WIFI_RECOVERY\" == \"WIFI_OK\" ]]; then
    log_result \"✅ SERVICE_RECOVERY: hostapd automatically recovered\"
    SERVICE_RECOVERY_PASS=true
else
    log_result \"❌ SERVICE_RECOVERY: Manual recovery needed - Services: \$AFTER_RECOVERY, WiFi: \$WIFI_RECOVERY\"
    # Manual recovery attempt
    /usr/local/sbin/wg-ap-up.sh >/dev/null 2>&1
    sleep 10
    MANUAL_RECOVERY=\$(check_services)
    log_result \"After manual recovery: \$MANUAL_RECOVERY\"
    SERVICE_RECOVERY_PASS=false
fi

# Test 3: Network Interface Stress Test
log_test \"=== TEST 3: NETWORK INTERFACE STRESS ===\"
log_test \"Simulating network interface reset...\"

# Reset network interface
ip link set ap0 down 2>/dev/null || true
sleep 2
ip link set ap0 up 2>/dev/null || true
sleep 5

# Check recovery
NETWORK_STATUS=\$(test_wifi)
log_test \"Network interface after reset: \$NETWORK_STATUS\"

if [[ \"\$NETWORK_STATUS\" == \"WIFI_OK\" ]]; then
    log_result \"✅ NETWORK_STRESS: Interface recovered successfully\"
    NETWORK_STRESS_PASS=true
else
    log_result \"❌ NETWORK_STRESS: Interface recovery failed - Status: \$NETWORK_STATUS\"
    NETWORK_STRESS_PASS=false
fi

# Test 4: Temperature Monitoring Test
log_test \"=== TEST 4: TEMPERATURE MONITORING ===\"
log_test \"Testing temperature monitoring system...\"

# Run temperature monitor
/usr/local/sbin/wg-temp-monitor.sh
TEMP_LOG_EXISTS=false
if [ -f \"/var/log/exhibition/temperature.log\" ]; then
    TEMP_ENTRIES=\$(wc -l < /var/log/exhibition/temperature.log)
    log_test \"Temperature log entries: \$TEMP_ENTRIES\"
    if [ \"\$TEMP_ENTRIES\" -gt 0 ]; then
        TEMP_LOG_EXISTS=true
    fi
fi

if \$TEMP_LOG_EXISTS; then
    log_result \"✅ TEMPERATURE: Monitoring system operational\"
    TEMPERATURE_PASS=true
else
    log_result \"❌ TEMPERATURE: Monitoring system not logging\"
    TEMPERATURE_PASS=false
fi

# Test 5: Memory and Disk Stress Test
log_test \"=== TEST 5: MEMORY/DISK STRESS ===\"
BEFORE_STRESS=\$(get_system_status)
log_test \"Before stress: \$BEFORE_STRESS\"

# Create memory pressure
log_test \"Creating memory pressure test...\"
dd if=/dev/zero of=/tmp/stress_test bs=1M count=100 2>/dev/null &
STRESS_PID=\$!
sleep 10

DURING_STRESS=\$(get_system_status)
log_test \"During stress: \$DURING_STRESS\"

# Stop stress test
kill \$STRESS_PID 2>/dev/null || true
rm /tmp/stress_test 2>/dev/null || true
sleep 5

AFTER_STRESS=\$(get_system_status)
log_test \"After stress: \$AFTER_STRESS\"

# Check if system remained stable
STRESS_SERVICES=\$(check_services)
if [[ \"\$STRESS_SERVICES\" == \"ALL_ACTIVE\" ]]; then
    log_result \"✅ STRESS_TEST: System stable under memory/disk stress\"
    STRESS_PASS=true
else
    log_result \"❌ STRESS_TEST: System unstable - Services: \$STRESS_SERVICES\"
    STRESS_PASS=false
fi

# Test 6: Watchdog System Test
log_test \"=== TEST 6: WATCHDOG SYSTEM ===\"
log_test \"Testing software watchdog...\"

# Run watchdog check
WATCHDOG_OUTPUT=\$(/usr/local/sbin/wg-watchdog.sh check 2>&1 | tail -3)
log_test \"Watchdog output: \$WATCHDOG_OUTPUT\"

# Check watchdog status file
WATCHDOG_STATUS=\"UNKNOWN\"
if [ -f \"/run/wg-watchdog.status\" ]; then
    WATCHDOG_STATUS=\$(cat /run/wg-watchdog.status)
elif [ -f \"/tmp/wg-watchdog-status\" ]; then
    WATCHDOG_STATUS=\$(cat /tmp/wg-watchdog-status)
fi

log_test \"Watchdog status: \$WATCHDOG_STATUS\"

if [[ \"\$WATCHDOG_STATUS\" == \"HEALTHY\" ]]; then
    log_result \"✅ WATCHDOG: Software watchdog operational\"
    WATCHDOG_PASS=true
else
    log_result \"❌ WATCHDOG: Software watchdog issues - Status: \$WATCHDOG_STATUS\"
    WATCHDOG_PASS=false
fi

# Test 7: Device Connection Limiting Test
log_test \"=== TEST 7: DEVICE CONNECTION LIMITS ===\"
log_test \"Testing device connection limiting...\"

# Check hostapd max connections
MAX_CONNECTIONS=\$(grep max_num_sta /etc/hostapd/hostapd.conf | cut -d'=' -f2 || echo \"NOT_SET\")
DHCP_RANGE=\$(grep dhcp-range /etc/dnsmasq.d/10-wg-ap.conf || echo \"NOT_SET\")

log_test \"Max connections: \$MAX_CONNECTIONS\"
log_test \"DHCP range: \$DHCP_RANGE\"

if [[ \"\$MAX_CONNECTIONS\" == \"5\" ]] && [[ \"\$DHCP_RANGE\" == *\"192.168.4.14\"* ]]; then
    log_result \"✅ DEVICE_LIMITS: Connection limiting properly configured\"
    DEVICE_LIMITS_PASS=true
else
    log_result \"❌ DEVICE_LIMITS: Configuration issues - Max: \$MAX_CONNECTIONS, DHCP: \$DHCP_RANGE\"
    DEVICE_LIMITS_PASS=false
fi

# Test 8: Exhibition Monitoring System Test
log_test \"=== TEST 8: EXHIBITION MONITORING ===\"
log_test \"Testing exhibition monitoring system...\"

# Check cron jobs
CRON_JOBS=\$(crontab -l | grep -c wg- || echo \"0\")
EXHIBITION_LOGS=\$(ls /var/log/exhibition/ | wc -l)

log_test \"Cron monitoring jobs: \$CRON_JOBS\"
log_test \"Exhibition log files: \$EXHIBITION_LOGS\"

if [ \"\$CRON_JOBS\" -gt 3 ] && [ \"\$EXHIBITION_LOGS\" -gt 3 ]; then
    log_result \"✅ MONITORING: Exhibition monitoring system active\"
    MONITORING_PASS=true
else
    log_result \"❌ MONITORING: Issues detected - Cron jobs: \$CRON_JOBS, Log files: \$EXHIBITION_LOGS\"
    MONITORING_PASS=false
fi

# Final Results Summary
log_test \"=== EXHIBITION READINESS TEST RESULTS ===\"
TOTAL_TESTS=8
PASSED_TESTS=0

if \$BASELINE_PASS; then ((PASSED_TESTS++)); fi
if \$SERVICE_RECOVERY_PASS; then ((PASSED_TESTS++)); fi
if \$NETWORK_STRESS_PASS; then ((PASSED_TESTS++)); fi
if \$TEMPERATURE_PASS; then ((PASSED_TESTS++)); fi
if \$STRESS_PASS; then ((PASSED_TESTS++)); fi
if \$WATCHDOG_PASS; then ((PASSED_TESTS++)); fi
if \$DEVICE_LIMITS_PASS; then ((PASSED_TESTS++)); fi
if \$MONITORING_PASS; then ((PASSED_TESTS++)); fi

PASS_PERCENTAGE=\$((\$PASSED_TESTS * 100 / \$TOTAL_TESTS))

log_result \"\"
log_result \"=== FINAL EXHIBITION READINESS ASSESSMENT ===\"
log_result \"Tests passed: \$PASSED_TESTS/\$TOTAL_TESTS (\$PASS_PERCENTAGE%)\"
log_result \"\"

if [ \$PASSED_TESTS -eq \$TOTAL_TESTS ]; then
    log_result \"🎉 EXHIBITION READY: System passed all tests\"
    log_result \"✅ RECOMMENDATION: Safe to deploy for 3-5 month exhibition\"
elif [ \$PASSED_TESTS -ge 6 ]; then
    log_result \"⚠️  EXHIBITION CAUTION: Most tests passed, minor issues to address\"
    log_result \"🔧 RECOMMENDATION: Address failed tests before deployment\"
else
    log_result \"❌ EXHIBITION NOT READY: Multiple critical issues detected\"
    log_result \"🛠️  RECOMMENDATION: Do not deploy until issues resolved\"
fi

log_result \"\"
log_result \"Final system status: \$(get_system_status)\"
log_result \"Services: \$(check_services)\"
log_result \"WiFi: \$(test_wifi)\"
log_result \"\"
log_result \"Test completed at: \$(date)\"

EOF

chmod +x /tmp/exhibition-readiness-test.sh"

echo "✅ Exhibition readiness test script created on Pi"

echo ""
echo "🎯 STARTING COMPREHENSIVE EXHIBITION READINESS TEST 🎯"
echo ""
echo "This will perform:"
echo "1. 📊 Baseline system health check"
echo "2. 🔧 Service failure and recovery simulation"
echo "3. 🌐 Network interface stress testing"
echo "4. 🌡️ Temperature monitoring verification"
echo "5. 💾 Memory/disk stress testing"
echo "6. 🐕 Watchdog system testing"
echo "7. 🔒 Device connection limiting verification"
echo "8. 📈 Exhibition monitoring system test"
echo ""
echo "This comprehensive test will determine if your Pi is truly ready"
echo "for 3-5 month autonomous exhibition operation."
echo ""
echo "Press ENTER to start the readiness test, or Ctrl+C to cancel"
read

echo "Starting exhibition readiness test..."
ssh "$PI_HOST" "sudo /tmp/exhibition-readiness-test.sh"

echo ""
echo "📊 EXHIBITION READINESS ANALYSIS"
echo "Getting test results and system status..."
ssh "$PI_HOST" "
echo '=== TEST RESULTS SUMMARY ==='
cat /tmp/readiness-results.log 2>/dev/null || echo 'Results log not found'
echo ''
echo '=== CURRENT SYSTEM STATUS ==='
echo 'Services:' && systemctl is-active hostapd dnsmasq nginx --no-pager
echo 'Temperature:' && vcgencmd measure_temp 2>/dev/null || echo 'N/A'
echo 'Memory usage:' && free -h | grep Mem
echo 'Disk usage:' && df -h / | tail -1
echo 'WiFi status: winzige_giganten' && ip addr show ap0 | grep 192.168.4.1 && echo 'WiFi operational' || echo 'WiFi check needed'
"