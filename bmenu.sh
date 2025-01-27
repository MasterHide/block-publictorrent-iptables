 #!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
echo -e "\033[31mThis script must be run as root. Exiting.\033[0m" # Red color for error
exit 1
fi

# Check for required commands
for cmd in curl iptables getent; do
if ! command -v $cmd &> /dev/null; then
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
echo -e "░█████╗░███╗░░██╗██╗░░██╗██╗████████╗"
echo -e "██╔══██╗████╗░██║██║░░██║██║╚══██╔══╝"
echo -e "██║░░██║██╔██╗██║███████║██║░░░██║░░░"
echo -e "██║░░██║██║╚████║██╔══██║██║░░░██║░░░"
echo -e "╚█████╔╝██║░╚███║██║░░██║██║░░░██║░░░"
echo -e "░╚════╝░╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░░░░╚═╝"
echo -e "\033[0m"
}

# Function to reset the system by deleting specific files
reset_system() {
print_header "Uninstalling and resetting system..."
# Confirm before proceeding with deletion
echo -e "${COLOR_WARNING}WARNING: This will delete the following files if they exist: bmenu.sh, bt.sh, and hostsTrackers. Do you want to continue? (yes/no): ${COLOR_RESET}"
read confirm
if [[ "$confirm" != "yes" ]]; then
print_error "Aborted deletion process."
return
fi

# List of paths to check and delete the files
paths_to_check=( "/home/ubuntu" "/root" "/opt/hiddify-manager" )

# Iterate through each directory path
for dir in "${paths_to_check[@]}"; do
# Check and delete bmenu.sh if it exists
if [ -f "$dir/bmenu.sh" ]; then
echo "Deleting bmenu.sh in $dir..."
rm -f "$dir/bmenu.sh"
else
print_error "bmenu.sh not found in $dir, skipping."
fi

# Check and delete bt.sh if it exists
if [ -f "$dir/bt.sh" ]; then
echo "Deleting bt.sh in $dir..."
rm -f "$dir/bt.sh"
else
print_error "bt.sh not found in $dir, skipping."
fi

# Check and delete hostsTrackers if it exists
if [ -f "$dir/hostsTrackers" ]; then
echo "Deleting hostsTrackers in $dir..."
rm -f "$dir/hostsTrackers"
else
print_error "hostsTrackers not found in $dir, skipping."
fi
done

print_success "Specific files deletion process completed."
}

# Function to add multiple hosts
add_multiple_hosts() {
while true; do
echo -e "${COLOR_INPUT}Enter a domain or IP to block (or type 'done' to finish): ${COLOR_RESET}"
read host_to_block

if [ "$host_to_block" == "done" ]; then
print_success "Finished adding hosts."
break
fi

if [ -z "$host_to_block" ]; then
print_error "No host provided. Skipping."
continue
fi

# Check if it's a domain or an IP
if [[ "$host_to_block" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ || "$host_to_block" =~ ^[0-9a-fA-F:]+$ ]]; then
# It's an IP, proceed directly
ips="$host_to_block"
else
# Resolve the domain to IP(s)
ips=$(getent ahosts "$host_to_block" | awk '{print $1}' | sort -u)
fi

# If no IPs are resolved, skip this domain
if [ -z "$ips" ]; then
print_error "Failed to resolve $host_to_block to IP addresses."
continue
fi

# Add the IPs to the blocklist file
echo "$host_to_block" >> "$TRACKERS_FILE"

# Add the IPs to iptables
for ip in $ips; do
sudo iptables -A INPUT -d "$ip" -j DROP
sudo iptables -A FORWARD -d "$ip" -j DROP
sudo iptables -A OUTPUT -d "$ip" -j DROP
done

print_success "$host_to_block added to blocklist."
done
}

# Function to remove multiple hosts
remove_multiple_hosts() {
while true; do
echo -e "${COLOR_INPUT}Enter a domain or IP to remove from blocklist (or type 'done' to finish): ${COLOR_RESET}"
read host_to_remove

if [ "$host_to_remove" == "done" ]; then
print_success "Finished removing hosts."
break
fi

if [ -z "$host_to_remove" ]; then
print_error "No host provided. Skipping."
continue
fi

# Remove the host from the blocklist file
sed -i "/$host_to_remove/d" "$TRACKERS_FILE"

# Resolve the domain to IP(s)
ips=$(getent ahosts "$host_to_remove" | awk '{print $1}' | sort -u)

# Remove iptables rules
for ip in $ips; do
sudo iptables -D INPUT -d "$ip" -j DROP
sudo iptables -D FORWARD -d "$ip" -j DROP
sudo iptables -D OUTPUT -d "$ip" -j DROP
done

print_success "$host_to_remove removed from blocklist."
done
}

# Function to check if a specific host (domain or IP) is blocked
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
echo -e "${COLOR_MENU}1. Add a new host to block${COLOR_RESET}"
echo -e "${COLOR_MENU}2. Remove a host from the blocklist${COLOR_RESET}"
echo -e "${COLOR_MENU}3. Add multiple hosts to block${COLOR_RESET}"
echo -e "${COLOR_MENU}4. Remove multiple hosts from blocklist${COLOR_RESET}"
echo -e "${COLOR_MENU}5. View current blocked hosts${COLOR_RESET}"
echo -e "${COLOR_MENU}6. Clean up hosts file list and remove unnecessary files${COLOR_RESET}"
echo -e "${COLOR_MENU}7. Install or Update${COLOR_RESET}"
echo -e "${COLOR_MENU}8. Uninstall all and reset system${COLOR_RESET}"
echo -e "${COLOR_MENU}9. Check if a specific host (domain/IP) is blocked${COLOR_RESET}"
echo -e "${COLOR_MENU}10. Exit${COLOR_RESET}"
echo -e "${COLOR_MENU}--------------------------------------------${COLOR_RESET}"
echo -n -e "${COLOR_INPUT}Select an option [1-10]: ${COLOR_RESET}"
read option

case $option in
1) add_single_host; break ;;
2) remove_single_host; break ;;
3) add_multiple_hosts; break ;;
4) remove_multiple_hosts; break ;;
5)
print_header "Blocked Hosts"
echo "--------------------------------"
cat "$TRACKERS_FILE"
echo "--------------------------------"
echo -e "${COLOR_INPUT}Press any key to continue...${COLOR_RESET}"
read -n 1
break ;;
6)
print_header "Running cleanup script..."
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/cleanup_hosts.sh)"
print_success "Cleanup completed."
break ;;
7)
print_header "Installing or updating bmenu.sh script..."
if [ -f "$BMENU_PATH" ]; then
print_success "$BMENU_PATH already exists."
else
sudo wget -O "$BMENU_PATH" https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bmenu.sh
sudo chmod +x "$BMENU_PATH"
print_success "bmenu.sh script installed/updated at $BMENU_PATH."
fi
break ;;
8) reset_system; break ;;
9) check_specific_host_status; break ;;
10) print_success "Exiting. Goodbye!"; exit 0 ;;
*)
print_error "Invalid option, please choose a valid option."
;;
esac
done
