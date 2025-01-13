#!/bin/bash

# ===========================================================
# Simple script to clean up /etc/hosts file by preserving user-specified entries.
# ===========================================================

# Check if we are running as root (necessary for modifying /etc/hosts)
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root (use sudo)."
  exit 1
fi

# Show the current /etc/hosts content
echo "Current /etc/hosts content:"
cat /etc/hosts
echo "--------------------------------------------------"

# Ask the user which entries to preserve
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
  echo "Error: No entries specified to preserve. Aborting operation."
  exit 1
fi

# Create a backup of the original /etc/hosts file with a timestamp
BACKUP_FILE="/etc/hosts.bak_$(date +'%Y%m%d%H%M%S')"
echo "Creating a backup of /etc/hosts as $BACKUP_FILE..."
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
  echo "The /etc/hosts file has been updated."
else
  echo "Error: No valid entries to write to /etc/hosts. Aborting operation."
  rm "$TEMP_FILE"
  exit 1
fi

# Clean up the temporary file
rm "$TEMP_FILE"

echo "Backup saved as $BACKUP_FILE."
echo "Operation completed."
