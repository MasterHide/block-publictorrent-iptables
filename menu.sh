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
}

# Function to uninstall bt.sh script
uninstall_script() {
    echo "Uninstalling bt.sh script..."
    if [ -f "/root/bt.sh" ]; then
        rm -f /root/bt.sh
        echo "bt.sh script removed."
    else
        echo "bt.sh script not found."
    fi

    # Flush iptables rules
    iptables -F
    iptables -t nat -F
    iptables -t mangle -F
    iptables -X

    systemctl restart netfilter-persistent
    echo "iptables rules flushed."
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

# Run the menu function
menu
