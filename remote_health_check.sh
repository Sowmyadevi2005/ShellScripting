#!/bin/bash
################################################################################
# Author: Sowmyadevi Telidevara
# Version: v1.0
#
# Description:
# This script connects to a running EC2 instance using its public IP address
# and a specified SSH private key. It performs basic server health checks 
# (like disk space, memory, CPU usage, and open network ports) **without copying
# the script to the server**. Instead, the health check commands are run remotely 
# from your local machine via SSH.
#
# NOTE:
# ⚠️ When running this script inside WSL (Ubuntu):
# - It's **recommended** to copy your `.pem` SSH key to your WSL home (e.g., `~/.ssh/`)
# - Set proper permissions using: `chmod 400 ~/.ssh/your-key.pem`
# - If you're providing a Windows-style path like `C:\Users\...`, the script will
#   auto-convert it to WSL path (`/mnt/c/...`), but make sure permission is `400`
################################################################################

# Store the remote health check commands to be executed on the EC2 instance.
health_check=$(cat <<'EOF'
echo "======== EC2 Health Check ========"
echo "Hostname: $(hostname)"
echo -e "\n--- Uptime ---"
uptime

echo -e "\n--- Disk Space ---"
df -h

echo -e "\n--- Memory Usage (MB) ---"
free -m

echo -e "\n--- Top CPU-consuming Processes ---"
top -b -o +%CPU | head -n 10

echo -e "\n--- Open Network Ports ---"
ss -tuln
EOF
)

# Ask user to provide the public IP address of the EC2 instance
read -p "Please provide Public IP address for the server to connect: " EC2_IP

# Ask user to provide the SSH private key path
# Accepts either Linux-style (/home/user/.ssh/key.pem) or Windows-style (C:\Users\...)
read -r -p "Please provide SSH key path: " SSH_KEY

# Convert Windows-style path (e.g., C:\Users\Sowmya\...) to WSL-compatible path (/mnt/c/Users/Sowmya/...)
if [[ "$SSH_KEY" == [A-Za-z]:\\* ]]; then  
    DRIVE=$(echo "$SSH_KEY" | cut -c1 | tr '[:upper:]' '[:lower:]')  # Extract drive letter and convert to lowercase
    SSH_KEY="/mnt/$DRIVE$(echo "$SSH_KEY" | cut -c3- | sed 's/\\/\//g')"  # Convert backslashes to forward slashes
fi

# Echo the final SSH key path (for debugging/logging)
echo "Using SSH Key: $SSH_KEY"

# Validate if the SSH key file exists
if [ ! -f "$SSH_KEY" ]; then
    echo "❌ Error: SSH key file does not exist at the given path."
    exit 1
fi

# Automatically trust the EC2 instance SSH fingerprint if not already in known_hosts
if ! ssh-keygen -F "$EC2_IP" > /dev/null; then
    echo "Fetching and saving EC2 SSH fingerprint for secure connection..."
    ssh-keyscan -H "$EC2_IP" >> ~/.ssh/known_hosts
fi

# Attempt to connect to EC2 and run the health check remotely
echo "Connecting to EC2 instance at $EC2_IP ..."
ssh -i "$SSH_KEY" ubuntu@"$EC2_IP" "bash -s" <<< "$health_check"
