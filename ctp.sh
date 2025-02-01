#!/bin/bash

# Define common torrent ports (TCP/UDP)
TORRENT_PORTS=(6881:6999 51413 12345 30000 40000 45000)
# Define known torrent tracker ports (DHT, PEX)
DHT_PORTS=(6881 8999 27000)
PEER_EXCHANGE_PORTS=(2710 2711)
TORRENT_DOMAINS=("thepiratebay.org" "1337x.to" "rarbg.to" "yts.mx" "torlock.com")

# Function to block torrent traffic
block_torrent() {
    echo "Blocking common torrent ports, DHT, and PEX traffic..."

    for port in "${TORRENT_PORTS[@]}"; do
        sudo iptables -A OUTPUT -p tcp --dport $port -j DROP
        sudo iptables -A OUTPUT -p udp --dport $port -j DROP
        sudo iptables -A INPUT -p tcp --sport $port -j DROP
        sudo iptables -A INPUT -p udp --sport $port -j DROP
    done

    for port in "${DHT_PORTS[@]}"; do
        sudo iptables -A OUTPUT -p udp --dport $port -j DROP
        sudo iptables -A INPUT -p udp --sport $port -j DROP
    done

    for port in "${PEER_EXCHANGE_PORTS[@]}"; do
        sudo iptables -A OUTPUT -p udp --dport $port -j DROP
        sudo iptables -A INPUT -p udp --sport $port -j DROP
    done

    for domain in "${TORRENT_DOMAINS[@]}"; do
        echo "0.0.0.0 $domain" | sudo tee -a /etc/hosts > /dev/null
    done

    sudo iptables-save > /etc/iptables/rules.v4
    echo "Torrent traffic blocked successfully!"
}

# Function to unblock torrent traffic
unblock_torrent() {
    echo "Unblocking torrent traffic..."

    # Remove iptables rules blocking torrent ports
    for port in "${TORRENT_PORTS[@]}"; do
        sudo iptables -D OUTPUT -p tcp --dport $port -j DROP
        sudo iptables -D OUTPUT -p udp --dport $port -j DROP
        sudo iptables -D INPUT -p tcp --sport $port -j DROP
        sudo iptables -D INPUT -p udp --sport $port -j DROP
    done

    for port in "${DHT_PORTS[@]}"; do
        sudo iptables -D OUTPUT -p udp --dport $port -j DROP
        sudo iptables -D INPUT -p udp --sport $port -j DROP
    done

    for port in "${PEER_EXCHANGE_PORTS[@]}"; do
        sudo iptables -D OUTPUT -p udp --dport $port -j DROP
        sudo iptables -D INPUT -p udp --sport $port -j DROP
    done

    # Remove blocked domains from /etc/hosts
    for domain in "${TORRENT_DOMAINS[@]}"; do
        sudo sed -i "/$domain/d" /etc/hosts
    done

    # Save the updated iptables rules
    sudo iptables-save > /etc/iptables/rules.v4
    echo "Torrent traffic unblocked successfully!"
}

# Function to install the script
install_script() {
    echo "Installing the torrent blocker script..."
    # Optionally, you can set up cronjobs or systemd here for automatic execution
    echo "Installation complete!"
}

# Function to uninstall the script
uninstall_script() {
    echo "Uninstalling the torrent blocker script..."

    # Remove iptables rules
    unblock_torrent

    # Optionally remove cron jobs or systemd services if set up
    echo "You may want to remove any cron jobs or systemd services associated with this script manually."

    # Remove the script file
    read -p "Do you want to remove the script file (ctp.sh)? (y/n): " remove_script
    if [ "$remove_script" == "y" ]; then
        rm -f $0
        echo "Script file removed!"
    fi

    echo "Uninstallation complete!"
}

# Display the menu to the user
echo "Please select an option:"
echo "1. Block torrent traffic"
echo "2. Unblock torrent traffic"
echo "3. Install the torrent blocker script"
echo "4. Uninstall the torrent blocker script"
read -p "Enter your choice (1/2/3/4): " choice

case $choice in
    1)
        block_torrent
        ;;
    2)
        unblock_torrent
        ;;
    3)
        install_script
        ;;
    4)
        uninstall_script
        ;;
    *)
        echo "Invalid choice. Exiting."
        ;;
esac
