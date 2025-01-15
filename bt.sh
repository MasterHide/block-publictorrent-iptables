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

# Define paths for multi-location installation
INSTALL_PATHS=(
    "/home/ubuntu"
    "/root"
    "/opt/hiddify-manager"
)

# Ensure all directories exist
for path in "${INSTALL_PATHS[@]}"; do
    mkdir -p "$path"
    print_success "Ensured directory exists: $path"
done

# Function to download a file to all paths
download_file_to_all_paths() {
    local url=$1
    local filename=$(basename "$url")

    for path in "${INSTALL_PATHS[@]}"; do
        local output_path="$path/$filename"
        wget -q -O "$output_path" "$url"
        if [ $? -eq 0 ]; then
            print_success "Downloaded $filename to $output_path."
            chmod +x "$output_path"
        else
            print_error "Failed to download $filename to $output_path."
        fi
    done
}

# Download essential files to all paths
download_file_to_all_paths "https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bmenu.sh"
download_file_to_all_paths "https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/hostsTrackers"
download_file_to_all_paths "https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bt.sh"

# Update /etc/hosts with hostsTrackers
for path in "${INSTALL_PATHS[@]}"; do
    if [ -f "$path/hostsTrackers" ]; then
        cat "$path/hostsTrackers" | sort -uf >> /etc/hosts
        print_success "Updated /etc/hosts with $path/hostsTrackers."
        rm -f "$path/hostsTrackers"
    fi
done

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

print_success "Blocking public trackers setup completed successfully."

# Automatically run bmenu.sh from any valid path
for path in "${INSTALL_PATHS[@]}"; do
    local bmenu_path="$path/bmenu.sh"
    if [ -f "$bmenu_path" ]; then
        print_success "Starting menu interface from $bmenu_path..."
        "$bmenu_path"
        exit 0
    fi
done

print_error "Failed to find bmenu.sh in any of the expected paths."
