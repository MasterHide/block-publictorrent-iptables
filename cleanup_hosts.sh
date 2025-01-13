#!/bin/bash

# ===========================================================
# Simple script to clean up /etc/hosts file by preserving user-specified entries.
# ===========================================================

# Function to print headers
function print_header() {
  echo -e "\033[1;34m$1\033[0m"
}

# Function to print success messages in green
function print_success() {
  echo -e "\033[1;32m$1\033[0m"
}

# Function to print error messages in red
function print_error() {
  echo -e "\033[1;31m$1\033[0m"
}

# Function to print a banner
function print_banner() {
  echo -e "\033[1;35m"
  echo "########################################################"
  echo "#                                                      #"
  echo "#                    HELLO!                           #"
  echo "#   Welcome to the /etc/hosts Cleanup Script!           #"
  echo "#                                                      #"
  echo "########################################################"
  echo -e "\033[0m"
}

# Print banner
print_banner

# Check if we are running as root (necessary for modifying /etc/hosts)
if [ "$(id -u)" -ne 0 ]; then
  print_error "Error: This script must be run as root (use sudo)."
  exit 1
fi

# Show the current /etc/hosts content
print_header "Current /etc/hosts content:"
echo "--------------------------------------------------"
cat /etc/hosts
echo "--------------------------------------------------"

# Ask the user which entries to preserve
print_header "Step 1: Specify Entries to Preserve"
echo "--------------------------------------------------"
echo "Please enter the host entries you want to keep (e.g., '127.0.0.1 localhost')."
echo "Type 'done' when you are finished."
echo "--------------------------------------------------"

PRESERVE_ENTRIES=()

while true; do
  read -r USER_ENTRY
  if [[ "$USER_ENTRY" == "done" ]]; then
    break
  fi
  # Add the entry to the preserve list
  PRESERVE_ENTRIES+=("$(echo "$USER_ENTRY" | xargs)")
done

# Check if the list of entries to preserve is empty
if [ ${#PRESERVE_ENTRIES[@]} -eq 0 ]; then
  print_error "Error: No entries specified to preserve. Aborting operation."
  exit 1
fi

# Ask for confirmation before proceeding
print_header "Step 2: Confirm the Changes"
echo "--------------------------------------------------"
echo "You are about to preserve the following entries:"
for entry in "${PRESERVE_ENTRIES[@]}"; do
  echo -e "\033[1;33m$entry\033[0m"
done
echo "--------------------------------------------------"
echo "Are you sure you want to continue? (y/n)"
read -r USER_CONFIRMATION

if [[ "$USER_CONFIRMATION" != "y" && "$USER_CONFIRMATION" != "Y" ]]; then
  print_error "Operation cancelled. No changes were made."
  exit 0
fi

# Create a backup of the original /etc/hosts file with a timestamp
BACKUP_FILE="/etc/hosts.bak_$(date +'%Y%m%d%H%M%S')"
print_success "Creating a backup of /etc/hosts as $BACKUP_FILE..."
cp /etc/hosts "$BACKUP_FILE"

# Create a temporary file to store the preserved entries
TEMP_FILE=$(mktemp)

# Add the preserved entries to the temporary file
for entry in "${PRESERVE_ENTRIES[@]}"; do
  echo "$entry" >> "$TEMP_FILE"
done

# Replace the /etc/hosts file with the preserved entries
if [ -s "$TEMP_FILE" ]; then
  cp "$TEMP_FILE" /etc/hosts
  print_success "The /etc/hosts file has been updated."
else
  print_error "Error: No valid entries to write to /etc/hosts. Aborting operation."
  rm "$TEMP_FILE"
  exit 1
fi

# Clean up the temporary file
rm "$TEMP_FILE"

# Final message
print_success "Backup saved as $BACKUP_FILE."
print_success "Operation completed."
