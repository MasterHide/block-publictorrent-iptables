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

# Display the menu
while true; do
    clear
    print_header "DARK-PROJECT B-IP MENU INTERFACE"
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
            print_info "Cleaning up /etc/hosts file..."
            sudo /root/cleanup_hosts.sh
            ;;
        5)
            print_info "Installing or updating bt.sh script..."
            sudo /root/bt.sh
            ;;
        6)
            print_error "Uninstalling all and resetting system..."
            sudo /root/uninstall_all.sh
            ;;
        7)
            print_success "Exiting. Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid option, please choose a valid option."
            ;;
    esac
done
