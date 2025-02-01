#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\033[31mThis script must be run as root. Exiting.\033[0m"
    exit 1
fi

# Define the files to remove
FILES_TO_REMOVE=(
    "/home/ubuntu/bmenu.sh"
    "/root/bmenu.sh"
    "/opt/hiddify-manager/bmenu.sh"
    "/home/ubuntu/bt.sh"
    "/root/bt.sh"
    "/opt/hiddify-manager/bt.sh"
    "/home/ubuntu/ctp.sh"
    "/root/ctp.sh"
    "/opt/hiddify-manager/ctp.sh"
    "/etc/trackers"
    "/etc/hostsTrackers"
)

# Remove each file if it exists
for file in "${FILES_TO_REMOVE[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo -e "\033[32mRemoved: $file\033[0m"
    else
        echo -e "\033[31mFile not found: $file\033[0m"
    fi
done

# Notify user about the completion
echo -e "\033[32mSystem reset completed. All specified files have been removed.\033[0m"

# Optional: Display a popup notification (for desktop environments)
if command -v notify-send &> /dev/null; then
    notify-send "System Reset" "All specified files have been removed successfully!"
fi

exit 0
