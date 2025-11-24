#!/bin/bash

################################################################################
# SCRIPT NAME: Application Log Analyzer
# PURPOSE: Scans log files for errors, warnings, and anomalies
# AUTHOR: DevOps Automation
# USE CASE: Automated log analysis for quick problem detection in production
################################################################################

# -----------------------------------------------------------------------------
# STEP 1: Configuration
# -----------------------------------------------------------------------------

# Default log file to analyze (can be overridden by command line argument)
LOG_FILE="${1:-/var/log/application.log}"

# Output report file
REPORT_FILE="/tmp/log_analysis_$(date +%Y%m%d_%H%M%S).txt"

# How many recent lines to analyze (default: last 1000 lines)
LINES_TO_CHECK=1000

# Alert thresholds
ERROR_THRESHOLD=10      # Alert if more than 10 errors found
WARNING_THRESHOLD=50    # Alert if more than 50 warnings found

# Email for alerts
ALERT_EMAIL="ops-team@example.com"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# STEP 2: Function to check if log file exists
# -----------------------------------------------------------------------------
check_log_file() {
    echo -e "${BLUE}=== Checking Log File ===${NC}"

    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}ERROR: Log file not found: $LOG_FILE${NC}"
        echo "Usage: $0 /path/to/logfile.log"
        exit 1
    fi

    if [ ! -r "$LOG_FILE" ]; then
        echo -e "${RED}ERROR: Cannot read log file: $LOG_FILE${NC}"
        echo "Please check file permissions"
        exit 1
    fi

    # Get file size
    FILE_SIZE=$(du -h "$LOG_FILE" | cut -f1)
    echo -e "${GREEN}✓ Log file found: $LOG_FILE (Size: $FILE_SIZE)${NC}"
    echo ""
}

# -----------------------------------------------------------------------------
# STEP 3: Function to count ERROR messages
# -----------------------------------------------------------------------------
analyze_errors() {
    echo -e "${BLUE}=== Analyzing ERRORS ===${NC}" | tee -a "$REPORT_FILE"

    # Search for common error keywords (case insensitive)
    # grep -i = case insensitive search
    # tail = get last N lines only
    ERROR_COUNT=$(tail -n "$LINES_TO_CHECK" "$LOG_FILE" | grep -i -c "ERROR\|FATAL\|CRITICAL\|EXCEPTION")

    echo "Total ERROR/FATAL/CRITICAL/EXCEPTION found: $ERROR_COUNT" | tee -a "$REPORT_FILE"

    # Show top 5 error messages
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo "" | tee -a "$REPORT_FILE"
        echo "Top 5 recent error messages:" | tee -a "$REPORT_FILE"
        echo "----------------------------" | tee -a "$REPORT_FILE"
        tail -n "$LINES_TO_CHECK" "$LOG_FILE" | grep -i "ERROR\|FATAL\|CRITICAL\|EXCEPTION" | tail -5 | tee -a "$REPORT_FILE"
        echo "" | tee -a "$REPORT_FILE"

        # Check threshold
        if [ "$ERROR_COUNT" -gt "$ERROR_THRESHOLD" ]; then
            echo -e "${RED}⚠️  ALERT: Error count ($ERROR_COUNT) exceeds threshold ($ERROR_THRESHOLD)${NC}" | tee -a "$REPORT_FILE"
            return 1
        else
            echo -e "${YELLOW}⚠️  Errors found but within acceptable limits${NC}" | tee -a "$REPORT_FILE"
        fi
    else
        echo -e "${GREEN}✓ No errors found${NC}" | tee -a "$REPORT_FILE"
    fi

    echo "" | tee -a "$REPORT_FILE"
    return 0
}

# -----------------------------------------------------------------------------
# STEP 4: Function to count WARNING messages
# -----------------------------------------------------------------------------
analyze_warnings() {
    echo -e "${BLUE}=== Analyzing WARNINGS ===${NC}" | tee -a "$REPORT_FILE"

    # Search for warning keywords
    WARNING_COUNT=$(tail -n "$LINES_TO_CHECK" "$LOG_FILE" | grep -i -c "WARN\|WARNING")

    echo "Total WARNINGS found: $WARNING_COUNT" | tee -a "$REPORT_FILE"

    # Check threshold
    if [ "$WARNING_COUNT" -gt "$WARNING_THRESHOLD" ]; then
        echo -e "${YELLOW}⚠️  Warning count is high: $WARNING_COUNT${NC}" | tee -a "$REPORT_FILE"

        # Show sample warnings
        echo "" | tee -a "$REPORT_FILE"
        echo "Sample warning messages:" | tee -a "$REPORT_FILE"
        echo "------------------------" | tee -a "$REPORT_FILE"
        tail -n "$LINES_TO_CHECK" "$LOG_FILE" | grep -i "WARN\|WARNING" | tail -3 | tee -a "$REPORT_FILE"
    else
        echo -e "${GREEN}✓ Warning count is acceptable${NC}" | tee -a "$REPORT_FILE"
    fi

    echo "" | tee -a "$REPORT_FILE"
}

