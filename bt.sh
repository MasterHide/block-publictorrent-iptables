#!/bin/bash
#
# 2025 Updated !!
# GitHub:   https://github.com/MasterHide/block-publictorrent-iptables
# Author:   MasterHide

echo -n "Blocking public trackers ... "

# Download trackers file
wget -q -O /etc/trackers https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/trackers
if [ $? -ne 0 ]; then
    echo "Failed to download trackers file."
    exit 1
fi

# Create cron job for blocking public trackers
cat >/etc/cron.daily/denypublic<<'EOF'
IFS=$'\n'
IPTABLES_CMD=$(which iptables)
L=$(/usr/bin/sort /etc/trackers | /usr/bin/uniq)
for fn in $L; do
        $IPTABLES_CMD -D INPUT -d $fn -j DROP
        $IPTABLES_CMD -D FORWARD -d $fn -j DROP
        $IPTABLES_CMD -D OUTPUT -d $fn -j DROP
        $IPTABLES_CMD -A INPUT -d $fn -j DROP
        $IPTABLES_CMD -A FORWARD -d $fn -j DROP
        $IPTABLES_CMD -A OUTPUT -d $fn -j DROP
done
EOF
chmod +x /etc/cron.daily/denypublic

# Download hostsTrackers file and update /etc/hosts
curl -s -LO https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/hostsTrackers
if [ $? -ne 0 ]; then
    echo "Failed to download hostsTrackers."
    exit 1
fi

# Update /etc/hosts with trackers
cat hostsTrackers | sort -uf >> /etc/hosts
if [ $? -ne 0 ]; then
    echo "Failed to update /etc/hosts."
    exit 1
fi

echo "Blocking public trackers completed successfully."

# Function to install or update the bt.sh script
install_bt_script() {
    echo "Installing or updating bt.sh script..."

    # Remove the old bt.sh file if it exists
    if [ -f "/root/bt.sh" ]; then
        rm -f /root/bt.sh
        echo "Old bt.sh file removed."
    fi

    # Download and install the new bt.sh script
    wget -q https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bt.sh -O /root/bt.sh
    if [ $? -eq 0 ]; then
        chmod +x /root/bt.sh
        echo "bt.sh script installed/updated successfully."
    else
        echo "Error: Failed to download bt.sh script."
        exit 1
    fi
}

# Now, let's run the menu interface
echo "Running the menu interface now..."

# Download the menu.sh script and make it executable
wget -q https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/menu.sh -O /root/menu.sh
if [ $? -ne 0 ]; then
    echo "Failed to download menu.sh script."
    exit 1
fi

chmod +x /root/menu.sh

# Install or update the bt.sh script before running the menu
install_bt_script

# Run the menu script
/root/menu.sh
