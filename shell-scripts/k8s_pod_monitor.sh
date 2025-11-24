#!/bin/bash

################################################################################
# SCRIPT NAME: Kubernetes Pod Health Monitor
# PURPOSE: Monitors pods in K8s cluster and auto-restarts failed ones
# AUTHOR: DevOps Automation
# USE CASE: Ensure applications in K8s maintain high availability
################################################################################

# -----------------------------------------------------------------------------
# STEP 1: Configuration - Set your preferences here
# -----------------------------------------------------------------------------

# Which namespace to monitor (change as needed)
# "default" is the default namespace, use "production" or "app-services" etc.
NAMESPACE="default"

# Where to save monitoring logs
LOG_FILE="/tmp/k8s_pod_monitor_$(date +%Y%m%d).log"

# Slack webhook for alerts (optional - add your webhook URL)
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# How many times to retry before giving up
MAX_RETRIES=3

# Color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# STEP 2: Function to check if kubectl is installed
# -----------------------------------------------------------------------------
check_prerequisites() {
    echo -e "${BLUE}=== Checking Prerequisites ===${NC}"

    # Check if kubectl command exists
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}ERROR: kubectl is not installed!${NC}"
        echo "Please install kubectl first: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi

    # Check if we can connect to K8s cluster
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}ERROR: Cannot connect to Kubernetes cluster!${NC}"
        echo "Please configure kubectl to connect to your cluster"
        exit 1
    fi

    echo -e "${GREEN}✓ kubectl is installed and cluster is reachable${NC}"
    echo ""
}

# -----------------------------------------------------------------------------
# STEP 3: Function to get all pods in namespace
# -----------------------------------------------------------------------------
get_all_pods() {
    # Get list of all pod names in the namespace
    # kubectl get pods returns pod details, we extract just the names
    kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null
}

# -----------------------------------------------------------------------------
# STEP 4: Function to check status of a single pod
# -----------------------------------------------------------------------------
check_pod_status() {
    local pod_name=$1

    # Get the pod status (Running, Pending, Failed, etc.)
    local status=$(kubectl get pod "$pod_name" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null)

    # Get the restart count (how many times pod has restarted)
    local restarts=$(kubectl get pod "$pod_name" -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null)

    # Return both values
    echo "$status|$restarts"
}

# -----------------------------------------------------------------------------
# STEP 5: Function to check if pod containers are ready
# -----------------------------------------------------------------------------
check_pod_ready() {
    local pod_name=$1

    # Check if all containers in pod are ready
    # Returns "True" if ready, "False" if not
    local ready=$(kubectl get pod "$pod_name" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)

    echo "$ready"
}

# -----------------------------------------------------------------------------
# STEP 6: Function to get pod logs (for troubleshooting)
# -----------------------------------------------------------------------------
get_pod_logs() {
    local pod_name=$1

    echo "Fetching last 10 lines of logs for $pod_name:"
    kubectl logs "$pod_name" -n "$NAMESPACE" --tail=10 2>/dev/null || echo "No logs available"
}

