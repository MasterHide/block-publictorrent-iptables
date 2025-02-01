#!/bin/bash -e

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\033[31mThis script must be run as root. Exiting.\033[0m"
    exit 1
fi

# Confirmation before execution
read -p "Are you sure you want to remove all files and unblock torrent traffic? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "\033[33mOperation canceled.\033[0m"
    exit 0
fi

# Define blocked torrent ports and domains
TORRENT_PORTS=(6881 6882 6883 6884 6885 6886 6887 6888 6889 6890 51413)
DHT_PORTS=(25130 27130 6881)
PEER_EXCHANGE_PORTS=(16881 49870)
TORRENT_DOMAINS=(
    "tracker.opentrackr.org"
    "tracker.openbittorrent.com"
    "tracker.leechers-paradise.org"
    "tracker.publicbt.com"
    "tracker.coppersurfer.tk"
)

# Function to unblock torrent traffic
unblock_torrent() {
    echo "Unblocking torrent traffic..."

    # Remove iptables rules blocking torrent ports
    for port in "${TORRENT_PORTS[@]}"; do
        iptables -D OUTPUT -p tcp --dport $port -j DROP || true
        iptables -D OUTPUT -p udp --dport $port -j DROP || true
        iptables -D INPUT -p tcp --sport $port -j DROP || true
        iptables -D INPUT -p udp --sport $port -j DROP || true
    done

    for port in "${DHT_PORTS[@]}"; do
        iptables -D OUTPUT -p udp --dport $port -j DROP || true
        iptables -D INPUT -p udp --sport $port -j DROP || true
    done

    for port in "${PEER_EXCHANGE_PORTS[@]}"; do
        iptables -D OUTPUT -p udp --dport $port -j DROP || true
        iptables -D INPUT -p udp --sport $port -j DROP || true
    done

    # Remove blocked domains from /etc/hosts
    for domain in "${TORRENT_DOMAINS[@]}"; do
        sed -i "/$domain/d" /etc/hosts
    done

    # Save the updated iptables rules
    iptables-save > /etc/iptables/rules.v4
    echo -e "\033[32mTorrent traffic unblocked successfully!\033[0m"
}

# Function to uninstall the script
uninstall_script() {
    echo "Uninstalling the torrent blocker script..."
    unblock_torrent
}

# Define the files to remove
FILES_TO_REMOVE=(
    "/home/ubuntu/bmenu.sh"
    "/root/bmenu.sh"
    "/opt/hiddify-manager/bmenu.sh"
    "/home/ubuntu/bt.sh"
    "/root/bt.sh"
    "/opt/hiddify-manager/bt.sh"
    "/home/ubuntu/ctp.sh"
    "/root/ctp.sh"
    "/opt/hiddify-manager/ctp.sh"
    "/etc/trackers"
    "/etc/hostsTrackers"
)

# Execute uninstall function first
uninstall_script

# Remove files
for file in "${FILES_TO_REMOVE[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo -e "\033[32mRemoved: $file\033[0m"
    else
        echo -e "\033[33mFile not found: $file (skipped)\033[0m"
    fi
done

# Notify user about the completion
echo -e "\033[32mSystem reset completed. All specified files have been removed.\033[0m"

# Optional: Display a popup notification (for desktop environments)
if command -v notify-send &> /dev/null; then
    notify-send "System Reset" "All specified files have been removed successfully!"
fi

exit 0
