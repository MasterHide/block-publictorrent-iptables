#!/bin/bash

# Define paths to files
TRACKERS_FILE="/etc/trackers"
HOSTS_TRACKERS_FILE="/etc/hostsTrackers"
HOSTS_FILE="/etc/hosts"

# Function to print headers
print_header() {
  echo -e "\033[1;34m$1\033[0m"
}

# Function to print success messages in green
print_success() {
  echo -e "\033[1;32m$1\033[0m"
}

# Function to print error messages in red
print_error() {
  echo -e "\033[1;31m$1\033[0m"
}

# Display the menu
while true; do
    clear
    print_header "Public Tracker Blocker Menu"
    echo "1. Add a new tracker to block"
    echo "2. Remove a tracker from the blocklist"
    echo "3. View current blocked trackers"
    echo "4. Clean up /etc/hosts file"
    echo "5. Install or Update bt.sh"
    echo "6. Uninstall all and reset system"
    echo "7. Exit"
    echo -n "Select an option [1-7]: "
    read option

    case $option in
        1)
            # Add tracker
            echo -n "Enter the hostname to add: "
            read hostname
            if ! grep -q "$hostname" "$TRACKERS_FILE"; then
                echo "$hostname" | sudo tee -a "$TRACKERS_FILE" > /dev/null
                echo "$hostname" | sudo tee -a "$HOSTS_TRACKERS_FILE" > /dev/null
                sudo iptables -A INPUT -d "$hostname" -j DROP
                sudo iptables -A FORWARD -d "$hostname" -j DROP
                sudo iptables -A OUTPUT -d "$hostname" -j DROP
                print_success "Tracker $hostname added and blocked successfully!"
            else
                print_error "Tracker $hostname already exists in the blocklist."
            fi
            ;;
        2)
            # Remove tracker
            echo -n "Enter the hostname to remove: "
            read hostname
            if grep -q "$hostname" "$TRACKERS_FILE"; then
                sudo sed -i "/$hostname/d" "$TRACKERS_FILE"
                sudo sed -i "/$hostname/d" "$HOSTS_TRACKERS_FILE"
                sudo iptables -D INPUT -d "$hostname" -j DROP
                sudo iptables -D FORWARD -d "$hostname" -j DROP
                sudo iptables -D OUTPUT -d "$hostname" -j DROP
                print_success "Tracker $hostname removed successfully."
            else
                print_error "Tracker $hostname not found in the blocklist."
            fi
            ;;
        3)
            # View current blocked trackers
            print_header "Blocked Trackers"
            echo "--------------------------------"
            cat "$TRACKERS_FILE"
            echo "--------------------------------"
            echo "Press any key to continue..."
            read -n 1
            ;;
        4)
            # Clean up /etc/hosts file
            sudo /root/cleanup_hosts.sh
            ;;
        5)
            # Install or update bt.sh script
            sudo /root/bt.sh
            ;;
        6)
            # Uninstall all and reset system
            sudo /root/uninstall_all.sh
            ;;
        7)
            echo "Exiting. Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid option, please choose a valid option."
            ;;
    esac
done
