#!/bin/bash

# Step 1: Remove the bt.sh script if it exists
if [ -f "/root/bt.sh" ]; then
    echo "Removing bt.sh script..."
    rm -f /root/bt.sh
else
    echo "bt.sh script not found in /root"
fi

# Step 2: Flush all iptables rules
echo "Flushing iptables rules..."

iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Remove any custom iptables chains, if they exist
iptables -t filter -X
iptables -t nat -X
iptables -t mangle -X

# Step 3: Restart iptables service to apply changes
echo "Restarting iptables service..."
systemctl restart netfilter-persistent

echo "Uninstallation complete."
