#!/bin/bash

################################################################################
# SCRIPT NAME: System Health Monitor
# PURPOSE: Checks server health and sends alerts when resources are low
# AUTHOR: DevOps Automation
# USE CASE: Monitor production servers requiring high availability
################################################################################

# -----------------------------------------------------------------------------
# STEP 1: Set up configuration (change these values as needed)
# -----------------------------------------------------------------------------

# Set threshold limits (when to send alert)
CPU_THRESHOLD=80          # Alert if CPU usage is above 80%
MEMORY_THRESHOLD=80       # Alert if Memory usage is above 80%
DISK_THRESHOLD=85         # Alert if Disk usage is above 85%

# Where to save the report
REPORT_FILE="/tmp/health_report_$(date +%Y%m%d_%H%M%S).txt"

# Email for alerts (change this to your email)
ALERT_EMAIL="ops-team@example.com"

# Color codes for terminal output (makes it look professional)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# STEP 2: Function to check CPU usage
# -----------------------------------------------------------------------------
check_cpu() {
    echo "=== Checking CPU Usage ===" | tee -a "$REPORT_FILE"

    # Get CPU usage percentage (100 minus idle time = used time)
    # 'top' command shows CPU stats, we extract the idle % and calculate usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)

    # If 'top' command format is different on Mac, use alternative method
    if [ -z "$CPU_USAGE" ]; then
        # For Mac systems, use different command
        CPU_USAGE=$(ps -A -o %cpu | awk '{s+=$1} END {print s}')
    fi

    # Convert to integer for comparison (remove decimal point)
    CPU_USAGE_INT=${CPU_USAGE%.*}

    echo "Current CPU Usage: ${CPU_USAGE_INT}%" | tee -a "$REPORT_FILE"

    # Check if CPU usage is above threshold
    if [ "$CPU_USAGE_INT" -gt "$CPU_THRESHOLD" ]; then
        echo -e "${RED}⚠️  ALERT: CPU usage is HIGH!${NC}" | tee -a "$REPORT_FILE"
        return 1  # Return error code
    else
        echo -e "${GREEN}✓ CPU usage is normal${NC}" | tee -a "$REPORT_FILE"
        return 0  # Return success code
    fi
}

# -----------------------------------------------------------------------------
# STEP 3: Function to check Memory usage
# -----------------------------------------------------------------------------
check_memory() {
    echo "" | tee -a "$REPORT_FILE"
    echo "=== Checking Memory Usage ===" | tee -a "$REPORT_FILE"

    # Get memory usage using 'free' command
    # 'free' shows total, used, and available memory
    MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.0f"), $3/$2 * 100.0}')

    # Alternative for Mac (if 'free' command not available)
    if [ -z "$MEMORY_USAGE" ]; then
        # Mac doesn't have 'free', so we use 'vm_stat'
        MEMORY_USAGE=$(vm_stat | awk '/Pages active/ {active=$3} /Pages wired/ {wired=$4} /Pages free/ {free=$3} END {gsub(/\./,"",active); gsub(/\./,"",wired); gsub(/\./,"",free); printf "%.0f\n", ((active+wired)/(active+wired+free))*100}')
    fi

    echo "Current Memory Usage: ${MEMORY_USAGE}%" | tee -a "$REPORT_FILE"

    # Check if Memory usage is above threshold
    if [ "$MEMORY_USAGE" -gt "$MEMORY_THRESHOLD" ]; then
        echo -e "${RED}⚠️  ALERT: Memory usage is HIGH!${NC}" | tee -a "$REPORT_FILE"
        return 1
    else
        echo -e "${GREEN}✓ Memory usage is normal${NC}" | tee -a "$REPORT_FILE"
        return 0
    fi
}