# -----------------------------------------------------------------------------
# STEP 5: Function to detect specific application issues
# -----------------------------------------------------------------------------
detect_specific_issues() {
    echo -e "${BLUE}=== Detecting Specific Issues ===${NC}" | tee -a "$REPORT_FILE"

    # Issue 1: Database connection problems
    DB_ERRORS=$(tail -n "$LINES_TO_CHECK" "$LOG_FILE" | grep -i -c "database.*error\|connection.*failed\|timeout")
    if [ "$DB_ERRORS" -gt 0 ]; then
        echo -e "${RED}⚠️  Database connection issues: $DB_ERRORS occurrences${NC}" | tee -a "$REPORT_FILE"
    else
        echo -e "${GREEN}✓ No database connection issues${NC}" | tee -a "$REPORT_FILE"
    fi

    # Issue 2: Out of memory errors
    MEMORY_ERRORS=$(tail -n "$LINES_TO_CHECK" "$LOG_FILE" | grep -i -c "out of memory\|memory.*full\|OutOfMemoryError")
    if [ "$MEMORY_ERRORS" -gt 0 ]; then
        echo -e "${RED}⚠️  Memory issues detected: $MEMORY_ERRORS occurrences${NC}" | tee -a "$REPORT_FILE"
    else
        echo -e "${GREEN}✓ No memory issues${NC}" | tee -a "$REPORT_FILE"
    fi

    # Issue 3: API/Network timeouts
    TIMEOUT_ERRORS=$(tail -n "$LINES_TO_CHECK" "$LOG_FILE" | grep -i -c "timeout\|timed out\|connection refused")
    if [ "$TIMEOUT_ERRORS" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Network/timeout issues: $TIMEOUT_ERRORS occurrences${NC}" | tee -a "$REPORT_FILE"
    else
        echo -e "${GREEN}✓ No timeout issues${NC}" | tee -a "$REPORT_FILE"
    fi

    # Issue 4: Authentication/Permission errors
    AUTH_ERRORS=$(tail -n "$LINES_TO_CHECK" "$LOG_FILE" | grep -i -c "unauthorized\|forbidden\|access denied\|authentication failed")
    if [ "$AUTH_ERRORS" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Authentication issues: $AUTH_ERRORS occurrences${NC}" | tee -a "$REPORT_FILE"
    else
        echo -e "${GREEN}✓ No authentication issues${NC}" | tee -a "$REPORT_FILE"
    fi

    echo "" | tee -a "$REPORT_FILE"
}

# -----------------------------------------------------------------------------
# STEP 6: Function to analyze performance and response times
# -----------------------------------------------------------------------------
analyze_performance() {
    echo -e "${BLUE}=== Analyzing Performance ===${NC}" | tee -a "$REPORT_FILE"

    # Look for slow response times (assuming logs have "response_time" or similar)
    SLOW_REQUESTS=$(tail -n "$LINES_TO_CHECK" "$LOG_FILE" | grep -i "response_time\|duration\|elapsed" | awk '{print $NF}' | grep -E "[0-9]+" | awk '{if($1 > 1000) count++} END {print count+0}')

    if [ "$SLOW_REQUESTS" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Slow requests detected: $SLOW_REQUESTS requests took >1000ms${NC}" | tee -a "$REPORT_FILE"
    else
        echo "Performance metrics look good" | tee -a "$REPORT_FILE"
    fi

    echo "" | tee -a "$REPORT_FILE"
}

# -----------------------------------------------------------------------------
# STEP 7: Function to find most frequent errors
# -----------------------------------------------------------------------------
find_top_errors() {
    echo -e "${BLUE}=== Top 5 Most Frequent Error Messages ===${NC}" | tee -a "$REPORT_FILE"

    # Extract error messages and count frequency
    # This helps identify recurring issues
    tail -n "$LINES_TO_CHECK" "$LOG_FILE" | \
        grep -i "ERROR\|EXCEPTION" | \
        awk -F'ERROR|EXCEPTION' '{print $2}' | \
        sort | uniq -c | sort -rn | head -5 | tee -a "$REPORT_FILE"

    echo "" | tee -a "$REPORT_FILE"
}

# -----------------------------------------------------------------------------
# STEP 8: Function to check for security issues
# -----------------------------------------------------------------------------
check_security_issues() {
    echo -e "${BLUE}=== Security Check ===${NC}" | tee -a "$REPORT_FILE"

    # Look for potential security issues in logs
    SECURITY_KEYWORDS=$(tail -n "$LINES_TO_CHECK" "$LOG_FILE" | grep -i -c "sql injection\|xss\|csrf\|hack\|attack\|breach\|malicious")

    if [ "$SECURITY_KEYWORDS" -gt 0 ]; then
        echo -e "${RED}⚠️  SECURITY ALERT: $SECURITY_KEYWORDS potential security-related messages found!${NC}" | tee -a "$REPORT_FILE"
        echo "Sample messages:" | tee -a "$REPORT_FILE"
        tail -n "$LINES_TO_CHECK" "$LOG_FILE" | grep -i "sql injection\|xss\|csrf\|hack\|attack\|breach\|malicious" | head -3 | tee -a "$REPORT_FILE"
    else
        echo -e "${GREEN}✓ No obvious security concerns in logs${NC}" | tee -a "$REPORT_FILE"
    fi

    echo "" | tee -a "$REPORT_FILE"
}

# -----------------------------------------------------------------------------
# STEP 9: Function to generate summary statistics
# -----------------------------------------------------------------------------
generate_statistics() {
    echo -e "${CYAN}=== Log Statistics ===${NC}" | tee -a "$REPORT_FILE"

    # Total lines analyzed
    TOTAL_LINES=$(tail -n "$LINES_TO_CHECK" "$LOG_FILE" | wc -l)
    echo "Total lines analyzed: $TOTAL_LINES" | tee -a "$REPORT_FILE"

    # Count by log level
    INFO_COUNT=$(tail -n "$LINES_TO_CHECK" "$LOG_FILE" | grep -i -c "INFO")
    DEBUG_COUNT=$(tail -n "$LINES_TO_CHECK" "$LOG_FILE" | grep -i -c "DEBUG")

    echo "INFO messages: $INFO_COUNT" | tee -a "$REPORT_FILE"
    echo "DEBUG messages: $DEBUG_COUNT" | tee -a "$REPORT_FILE"

    # Time range of logs being analyzed
    FIRST_TIMESTAMP=$(tail -n "$LINES_TO_CHECK" "$LOG_FILE" | head -1 | awk '{print $1, $2}')
    LAST_TIMESTAMP=$(tail -n "$LINES_TO_CHECK" "$LOG_FILE" | tail -1 | awk '{print $1, $2}')

    echo "Log time range: $FIRST_TIMESTAMP to $LAST_TIMESTAMP" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
}

# -----------------------------------------------------------------------------
# STEP 10: Main function - Run all analyses
# -----------------------------------------------------------------------------
main() {
    echo "=============================================="
    echo "     APPLICATION LOG ANALYSIS REPORT"
    echo "     Date: $(date)"
    echo "=============================================="
    echo "" | tee "$REPORT_FILE"

    # Check if log file exists
    check_log_file

    # Run all analysis functions
    generate_statistics
    analyze_errors
    analyze_warnings
    detect_specific_issues
    analyze_performance
    find_top_errors
    check_security_issues

    # Final summary
    echo "=============================================="
    echo "            ANALYSIS COMPLETE"
    echo "=============================================="
    echo -e "${GREEN}Full report saved to: $REPORT_FILE${NC}"
    echo ""

    # Offer to view the report
    echo "To view full report: cat $REPORT_FILE"
    echo "To view errors only: grep 'ERROR\|⚠️' $REPORT_FILE"
}

# -----------------------------------------------------------------------------
# Run the script
# -----------------------------------------------------------------------------
main

################################################################################
# HOW TO USE THIS SCRIPT:
#
# 1. Make executable: chmod +x log_analyzer.sh
# 2. Analyze default log: ./log_analyzer.sh
# 3. Analyze specific log: ./log_analyzer.sh /path/to/app.log
# 4. Schedule in cron (analyze every hour):
#    0 * * * * /path/to/log_analyzer.sh /var/log/application.log
#
# KEY BENEFITS:
# - Proactive detection of issues before they impact users
# - Automated analysis saves hours of manual log investigation
# - Pattern detection for database issues, memory leaks, slow APIs
# - Threshold-based alerting reduces noise
# - Useful for post-incident analysis and root cause investigation
# - Detects security-related keywords and anomalies
#
# ENHANCEMENT IDEAS:
# - Integration with ELK stack, Splunk, or other log aggregation systems
# - Machine learning for anomaly detection
# - Real-time alerting via Slack, PagerDuty, or email
# - Dashboard creation for metrics visualization
# - Report archival for compliance and historical analysis
# - Multi-file and distributed log analysis
# - Custom pattern libraries for different application types
################################################################################
