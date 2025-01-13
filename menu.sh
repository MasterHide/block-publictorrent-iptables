#!/bin/bash

# Function to completely remove all installed files and configurations
purge_all() {
    echo "Starting purge process..."

    # Remove bt.sh script if it exists
    if [ -f "/root/bt.sh" ]; then
        rm -f /root/bt.sh
        echo "Removed bt.sh script."
    else
        echo "bt.sh script not found."
    fi

    # Remove hostsTrackers file if it exists
    if [ -f "/root/hostsTrackers" ]; then
        rm -f /root/hostsTrackers
        echo "Removed hostsTrackers file."
    else
        echo "hostsTrackers file not found."
    fi

    # Remove the menu script itself if it exists
    if [ -f "/root/menu.sh" ]; then
        rm -f /root/menu.sh
        echo "Removed menu.sh script."
    else
        echo "menu.sh script not found."
    fi

    # Clean up iptables rules (flush and reset)
    echo "Flushing iptables rules..."
    iptables -F
    iptables -t nat -F
    iptables -t mangle -F
    iptables -X
    systemctl restart netfilter-persistent

    echo "Iptables rules flushed."

    # Optionally, clean up cron jobs if any were added
    if [ -f "/etc/cron.daily/denypublic" ]; then
        rm -f /etc/cron.daily/denypublic
        echo "Removed denypublic cron job."
    else
        echo "Denypublic cron job not found."
    fi

    echo "Purge completed successfully."
}

# Check if the script is being run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

# Confirm with the user before purging
read -p "Are you sure you want to completely remove all scripts and configurations? (y/n): " confirm

if [ "$confirm" == "y" ]; then
    purge_all
else
    echo "Purge operation aborted."
    exit 0
fi
