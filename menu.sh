#!/bin/bash

# Function to install bt.sh script
install_script() {
    echo "Installing bt.sh script..."

    # Check if bt.sh already exists in /root
    if [ -f "/root/bt.sh" ]; then
        echo "bt.sh is already installed."
    else
        # Download bt.sh script
        wget -q https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bt.sh -O /root/bt.sh
        if [ $? -eq 0 ]; then
            chmod +x /root/bt.sh
            echo "bt.sh installed successfully."

            # Run the bt.sh script automatically after installation
            bash /root/bt.sh
        else
            echo "Error: Failed to download bt.sh script."
        fi
    fi

    # Download hostsTrackers file
    wget -q https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/hostsTrackers -O /root/hostsTrackers
    if [ $? -eq 0 ]; then
        echo "hostsTrackers file downloaded successfully."
    else
        echo "Error: Failed to download hostsTrackers file."
    fi

    # Go back to menu after installation
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

    # Remove any remaining hostsTrackers from /etc
    if [ -f "/etc/hostsTrackers" ]; then
        rm -f /etc/hostsTrackers
        echo "hostsTrackers file removed from /etc."
    else
        echo "hostsTrackers file not found in /etc."
    fi

    # Flush iptables rules
    iptables -F
    iptables -t nat -F
    iptables -t mangle -F
    iptables -X
    systemctl restart netfilter-persistent

    echo "iptables rules flushed."

    # Remove the menu command from system if it exists
    if [ -f "/usr/local/bin/menu" ]; then
        rm -f /usr/local/bin/menu
        echo "Menu command removed from system."
    else
        echo "Menu command not found in /usr/local/bin."
    fi

    # Clean up the uninstall_all.sh script if it exists
    if [ -f "/root/uninstall_all.sh" ]; then
        rm -f /root/uninstall_all.sh
        echo "uninstall_all.sh script removed."
    else
        echo "uninstall_all.sh script not found."
    fi

    # Clean up any remaining files related to the script
    rm -f /root/bt.sh
    rm -f /root/hostsTrackers

    echo "Uninstallation complete."
    exit 0  # Exit after uninstallation is complete
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
