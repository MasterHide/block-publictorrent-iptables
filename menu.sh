#!/bin/bash

# Define colors
RESET="\033[0m"
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
WHITE="\033[97m"

# Function to install bt.sh script
install_script() {
    echo -e "${CYAN}Installing bt.sh script...${RESET}"
    if [ -f "/root/bt.sh" ]; then
        echo -e "${YELLOW}bt.sh script is already installed.${RESET}"
    else
        wget -q https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bt.sh -O /root/bt.sh
        chmod +x /root/bt.sh
        echo -e "${GREEN}bt.sh script installed successfully.${RESET}"
    fi
}

# Function to uninstall bt.sh script
uninstall_script() {
    echo -e "${CYAN}Uninstalling bt.sh script...${RESET}"

    # Remove bt.sh if it exists
    if [ -f "/root/bt.sh" ]; then
        echo -e "${RED}Removing bt.sh script...${RESET}"
        rm -f /root/bt.sh
    else
        echo -e "${YELLOW}bt.sh script not found in /root.${RESET}"
    fi

    # Flush all iptables rules
    echo -e "${CYAN}Flushing iptables rules...${RESET}"
    iptables -F
    iptables -t nat -F
    iptables -t mangle -F
    iptables -X
    iptables -t filter -X
    iptables -t nat -X
    iptables -t mangle -X

    # Restart iptables service
    echo -e "${CYAN}Restarting iptables service...${RESET}"
    systemctl restart netfilter-persistent

    # Reset /etc/hosts file
    echo -e "${CYAN}Resetting /etc/hosts file...${RESET}"
    sudo truncate -s 0 /etc/hosts
    echo -e "127.0.0.1       localhost\n::1             localhost ip6-localhost ip6-loopback\nfe00::0         ip6-localnet\nff00::0         ip6-mcastprefix\nff02::1         ip6-allnodes\nff02::2         ip6-allrouters" | sudo tee /etc/hosts

    echo -e "${GREEN}Uninstallation complete.${RESET}"
}

# Function to show the menu
menu() {
    clear
    echo -e "${BLUE}----------------------------------${RESET}"
    echo -e "${WHITE}${BOLD}      Select an Option:          ${RESET}"
    echo -e "${BLUE}----------------------------------${RESET}"
    echo -e "${GREEN}1. Install bt.sh Script${RESET}"
    echo -e "${RED}2. Uninstall bt.sh Script${RESET}"
    echo -e "${CYAN}3. Exit${RESET}"
    echo -e "${BLUE}----------------------------------${RESET}"
    read -p "Enter your choice [1-3]: " choice

    case $choice in
        1)
            install_script
            ;;
        2)
            uninstall_script
            ;;
        3)
            echo -e "${YELLOW}Exiting...${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option! Please select 1, 2, or 3.${RESET}"
            menu
            ;;
    esac
}

# Check if the script is being run as root, if not, prompt to run with sudo
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script must be run as root or with sudo.${RESET}"
    exit 1
fi

# Run the menu
menu

# Optional: Self-remove the script after execution
# rm -f /usr/local/bin/menu
