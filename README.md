# DevOps Automation Portfolio

## Overview
This repository contains real-world automation examples demonstrating DevOps best practices using Shell scripting and Python. These scripts solve common operational challenges in production environments.

## What's Inside

### 1. System Health Monitoring (Shell Script)
**File:** `shell-scripts/system_health_monitor.sh`
**What it does:** Automated server health checks for CPU, Memory, and Disk usage with threshold-based alerting
**Use case:** Proactive monitoring for production servers requiring high availability

### 2. Kubernetes Pod Health Monitor (Shell Script)
**File:** `shell-scripts/k8s_pod_monitor.sh`
**What it does:** Monitors Kubernetes pods and automatically remediates unhealthy states
**Use case:** Ensures containerized applications maintain high availability with self-healing capabilities

### 3. Log Analysis & Error Detection (Shell Script)
**File:** `shell-scripts/log_analyzer.sh`
**What it does:** Automated log parsing and analysis to detect errors, security issues, and performance problems
**Use case:** Quick problem detection and root cause analysis in production environments

### 4. Automated Deployment (Python Script)
**File:** `python-scripts/auto_deploy.py`
**What it does:** End-to-end deployment automation with health checks and automatic rollback capabilities
**Use case:** Safe, repeatable deployments as part of CI/CD pipelines

## Quick Start

### Prerequisites
- Linux/Mac system
- Basic shell access
- For K8s script: kubectl installed
- For Python script: Python 3.x

### How to Use Each Script

```bash
# 1. System Health Monitor
cd shell-scripts
chmod +x system_health_monitor.sh
./system_health_monitor.sh

# 2. Kubernetes Pod Monitor
chmod +x k8s_pod_monitor.sh
./k8s_pod_monitor.sh

# 3. Log Analyzer
chmod +x log_analyzer.sh
./log_analyzer.sh /path/to/logfile.log

# 4. Python Deployment Script
cd ../python-scripts
python3 auto_deploy.py
```

## Key Features

### Design Principles:
- **Production-ready**: All scripts include proper error handling and logging
- **Well-documented**: Extensive inline comments explaining logic and decisions
- **Configurable**: Easy to customize thresholds, paths, and behaviors
- **Modular**: Clean function-based architecture for maintainability

### Technologies Demonstrated:
- Shell scripting (Bash)
- Python 3
- Kubernetes (kubectl)
- System monitoring tools
- CI/CD practices
- Error handling and logging

## File Structure
```
devops-automation-scripts/
├── README.md (this file)
├── USAGE_GUIDE.md (detailed documentation)
├── shell-scripts/
│   ├── system_health_monitor.sh
│   ├── k8s_pod_monitor.sh
│   └── log_analyzer.sh
├── python-scripts/
│   └── auto_deploy.py
└── sample-logs/
    └── application.log (for testing)
```

## Learning Resources
Each script includes:
- Detailed inline comments explaining every section
- Usage examples and best practices
- Common pitfalls and solutions
- Ideas for enhancements and customizations

## About
This repository showcases automation solutions for common DevOps challenges. Each example is based on real-world production scenarios and demonstrates practical problem-solving skills.

## License
MIT License - Feel free to use and modify these scripts for your own projects!
