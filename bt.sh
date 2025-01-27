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

print_success() { echo -e "${GREEN}$1${NC}"; }
print_error() { echo -e "${RED}$1${NC}"; exit 1; }
print_warning() { echo -e "${YELLOW}$1${NC}"; }

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root. Exiting."
fi

# Check for required commands
for cmd in wget iptables sort; do
    if ! command -v $cmd &>/dev/null; then
        print_error "Required command '$cmd' is not installed. Exiting."
    fi
done

# Define paths for multi-location installation
INSTALL_PATHS=(
    "/home/ubuntu"
    "/root"
    "/opt/hiddify-manager"
)

# Ensure all directories exist and are writable
for path in "${INSTALL_PATHS[@]}"; do
    mkdir -p "$path" || print_error "Failed to create directory: $path"
    if [ ! -w "$path" ]; then
        print_error "No write permission for $path. Exiting."
    fi
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
ESSENTIAL_FILES=(
    "https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bmenu.sh"
    "https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/hostsTrackers"
    "https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/bt.sh"
)
for file in "${ESSENTIAL_FILES[@]}"; do
    download_file_to_all_paths "$file"
done

# Update /etc/hosts with hostsTrackers
for path in "${INSTALL_PATHS[@]}"; do
    if [ -f "$path/hostsTrackers" ]; then
        cat "$path/hostsTrackers" | sort -uf >> /etc/hosts || print_error "Failed to update /etc/hosts with $path/hostsTrackers."
        print_success "Updated /etc/hosts with $path/hostsTrackers."
        rm -f "$path/hostsTrackers"
    fi
done

# Create cron job for blocking public trackers
CRON_FILE="/etc/cron.daily/denypublic"
cat >"$CRON_FILE"<<'EOF'
#!/bin/bash
IFS=$'\n'
IPTABLES_CMD=$(which iptables)
if [ ! -f /etc/trackers ]; then
    echo "No /etc/trackers file found. Exiting."
    exit 1
fi
L=$(sort /etc/trackers | uniq)
for fn in $L; do
    $IPTABLES_CMD -D INPUT -d $fn -j DROP
    $IPTABLES_CMD -D FORWARD -d $fn -j DROP
    $IPTABLES_CMD -D OUTPUT -d $fn -j DROP
    $IPTABLES_CMD -A INPUT -d $fn -j DROP
    $IPTABLES_CMD -A FORWARD -d $fn -j DROP
    $IPTABLES_CMD -A OUTPUT -d $fn -j DROP
done
EOF
chmod +x "$CRON_FILE" || print_error "Failed to make $CRON_FILE executable."
print_success "Blocking public trackers setup completed successfully."

# Install bmenu globally
for path in "${INSTALL_PATHS[@]}"; do
    if [ -f "$path/bmenu.sh" ]; then
        cp "$path/bmenu.sh" /usr/local/bin/bmenu || print_error "Failed to install bmenu globally."
        chmod +x /usr/local/bin/bmenu || print_error "Failed to set executable permission for bmenu."
        chown root:root /usr/local/bin/bmenu
        print_success "bmenu command is now available globally to all users."
        exit 0
    fi
done

# If no bmenu.sh was found in the defined paths
print_error "bmenu.sh not found in any of the defined installation paths."
