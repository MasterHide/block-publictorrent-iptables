#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\033[1;31mThis script must be run as root. Exiting.\033[0m"
    exit 1
fi

# Define paths to files
TRACKERS_FILE="/etc/trackers"
HOSTS_TRACKERS_FILE="/etc/hostsTrackers"
HOSTS_FILE="/etc/hosts"

# Function to print headers with color
print_header() {
  echo -e "\033[1;34m$1\033[0m"  # Blue color for headers
}

# Function to print success messages in green
print_success() {
  echo -e "\033[1;32m$1\033[0m"  # Green color for success
}

# Function to print error messages in red
print_error() {
  echo -e "\033[1;31m$1\033[0m"  # Red color for errors
}

# Function to print info messages in yellow
print_info() {
  echo -e "\033[1;33m$1\033[0m"  # Yellow color for info
}

# Display the custom logo
print_logo() {
  echo -e "\033[1;35m
▒▒▒▒▒▄██████████▄▒▒▒▒▒
▒▒▒▄██████████████▄▒▒▒
▒▒██████████████████▒▒
▒▐███▀▀▀▀▀██▀▀▀▀▀███▌▒
▒███▒▒▌■▐▒▒▒▒▌■▐▒▒███▒
▒▐██▄▒▀▀▀▒▒▒▒▀▀▀▒▄██▌▒
▒▒▀████▒▄▄▒▒▄▄▒████▀▒▒
▒▒▐███▒▒▒▀▒▒▀▒▒▒███▌▒▒
▒▒███▒▒▒▒▒▒▒▒▒▒▒▒███▒▒
▒▒▒██▒▒▀▀▀▀▀▀▀▀▒▒██▒▒▒
▒▒▒▐██▄▒▒▒▒▒▒▒▒▄██▌▒▒▒
▒▒▒▒▀████████████▀▒▒▒▒
\033[0m"
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
    print_logo  # Display the logo
    print_header "Public Host Blocker Menu"
    echo -e "\033[1;37m--------------------------------------------\033[0m"  # Separator line
    echo -e "\033[1;32m1.\033[0m Add a new host to block"
    echo -e "\033[1;32m2.\033[0m Remove a host from the blocklist"
    echo -e "\033[1;32m3.\033[0m View current blocked hosts"
    echo -e "\033[1;32m4.\033[0m Clean up /etc/hosts file"
    echo -e "\033[1;32m5.\033[0m Install or Update bt.sh"
    echo -e "\033[1;32m6.\033[0m Uninstall all and reset system"
    echo -e "\033[1;32m7.\033[0m Exit"
    echo -e "\033[1;37m--------------------------------------------\033[0m"  # Separator line
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
