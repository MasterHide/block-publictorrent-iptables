#!/bin/bash

# Function to Install bt.sh Script
install_script() {
    echo "Installing bt.sh script..."
    wget -q https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bt.sh -O /root/bt.sh
    chmod +x /root/bt.sh
    echo "bt.sh script installed successfully."

    # Optionally: You can add additional installation steps here if needed
    # Example: Install dependencies or set up services
}

# Function to Uninstall bt.sh Script
uninstall_script() {
    echo "Uninstalling bt.sh script..."

    # Step 1: Remove the bt.sh script if it exists
    if [ -f "/root/bt.sh" ]; then
        echo "Removing bt.sh script..."
        rm -f /root/bt.sh
    else
        echo "bt.sh script not found in /root"
    fi

    # Step 2: Remove the uninstall_bt.sh script if it exists
    if [ -f "/root/uninstall_bt.sh" ]; then
        echo "Removing uninstall_bt.sh script..."
        rm -f /root/uninstall_bt.sh
    fi

    # Step 3: Flush all iptables rules
    echo "Flushing iptables rules..."
    iptables -F
    iptables -t nat -F
    iptables -t mangle -F
    iptables -X
    iptables -t filter -X
    iptables -t nat -X
    iptables -t mangle -X

    # Step 4: Restart iptables service to apply changes
    echo "Restarting iptables service..."
    systemctl restart netfilter-persistent

    # Step 5: Reset /etc/hosts file to its default state
    echo "Resetting /etc/hosts file..."
    sudo truncate -s 0 /etc/hosts
    echo -e "127.0.0.1       localhost\n::1             localhost ip6-localhost ip6-loopback\nfe00::0         ip6-localnet\nff00::0         ip6-mcastprefix\nff02::1         ip6-allnodes\nff02::2         ip6-allrouters" | sudo tee /etc/hosts

    # Step 6: Completion message
    echo "Uninstallation complete."
}

# Menu Function
menu() {
    echo "----------------------------------"
    echo "      Select an Option:          "
    echo "----------------------------------"
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

# Run the menu
menu
