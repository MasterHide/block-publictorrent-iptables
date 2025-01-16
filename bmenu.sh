#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\033[31mThis script must be run as root. Exiting.\033[0m"  # Red color for error
    exit 1
fi

# Define paths to files
TRACKERS_FILE="/etc/trackers"
HOSTS_TRACKERS_FILE="/etc/hostsTrackers"
HOSTS_FILE="/etc/hosts"
HIDDIFY_PATH="/opt/hiddify-manager"
BMENU_PATH="$HIDDIFY_PATH/bmenu.sh"
LOCK_FILE="/tmp/hiddify_update_lock"  # Lock file to prevent Hiddify from applying config during script execution

# Color definitions for better UI/UX
COLOR_HEADER="\033[1;34m"
COLOR_SUCCESS="\033[32m"
COLOR_ERROR="\033[31m"
COLOR_RESET="\033[0m"
COLOR_MENU="\033[1;36m"
COLOR_INPUT="\033[1;33m"
COLOR_WARNING="\033[33m"

# Function to print headers with color
print_header() {
    echo -e "${COLOR_HEADER}$1${COLOR_RESET}"
}

# Function to print success messages with color
print_success() {
    echo -e "${COLOR_SUCCESS}$1${COLOR_RESET}"
}

# Function to print error messages with color
print_error() {
    echo -e "${COLOR_ERROR}$1${COLOR_RESET}"
}

# Function to display the banner at the top of the menu
print_banner() {
    echo -e "\033[1;33m********************************************\033[0m"
    echo -e "\033[1;33m***  DARK-PROJECT B-IP MENU INTERFACE V2.0 ***\033[0m"
    echo -e "\033[1;33m***      Created by x404 MASTER          ***\033[0m"
    echo -e "\033[1;33m********************************************\033[0m"
    echo -e "\033[0;32m"
    echo -e "░█████╗░███╗░░██╗██╗░░██╗██╗████████╗"
    echo -e "██╔══██╗████╗░██║██║░░██║██║╚══██╔══╝"
    echo -e "██║░░██║██╔██╗██║███████║██║░░░██║░░░"
    echo -e "██║░░██║██║╚████║██╔══██║██║░░░██║░░░"
    echo -e "╚█████╔╝██║░╚███║██║░░██║██║░░░██║░░░"
    echo -e "░╚════╝░╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░░░░╚═╝"
    echo -e "\033[0m"
}

