#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

# Define paths to files
TRACKERS_FILE="/etc/trackers"
HOSTS_TRACKERS_FILE="/etc/hostsTrackers"
HOSTS_FILE="/etc/hosts"

# Function to print headers
print_header() {
  echo "$1"
}

# Function to print success messages
print_success() {
  echo "$1"
}

# Function to print error messages
print_error() {
  echo "$1"
}

# Add host
add_host() {
    echo -n "Enter the hostname to add: "
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
    echo -n "Enter the hostname to remove: "
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

# Uninstall and clean up all files dynamically
uninstall_all() {
    echo "Uninstalling all and cleaning up..."

    # Dynamically find files to remove
    BMENU_PATH=$(find / -type f -name "bmenu.sh" 2>/dev/null)
    BT_PATH=$(find / -type f -name "bt.sh" 2>/dev/null)
    HOSTS_TRACKERS_PATH=$(find / -type f -name "hostsTrackers" 2>/dev/null)
    CLEANUP_PATH=$(find / -type f -name "cleanup_hosts.sh.save" 2>/dev/null)
    UNINSTALL_PATH=$(find / -type f -name "uninstall_all.sh" 2>/dev/null)

    # Remove the files if found
    if [ -n "$BMENU_PATH" ]; then
        sudo rm -f "$BMENU_PATH"
        print_success "Removed bmenu.sh"
    else
        print_error "bmenu.sh not found."
    fi

    if [ -n "$BT_PATH" ]; then
        sudo rm -f "$BT_PATH"
        print_success "Removed bt.sh"
    else
        print_error "bt.sh not found."
    fi

    if [ -n "$HOSTS_TRACKERS_PATH" ]; then
        sudo rm -f "$HOSTS_TRACKERS_PATH"
        print_success "Removed hostsTrackers"
    else
        print_error "hostsTrackers not found."
    fi

    if [ -n "$CLEANUP_PATH" ]; then
        sudo rm -f "$CLEANUP_PATH"
        print_success "Removed cleanup_hosts.sh.save"
    else
        print_error "cleanup_hosts.sh.save not found."
    fi

    if [ -n "$UNINSTALL_PATH" ]; then
        sudo rm -f "$UNINSTALL_PATH"
        print_success "Removed uninstall_all.sh"
    else
        print_error "uninstall_all.sh not found."
    fi

    print_success "Uninstallation and cleanup complete."
    # Do not exit, just return to the menu
}

# Display the menu
while true; do
    clear
    print_header "DARK-PROJECT B-IP MENU INTERFACE"
    print_header "Created by x404 MASTER"
    echo "--------------------------------------------"
    echo "1. Add a new host to block"
    echo "2. Remove a host from the blocklist"
    echo "3. View current blocked hosts"
    echo "4. Clean up hosts file list"
    echo "5. Install or Update"
    echo "6. Uninstall all and reset system"
    echo "7. Exit"
    echo "--------------------------------------------"
    echo -n "Select an option [1-7]: "
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
            echo "Press any key to continue..."
            read -n 1
            ;;
        4)
            print_header "Cleaning up /etc/hosts file..."
            sudo /root/cleanup_hosts.sh
            ;;
        5)
            print_header "Installing or updating bt.sh script..."
            sudo /root/bt.sh
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
