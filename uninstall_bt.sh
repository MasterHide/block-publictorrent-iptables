#!/bin/bash

# Step 1: Remove the bt.sh script if it exists
if [ -f "/root/bt.sh" ]; then
    echo "Removing bt.sh script..."
    rm -f /root/bt.sh
else
    echo "bt.sh script not found in /root"
fi

# Step 2: Remove iptables rules added by the script
echo "Flushing iptables rules..."

# This will flush all the iptables rules, ensuring no leftover rules remain
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Step 3: Remove any custom iptables chains, if they exist
iptables -t filter -X
iptables -t nat -X
iptables -t mangle -X

# Step 4: Restart iptables service (optional but can ensure changes are applied)
echo "Restarting iptables service..."
systemctl restart netfilter-persistent

echo "Uninstallation complete."