# Add single host or IP
add_single_host() {
    echo -n -e "${COLOR_INPUT}Enter the hostname or IP to add: ${COLOR_RESET}"
    read host_or_ip

    # If the input is a valid IP, process it directly
    if [[ "$host_or_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ips=$host_or_ip
    else
        # Resolve hostname to IP(s)
        ips=$(getent ahosts "$host_or_ip" | awk '{print $1}' | sort -u)
    fi

    if [ -z "$ips" ]; then
        print_error "Failed to resolve $host_or_ip to any IP address. Exiting."
        return
    fi

    # Add hostname or IP to tracker files
    if ! grep -q "$host_or_ip" "$TRACKERS_FILE" && ! grep -q "$host_or_ip" "$HOSTS_TRACKERS_FILE"; then
        echo "$host_or_ip" | sudo tee -a "$TRACKERS_FILE" > /dev/null
        echo "$host_or_ip" | sudo tee -a "$HOSTS_TRACKERS_FILE" > /dev/null
    fi

    # Block each resolved IP in both default and Docker chains
    for ip in $ips; do
        sudo iptables -A INPUT -d "$ip" -j DROP
        sudo iptables -A FORWARD -d "$ip" -j DROP
        sudo iptables -A OUTPUT -d "$ip" -j DROP
        sudo iptables -I DOCKER-USER -d "$ip" -j DROP
        sudo iptables -L -n | grep "$ip" && print_success "Rule applied for $ip" || print_error "Failed to apply rule for $ip"
    done

    # Prevent Hiddify Manager from applying config during the update
    touch "$LOCK_FILE"

    # Check if Hiddify Manager exists and integrate custom rules
    if [ -d "$HIDDIFY_PATH" ]; then
        echo "iptables -I DOCKER-USER -d $ip -j DROP" >> "$HIDDIFY_PATH/apply_configs.sh"
        echo "iptables -I INPUT -d $ip -j DROP" >> "$HIDDIFY_PATH/apply_configs.sh"
        echo "iptables -I OUTPUT -d $ip -j DROP" >> "$HIDDIFY_PATH/apply_configs.sh"
    fi

    # Remove the lock file once the changes are made
    rm -f "$LOCK_FILE"

    print_success "Host or IP $host_or_ip and its IP(s) blocked successfully!"
}

# Add multiple hosts or IPs
add_multiple_hosts() {
    echo -e "${COLOR_INPUT}Enter multiple hostnames or IPs, one per line. Press Enter on an empty line to finish:${COLOR_RESET}"
    hosts_or_ips=()
    while true; do
        read host_or_ip
        [ -z "$host_or_ip" ] && break
        hosts_or_ips+=("$host_or_ip")
    done

    for host_or_ip in "${hosts_or_ips[@]}"; do
        # If the input is a valid IP, process it directly
        if [[ "$host_or_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            ips=$host_or_ip
        else
            # Resolve hostname to IP(s)
            ips=$(getent ahosts "$host_or_ip" | awk '{print $1}' | sort -u)
        fi

        if [ -z "$ips" ]; then
            print_error "Failed to resolve $host_or_ip to any IP address. Skipping."
            continue
        fi

        # Add hostname or IP to tracker files
        if ! grep -q "$host_or_ip" "$TRACKERS_FILE" && ! grep -q "$host_or_ip" "$HOSTS_TRACKERS_FILE"; then
            echo "$host_or_ip" | sudo tee -a "$TRACKERS_FILE" > /dev/null
            echo "$host_or_ip" | sudo tee -a "$HOSTS_TRACKERS_FILE" > /dev/null
        fi

        # Block each resolved IP in both default and Docker chains
        for ip in $ips; do
            sudo iptables -A INPUT -d "$ip" -j DROP
            sudo iptables -A FORWARD -d "$ip" -j DROP
            sudo iptables -A OUTPUT -d "$ip" -j DROP
            sudo iptables -I DOCKER-USER -d "$ip" -j DROP
            sudo iptables -L -n | grep "$ip" && print_success "Rule applied for $ip" || print_error "Failed to apply rule for $ip"
        done
    done

    # Prevent Hiddify Manager from applying config during the update
    touch "$LOCK_FILE"

    # Check if Hiddify Manager exists and integrate custom rules
    if [ -d "$HIDDIFY_PATH" ]; then
        echo "iptables -I DOCKER-USER -d $ip -j DROP" >> "$HIDDIFY_PATH/apply_configs.sh"
        echo "iptables -I INPUT -d $ip -j DROP" >> "$HIDDIFY_PATH/apply_configs.sh"
        echo "iptables -I OUTPUT -d $ip -j DROP" >> "$HIDDIFY_PATH/apply_configs.sh"
    fi

    # Remove the lock file once the changes are made
    rm -f "$LOCK_FILE"

    print_success "All specified hosts and IPs have been blocked successfully!"
}

# Add host menu
add_host_menu() {
    echo -e "${COLOR_MENU}--------------------------------------------${COLOR_RESET}"
    echo -e "${COLOR_MENU}1. Block Single Domain/IP${COLOR_RESET}"
    echo -e "${COLOR_MENU}2. Block Multiple Domains/IPs${COLOR_RESET}"
    echo -e "${COLOR_MENU}--------------------------------------------${COLOR_RESET}"
    echo -n -e "${COLOR_INPUT}Select an option [1-2]: ${COLOR_RESET}"
    read sub_option

    case $sub_option in
        1)
            add_single_host
            ;;
        2)
            add_multiple_hosts
            ;;
        *)
            print_error "Invalid option, please select a valid one."
            ;;
    esac
}

# Remove unnecessary files or reset system
reset_system() {
    print_header "Uninstalling and resetting system..."

    # Deleting files and directories in the specified paths
    rm -rf /home/ubuntu/.cache /home/ubuntu/.npm /home/ubuntu/.local
    rm -rf /root/.cache /root/.npm /root/.local
    rm -rf "$HIDDIFY_PATH" /opt/hiddify-manager /opt/hiddify

    # Execute any system reset commands
    sudo bash "$BMENU_PATH" uninstall_all

    print_success "System reset completed and unnecessary files deleted."
}

# Remove host
remove_host() {
    echo -n -e "${COLOR_INPUT}Enter the hostname or IP to remove: ${COLOR_RESET}"
    read host_or_ip

    if ! grep -q "$host_or_ip" "$TRACKERS_FILE" && ! grep -q "$host_or_ip" "$HOSTS_TRACKERS_FILE"; then
        print_error "Host or IP not found. Exiting."
        return
    fi

    sudo sed -i "/$host_or_ip/d" "$TRACKERS_FILE"
    sudo sed -i "/$host_or_ip/d" "$HOSTS_TRACKERS_FILE"
    sudo iptables -D INPUT -d "$host_or_ip" -j DROP
    sudo iptables -D FORWARD -d "$host_or_ip" -j DROP
    sudo iptables -D OUTPUT -d "$host_or_ip" -j DROP
    sudo iptables -D DOCKER-USER -d "$host_or_ip" -j DROP

    print_success "$host_or_ip has been removed successfully!"
}

# Remove host menu
remove_host_menu() {
    echo -e "${COLOR_MENU}--------------------------------------------${COLOR_RESET}"
    echo -e "${COLOR_MENU}Enter the hostname or IP to remove: ${COLOR_RESET}"
    remove_host
}

# Main Menu
while true; do
    clear
    print_banner  # Print the banner at the top of each menu
    print_header "DARK-PROJECT B-IP MENU INTERFACE V2.0"
    print_header "Created by x404 MASTER"
    echo -e "${COLOR_MENU}--------------------------------------------${COLOR_RESET}"
    echo -e "${COLOR_MENU}1. Add a new host to block${COLOR_RESET}"
    echo -e "${COLOR_MENU}2. Remove a host from the blocklist${COLOR_RESET}"
    echo -e "${COLOR_MENU}3. View current blocked hosts${COLOR_RESET}"
    echo -e "${COLOR_MENU}4. Clean up hosts file list and remove unnecessary files${COLOR_RESET}"
    echo -e "${COLOR_MENU}5. Install or Update${COLOR_RESET}"
    echo -e "${COLOR_MENU}6. Uninstall all and reset system${COLOR_RESET}"
    echo -e "${COLOR_MENU}7. Exit${COLOR_RESET}"
    echo -e "${COLOR_MENU}--------------------------------------------${COLOR_RESET}"
    echo -n -e "${COLOR_INPUT}Select an option [1-7]: ${COLOR_RESET}"
    read option

    case $option in
        1)
            add_host_menu
            ;;
        2)
            remove_host_menu
            ;;
        3)
            print_header "Blocked Hosts"
            echo "--------------------------------"
            cat "$TRACKERS_FILE"
            echo "--------------------------------"
            echo -e "${COLOR_INPUT}Press any key to continue...${COLOR_RESET}"
            read -n 1
            ;;
        4)
            print_header "Running cleanup script..."
            sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/cleanup_hosts.sh)"
            print_success "Cleanup completed."
            ;;
        5)
            print_header "Installing or updating bmenu.sh script..."
            if [ -f "$BMENU_PATH" ]; then
                print_success "$BMENU_PATH already exists."
            else
                sudo wget -O "$BMENU_PATH" https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bmenu.sh
                sudo chmod +x "$BMENU_PATH"
                print_success "bmenu.sh script installed/updated at $BMENU_PATH."
            fi
            ;;
        6)
            reset_system
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
