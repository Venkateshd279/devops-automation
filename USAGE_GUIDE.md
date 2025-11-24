# Usage Guide - DevOps Automation Scripts

## Overview
This guide provides detailed usage instructions and best practices for each automation script in this repository.

---

## 1. System Health Monitor

### Purpose
Automated monitoring of server health metrics (CPU, Memory, Disk) with threshold-based alerting.

### Prerequisites
- Linux or macOS system
- Bash shell
- Standard system utilities (top, free/vm_stat, df)

### Configuration
Edit these variables in `system_health_monitor.sh`:

```bash
CPU_THRESHOLD=80         # Alert threshold for CPU usage (%)
MEMORY_THRESHOLD=80      # Alert threshold for memory usage (%)
DISK_THRESHOLD=85        # Alert threshold for disk usage (%)
ALERT_EMAIL="ops-team@example.com"  # Email for alerts
```

### Usage

**Manual execution:**
```bash
chmod +x shell-scripts/system_health_monitor.sh
./shell-scripts/system_health_monitor.sh
```

**Automated scheduling (every 15 minutes):**
```bash
crontab -e
# Add line:
*/15 * * * * /path/to/system_health_monitor.sh
```

### Output
- Console output with color-coded status
- Timestamped report files in `/tmp/`
- Alerts when thresholds are exceeded

### Use Cases
- Production server monitoring
- Resource capacity planning
- Proactive issue detection
- Infrastructure health dashboards

---

## 2. Kubernetes Pod Health Monitor

### Purpose
Monitors Kubernetes pods for unhealthy states and automatically remediates issues.

### Prerequisites
- kubectl installed and configured
- Access to Kubernetes cluster
- Appropriate RBAC permissions

### Configuration
Edit these variables in `k8s_pod_monitor.sh`:

```bash
NAMESPACE="default"      # Kubernetes namespace to monitor
MAX_RETRIES=3           # Number of restart attempts
SLACK_WEBHOOK="..."     # Slack webhook URL for alerts
```

### Usage

**Manual execution:**
```bash
chmod +x shell-scripts/k8s_pod_monitor.sh
./shell-scripts/k8s_pod_monitor.sh
```

**Monitor specific namespace:**
```bash
NAMESPACE="production" ./shell-scripts/k8s_pod_monitor.sh
```

**Automated scheduling (every 5 minutes):**
```bash
crontab -e
# Add line:
*/5 * * * * /path/to/k8s_pod_monitor.sh
```

### What It Checks
- Pod status (Running, Failed, Pending, etc.)
- Container readiness status
- Restart counts (detects crash loops)
- Pod events for debugging

### Auto-Remediation
- Deletes failed pods (Kubernetes recreates them)
- Alerts on high restart counts
- Logs all interventions

### Use Cases
- Kubernetes cluster monitoring
- Automated pod recovery
- SLA maintenance
- DevOps on-call support

---

## 3. Log Analysis & Error Detection

### Purpose
Automated analysis of application logs to detect errors, warnings, and anomalies.

### Prerequisites
- Linux or macOS system
- Bash shell
- Read access to log files

### Configuration
Edit these variables in `log_analyzer.sh`:

```bash
LINES_TO_CHECK=1000      # Number of recent lines to analyze
ERROR_THRESHOLD=10       # Alert if errors exceed this
WARNING_THRESHOLD=50     # Alert if warnings exceed this
ALERT_EMAIL="ops-team@example.com"
```

### Usage

**Analyze default log:**
```bash
chmod +x shell-scripts/log_analyzer.sh
./shell-scripts/log_analyzer.sh
```

**Analyze specific log file:**
```bash
./shell-scripts/log_analyzer.sh /var/log/application.log
```

**Automated hourly analysis:**
```bash
crontab -e
# Add line:
0 * * * * /path/to/log_analyzer.sh /var/log/application.log
```

### What It Analyzes
- Error and exception counts
- Warning messages
- Database connection issues
- Memory and timeout errors
- Authentication failures
- Security-related keywords
- Performance metrics

### Output
- Timestamped analysis reports in `/tmp/`
- Summary statistics
- Top 5 most frequent errors
- Sample log lines for each issue type

