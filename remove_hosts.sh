#!/bin/bash

# ===========================================================
# This script will remove all entries from the /etc/hosts file
# except the ones you choose to preserve.
#
# It ensures the script runs with root privileges and creates
# a backup of the original file before making any changes.
# ===========================================================

# Display a friendly welcome message
echo "Welcome to the /etc/hosts cleanup script!"
echo "This script will keep only the entries you specify and remove all others."

# Define the entries you want to keep (add as many entries as needed)
PRESERVE_ENTRIES=(
  "127.0.1.1       exsample-01       exsample-02"
  "127.0.0.1       mysite.local"
  "192.168.1.10    myserver"
)

# Check if we are running as root (necessary for modifying /etc/hosts)
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root (use sudo)."
  exit 1
fi

# Ask if the user wants to preview the current /etc/hosts file
echo "Do you want to view the current contents of /etc/hosts before proceeding? (y/n)"
read -r USER_CHOICE

if [[ "$USER_CHOICE" == "y" || "$USER_CHOICE" == "Y" ]]; then
  echo "Here are the current entries in /etc/hosts:"
  cat /etc/hosts
  echo "========================================="
  echo "You can now review the file before continuing."
  echo "========================================="
fi

# Inform the user that a backup will be created
echo "A backup of /etc/hosts will be created before making any changes."
echo "The following entries will be preserved:"

# Display the entries to be preserved
for entry in "${PRESERVE_ENTRIES[@]}"; do
  echo "$entry"
done

echo "Are you sure you want to continue and remove all other entries? (y/n)"
read -r USER_CONFIRMATION

# If user confirms, proceed with the operation
if [[ "$USER_CONFIRMATION" == "y" || "$USER_CONFIRMATION" == "Y" ]]; then
  echo "Proceeding with cleanup..."

  # Create a backup of the original /etc/hosts file with a timestamp
  BACKUP_FILE="/etc/hosts.bak_$(date +'%Y%m%d%H%M%S')"
  echo "Creating a backup of /etc/hosts as $BACKUP_FILE..."
  if ! cp /etc/hosts "$BACKUP_FILE"; then
    echo "Error: Failed to create backup."
    exit 1
  fi

  # Create a unique temporary file using mktemp
  TEMP_FILE=$(mktemp /tmp/hosts_XXXXXX.tmp)

  # Remove all lines except the ones we want to preserve
  # Loop through each entry in the PRESERVE_ENTRIES array
  for entry in "${PRESERVE_ENTRIES[@]}"; do
    grep -F "$entry" /etc/hosts >> "$TEMP_FILE"
  done

  # Ensure there is content before overwriting /etc/hosts
  if [ -s "$TEMP_FILE" ]; then
    cat "$TEMP_FILE" > /etc/hosts
  else
    echo "Error: No valid entries to write to /etc/hosts. Aborting operation."
    rm "$TEMP_FILE"
    exit 1
  fi

  # Clean up the temporary file
  rm "$TEMP_FILE"

  # Inform the user that the operation is complete
  echo "The specified entries have been kept, and all other entries have been removed from /etc/hosts."
  echo "Backup of the original /etc/hosts file is saved as $BACKUP_FILE."

else
  # If user does not confirm, exit the script
  echo "Operation cancelled. No changes were made."
  exit 0
fi
