#!/bin/bash

# Function to log messages
log_message() {
    echo -e "[INFO] $1"
}

# Check if script is being run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "[ERROR] This script must be run as root or with sudo."
    exit 1
fi

# Step 1: Remove the bt.sh script if it exists
if [ -f "/root/bt.sh" ]; then
    log_message "Removing bt.sh script..."
    rm -f /root/bt.sh
else
    log_message "bt.sh script not found in /root."
fi

# Step 2: Remove the uninstall_bt.sh script if it exists
if [ -f "/root/uninstall_bt.sh" ]; then
    log_message "Removing uninstall_bt.sh script..."
    rm -f /root/uninstall_bt.sh
else
    log_message "uninstall_bt.sh script not found in /root."
fi

# Step 3: Flush all iptables rules
log_message "Flushing iptables rules..."
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Remove any custom iptables chains, if they exist
iptables -t filter -X
iptables -t nat -X
iptables -t mangle -X

# Step 4: Restart iptables service to apply changes
log_message "Restarting iptables service..."
if systemctl restart netfilter-persistent; then
    log_message "iptables service restarted successfully."
else
    log_message "[ERROR] Failed to restart iptables service."
    exit 1
fi

# Step 5: Reset /etc/hosts file to its default state
log_message "Resetting /etc/hosts file..."
if [ -f /etc/hosts ]; then
    cp /etc/hosts /etc/hosts.bak
    log_message "Backup of /etc/hosts created at /etc/hosts.bak."
fi

sudo truncate -s 0 /etc/hosts
echo -e "127.0.0.1       localhost\n::1             localhost ip6-localhost ip6-loopback\nfe00::0         ip6-localnet\nff00::0         ip6-mcastprefix\nff02::1         ip6-allnodes\nff02::2         ip6-allrouters" | sudo tee /etc/hosts

# Step 6: Optionally, remove any other files installed by your script
# Uncomment and modify this section if there are other files to remove
# sudo rm -f /path/to/other/installed/files

# Step 7: Completion message
log_message "Uninstallation complete. Thank you for using the script."
