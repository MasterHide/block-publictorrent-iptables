#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\033[31mThis script must be run as root. Exiting.\033[0m"  # Red color for error
    exit 1
fi

# Define paths to files
TRACKERS_FILE="/etc/trackers"
HOSTS_TRACKERS_FILE="/etc/hostsTrackers"
HOSTS_FILE="/etc/hosts"
HIDDIFY_PATH="/opt/hiddify-manager"
BMENU_PATH="$HIDDIFY_PATH/bmenu.sh"

# Color definitions for better UI/UX
COLOR_HEADER="\033[1;34m"
COLOR_SUCCESS="\033[32m"
COLOR_ERROR="\033[31m"
COLOR_RESET="\033[0m"
COLOR_MENU="\033[1;36m"
COLOR_INPUT="\033[1;33m"
COLOR_WARNING="\033[33m"

# Function to print headers with color
print_header() {
    echo -e "${COLOR_HEADER}$1${COLOR_RESET}"
}

# Function to print success messages with color
print_success() {
    echo -e "${COLOR_SUCCESS}$1${COLOR_RESET}"
}

# Function to print error messages with color
print_error() {
    echo -e "${COLOR_ERROR}$1${COLOR_RESET}"
}

# Add host
add_host() {
    echo -n -e "${COLOR_INPUT}Enter the hostname to add: ${COLOR_RESET}"
    read hostname
    if ! grep -q "$hostname" "$TRACKERS_FILE" && ! grep -q "$hostname" "$HOSTS_TRACKERS_FILE"; then
        echo "$hostname" | sudo tee -a "$TRACKERS_FILE" > /dev/null
        echo "$hostname" | sudo tee -a "$HOSTS_TRACKERS_FILE" > /dev/null
        sudo iptables -A INPUT -d "$hostname" -j DROP
        sudo iptables -A FORWARD -d "$hostname" -j DROP
        sudo iptables -A OUTPUT -d "$hostname" -j DROP
        print_success "Host $hostname added and blocked successfully!"
    else
        print_error "Host $hostname already exists in the blocklist."
    fi
}

# Remove host
remove_host() {
    echo -n -e "${COLOR_INPUT}Enter the hostname to remove: ${COLOR_RESET}"
    read hostname
    if grep -q "$hostname" "$TRACKERS_FILE"; then
        sudo sed -i "/$hostname/d" "$TRACKERS_FILE"
        sudo sed -i "/$hostname/d" "$HOSTS_TRACKERS_FILE"
        sudo iptables -D INPUT -d "$hostname" -j DROP
        sudo iptables -D FORWARD -d "$hostname" -j DROP
        sudo iptables -D OUTPUT -d "$hostname" -j DROP
        print_success "Host $hostname removed successfully."
    else
        print_error "Host $hostname not found in the blocklist."
    fi
}

# Uninstall and clean up all files (using predefined paths, no dynamic search)
uninstall_all() {
    print_header "Uninstalling all and cleaning up..."

    # List of files to remove from /root
    files_to_remove_root=(
        "/root/bmenu.sh"
        "/root/uninstall_all.sh"
        "/root/bt.sh"
        "/root/hostsTrackers"
        "/root/cleanup_hosts.sh.save"
        "/root/trackers"
    )

    # List of files to remove from /home/ubuntu
    files_to_remove_home_ubuntu=(
        "/home/ubuntu/bmenu.sh"
        "/home/ubuntu/uninstall_all.sh"
        "/home/ubuntu/bt.sh"
        "/home/ubuntu/hostsTrackers"
        "/home/ubuntu/cleanup_hosts.sh.save"
        "/home/ubuntu/trackers"
    )

    # Remove files from /root
    for file in "${files_to_remove_root[@]}"; do
        if [ -f "$file" ]; then
            sudo rm -f "$file"
            echo -e "${COLOR_SUCCESS}Removed from /root: $file${COLOR_RESET}"
        else
            echo -e "${COLOR_WARNING}File not found in /root: $file${COLOR_RESET}"
        fi
    done

    # Remove files from /home/ubuntu
    for file in "${files_to_remove_home_ubuntu[@]}"; do
        if [ -f "$file" ]; then
            sudo rm -f "$file"
            echo -e "${COLOR_SUCCESS}Removed from /home/ubuntu: $file${COLOR_RESET}"
        else
            echo -e "${COLOR_WARNING}File not found in /home/ubuntu: $file${COLOR_RESET}"
        fi
    done

    print_success "All specified files have been processed and removed."
    # Return to the menu (don't exit)
}

# Option 4: Use the external cleanup script to handle cleanup
cleanup_files() {
    print_header "Running external cleanup script for /etc/hosts and removing unnecessary files..."

    # Use the external cleanup script you mentioned
    sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/cleanup_hosts.sh)"

    print_success "Cleanup completed using the external script."
}

# Display the menu with color improvements
while true; do
    clear
    print_header "DARK-PROJECT B-IP MENU INTERFACE"
    print_header "Created by x404 MASTER"
    echo -e "${COLOR_MENU}--------------------------------------------${COLOR_RESET}"
    echo -e "${COLOR_MENU}1. Add a new host to block${COLOR_RESET}"
    echo -e "${COLOR_MENU}2. Remove a host from the blocklist${COLOR_RESET}"
    echo -e "${COLOR_MENU}3. View current blocked hosts${COLOR_RESET}"
    echo -e "${COLOR_MENU}4. Clean up hosts file list and remove unnecessary files${COLOR_RESET}"
    echo -e "${COLOR_MENU}5. Install or Update${COLOR_RESET}"
    echo -e "${COLOR_MENU}6. Uninstall all and reset system${COLOR_RESET}"
    echo -e "${COLOR_MENU}7. Exit${COLOR_RESET}"
    echo -e "${COLOR_MENU}--------------------------------------------${COLOR_RESET}"
    echo -n -e "${COLOR_INPUT}Select an option [1-7]: ${COLOR_RESET}"
    read option

    case $option in
        1)
            add_host
            ;;
        2)
            remove_host
            ;;
        3)
            print_header "Blocked Hosts"
            echo "--------------------------------"
            cat "$TRACKERS_FILE"
            echo "--------------------------------"
            echo -e "${COLOR_INPUT}Press any key to continue...${COLOR_RESET}"
            read -n 1
            ;;
        4)
            cleanup_files  # Use the external cleanup script
            ;;
        5)
            print_header "Installing or updating bmenu.sh script..."
            if [ -f "$BMENU_PATH" ]; then
                print_success "$BMENU_PATH already exists."
            else
                sudo wget -O "$BMENU_PATH" https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bmenu.sh
                sudo chmod +x "$BMENU_PATH"
                print_success "bmenu.sh script installed/updated at $BMENU_PATH."
            fi
            ;;
        6)
            uninstall_all  # Call the uninstall function
            # Stay in the menu after uninstallation, don't exit
            ;;
        7)
            print_success "Exiting. Goodbye Adarei umma!"
            exit 0
            ;;
        *)
            print_error "Invalid option, please choose a valid option."
            ;;
    esac
done