# -----------------------------------------------------------------------------
# STEP 7: Function to restart a failed pod
# -----------------------------------------------------------------------------
restart_pod() {
    local pod_name=$1

    echo -e "${YELLOW}Attempting to restart pod: $pod_name${NC}" | tee -a "$LOG_FILE"

    # Delete the pod - K8s will automatically recreate it (if part of Deployment)
    if kubectl delete pod "$pod_name" -n "$NAMESPACE" --grace-period=30 2>/dev/null; then
        echo -e "${GREEN}✓ Pod deletion initiated - K8s will recreate it${NC}" | tee -a "$LOG_FILE"

        # Wait for pod to come back up
        echo "Waiting 15 seconds for pod to restart..."
        sleep 15

        # Check if new pod is running
        new_status=$(kubectl get pod "$pod_name" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null)
        if [ "$new_status" == "Running" ]; then
            echo -e "${GREEN}✓ Pod successfully restarted and running!${NC}" | tee -a "$LOG_FILE"
            return 0
        else
            echo -e "${RED}⚠️  Pod restarted but status is: $new_status${NC}" | tee -a "$LOG_FILE"
            return 1
        fi
    else
        echo -e "${RED}✗ Failed to restart pod${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# STEP 8: Function to send alert to Slack (optional)
# -----------------------------------------------------------------------------
send_slack_alert() {
    local message=$1

    # Only send if webhook is configured (not using default dummy URL)
    if [[ "$SLACK_WEBHOOK" != *"YOUR/WEBHOOK/URL"* ]]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🚨 K8s Alert: $message\"}" \
            "$SLACK_WEBHOOK" 2>/dev/null
    fi

    # Log the alert
    echo "[ALERT] $message" | tee -a "$LOG_FILE"
}

# -----------------------------------------------------------------------------
# STEP 9: Function to monitor a single pod
# -----------------------------------------------------------------------------
monitor_pod() {
    local pod_name=$1

    echo -e "${BLUE}Checking pod: $pod_name${NC}"

    # Get pod status and restart count
    local pod_info=$(check_pod_status "$pod_name")
    local status=$(echo "$pod_info" | cut -d'|' -f1)
    local restarts=$(echo "$pod_info" | cut -d'|' -f2)

    # Get ready status
    local ready=$(check_pod_ready "$pod_name")

    # Display current status
    echo "  Status: $status | Ready: $ready | Restarts: $restarts"

    # Check for problems
    # Problem 1: Pod is not in Running state
    if [ "$status" != "Running" ]; then
        echo -e "${RED}  ✗ Pod is NOT running! (Status: $status)${NC}" | tee -a "$LOG_FILE"

        # Get logs for debugging
        get_pod_logs "$pod_name" >> "$LOG_FILE"

        # Try to restart
        restart_pod "$pod_name"
        send_slack_alert "Pod $pod_name was $status and has been restarted"
        return 1
    fi

    # Problem 2: Pod is running but containers not ready
    if [ "$ready" != "True" ]; then
        echo -e "${YELLOW}  ⚠️  Pod is running but NOT ready!${NC}" | tee -a "$LOG_FILE"
        send_slack_alert "Pod $pod_name is not ready. Investigating..."
        return 1
    fi

    # Problem 3: Too many restarts (indicates crash loop)
    if [ ! -z "$restarts" ] && [ "$restarts" -gt 5 ]; then
        echo -e "${YELLOW}  ⚠️  Pod has restarted $restarts times (may be crash looping)${NC}" | tee -a "$LOG_FILE"
        send_slack_alert "Pod $pod_name has restarted $restarts times. Check logs!"
        return 1
    fi

    # All good!
    echo -e "${GREEN}  ✓ Pod is healthy${NC}"
    return 0
}

# -----------------------------------------------------------------------------
# STEP 10: Main function - Monitor all pods
# -----------------------------------------------------------------------------
main() {
    echo "=============================================="
    echo "    KUBERNETES POD HEALTH MONITOR"
    echo "    Namespace: $NAMESPACE"
    echo "    Time: $(date)"
    echo "=============================================="
    echo ""

    # Check if kubectl is available
    check_prerequisites

    # Get all pods in namespace
    echo -e "${BLUE}=== Fetching all pods in namespace: $NAMESPACE ===${NC}"
    PODS=$(get_all_pods)

    # Check if any pods exist
    if [ -z "$PODS" ]; then
        echo -e "${YELLOW}No pods found in namespace: $NAMESPACE${NC}"
        exit 0
    fi

    # Count pods
    POD_COUNT=$(echo "$PODS" | wc -w)
    echo "Found $POD_COUNT pod(s) to monitor"
    echo ""

    # Initialize counters
    HEALTHY_COUNT=0
    UNHEALTHY_COUNT=0

    # Loop through each pod and check health
    for pod in $PODS; do
        if monitor_pod "$pod"; then
            ((HEALTHY_COUNT++))
        else
            ((UNHEALTHY_COUNT++))
        fi
        echo ""
    done

    # Print summary
    echo "=============================================="
    echo "               SUMMARY"
    echo "=============================================="
    echo -e "Total Pods: $POD_COUNT"
    echo -e "${GREEN}Healthy: $HEALTHY_COUNT${NC}"
    echo -e "${RED}Unhealthy: $UNHEALTHY_COUNT${NC}"
    echo ""
    echo "Log file: $LOG_FILE"
    echo "=============================================="

    # Return exit code based on health
    if [ $UNHEALTHY_COUNT -gt 0 ]; then
        exit 1  # Failure - some pods unhealthy
    else
        exit 0  # Success - all pods healthy
    fi
}

# -----------------------------------------------------------------------------
# Run the script
# -----------------------------------------------------------------------------
main

################################################################################
# HOW TO USE THIS SCRIPT:
#
# 1. Install kubectl and configure cluster access
# 2. Make script executable: chmod +x k8s_pod_monitor.sh
# 3. Run manually: ./k8s_pod_monitor.sh
# 4. Run for specific namespace: NAMESPACE="production" ./k8s_pod_monitor.sh
# 5. Schedule in cron (check every 5 minutes):
#    */5 * * * * /path/to/k8s_pod_monitor.sh
#
# KEY BENEFITS:
# - Automates pod health monitoring in Kubernetes clusters
# - Proactive detection and auto-remediation of failed pods
# - Reduces manual kubectl checking and monitoring overhead
# - Integrates with alerting systems (Slack, PagerDuty, email)
# - Maintains high availability for containerized applications
#
# KUBERNETES CONCEPTS DEMONSTRATED:
# - Pod lifecycle management and health checks
# - Namespace-based resource organization
# - kubectl integration for cluster interaction
# - Self-healing patterns in container orchestration
# - Container restart policies and troubleshooting
#
# ENHANCEMENT IDEAS:
# - Add resource usage monitoring (CPU, memory per pod)
# - Implement predictive alerts based on restart patterns
# - Support for monitoring multiple clusters
# - Integration with metrics systems (Prometheus, Grafana)
################################################################################
