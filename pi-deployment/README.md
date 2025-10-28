# Raspberry Pi Deployment Scripts

Exhibition hardening and deployment scripts for the Winzige Giganten installation.

## Deployment Scripts

### Main Deployment
- **`deploy-exhibition-scripts.sh`** - Deploy all monitoring and watchdog scripts to Pi
- **`deploy-device-limits.sh`** - Configure 5-device connection limit
- **`deploy-optimization.sh`** - Deploy system optimizations (SD card preservation, memory tuning)
- **`setup_pi.sh`** - Initial Pi setup script

### Testing Scripts
All testing scripts are in the `testing/` folder:
- **`exhibition-readiness-test.sh`** - Comprehensive exhibition readiness validation
- **`stress-test-5-devices.sh`** - Test 5 concurrent device connections
- **`power-comparison-test.sh`** - Compare power consumption scenarios

### Monitoring Scripts
All monitoring scripts are in the `scripts/` folder:
- **`wg-emergency-reboot.sh`** - Emergency reboot handler
- **`wg-log-manager.sh`** - Log rotation and management
- **`wg-maintenance.sh`** - Weekly maintenance tasks
- **`configure-device-limits.sh`** - Device limiting configuration
- **`exhibition-optimization.sh`** - System optimization settings
- **`exhibition-crontab`** - Cron job configuration

## Usage

1. Deploy monitoring system:
   ```bash
   ./deploy-exhibition-scripts.sh
   ```

2. Deploy device limits:
   ```bash
   ./deploy-device-limits.sh
   ```

3. Deploy optimizations:
   ```bash
   ./deploy-optimization.sh
   ```

4. Run readiness test:
   ```bash
   ./testing/exhibition-readiness-test.sh
   ```

## System Validated
- ✅ 3 successful power cycles without issues
- ✅ Autonomous recovery operational
- ✅ Exhibition-ready for 3-5 month deployment
