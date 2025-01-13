#!/bin/bash

# ===========================================================
# This script will remove all entries from the /etc/hosts file
# except the ones you choose to preserve.
#
# It ensures the script runs with root privileges and creates
# a backup of the original file before making any changes.
# ===========================================================

# Function to print headers
function print_header() {
  echo -e "\033[1;34m$1\033[0m"
}

# Function to print messages in green
function print_success() {
  echo -e "\033[1;32m$1\033[0m"
}

# Function to print messages in red
function print_error() {
  echo -e "\033[1;31m$1\033[0m"
}

# Display a friendly welcome message
print_header "Welcome to the /etc/hosts Cleanup Script"
echo "--------------------------------------------------"
echo "This script will allow you to choose which entries you want to preserve in /etc/hosts."
echo "--------------------------------------------------"

# Check if we are running as root (necessary for modifying /etc/hosts)
if [ "$(id -u)" -ne 0 ]; then
  print_error "Error: This script must be run as root (use sudo)."
  exit 1
fi

# Ask if the user wants to preview the current /etc/hosts file
print_header "Step 1: Preview the current /etc/hosts file"
echo "--------------------------------------------------"
echo "Do you want to view the current contents of /etc/hosts before proceeding? (y/n)"
read -r USER_CHOICE

if [[ "$USER_CHOICE" == "y" || "$USER_CHOICE" == "Y" ]]; then
  print_header "Current /etc/hosts File"
  cat /etc/hosts
  echo "--------------------------------------------------"
  echo "You can now review the file before continuing."
  echo "--------------------------------------------------"
fi

# Count the number of lines (hosts) in /etc/hosts
ORIGINAL_COUNT=$(wc -l < /etc/hosts)
print_success "The current /etc/hosts file contains $ORIGINAL_COUNT entries."

# Ask the user for the host entries they want to preserve
print_header "Step 2: Specify Entries to Preserve"
echo "--------------------------------------------------"
echo "Please enter the exact host entries you want to keep (separate multiple entries with spaces or new lines)."
echo "Example: '127.0.1.1 example1 example2'"
echo "When you're done, type 'done' and press Enter."

# Initialize an empty array to store the preserved entries
PRESERVE_ENTRIES=()

# Read user input for entries they want to keep
while true; do
  read -r USER_ENTRY
  if [[ "$USER_ENTRY" == "done" ]]; then
    break
  fi
  # Trim spaces and add to the list
  PRESERVE_ENTRIES+=("$(echo "$USER_ENTRY" | xargs)")
done

# Ensure that the array is not empty before proceeding
if [ ${#PRESERVE_ENTRIES[@]} -eq 0 ]; then
  print_error "Error: No entries to preserve were entered. Aborting operation."
  exit 1
fi

# Inform the user that a backup will be created
print_header "Step 3: Backup and Proceed"
echo "--------------------------------------------------"
echo "A backup of /etc/hosts will be created before making any changes."
echo "The following entries will be preserved:"

# Display the entries to be preserved
for entry in "${PRESERVE_ENTRIES[@]}"; do
  echo "$entry"
done

# Confirm whether the user wants to continue
echo "--------------------------------------------------"
echo "Are you sure you want to continue and remove all other entries? (y/n)"
read -r USER_CONFIRMATION

# If user confirms, proceed with the operation
if [[ "$USER_CONFIRMATION" == "y" || "$USER_CONFIRMATION" == "Y" ]]; then
  print_success "Proceeding with cleanup..."

  # Create a backup of the original /etc/hosts file with a timestamp
  BACKUP_FILE="/etc/hosts.bak_$(date +'%Y%m%d%H%M%S')"
  print_success "Creating a backup of /etc/hosts as $BACKUP_FILE..."
  if ! cp /etc/hosts "$BACKUP_FILE"; then
    print_error "Error: Failed to create backup."
    exit 1
  fi

  # Clean up the /etc/hosts file by removing leading/trailing whitespace
  # and ensure uniform formatting
  CLEANED_HOSTS=$(cat /etc/hosts | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sort -u)

  # Create a unique temporary file using mktemp
  TEMP_FILE=$(mktemp /tmp/hosts_XXXXXX.tmp)

  # Loop through each entry in the PRESERVE_ENTRIES array and check if it's in the cleaned /etc/hosts file
  for entry in "${PRESERVE_ENTRIES[@]}"; do
    # Check if the preserved entry exists in the cleaned /etc/hosts
    if echo "$CLEANED_HOSTS" | grep -qF "$entry"; then
      echo "$entry" >> "$TEMP_FILE"
    fi
  done

  # Ensure there is content before overwriting /etc/hosts
  if [ -s "$TEMP_FILE" ]; then
    cat "$TEMP_FILE" > /etc/hosts
  else
    print_error "Error: No valid entries to write to /etc/hosts. Aborting operation."
    rm "$TEMP_FILE"
    exit 1
  fi

  # Clean up the temporary file
  rm "$TEMP_FILE"

  # Count the number of lines after modification
  FINAL_COUNT=$(wc -l < /etc/hosts)
  print_success "The /etc/hosts file now contains $FINAL_COUNT entries."

  # Check if the count of entries has changed
  if [ "$FINAL_COUNT" -eq "$ORIGINAL_COUNT" ]; then
    print_success "No entries were removed. The file has the same number of entries as before."
  else
    print_success "The file has been updated. Entries were removed and/or added."
  fi

  # Inform the user that the operation is complete
  print_success "The specified entries have been kept, and all other entries have been removed from /etc/hosts."
  print_success "Backup of the original /etc/hosts file is saved as $BACKUP_FILE."

else
  # If user does not confirm, exit the script
  print_error "Operation cancelled. No changes were made."
  exit 0
fi
