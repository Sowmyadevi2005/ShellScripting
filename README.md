
# 🐚 AWS Shell Scripts for Cloud Automation

Welcome to my shell scripting playground! 🚀 This repository contains real-time automation scripts integrating Linux fundamentals with AWS services using CLI. All scripts are written and tested in a WSL environment.

> 💡 Special thanks to **Adhithya Jaswal** for teaching Linux fundamentals from scratch and **Abhishek Vermalla** for helping integrate shell scripts with AWS in practical use cases.

---

## 📜 Scripts Overview

### 1. `iam_management.sh`
Create, delete, and list AWS IAM users with automation.
- 🔐 Automates IAM user lifecycle tasks
- 💡 Useful for bulk IAM operations and user audits

### 2. `list_iam_resources.sh`
List all IAM users, groups, and roles in your AWS account.
- 📋 Great for IAM resource visibility and quick audits

### 3. `aws_daily_cost_alerts.sh`
Sends daily AWS cost reports using AWS Budgets and SNS.
- 💰 Helps track cloud spend and avoid surprises

### 4. `aws_list_resources.sh`
Lists AWS resources (EC2, RDS, S3, Lambda, etc.) across all supported regions.
- 🗺️ Useful for resource inventory, cleanup, or audits

### 5. `lambda-error-notification.sh`
Fetches Lambda logs and notifies if there are `ERROR` entries.
- 🛠️ Ideal for early detection of issues in serverless functions

### 6. `mysql-backup-to-s3.sh`
Automates MySQL database backup, compression, and upload to an S3 bucket.
- 🧱 Ensures secure and regular backups from RDS
- 🔁 Includes optional cleanup of old backups

### 7. `remote_health_check.sh`
Remotely checks EC2 instance health using port availability and basic connectivity — **without copying scripts to the instance**.
- 🧪 Helps monitor system availability and catch issues early

---

🛠️ Requirements
1. AWS CLI configured (aws configure)

2.IAM permissions to access respective AWS resources

3.MySQL client for DB backup script

4.tar, gzip, and basic Linux utilities