# -----------------------------------------------------------------------------
# STEP 4: Function to check Disk usage
# -----------------------------------------------------------------------------
check_disk() {
    echo "" | tee -a "$REPORT_FILE"
    echo "=== Checking Disk Usage ===" | tee -a "$REPORT_FILE"

    # Get disk usage for root partition
    # 'df' command shows disk space usage
    # -h makes it human readable, we check / (root) partition
    DISK_USAGE=$(df -h / | grep / | awk '{print $5}' | cut -d'%' -f1)

    echo "Current Disk Usage: ${DISK_USAGE}%" | tee -a "$REPORT_FILE"

    # Check if Disk usage is above threshold
    if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
        echo -e "${RED}⚠️  ALERT: Disk usage is HIGH!${NC}" | tee -a "$REPORT_FILE"
        return 1
    else
        echo -e "${GREEN}✓ Disk usage is normal${NC}" | tee -a "$REPORT_FILE"
        return 0
    fi
}

# -----------------------------------------------------------------------------
# STEP 5: Function to check if important services are running
# -----------------------------------------------------------------------------
check_services() {
    echo "" | tee -a "$REPORT_FILE"
    echo "=== Checking Critical Services ===" | tee -a "$REPORT_FILE"

    # List of critical services to check (add your services here)
    SERVICES=("sshd" "cron")

    for service in "${SERVICES[@]}"; do
        # Check if service is running using 'systemctl' or 'ps'
        if systemctl is-active --quiet "$service" 2>/dev/null || pgrep "$service" > /dev/null; then
            echo -e "${GREEN}✓ $service is running${NC}" | tee -a "$REPORT_FILE"
        else
            echo -e "${YELLOW}⚠️  WARNING: $service is not running${NC}" | tee -a "$REPORT_FILE"
        fi
    done
}

# -----------------------------------------------------------------------------
# STEP 6: Function to send alert email (if needed)
# -----------------------------------------------------------------------------
send_alert() {
    local alert_message=$1

    echo "" | tee -a "$REPORT_FILE"
    echo "=== Sending Alert ===" | tee -a "$REPORT_FILE"

    # In real production, you would send email using 'mail' command or API
    # For demo, we just save to file
    echo "ALERT: $alert_message" >> "$REPORT_FILE"

    # Example email command (uncomment when email is configured):
    # echo "$alert_message" | mail -s "Server Health Alert" "$ALERT_EMAIL"

    echo "Alert logged to $REPORT_FILE"
}

# -----------------------------------------------------------------------------
# STEP 7: Main execution - Run all checks
# -----------------------------------------------------------------------------
main() {
    echo "==========================================="
    echo "    SERVER HEALTH CHECK REPORT"
    echo "    Date: $(date)"
    echo "==========================================="
    echo ""

    # Initialize alert flag
    ALERT_NEEDED=0

    # Run all health checks
    check_cpu || ALERT_NEEDED=1
    check_memory || ALERT_NEEDED=1
    check_disk || ALERT_NEEDED=1
    check_services

    # Final summary
    echo "" | tee -a "$REPORT_FILE"
    echo "==========================================="
    if [ $ALERT_NEEDED -eq 1 ]; then
        echo -e "${RED}SYSTEM STATUS: ALERT - Action Required!${NC}" | tee -a "$REPORT_FILE"
        send_alert "Server health check failed. Please review $REPORT_FILE"
    else
        echo -e "${GREEN}SYSTEM STATUS: All systems normal ✓${NC}" | tee -a "$REPORT_FILE"
    fi
    echo "==========================================="
    echo ""
    echo "Full report saved to: $REPORT_FILE"
}

# -----------------------------------------------------------------------------
# Run the script
# -----------------------------------------------------------------------------
main

################################################################################
# HOW TO USE THIS SCRIPT:
#
# 1. Make it executable: chmod +x system_health_monitor.sh
# 2. Run manually: ./system_health_monitor.sh
# 3. Schedule in cron (run every 15 minutes):
#    crontab -e
#    Add line: */15 * * * * /path/to/system_health_monitor.sh
#
# KEY BENEFITS:
# - Proactive monitoring prevents system outages
# - Automated alerts save time from manual checking
# - Threshold-based notifications reduce alert fatigue
# - Can be integrated with Slack, PagerDuty, or email systems
# - Ideal for production environments requiring high availability
#
# ENHANCEMENT IDEAS:
# - Add support for custom metrics (network, application-specific)
# - Integrate with time-series databases for historical analysis
# - Add support for monitoring multiple servers from single script
# - Implement predictive alerting based on trends
################################################################################
