#!/bin/bash

# Step 1: Remove the bt.sh script if it exists
if [ -f "/root/bt.sh" ]; then
    echo "Removing bt.sh script..."
    rm -f /root/bt.sh
else
    echo "bt.sh script not found in /root"
fi

# Step 2: Remove the uninstall_bt.sh script if it exists
if [ -f "/root/uninstall_bt.sh" ]; then
    echo "Removing uninstall_bt.sh script..."
    rm -f /root/uninstall_bt.sh
else
    echo "uninstall_bt.sh script not found in /root"
fi

# Step 3: Flush all iptables rules
echo "Flushing iptables rules..."

iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Remove any custom iptables chains, if they exist
iptables -t filter -X
iptables -t nat -X
iptables -t mangle -X

# Step 4: Restart iptables service to apply changes
echo "Restarting iptables service..."
systemctl restart netfilter-persistent

# Step 5: Reset /etc/hosts file to its default state
echo "Resetting /etc/hosts file..."
sudo truncate -s 0 /etc/hosts
echo -e "127.0.0.1       localhost\n::1             localhost ip6-localhost ip6-loopback\nfe00::0         ip6-localnet\nff00::0         ip6-mcastprefix\nff02::1         ip6-allnodes\nff02::2         ip6-allrouters" | sudo tee /etc/hosts

# Step 6: Optionally, remove any other files installed by your script
# Uncomment and modify this section if there are other files to remove
# sudo rm -f /path/to/other/installed/files

# Step 7: Completion message
echo "Uninstallation complete."
