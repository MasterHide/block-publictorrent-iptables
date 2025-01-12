#!/bin/bash

# Function to display the menu
function show_menu {
    clear
    echo "----------------------------------"
    echo "1) Install Script"
    echo "2) Uninstall Script"
    echo "3) Exit"
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
            exit 0
            ;;
        *)
            echo "Invalid choice, please try again."
            show_menu
            ;;
    esac
}

# Function to install the script
function install_script {
    clear
    echo "Installing the script..."

    # Download the installation scripts (bt.sh and uninstall_bt.sh)
    wget -q -O /root/bt.sh https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bt.sh
    chmod +x /root/bt.sh

    wget -q -O /root/uninstall_bt.sh https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/uninstall_bt.sh
    chmod +x /root/uninstall_bt.sh

    # Move the menu.sh to /usr/local/bin/ so it can be used by any user
    sudo mv /root/menu.sh /usr/local/bin/menu

    echo "Script installed successfully."
    show_menu
}

# Function to uninstall the script
function uninstall_script {
    clear
    echo "Uninstalling the script..."

    # Call the uninstall_bt.sh script to clean up
    sudo bash /root/uninstall_bt.sh

    # Remove the 'menu' command
    if [ -f "/usr/local/bin/menu" ]; then
        echo "Removing menu command..."
        sudo rm -f /usr/local/bin/menu
    else
        echo "menu command not found."
    fi

    echo "Uninstallation complete."
    exit 0
}

# Show the menu to the user
show_menu
