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

    # Add the installation steps here
    # For example, if you're installing the bt.sh script:
    wget -q -O /root/bt.sh https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bt.sh
    chmod +x /root/bt.sh

    # Install the uninstall script (if necessary)
    wget -q -O /root/uninstall_bt.sh https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/uninstall_bt.sh
    chmod +x /root/uninstall_bt.sh

    # Move the `menu` script to a global directory so it can be accessed by all users
    sudo mv /root/menu.sh /usr/local/bin/menu

    # Run any setup or configuration commands you need
    echo "Script installed successfully."

    # Return to the menu after installation
    show_menu
}

# Function to uninstall the script
function uninstall_script {
    clear
    echo "Uninstalling the script..."

    # Call the uninstall_bt.sh script to clean up
    sudo bash /root/uninstall_bt.sh

    # Return to the menu after uninstallation
    show_menu
}

# Show the menu to the user
show_menu
