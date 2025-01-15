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

# Uninstall and clean up all files (using predefined paths, no dynamic search)
uninstall_all() {
    echo "Uninstalling all and cleaning up..."

    # List of files to remove from /root
    files_to_remove_root=(
        "/root/bmenu.sh"
        "/root/uninstall_all.sh"
        "/root/bt.sh"
        "/root/hostsTrackers"
        "/root/cleanup_hosts.sh.save"
        "/root/trackers"
        "/root/hostsTrackers"
    )

    # List of files to remove from /home/ubuntu
    files_to_remove_home_ubuntu=(
        "/home/ubuntu/bmenu.sh"
        "/home/ubuntu/uninstall_all.sh"
        "/home/ubuntu/bt.sh"
        "/home/ubuntu/hostsTrackers"
        "/home/ubuntu/cleanup_hosts.sh.save"
        "/home/ubuntu/trackers"
        "/home/ubuntu/hostsTrackers"
    )

    # Remove files from /root
    for file in "${files_to_remove_root[@]}"; do
        if [ -f "$file" ]; then
            sudo rm -f "$file"
            echo "Removed from /root: $file"
        else
            echo "File not found in /root: $file"
        fi
    done

    # Remove files from /home/ubuntu
    for file in "${files_to_remove_home_ubuntu[@]}"; do
        if [ -f "$file" ]; then
            sudo rm -f "$file"
            echo "Removed from /home/ubuntu: $file"
        else
            echo "File not found in /home/ubuntu: $file"
        fi
    done

    print_success "All specified files have been processed and removed."
    # Return to the menu (don't exit)
}

# Cleanup /etc/hosts and remove unnecessary files from /root and /home/ubuntu
cleanup_files() {
    echo "Cleaning up files and /etc/hosts..."

    # Display the current contents of /etc/hosts before modifying
    echo "Current contents of /etc/hosts:"
    cat /etc/hosts
    echo "------------------------------------------"

    # Backup the /etc/hosts file before modifying it
    echo "Backing up /etc/hosts to /etc/hosts.bak..."
    sudo cp /etc/hosts /etc/hosts.bak

    # Remove lines containing 'trackers', 'ads', and 'hostsTrackers' in /etc/hosts
    echo "Cleaning up /etc/hosts..."
    sudo sed -i '/trackers/d' /etc/hosts
    sudo sed -i '/ads/d' /etc/hosts
    sudo sed -i '/hostsTrackers/d' /etc/hosts

    # List of files to remove from /root
    files_to_remove_root=(
        "/root/bmenu.sh"
        "/root/uninstall_all.sh"
        "/root/bt.sh"
        "/root/hostsTrackers"
        "/root/cleanup_hosts.sh.save"
        "/root/trackers"
        "/root/hostsTrackers"
    )

    # List of files to remove from /home/ubuntu
    files_to_remove_home_ubuntu=(
        "/home/ubuntu/bmenu.sh"
        "/home/ubuntu/uninstall_all.sh"
        "/home/ubuntu/bt.sh"
        "/home/ubuntu/hostsTrackers"
        "/home/ubuntu/cleanup_hosts.sh.save"
        "/home/ubuntu/trackers"
        "/home/ubuntu/hostsTrackers"
    )

    # Remove files from /root
    for file in "${files_to_remove_root[@]}"; do
        if [ -f "$file" ]; then
            sudo rm -f "$file"
            echo "Removed from /root: $file"
        else
            echo "File not found in /root: $file"
        fi
    done

    # Remove files from /home/ubuntu
    for file in "${files_to_remove_home_ubuntu[@]}"; do
        if [ -f "$file" ]; then
            sudo rm -f "$file"
            echo "Removed from /home/ubuntu: $file"
        else
            echo "File not found in /home/ubuntu: $file"
        fi
    done

    print_success "All specified files have been processed and removed."
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
    echo "4. Clean up hosts file list and remove unnecessary files"
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
            cleanup_files  # Run cleanup files and /etc/hosts cleanup
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
