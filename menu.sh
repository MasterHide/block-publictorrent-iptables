#!/bin/bash

# Define log file location
LOGFILE="/var/log/block_publictorrent.log"

# Function to log messages
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> $LOGFILE
}

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to display the introduction message
show_intro() {
    clear
    echo -e "${CYAN}#########################################"
    echo -e "${CYAN}# ${WHITE}Welcome to the Public Torrent Blocker${CYAN} #"
    echo -e "${CYAN}#########################################"
    echo -e "${YELLOW}This script allows you to install, uninstall, and manage your block-publictorrent-iptables script.${NC}"
    echo -e "${BLUE}Select an option from the menu below to proceed.${NC}"
    echo -e ""
}

# Function to install the bt.sh script
install_script() {
    echo -e "${GREEN}Installing bt.sh script...${NC}"
    wget -q -O /root/bt.sh https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bt.sh
    chmod +x /root/bt.sh
    log_message "bt.sh script installed successfully"
    echo -e "${GREEN}bt.sh installed!${NC}"
    show_menu
}

# Function to uninstall the bt.sh script
uninstall_script() {
    echo -e "${RED}Uninstalling bt.sh script...${NC}"

    # Remove the bt.sh script if it exists
    if [ -f "/root/bt.sh" ]; then
        rm -f /root/bt.sh
        log_message "bt.sh script uninstalled successfully"
        echo -e "${RED}bt.sh script uninstalled!${NC}"
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
    log_message "Uninstallation complete."

    show_menu
}

# Function to view installation logs
view_logs() {
    if [ -f "$LOGFILE" ]; then
        echo -e "${CYAN}Viewing logs...${NC}"
        cat $LOGFILE
    else
        echo -e "${YELLOW}No logs found.${NC}"
    fi
    show_menu
}

# Function to check iptables status
check_iptables_status() {
    echo -e "${CYAN}Checking iptables status...${NC}"
    sudo iptables -L -v -n
    show_menu
}

# Function to update the script (self-update)
update_script() {
    echo -e "${BLUE}Checking for script updates...${NC}"
    wget -q -O /usr/local/bin/menu.sh https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/menu.sh
    chmod +x /usr/local/bin/menu.sh
    echo -e "${GREEN}Update completed!${NC}"
    show_menu
}

# Function to display the menu to the user
show_menu() {
    show_intro
    echo -e "${GREEN}----------------------------------${NC}"
    echo -e "${WHITE}1) Install Script${NC}"
    echo -e "${WHITE}2) Uninstall Script${NC}"
    echo -e "${WHITE}4) Check iptables Status${NC}"
    echo -e "${WHITE}5) Update Script${NC}"
    echo -e "${RED}6) Exit${NC}"
    echo -e "${GREEN}----------------------------------${NC}"
    read -p "Enter your choice [1-6]: " choice
    case $choice in
        1)
            install_script
            ;;
        2)
            uninstall_script
            ;;
        4)
            check_iptables_status
            ;;
        5)
            update_script
            ;;
        6)
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