### Use Cases
- Incident response
- Root cause analysis
- Application monitoring
- Security audit
- Performance troubleshooting

---

## 4. Automated Deployment

### Purpose
End-to-end deployment automation with health checks and automatic rollback.

### Prerequisites
- Python 3.x
- Application build artifacts
- Health check endpoint configured

### Configuration
Edit these variables in `auto_deploy.py`:

```python
APP_NAME = "web-application"
APP_VERSION = "v2.5.0"
SOURCE_DIR = "/tmp/builds/web-application"
DEPLOY_DIR = "/opt/applications/web-application"
BACKUP_DIR = "/opt/backups/web-application"
HEALTH_CHECK_URL = "http://localhost:8080/health"
HEALTH_CHECK_TIMEOUT = 60  # seconds
```

### Usage

**Manual deployment:**
```bash
chmod +x python-scripts/auto_deploy.py
python3 python-scripts/auto_deploy.py
```

**CI/CD Integration (Jenkins example):**
```groovy
stage('Deploy') {
    steps {
        sh 'python3 /path/to/auto_deploy.py'
    }
}
```

### Deployment Workflow
1. **Pre-deployment checks**
   - Verify build artifacts exist
   - Check current application status

2. **Backup**
   - Create timestamped backup of current version

3. **Deployment**
   - Stop current application gracefully
   - Deploy new version
   - Start new application

4. **Health Check**
   - Wait for application to start
   - Call health check endpoint
   - Retry up to 12 times (60 seconds)

5. **Rollback (if needed)**
   - Stop failed deployment
   - Restore backup
   - Restart previous version

### Success Criteria
- Health check endpoint returns 200 OK
- Application responds within timeout period

### Use Cases
- CI/CD pipelines
- Blue-green deployments
- Safe production releases
- Zero-downtime deployments

---

## Best Practices

### General
1. **Test in non-production first** - Always test scripts in dev/staging before production
2. **Monitor script execution** - Use logging and monitoring to track script performance
3. **Version control** - Keep scripts in Git for version history and collaboration
4. **Documentation** - Update configs and documentation when making changes

### Security
1. **Least privilege** - Run scripts with minimum required permissions
2. **Secrets management** - Use environment variables or secret managers for credentials
3. **Audit logs** - Keep logs of all automated actions
4. **Access control** - Restrict who can modify and execute scripts

### Reliability
1. **Error handling** - Scripts include proper error detection and handling
2. **Idempotency** - Scripts can be run multiple times safely
3. **Timeout handling** - All operations have appropriate timeouts
4. **Alerting** - Configure alerts for script failures

### Maintenance
1. **Regular reviews** - Periodically review and update scripts
2. **Threshold tuning** - Adjust alert thresholds based on observed patterns
3. **Dependency updates** - Keep tools and libraries up to date
4. **Documentation updates** - Keep usage guides current with code changes

---

## Troubleshooting

### Common Issues

**System Health Monitor**
- **Issue**: CPU metrics not accurate on Mac
- **Solution**: Script includes Mac-specific commands (ps, vm_stat)

**Kubernetes Monitor**
- **Issue**: "kubectl: command not found"
- **Solution**: Install kubectl and configure cluster access

- **Issue**: "Error: Forbidden"
- **Solution**: Check RBAC permissions for service account

**Log Analyzer**
- **Issue**: "Permission denied" on log file
- **Solution**: Ensure read permissions on log files

**Auto Deploy**
- **Issue**: Health check fails immediately
- **Solution**: Verify HEALTH_CHECK_URL is correct and accessible

- **Issue**: Rollback fails
- **Solution**: Check backup directory exists and has proper permissions

---

## Contributing

Contributions are welcome! When adding enhancements:
1. Maintain inline documentation style
2. Add appropriate error handling
3. Update this usage guide
4. Test thoroughly in multiple environments

---

## Support

For issues or questions:
- Check inline script comments for detailed explanations
- Review troubleshooting section above
- Open an issue on GitHub with detailed description

---

## License

MIT License - See repository root for full license text
