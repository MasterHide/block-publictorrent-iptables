#!/bin/bash

# Function to install bt.sh script
install_script() {
    echo "Installing bt.sh script..."
    if [ -f "/root/bt.sh" ]; then
        echo "bt.sh is already installed."
    else
        wget -q https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bt.sh -O /root/bt.sh
        chmod +x /root/bt.sh
        echo "bt.sh installed successfully."
    fi

    # Automatically start the menu after installation
    menu
}

# Function to uninstall bt.sh script and remove both bt.sh and hostsTrackers
uninstall_script() {
    echo "Uninstalling bt.sh script..."

    # Remove bt.sh if it exists
    if [ -f "/root/bt.sh" ]; then
        rm -f /root/bt.sh
        echo "bt.sh script removed."
    else
        echo "bt.sh script not found."
    fi

    # Remove hostsTrackers if it exists
    if [ -f "/root/hostsTrackers" ]; then
        rm -f /root/hostsTrackers
        echo "hostsTrackers file removed."
    else
        echo "hostsTrackers file not found."
    fi

    # Flush iptables rules
    iptables -F
    iptables -t nat -F
    iptables -t mangle -F
    iptables -X

    systemctl restart netfilter-persistent
    echo "iptables rules flushed."

    # Remove the menu command if it exists
    if [ -f "/usr/local/bin/menu" ]; then
        rm -f /usr/local/bin/menu
        echo "Menu command removed from system."
    else
        echo "Menu command not found in /usr/local/bin."
    fi

    echo "Uninstallation complete."
}

# Function to display the menu
menu() {
    clear
    echo "----------------------------------"
    echo "Select an Option:"
    echo "1. Install bt.sh Script"
    echo "2. Uninstall bt.sh Script"
    echo "3. Exit"
    echo "----------------------------------"
    read -p "Enter your choice [1-3]: " choice

    case $choice in
        1)
            install_script
            ;;
        2)
            uninstall_script
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

# Ensure the script is being run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

# Run the menu function
menu
