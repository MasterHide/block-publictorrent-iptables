#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\033[31mThis script must be run as root. Exiting.\033[0m" # Red color for error
    exit 1
fi

# Unique Lock file based on process ID (PID)
LOCK_FILE="/tmp/hiddify_update_lock_$$"

# Ensure to remove the lock file at the end of the script or on exit
trap "rm -f $LOCK_FILE" EXIT

# Check if the lock file exists (indicating an instance is already running)
if [ -f "$LOCK_FILE" ]; then
    echo -e "\033[31mAnother instance of the script is already running. Exiting.\033[0m"
    exit 1
else
    touch "$LOCK_FILE"  # Create the lock file with a unique name
fi

# Check for required commands
required_commands=("curl" "iptables" "getent")
for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "\033[31m$cmd is not installed. Please install $cmd and rerun the script.\033[0m"
        exit 1
    fi
done

# Define paths to files
TRACKERS_FILE="/etc/trackers"
HOSTS_TRACKERS_FILE="/etc/hostsTrackers"
HOSTS_FILE="/etc/hosts"
HIDDIFY_PATH="/opt/hiddify-manager"
BMENU_PATH="$HIDDIFY_PATH/bmenu.sh"
LOCK_FILE="/tmp/hiddify_update_lock" # Lock file to prevent Hiddify from applying config during script execution

# Ensure write permissions on tracker files
for file in "$TRACKERS_FILE" "$HOSTS_TRACKERS_FILE"; do
    if [ ! -w "$file" ]; then
        echo -e "\033[31mNo write permission for $file. Exiting.\033[0m"
        exit 1
    fi
done

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
echo -e "\033[1;33m*** DARK-PROJECT B-IP MENU INTERFACE V2.5 ***\033[0m"
echo -e "\033[1;33m*** Created by x404 MASTER ***\033[0m"
echo -e "\033[1;33m*** Let's reduce the risk ***\033[0m"
echo -e "\033[1;33m*** contact - https://t.me/Dark_Evi ***\033[0m"
echo -e "\033[1;33m********************************************\033[0m"
echo -e "\033[0;32m"
echo -e "██╗░░██╗░░░░░░░██████╗██╗░░░░░"
echo -e "╚██╗██╔╝░░░░░░██╔════╝██║░░░░░"
echo -e "░╚███╔╝░█████╗╚█████╗░██║░░░░░"
echo -e "░██╔██╗░╚════╝░╚═══██╗██║░░░░░"
echo -e "██╔╝╚██╗░░░░░░██████╔╝███████╗"
echo -e "╚═╝░░╚═╝░░░░░░╚═════╝░╚══════╝"
echo -e "\033[0m"
}

# Function to check if getent is installed and DNS works
check_getent() {
    if ! command -v getent &> /dev/null; then
        print_error "getent command is not installed. Please install the necessary package."
        print_error "On Ubuntu/Debian, run: sudo apt-get install libc-bin"
        print_error "On RHEL/CentOS, run: sudo yum install glibc-common"
        exit 1
    fi
    # Check if DNS resolution works
    if ! getent hosts example.com &> /dev/null; then
        print_error "DNS resolution is not working. Please check your network configuration."
        exit 1
    fi
}

