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

# Now, let's run the menu
echo "Running the menu interface now..."

# Download the menu.sh script and make it executable
wget -q https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/menu.sh -O /root/menu.sh
if [ $? -ne 0 ]; then
    echo "Failed to download menu.sh script."
    exit 1
fi

chmod +x /root/menu.sh

# Automatically select option 1 in menu.sh (Install full script)
echo "Automatically selecting option 1 to install the full script..."
echo "1" | /root/menu.sh

# Display pop-up message after installation
echo "Installation complete. Working now."

# Now, give the user the option to type `menu` to enter the menu again
echo "You can now type 'menu' to go back to the main menu."

# Clean up (do not delete menu.sh for future use)
# If you want the menu to be removed after running the script, uncomment the line below:
# rm -f /root/menu.sh
