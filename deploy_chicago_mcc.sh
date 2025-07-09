#!/bin/bash

# ==============================================================================
# Microsoft Connected Cache (MCC) Automated Deployment Script
#
# Description:
# This script automates the setup and provisioning of a Microsoft Connected
# Cache node on an Ubuntu server. It performs the following steps:
#   1. Updates the system's package lists and upgrades existing packages.
#   2. Downloads the official MCC installation script from Microsoft.
#   3. Verifies the downloaded file appears to be a valid script.
#   4. Makes the installation script executable.
#   5. Runs the provisioning script with the specified customer and node details.
#
# Instructions:
#   1. Save the script to a file (e.g., `deploy_chicago_mcc.sh`).
#   2. Make the script executable: chmod +x deploy_chicago_mcc.sh
#   3. Run the script with sudo: sudo ./deploy_chicago_mcc.sh
#
# Troubleshooting:
# If you get a "No such file or directory" error when running the script with
# sudo, it might be due to Windows-style line endings. You can fix this by
# running the following command on the script file before executing it:
#   sed -i 's/\r$//' deploy_chicago_mcc.sh
#
# ==============================================================================

# --- Script Configuration ---
# Exit immediately if a command exits with a non-zero status.
set -e

# --- User Configuration - 1st Chicago Node ---
# These values are pre-filled with the details you provided.

CUSTOMER_ID="6477d052-c32e-42fc-8c0a-b25b46fa5a79"
CACHE_NODE_ID="71284511-b5ba-48a2-82af-a57d5dc35d9f"
CUSTOMER_KEY="a329105f-1c09-46ce-9f6b-c5a9dedfa207"
REGISTRATION_KEY="ff4027f8-48dd-41d3-b3eb-6147592c12a4"

# Specify the full path for the cache drive and its size in GB.
# Format: "/path/to/drive,size_in_gb"
DRIVE_PATH_AND_SIZE="/cachenode/node1,450"

# --- Script Variables ---
INSTALLER_URL="https://aka.ms/MCC-Ent-InstallScript-Linux"
INSTALLER_FILENAME="provisionmcc.sh"

# --- Main Execution ---

echo "================================================="
echo "Starting Microsoft Connected Cache Deployment"
echo "Target Node: 1st Chicago Node"
echo "================================================="

# Step 1: Update the System
# -------------------------
echo "[Step 1/5] Updating system packages. This may take a few minutes..."
sudo apt-get update && sudo apt-get upgrade -y
echo "System update complete."
echo "-------------------------------------------------"

# Step 2: Download the MCC Installer
# ----------------------------------
echo "[Step 2/5] Downloading the MCC installation script..."
# Use wget with -L to follow redirects.
if wget -L "$INSTALLER_URL" -O "$INSTALLER_FILENAME"; then
    echo "Installer downloaded successfully as '$INSTALLER_FILENAME'."
else
    echo "ERROR: Failed to download the installer from $INSTALLER_URL."
    exit 1
fi
echo "-------------------------------------------------"

# Step 3: Verify the Downloaded Script
# ------------------------------------
echo "[Step 3/5] Verifying the downloaded file..."
echo "The first 5 lines of '$INSTALLER_FILENAME' are:"
echo "--------------------"
head -n 5 "$INSTALLER_FILENAME"
echo "--------------------"
echo "The file should start with '#!/bin/bash'."
echo "If it looks like HTML or an error message, please stop the script (Ctrl+C)."
read -p "Press Enter to continue if the file looks correct..."
echo "Verification passed."
echo "-------------------------------------------------"


# Step 4: Make the Installer Executable
# -------------------------------------
echo "[Step 4/5] Setting execute permissions on the installer..."
chmod +x "$INSTALLER_FILENAME"
echo "Permissions set successfully."
echo "-------------------------------------------------"

# Step 5: Run the Provisioning Script
# -----------------------------------
echo "[Step 5/5] Running the MCC provisioning script..."
echo "Using the following configuration:"
echo "  - Customer ID:      $CUSTOMER_ID"
echo "  - Cache Node ID:    $CACHE_NODE_ID"
echo "  - Drive & Size:     $DRIVE_PATH_AND_SIZE"
echo ""

# Execute the script with the configured parameters.
# Note: The customerkey and registrationkey are intentionally not echoed to the console.
sudo ./"$INSTALLER_FILENAME" \
    customerid="$CUSTOMER_ID" \
    cachenodeid="$CACHE_NODE_ID" \
    customerkey="$CUSTOMER_KEY" \
    registrationkey="$REGISTRATION_KEY" \
    drivepathandsizeingb="$DRIVE_PATH_AND_SIZE"

echo "================================================="
echo "MCC provisioning script execution finished."
echo "Please check the output above for any errors or success messages."
echo "Deployment complete."
echo "================================================="

exit 0
