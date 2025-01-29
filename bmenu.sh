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

# Function to add a single host to blocklist
add_single_host() {
echo -e "${COLOR_INPUT}Enter domain or IP to block: ${COLOR_RESET}"
read host_or_ip

# Check if the input is empty
if [ -z "$host_or_ip" ]; then
print_error "No domain or IP entered. Returning to the menu."
return
fi

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
print_error "Failed to resolve $host_or_ip to IP addresses."
return
fi

# Block the IPs in iptables
for ip in $ips; do
# Check if the rule already exists in iptables before adding it
if ! iptables -C INPUT -d "$ip" -j DROP &>/dev/null && \
! iptables -C FORWARD -d "$ip" -j DROP &>/dev/null && \
! iptables -C OUTPUT -d "$ip" -j DROP &>/dev/null && \
! iptables -C DOCKER-USER -d "$ip" -j DROP &>/dev/null; then
iptables -A INPUT -d "$ip" -j DROP
iptables -A FORWARD -d "$ip" -j DROP
iptables -A OUTPUT -d "$ip" -j DROP
iptables -I DOCKER-USER -d "$ip" -j DROP
print_success "$ip has been blocked successfully."
else
print_error "$ip is already blocked, skipping."
fi

# Add domain/IP to the tracker files (if not already present)
if ! grep -q "$host_or_ip" "$TRACKERS_FILE" && ! grep -q "$host_or_ip" "$HOSTS_TRACKERS_FILE"; then
echo "$host_or_ip" | tee -a "$TRACKERS_FILE" > /dev/null
echo "$host_or_ip" | tee -a "$HOSTS_TRACKERS_FILE" > /dev/null
print_success "$host_or_ip has been added to the blocklist."
else
print_error "$host_or_ip is already in the blocklist, skipping."
fi
done
}

# Function to add multiple hosts (domains or IPs) to blocklist
add_multiple_hosts() {
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
print_error "Failed to resolve $host_or_ip to IP addresses."
continue
fi

# Block the IPs in iptables
for ip in $ips; do
# Check if the rule already exists in iptables before adding it
if ! sudo iptables -C INPUT -d "$ip" -j DROP &>/dev/null && \
! sudo iptables -C FORWARD -d "$ip" -j DROP &>/dev/null && \
! sudo iptables -C OUTPUT -d "$ip" -j DROP &>/dev/null && \
! sudo iptables -C DOCKER-USER -d "$ip" -j DROP &>/dev/null; then
sudo iptables -A INPUT -d "$ip" -j DROP
sudo iptables -A FORWARD -d "$ip" -j DROP
sudo iptables -A OUTPUT -d "$ip" -j DROP
sudo iptables -I DOCKER-USER -d "$ip" -j DROP
print_success "$ip has been blocked successfully."
else
print_error "$ip is already blocked, skipping."
fi

# Add domain/IP to the tracker files (if not already present)
if ! grep -q "$host_or_ip" "$TRACKERS_FILE" && ! grep -q "$host_or_ip" "$HOSTS_TRACKERS_FILE"; then
echo "$host_or_ip" | sudo tee -a "$TRACKERS_FILE" > /dev/null
echo "$host_or_ip" | sudo tee -a "$HOSTS_TRACKERS_FILE" > /dev/null
print_success "$host_or_ip has been added to the blocklist."
else
print_error "$host_or_ip is already in the blocklist, skipping."
fi
done
done
}

# Function to remove a single host (domain or IP) from the blocklist
remove_single_host() {
echo -e "${COLOR_INPUT}Enter domain or IP to remove from the blocklist: ${COLOR_RESET}"
read host_or_ip

# Check if it's empty
if [ -z "$host_or_ip" ]; then
print_error "No domain or IP provided. Returning to the menu."
return
fi

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
print_error "Failed to resolve $host_or_ip to IP addresses."
return
fi

# Remove the IPs from iptables
for ip in $ips; do
sudo iptables -D INPUT -d "$ip" -j DROP
sudo iptables -D FORWARD -d "$ip" -j DROP
sudo iptables -D OUTPUT -d "$ip" -j DROP
sudo iptables -D DOCKER-USER -d "$ip" -j DROP
print_success "$ip has been unblocked successfully."

# Remove the domain/IP from the tracker files
sudo sed -i "/$host_or_ip/d" "$TRACKERS_FILE"
sudo sed -i "/$host_or_ip/d" "$HOSTS_TRACKERS_FILE"
print_success "$host_or_ip has been removed from the blocklist."
done
}

