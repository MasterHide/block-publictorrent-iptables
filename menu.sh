#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to display the introduction message
show_intro() {
    clear
    echo -e "${CYAN}#########################################"
    echo -e "${CYAN}# ${WHITE}Torrent Blocker - Menu${CYAN} #"
    echo -e "${CYAN}#########################################"
    echo -e "${YELLOW}Please select an option below.${NC}"
    echo -e ""
}

# Function to install the bt.sh script
install_script() {
    echo -e "${GREEN}Installing bt.sh script...${NC}"
    wget -q -O /root/bt.sh https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bt.sh
    chmod +x /root/bt.sh
    echo -e "${GREEN}bt.sh script installed successfully!${NC}"
    show_menu
}

# Function to uninstall the bt.sh script
uninstall_script() {
    echo -e "${RED}Uninstalling bt.sh script...${NC}"

    # Remove the bt.sh script if it exists
    if [ -f "/root/bt.sh" ]; then
        rm -f /root/bt.sh
        echo -e "${RED}bt.sh script uninstalled successfully!${NC}"
    else
        echo -e "${RED}bt.sh script not found.${NC}"
    fi

    # Reset iptables and other changes made by the script
    echo -e "${YELLOW}Flushing iptables rules...${NC}"
    sudo iptables -F
    sudo iptables -t nat -F
    sudo iptables -t mangle -F
    sudo iptables -X
    sudo systemctl restart netfilter-persistent

    # Reset /etc/hosts file
    sudo truncate -s 0 /etc/hosts
    echo -e "127.0.0.1       localhost\n::1             localhost ip6-localhost ip6-loopback\nfe00::0         ip6-localnet\nff00::0         ip6-mcastprefix\nff02::1         ip6-allnodes\nff02::2         ip6-allrouters" | sudo tee /etc/hosts
    echo -e "${GREEN}Uninstallation complete.${NC}"

    show_menu
}

# Function to display the menu to the user
show_menu() {
    show_intro
    echo -e "${GREEN}----------------------------------${NC}"
    echo -e "${WHITE}1) Install Script${NC}"
    echo -e "${RED}2) Uninstall Script${NC}"
    echo -e "${RED}3) Exit${NC}"
    echo -e "${GREEN}----------------------------------${NC}"
    read -p "Enter your choice [1-3]: " choice
    case $choice in
        1)
            install_script
            ;;
        2)
            uninstall_script
            ;;
        3)
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice, please try again.${NC}"
            show_menu
            ;;
    esac
}

# Show the menu to the user
show_menu