# Function to remove the existing iptables rule and domain from list
remove_existing_block() {
    local host_or_ip="$1"

    # Resolve the domain to IPs (if it's a domain)
    if [[ ! "$host_or_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ips=$(getent ahosts "$host_or_ip" | awk '{print $1}' | sort -u)
    else
        ips="$host_or_ip"
    fi

    # Remove iptables rules
    for ip in $ips; do
        iptables -D INPUT -d "$ip" -j DROP &>/dev/null
        iptables -D FORWARD -d "$ip" -j DROP &>/dev/null
        iptables -D OUTPUT -d "$ip" -j DROP &>/dev/null
        iptables -D DOCKER-USER -d "$ip" -j DROP &>/dev/null
    done

    # Remove the domain/IP from the tracker files
    sed -i "/$host_or_ip/d" "$TRACKERS_FILE"
    sed -i "/$host_or_ip/d" "$HOSTS_TRACKERS_FILE"
}

# Function to save iptables rules
save_iptables() {
    iptables-save > /etc/iptables/rules.v4
    print_success "Iptables rules saved successfully."
}

# Function to add a single host to blocklist
add_single_host() {
    check_getent # Ensure getent is available

    echo -e "${COLOR_INPUT}Enter domain or IP to block: ${COLOR_RESET}"
    read host_or_ip

    # Check if the input is empty
    if [ -z "$host_or_ip" ]; then
        print_error "No domain or IP entered. Returning to the menu."
        return
    fi

    # Check if the domain/IP already exists in the blocklist
    if grep -q "$host_or_ip" "$TRACKERS_FILE" || grep -q "$host_or_ip" "$HOSTS_TRACKERS_FILE"; then
        print_warning "$host_or_ip is already blocked. Removing existing block and updating..."

        # Remove the existing block and update the rule
        remove_existing_block "$host_or_ip"
    fi

    # Check if it's an IP or a domain
    if [[ "$host_or_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ips="$host_or_ip"
    else
        ips=$(getent ahosts "$host_or_ip" | awk '{print $1}' | sort -u)
    fi

    # If no IPs are resolved, skip this domain
    if [ -z "$ips" ]; then
        print_error "Failed to resolve $host_or_ip to IP addresses."
        return
    fi

    # Block the IPs in iptables and update the files
    for ip in $ips; do
        # Add the IP to iptables rules
        iptables -A INPUT -d "$ip" -j DROP
        iptables -A FORWARD -d "$ip" -j DROP
        iptables -A OUTPUT -d "$ip" -j DROP
        iptables -I DOCKER-USER -d "$ip" -j DROP
        print_success "$ip has been blocked successfully."

        # Add domain/IP to the tracker files
        echo "$host_or_ip" | tee -a "$TRACKERS_FILE" > /dev/null
        echo "$host_or_ip" | tee -a "$HOSTS_TRACKERS_FILE" > /dev/null
        print_success "$host_or_ip has been added to the blocklist."
    done

    save_iptables # Save iptables rules
}

# Function to add multiple hosts (domains or IPs) to blocklist
add_multiple_hosts() {
    check_getent # Ensure getent is available

    echo -e "${COLOR_INPUT}Enter domains or IPs to block (press Enter without input to stop):${COLOR_RESET}"

    while true; do
        # Prompt for user input
        echo -n -e "${COLOR_INPUT}Enter domain or IP: ${COLOR_RESET}"
        read host_or_ip

        # Exit the loop if the user presses Enter without typing anything
        if [ -z "$host_or_ip" ]; then
            print_success "No more domains or IPs to add. Returning to the menu."
            break
        fi

        # Check if the domain/IP already exists in the blocklist
        if grep -q "$host_or_ip" "$TRACKERS_FILE" || grep -q "$host_or_ip" "$HOSTS_TRACKERS_FILE"; then
            print_warning "$host_or_ip is already blocked. Removing existing block and updating..."

            # Remove the existing block and update the rule
            remove_existing_block "$host_or_ip"
        fi

        # Check if it's an IP or a domain
        if [[ "$host_or_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            ips="$host_or_ip"
        else
            ips=$(getent ahosts "$host_or_ip" | awk '{print $1}' | sort -u)
        fi

        # If no IPs are resolved, skip this domain
        if [ -z "$ips" ]; then
            print_error "Failed to resolve $host_or_ip to IP addresses."
            continue
        fi

        # Block the IPs in iptables and update the files
        for ip in $ips; do
            # Add the IP to iptables rules
            iptables -A INPUT -d "$ip" -j DROP
            iptables -A FORWARD -d "$ip" -j DROP
            iptables -A OUTPUT -d "$ip" -j DROP
            iptables -I DOCKER-USER -d "$ip" -j DROP
            print_success "$ip has been blocked successfully."

            # Add domain/IP to the tracker files
            echo "$host_or_ip" | tee -a "$TRACKERS_FILE" > /dev/null
            echo "$host_or_ip" | tee -a "$HOSTS_TRACKERS_FILE" > /dev/null
            print_success "$host_or_ip has been added to the blocklist."
        done
    done

    save_iptables # Save iptables rules
}

# Unified function to remove and unblock multiple hosts (IPs and domains)
remove_and_unblock_multiple_hosts() {
    echo -e "${COLOR_INPUT}Enter domains or IPs to remove and unblock (separate with spaces): ${COLOR_RESET}"
    read -r input_hosts

    # Check if input is empty
    if [ -z "$input_hosts" ]; then
        print_error "No domains or IPs provided. Returning to the menu."
        return
    fi

    # Loop over each host or IP in the input
    for host_or_ip in $input_hosts; do
        # Initialize ips as empty before processing a new host/IP
        ips=""

        # Replace hyphens with dots in case of the "88-222-210-216.init.lt" format
        host_or_ip=$(echo "$host_or_ip" | sed 's/-/\./g')

        # Check if it's an IP or a domain
        if [[ "$host_or_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            # It's an IP address, use it directly
            ips="$host_or_ip"
        else
            # Resolve the domain to IP(s)
            ips=$(getent ahosts "$host_or_ip" | awk '{print $1}' | sort -u)
        fi

        # If no IPs are resolved, skip this domain
        if [ -z "$ips" ]; then
            print_error "Failed to resolve $host_or_ip to IP addresses. Skipping."
            continue
        fi

        # Remove the IPs from iptables
        for ip in $ips; do
            if sudo iptables -C INPUT -d "$ip" -j DROP 2>/dev/null; then
                sudo iptables -D INPUT -d "$ip" -j DROP
                sudo iptables -D FORWARD -d "$ip" -j DROP
                sudo iptables -D OUTPUT -d "$ip" -j DROP
                sudo iptables -D DOCKER-USER -d "$ip" -j DROP
                print_success "$ip has been unblocked successfully."
            else
                print_error "$ip was not blocked previously, skipping iptables removal."
            fi
        done

        # Remove the domain/IP from the tracker files
        for ip in $ips; do
            sudo sed -i "/$ip/d" "$TRACKERS_FILE"
            sudo sed -i "/$ip/d" "$HOSTS_TRACKERS_FILE"
            print_success "$ip has been removed from the blocklist."
        done

        # Also remove the host from /etc/hosts
        sudo sed -i "/$host_or_ip/d" /etc/hosts
        print_success "$host_or_ip has been removed from /etc/hosts."

        # Remove the host from /etc/trackers
        sudo sed -i "/$host_or_ip/d" /etc/trackers
        print_success "$host_or_ip has been removed from /etc/trackers."

        # Remove the host from /etc/hostsTrackers
        sudo sed -i "/$host_or_ip/d" /etc/hostsTrackers
        print_success "$host_or_ip has been removed from /etc/hostsTrackers."
    done

    # Ask the user if they want to check existing iptables rules
    echo -e "${COLOR_INPUT}Do you want to check the existing iptables rules with line numbers? (y/n): ${COLOR_RESET}"
    read -r check_rules

    if [[ "$check_rules" =~ ^[Yy]$ ]]; then
        # Show the existing iptables rules with line numbers
        echo -e "${COLOR_INFO}Existing iptables rules with line numbers: ${COLOR_RESET}"
        sudo iptables -L -v --line-numbers
    else
        echo -e "${COLOR_INFO}Skipping iptables rules check.${COLOR_RESET}"
    fi
}

# Function to check if a specific host (domain or IP) is blocked (Active/Not Active)
check_specific_host_status() {
echo -e "${COLOR_INPUT}Enter domain or IP to check if it's blocked: ${COLOR_RESET}"
read host_or_ip

# Check if input is empty
if [ -z "$host_or_ip" ]; then
print_error "No domain or IP provided. Returning to the menu."
return
fi

# Check if it's an IP or domain
if [[ "$host_or_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ || "$host_or_ip" =~ ^[0-9a-fA-F:]+$ ]]; then
# It's either an IPv4 or IPv6 address, use it directly
ips="$host_or_ip"
else
# Resolve the domain to IP(s)
ips=$(getent ahosts "$host_or_ip" | awk '{print $1}' | sort -u)
fi

# If no IPs are resolved, skip this domain
if [ -z "$ips" ]; then
print_error "Failed to resolve $host_or_ip to IP addresses."
return
fi

# Check if the IP is blocked
for ip in $ips; do
# Check if the IP is blocked in iptables
if sudo iptables -C INPUT -d "$ip" -j DROP &>/dev/null || \
sudo iptables -C FORWARD -d "$ip" -j DROP &>/dev/null || \
sudo iptables -C OUTPUT -d "$ip" -j DROP &>/dev/null || \
sudo iptables -C DOCKER-USER -d "$ip" -j DROP &>/dev/null || \
sudo ip6tables -C INPUT -d "$ip" -j DROP &>/dev/null || \
sudo ip6tables -C FORWARD -d "$ip" -j DROP &>/dev/null || \
sudo ip6tables -C OUTPUT -d "$ip" -j DROP &>/dev/null || \
sudo ip6tables -C DOCKER-USER -d "$ip" -j DROP &>/dev/null; then
echo -e "$ip - Blocked - Active"
else
echo -e "$ip - Not Blocked - Not Active"
fi
done
}

# Main Menu
while true; do
clear
print_banner # Print the banner at the top of each menu
print_header "MAIN MENU"
print_header "V2.5"
echo -e "${COLOR_MENU}--------------------------------------------${COLOR_RESET}"
echo -e "${COLOR_MENU}1. Torrent Traffic Management${COLOR_RESET}"
echo -e "${COLOR_MENU}2. Add a new host to block${COLOR_RESET}"
echo -e "${COLOR_MENU}3. Remove a host from the blocklist${COLOR_RESET}"
echo -e "${COLOR_MENU}4. View current blocked hosts${COLOR_RESET}"
echo -e "${COLOR_MENU}5. Clean up hosts file list and remove unnecessary files${COLOR_RESET}"
echo -e "${COLOR_MENU}6. Install or Update${COLOR_RESET}"
echo -e "${COLOR_MENU}7. Uninstall all and reset system${COLOR_RESET}"
echo -e "${COLOR_MENU}8. Check if a specific host (domain/IP) is blocked${COLOR_RESET}"
echo -e "${COLOR_MENU}9. Exit${COLOR_RESET}"
echo -e "${COLOR_MENU}--------------------------------------------${COLOR_RESET}"
echo -n -e "${COLOR_INPUT}Select an option [1-8]: ${COLOR_RESET}"
read option

case $option in
1)
# Function to print a warning message
warn_msg() {
    tput setaf 1; # Set text color to red
    echo "WARNING: Blocking torrent traffic may impact some applications. Please proceed with caution."
    echo "To unblock torrent traffic and remove the script later, you will need to run the unblocking process."
    tput sgr0; # Reset text formatting
}

# Submenu for option 1
while true; do
    clear
    print_header "Running Torrent Traffic Management..." 

    # Show warning message
    warn_msg

    # Confirm before continuing
    read -p "Do you want to continue with blocking torrent traffic? (y/n): " proceed
    if [[ "$proceed" != "y" ]]; then
        echo "Aborted. Returning to the main menu."
        break
    fi

    # Run the torrent blocking script
    curl -fsSL https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/ctp.sh -o ctp.sh && chmod +x ctp.sh && sudo ./ctp.sh
    print_success "Torrent Traffic blocking completed."

    # Ask user if they want to return to the main menu or exit
    read -p "Do you want to return to the main menu? (y/n): " choice
    if [[ "$choice" != "y" ]]; then
        break  # Exit the loop if the user doesn't want to return
    fi
done
;;
2)
# Submenu for option 2
while true; do
clear
print_header "Add a new host to block"
echo -e "${COLOR_MENU}--------------------------------------------${COLOR_RESET}"
echo -e "${COLOR_MENU}1. Add a single host${COLOR_RESET}"
echo -e "${COLOR_MENU}2. Add multiple hosts${COLOR_RESET}"
echo -e "${COLOR_MENU}3. Go back to main menu${COLOR_RESET}"
echo -e "${COLOR_MENU}--------------------------------------------${COLOR_RESET}"
echo -n -e "${COLOR_INPUT}Select an option [1-3]: ${COLOR_RESET}"
read submenu_option

case $submenu_option in
1) add_single_host; break ;;
2) add_multiple_hosts; break ;;
3) break ;;
*) print_error "Invalid option, please choose a valid option." ;;
esac
done
;;
3)
# Submenu for option 3 (remove hosts)
while true; do
    clear
    print_header "Manage Blocked Hosts & IPs"
    echo -e "${COLOR_MENU}--------------------------------------------${COLOR_RESET}"
    echo -e "${COLOR_MENU}1. Remove and unblock multiple hosts/IPs (IPv4, IPv6 or domain)${COLOR_RESET}"
    echo -e "${COLOR_MENU}2. Go back to main menu${COLOR_RESET}"
    echo -e "${COLOR_MENU}--------------------------------------------${COLOR_RESET}"
    echo -n -e "${COLOR_INPUT}Select an option [1-2]: ${COLOR_RESET}"
    read submenu_option

    case $submenu_option in
    1)
        # Call the unified function to unblock and remove multiple hosts
        remove_and_unblock_multiple_hosts
        echo -e "${COLOR_INPUT}Press any key to continue...${COLOR_RESET}"
        read -n 1
        break
        ;;
    2) break ;;
    *)
        print_error "Invalid option, please choose a valid option."
        ;;
    esac