# Function to remove multiple hosts (domains or IPs) from blocklist
remove_multiple_hosts() {
echo -e "${COLOR_INPUT}Enter domains or IPs to remove from the blocklist (press Enter without input to stop):${COLOR_RESET}"

while true; do
# Prompt for user input
echo -n -e "${COLOR_INPUT}Enter domain or IP to remove: ${COLOR_RESET}"
read host_or_ip

# Exit the loop if the user presses Enter without typing anything
if [ -z "$host_or_ip" ]; then
print_success "No more domains or IPs to remove. Returning to the menu."
break
fi

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
print_error "Failed to resolve $host_or_ip to IP addresses."
continue
fi

# Remove the IPs from iptables
for ip in $ips; do
sudo iptables -D INPUT -d "$ip" -j DROP
sudo iptables -D FORWARD -d "$ip" -j DROP
sudo iptables -D OUTPUT -d "$ip" -j DROP
sudo iptables -D DOCKER-USER -d "$ip" -j DROP
print_success "$ip has been unblocked successfully."

# Remove the domain/IP from the tracker files
sudo sed -i "/$host_or_ip/d" "$TRACKERS_FILE"
sudo sed -i "/$host_or_ip/d" "$HOSTS_TRACKERS_FILE"
print_success "$host_or_ip has been removed from the blocklist."
done
done
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
echo -e "${COLOR_MENU}1. Add a new host to block${COLOR_RESET}"
echo -e "${COLOR_MENU}2. Remove a host from the blocklist${COLOR_RESET}"
echo -e "${COLOR_MENU}3. View current blocked hosts${COLOR_RESET}"
echo -e "${COLOR_MENU}4. Clean up hosts file list and remove unnecessary files${COLOR_RESET}"
echo -e "${COLOR_MENU}5. Install or Update${COLOR_RESET}"
echo -e "${COLOR_MENU}6. Uninstall all and reset system${COLOR_RESET}"
echo -e "${COLOR_MENU}7. Check if a specific host (domain/IP) is blocked${COLOR_RESET}"
echo -e "${COLOR_MENU}8. Exit${COLOR_RESET}"
echo -e "${COLOR_MENU}--------------------------------------------${COLOR_RESET}"
echo -n -e "${COLOR_INPUT}Select an option [1-8]: ${COLOR_RESET}"
read option

case $option in
1)
# Submenu for option 1
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
2)
# Function to remove entries from /etc/hosts
remove_from_hosts() {
local host=$1
if grep -q "$host" /etc/hosts; then
sed -i "/$host/d" /etc/hosts
echo "Removed $host from /etc/hosts."
else
echo "$host not found in /etc/hosts."
fi
}

# Function to remove IP blocks from iptables
unblock_ip() {
local ip=$1
if iptables -L INPUT -n | grep -q "$ip"; then
iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
iptables -D FORWARD -s "$ip" -j DROP 2>/dev/null
iptables -D OUTPUT -d "$ip" -j DROP 2>/dev/null
echo "Unblocked IP: $ip from iptables."
else
echo "IP $ip is not blocked in iptables."
fi
}

# Submenu for option 2 (remove hosts)
while true; do
clear
print_header "Manage Blocked Hosts & IPs"
echo -e "${COLOR_MENU}--------------------------------------------${COLOR_RESET}"
echo -e "${COLOR_MENU}1. Remove a single host${COLOR_RESET}"
echo -e "${COLOR_MENU}2. Remove multiple hosts${COLOR_RESET}"
echo -e "${COLOR_MENU}3. Unblock Host & IP In default /etc/hosts${COLOR_RESET}" # New Option
echo -e "${COLOR_MENU}4. Go back to main menu${COLOR_RESET}"
echo -e "${COLOR_MENU}--------------------------------------------${COLOR_RESET}"
echo -n -e "${COLOR_INPUT}Select an option [1-4]: ${COLOR_RESET}"
read submenu_option

case $submenu_option in
1) remove_single_host; break ;;
2) remove_multiple_hosts; break ;;
3)
# Unblock Host & IP
print_header "Unblock Host & IP"
echo "--------------------------------"
echo "Enter the hostnames or IP addresses to unblock (separate multiple values with spaces):"
read -r input_hosts

# Process each input value (can be a hostname or IP)
for item in $input_hosts; do
# Remove from /etc/hosts
remove_from_hosts "$item"

# Check if input is an IP address
if [[ "$item" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
unblock_ip "$item"
fi
done

# Flush DNS cache to apply changes
echo "Flushing DNS cache..."
systemctl restart systemd-resolved || systemctl restart networking || systemd-resolve --flush-caches

echo "--------------------------------"
echo "Unblocking process completed."
echo -e "${COLOR_INPUT}Press any key to continue...${COLOR_RESET}"
read -n 1
;;
4) break ;;
*) print_error "Invalid option, please choose a valid option." ;;
esac
done

;;

3)
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
# Check if a specific host (domain/IP) is blocked
check_specific_host_status
echo -e "${COLOR_INPUT}Press any key to continue...${COLOR_RESET}"
read -n 1
;;
8)
print_success "Exiting. Goodbye!"
exit 0
;;
*)
print_error "Invalid option, please choose a valid option."
;;
esac
done
