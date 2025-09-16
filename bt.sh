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
# Functions for output
print_success() { echo -e "${GREEN}$1${NC}"; }
print_error() { echo -e "${RED}$1${NC}"; exit 1; }
print_warning() { echo -e "${YELLOW}$1${NC}"; }
# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root. Exiting."
fi
# Check for required commands
for cmd in wget iptables sort getent; do
    if ! command -v $cmd &>/dev/null; then
        print_error "Required command '$cmd' is not installed. Exiting."
    fi
done
# Check if ip6tables is available for IPv6 support
IP6TABLES_AVAILABLE=false
if command -v ip6tables &> /dev/null; then
    IP6TABLES_AVAILABLE=true
    print_success "IPv6 support available (ip6tables found)."
else
    print_warning "IPv6 support not available (ip6tables not found). Only IPv4 will be blocked."
fi
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
# Ensure /etc/hostsTrackers exists, create it if not
if [ ! -f "/etc/hostsTrackers" ]; then
    touch /etc/hostsTrackers || print_error "Failed to create /etc/hostsTrackers."
    print_success "Created /etc/hostsTrackers."
fi
# Move hostsTrackers to a persistent location (check if file exists in any of the paths)
if [ -f "/root/hostsTrackers" ]; then
    mv /root/hostsTrackers /etc/trackers || print_error "Failed to move hostsTrackers."
    print_success "Moved hostsTrackers to /etc/trackers for persistent blocking."
fi
# Create a domains-only file for IP resolution
if [ -f "/etc/trackers" ]; then
    # Extract only domain names (second field) and skip empty lines and comments
    grep -v '^#' /etc/trackers | grep -v '^$' | awk '{print $2}' > /etc/domains-only || print_error "Failed to create domains-only file."
    print_success "Created domains-only file for IP resolution."
fi
# Update /etc/hosts with tracker domains (if /etc/trackers exists)
if [ -f "/etc/trackers" ]; then
    # Backup the current hosts file
    cp /etc/hosts /etc/hosts.backup-$(date +%Y%m%d-%H%M%S)
    
    # Remove any existing tracker entries
    sed -i '/# Added by torrent block script/d' /etc/hosts
    
    # Add the new entries from trackers
    while read -r line; do
        # Skip empty lines and comments
        if [ -z "$line" ] || [[ "$line" == \#* ]]; then
            continue
        fi
        
        # Extract domain from line (format: "0.0.0.0 domain.com")
        domain=$(echo "$line" | awk '{print $2}')
        if [ -n "$domain" ]; then
            echo "# Added by torrent block script $line" >> /etc/hosts
        fi
    done < /etc/trackers
    
    print_success "Updated /etc/hosts with tracker domains."
else
    print_error "/etc/trackers does not exist. Exiting."
fi
# Create cron job for blocking public trackers
CRON_FILE="/etc/cron.daily/denypublic"
cat >"$CRON_FILE"<<'EOF'
#!/bin/bash
# Function to resolve domain to IPs
resolve_domain() {
    local domain=$1
    local ipv4s=$(getent ahosts "$domain" 2>/dev/null | grep "STREAM" | awk '{print $1}' | grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$" | sort -u)
    local ipv6s=$(getent ahosts "$domain" 2>/dev/null | grep "STREAM" | awk '{print $1}' | grep -E "^[0-9a-fA-F:]+$" | sort -u)
    echo "$ipv4s $ipv6s"
}

# Function to block an IP
block_ip() {
    local ip=$1
    local is_ipv6=false
    
    # Check if it's an IPv6 address
    if [[ "$ip" =~ ^[0-9a-fA-F:]+$ ]]; then
        is_ipv6=true
    fi
    
    # Remove existing rules first to avoid duplicates
    if [ "$is_ipv6" = true ]; then
        if command -v ip6tables &> /dev/null; then
            ip6tables -D INPUT -d "$ip" -j DROP 2>/dev/null
            ip6tables -D FORWARD -d "$ip" -j DROP 2>/dev/null
            ip6tables -D OUTPUT -d "$ip" -j DROP 2>/dev/null
            # Check if DOCKER-USER chain exists
            if ip6tables -n -L DOCKER-USER >/dev/null 2>&1; then
                ip6tables -D DOCKER-USER -d "$ip" -j DROP 2>/dev/null
            fi
            # Add the new rules
            ip6tables -A INPUT -d "$ip" -j DROP
            ip6tables -A FORWARD -d "$ip" -j DROP
            ip6tables -A OUTPUT -d "$ip" -j DROP
            if ip6tables -n -L DOCKER-USER >/dev/null 2>&1; then
                ip6tables -I DOCKER-USER -d "$ip" -j DROP
            fi
            echo "Blocked IPv6: $ip"
        fi
    else
        # It's an IPv4 address
        iptables -D INPUT -d "$ip" -j DROP 2>/dev/null
        iptables -D FORWARD -d "$ip" -j DROP 2>/dev/null
        iptables -D OUTPUT -d "$ip" -j DROP 2>/dev/null
        # Check if DOCKER-USER chain exists
        if iptables -n -L DOCKER-USER >/dev/null 2>&1; then
            iptables -D DOCKER-USER -d "$ip" -j DROP 2>/dev/null
        fi
        # Add the new rules
        iptables -A INPUT -d "$ip" -j DROP
        iptables -A FORWARD -d "$ip" -j DROP
        iptables -A OUTPUT -d "$ip" -j DROP
        if iptables -n -L DOCKER-USER >/dev/null 2>&1; then
            iptables -I DOCKER-USER -d "$ip" -j DROP
        fi
        echo "Blocked IPv4: $ip"
    fi
}

# Main processing
if [ ! -f /etc/trackers ]; then
    echo "No /etc/trackers file found. Exiting."
    exit 1
fi

# Process each entry in the trackers file
while IFS= read -r line; do
    # Skip empty lines and comments
    if [ -z "$line" ] || [[ "$line" == \#* ]]; then
        continue
    fi
    
    # Extract domain from line (format: "0.0.0.0 domain.com")
    domain=$(echo "$line" | awk '{print $2}')
    
    if [ -z "$domain" ]; then
        continue
    fi
    
    # Check if it's an IPv4 address
    if [[ "$domain" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        block_ip "$domain"
    # Check if it's an IPv6 address
    elif [[ "$domain" =~ ^[0-9a-fA-F:]+$ ]]; then
        block_ip "$domain"
    else
        # It's a domain name, resolve it
        echo "Resolving domain: $domain"
        ips=$(resolve_domain "$domain")
        if [ -z "$ips" ]; then
            echo "Failed to resolve $domain to any IP addresses. Using dnsmasq fallback."
            # Use dnsmasq for domain blocking (if installed)
            if command -v dnsmasq &> /dev/null; then
                echo "address=/$domain/0.0.0.0" >> /etc/dnsmasq.d/blocked_domains.conf
                echo "Added $domain to dnsmasq blocklist."
            fi
            continue
        fi
        
        # Block each resolved IP
        for ip in $ips; do
            block_ip "$ip"
        done
    fi
done < /etc/trackers

# Save iptables rules
iptables-save > /etc/iptables/rules.v4
if command -v ip6tables &> /dev/null; then
    ip6tables-save > /etc/iptables/rules.v6
fi

# Restart dnsmasq if updated
if [ -f /etc/dnsmasq.d/blocked_domains.conf ]; then
    systemctl restart dnsmasq 2>/dev/null || echo "dnsmasq restart failed, but IP blocking should still work."
    echo "DNS-based blocking updated."
fi

echo "Blocking public trackers updated successfully."
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