done
;;

4)
print_header "Blocked Hosts"
echo "--------------------------------"

# Display content from /etc/hosts
echo "Blocked Entries from /etc/hosts:"
echo "--------------------------------"
if [ -s "/etc/hosts" ]; then
cat /etc/hosts
else
echo "No entries found in /etc/hosts."
fi

echo "--------------------------------"

# Display content from /etc/trackers
echo "Blocked Trackers from /etc/trackers:"
echo "--------------------------------"
if [ -s "$TRACKERS_FILE" ]; then
cat "$TRACKERS_FILE"
else
echo "No entries found in $TRACKERS_FILE."
fi

echo "--------------------------------"
echo -e "${COLOR_INPUT}Press any key to continue...${COLOR_RESET}"
read -n 1
;;

5)
print_header "Running cleanup script..."
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/cleanup_hosts.sh)"
print_success "Cleanup completed."
;;
6)
print_header "Installing or updating bmenu.sh script..."
if [ -f "$BMENU_PATH" ]; then
print_success "$BMENU_PATH already exists."
else
sudo wget -O "$BMENU_PATH" https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bmenu.sh
sudo chmod +x "$BMENU_PATH"
print_success "bmenu.sh script installed/updated at $BMENU_PATH."
fi
;;
7)
    reset_system
    echo "Downloading and executing rmfew.sh..."
    
    # Download rmfew.sh to a temporary location
    wget -q -O /tmp/rmfew.sh https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/rmfew.sh
    
    # Ensure the script has execution permission
    chmod +x /tmp/rmfew.sh
    
    # Run the script
    /tmp/rmfew.sh
    
    exit 0
;;

8)
# Check if a specific host (domain/IP) is blocked
check_specific_host_status
echo -e "${COLOR_INPUT}Press any key to continue...${COLOR_RESET}"
read -n 1
;;

9)
print_success "Exiting. Goodbye!"
exit 0
;;
*)
print_error "Invalid option, please choose a valid option."
;;
esac
done
