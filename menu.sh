#!/bin/bash

# Function to uninstall everything
uninstall_script() {
    echo "Uninstalling all scripts and files..."

    # Run your manual uninstall command
    wget -q -O uninstall_all.sh https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/uninstall_all.sh
    chmod +x uninstall_all.sh
    sudo ./uninstall_all.sh
    rm -f uninstall_all.sh
    rm -f /root/bt.sh
    rm -f /root/hostsTrackers

    echo "Uninstallation complete."

    # Remove the menu script itself and the command
    rm -f /root/menu.sh
    rm -f /usr/local/bin/menu
    echo "Menu script and command removed."
}

# Function to display the menu
menu() {
    clear
    echo "----------------------------------"
    echo "Select an Option:"
    echo "1. Uninstall Script"
    echo "2. Exit"
    echo "----------------------------------"
    read -p "Enter your choice [1-2]: " choice

    case $choice in
        1)
            uninstall_script
            ;;
        2)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option! Please select 1 or 2."
            menu
            ;;
    esac
}

# Create a menu command to open the menu script easily
if ! command -v menu &>/dev/null; then
    ln -s /root/menu.sh /usr/local/bin/menu
fi

# Run the menu
menu
