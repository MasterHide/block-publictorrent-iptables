#!/bin/bash

# Function to install bt.sh script
install_script() {
    echo "Installing bt.sh script..."

    # Check if bt.sh already exists
    if [ -f "/root/bt.sh" ]; then
        echo "bt.sh script is already installed."
    else
        # Download and install bt.sh
        wget -q https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bt.sh -O /root/bt.sh
        if [ $? -eq 0 ]; then
            chmod +x /root/bt.sh
            echo "bt.sh script installed successfully."
        else
            echo "Error: Failed to download bt.sh script."
        fi
    fi
}

# Function to uninstall bt.sh script
uninstall_script() {
    echo "Uninstalling bt.sh script..."

    # Remove bt.sh if it exists
    if [ -f "/root/bt.sh" ]; then
        echo "Removing bt.sh script..."
        rm -f /root/bt.sh
        echo "bt.sh script removed."
    else
        echo "bt.sh script not found in /root."
    fi

    # Flush all iptables rules
    echo "Flushing iptables rules..."
    iptables -F
    iptables -t nat -F
    iptables -t mangle -F
    iptables -X
    iptables -t filter -X
    iptables -t nat -X
    iptables -t mangle -X

    # Restart iptables service
    echo "Restarting iptables service..."
    systemctl restart netfilter-persistent

    # Reset /etc/hosts file
    echo "Resetting /etc/hosts file..."
    sudo truncate -s 0 /etc/hosts
    echo -e "127.0.0.1       localhost\n::1             localhost ip6-localhost ip6-loopback\nfe00::0         ip6-localnet\nff00::0         ip6-mcastprefix\nff02::1         ip6-allnodes\nff02::2         ip6-allrouters" | sudo tee /etc/hosts

    echo
