#!/bin/bash

# Function to uninstall everything
uninstall_script() {
    echo "Uninstalling all scripts and files..."

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

    # Remove the symlink for the menu command
    rm -f /usr/local/bin/menu
    echo "Menu command removed."

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

    echo "Uninstallation complete."
}

# Function to display the menu
menu() {
    clear
    echo "----------------------------------"
    echo "Select an Option:"
    echo "1. Uninstall Script"
    echo "2. Purge All (Uninstall and Remove All Files)"
    echo "3. Exit"
    echo "----------------------------------"
    read -p "Enter your choice [1-3]: " choice

    case $choice in
        1)
            uninstall_script
            ;;
        2)
            purge_all
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option! Please select 1, 2, or 3."
            menu
            ;;
    esac
}

# Function to purge everything (delete all files and configurations)
purge_all() {
    echo "Starting purge process..."

    # Confirm with the user before purging
    read -p "Are you sure you want to completely remove all scripts and configurations? (y/n): " confirm

    if [ "$confirm" == "y" ]; then
        # Call uninstall_script to remove files and configurations
        uninstall_script
    else
        echo "Purge operation aborted."
        exit 0
    fi
}

# Ensure the script is being run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

# Run the menu
menu
