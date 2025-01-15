#!/bin/bash
#
# 2025 Updated !!
# GitHub:   https://github.com/MasterHide/block-publictorrent-iptables
# Author:   MasterHide

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

# Function to print success message
print_success() {
    echo -e "${GREEN}$1${NC}"
}

# Function to print error message
print_error() {
    echo -e "${RED}$1${NC}"
}

# Function to print warning message
print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root. Exiting."
    exit 1
fi

# Function to download a file and handle errors
download_file() {
    local url=$1
    local output_path=$2
    local retries=3

    for ((i=1; i<=retries; i++)); do
        echo -n "Downloading ${url}..."
        wget -q -O "$output_path" "$url"
        if [ $? -eq 0 ]; then
            print_success "Downloaded successfully to ${output_path}."
            return 0
        else
            print_warning "Failed to download. Retrying ($i/$retries)..."
        fi
    done
    print_error "Failed to download after $retries attempts."
    return 1
}

echo -n "Blocking public trackers ... "

# Download trackers file
download_file "https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/trackers" "/etc/trackers" || exit 1

# Create cron job for blocking public trackers
cat >/etc/cron.daily/denypublic<<'EOF'
IFS=$'\n'
IPTABLES_CMD=$(which iptables)
L=$(/usr/bin/sort /etc/trackers | /usr/bin/uniq)
for fn in $L; do
        $IPTABLES_CMD -D INPUT -d $fn -j DROP
        $IPTABLES_CMD -D FORWARD -d $fn -j DROP
        $IPTABLES_CMD -D OUTPUT -d $fn -j DROP
        $IPTABLES_CMD -A INPUT -d $fn -j DROP
        $IPTABLES_CMD -A FORWARD -d $fn -j DROP
        $IPTABLES_CMD -A OUTPUT -d $fn -j DROP
done
EOF
chmod +x /etc/cron.daily/denypublic

# Download hostsTrackers file and update /etc/hosts
download_file "https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/hostsTrackers" "hostsTrackers" || exit 1

cat hostsTrackers | sort -uf >> /etc/hosts
rm -f hostsTrackers

print_success "Blocking public trackers completed successfully."

# Function to install or update the bt.sh script
install_bt_script() {
    print_warning "Installing or updating bt.sh script..."

    # Ensure no backup files of bt.sh are left (bt.sh.1, bt.sh.2, etc.)
    rm -f /root/bt.sh*
    print_success "Removed old bt.sh and backup files."

    # Download and install the new bt.sh script
    download_file "https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bt.sh" "/root/bt.sh" || exit 1

    chmod +x /root/bt.sh
    print_success "bt.sh script installed/updated successfully."
}

# Automatically download and execute bmenu.sh
download_and_run_bmenu() {
    print_warning "Downloading bmenu.sh..."

    # Set download paths and URLs
    local download_path_ubuntu="/home/ubuntu/bmenu.sh"
    local download_path_root="/root/bmenu.sh"
    local download_path_hiddify="/opt/hiddify-manager/bmenu.sh"
    local url="https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bmenu.sh"

    # Try downloading bmenu.sh to /home/ubuntu/, /root/, and /opt/hiddify-manager/
    if ! download_file "$url" "$download_path_ubuntu"; then
        print_warning "Failed to download to /home/ubuntu, trying /root/..."
        if ! download_file "$url" "$download_path_root"; then
            print_warning "Failed to download to /root, trying /opt/hiddify-manager/..."
            if ! download_file "$url" "$download_path_hiddify"; then
                print_error "Failed to download bmenu.sh to all locations. Exiting."
                exit 1
            fi
        fi
    fi

    # Make bmenu.sh executable
    chmod +x "$download_path_ubuntu" || chmod +x "$download_path_root" || chmod +x "$download_path_hiddify"

    # Run bmenu.sh (start the menu interface)
    print_success "Starting menu interface..."
    if [ -f "$download_path_ubuntu" ]; then
        $download_path_ubuntu
    elif [ -f "$download_path_root" ]; then
        $download_path_root
    else
        $download_path_hiddify
    fi
}

# Run the function to download and start the menu interface
download_and_run_bmenu
