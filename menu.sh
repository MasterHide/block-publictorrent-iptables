#!/bin/bash

# Function to display the menu
function show_menu {
    echo "1) Install Script"
    echo "2) Uninstall Script"
    echo "3) Exit"
    read -p "Choose an option: " choice
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
    echo "Installing the script..."
    # Insert installation commands here
    # For example: wget, chmod, mv, etc.
    # ...
    echo "Installation complete."
}

# Function to uninstall the script
function uninstall_script {
    echo "Uninstalling the script..."
    # Call your uninstall_bt.sh script here
    sudo bash /path/to/uninstall_bt.sh
    exit 0
}

# Show the menu to the user
show_menu
