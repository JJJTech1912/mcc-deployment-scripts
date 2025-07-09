#!/bin/bash

# ==============================================================================
# Microsoft Connected Cache (MCC) Automated Deployment Script (v6)
#
# Description:
# This script automates the setup and provisioning of a Microsoft Connected
# Cache node on an Ubuntu server. It performs the following steps:
#   1. Updates the system's package lists and upgrades existing packages.
#   2. Installs the 'unzip' utility if it is not already present.
#   3. Downloads the official MCC installation ZIP archive from Microsoft.
#   4. Extracts the contents of the ZIP archive.
#   5. Creates the necessary logging directory for the MCC script.
#   6. Changes into the script directory and runs the provisioning script.
#
# ==============================================================================

# --- Script Configuration ---
# Exit immediately if a command exits with a non-zero status.
set -e

# --- User Configuration - 1st Chicago Node ---
CUSTOMER_ID="6477d052-c32e-42fc-8c0a-b25b46fa5a79"
CACHE_NODE_ID="71284511-b5ba-48a2-82af-a57d5dc35d9f"
CUSTOMER_KEY="a329105f-1c09-46ce-9f6b-c5a9dedfa207"
REGISTRATION_KEY="ff4027f8-48dd-41d3-b3eb-6147592c12a4"
DRIVE_PATH_AND_SIZE="/cachenode/node1,450"

# --- Script Variables ---
INSTALLER_URL="https://aka.ms/MCC-Ent-InstallScript-Linux"
ZIP_FILENAME="mccscripts.zip"
# The script is expected to be inside this subdirectory within the zip
SCRIPT_DIR="MccScripts"
INSTALLER_FILENAME="provisionmcc.sh"
INSTALLER_PATH="${SCRIPT_DIR}/${INSTALLER_FILENAME}"
LOG_DIR="/etc/mccresourcecreation"

# --- Main Execution ---

echo "================================================="
echo "Starting Microsoft Connected Cache Deployment"
echo "Target Node: 1st Chicago Node"
echo "================================================="

# Step 1: Update the System
# -------------------------
echo "[Step 1/6] Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y
echo "System update complete."
echo "-------------------------------------------------"

# Step 2: Ensure 'unzip' is installed
# -----------------------------------
echo "[Step 2/6] Checking for 'unzip' utility..."
if ! command -v unzip &> /dev/null
then
    echo "'unzip' could not be found. Installing..."
    sudo apt-get install unzip -y
    echo "'unzip' installed successfully."
else
    echo "'unzip' is already installed."
fi
echo "-------------------------------------------------"

# Step 3: Download the MCC Installer ZIP
# --------------------------------------
echo "[Step 3/6] Downloading the MCC installation archive..."
if wget -L "$INSTALLER_URL" -O "$ZIP_FILENAME"; then
    echo "Archive downloaded successfully as '$ZIP_FILENAME'."
else
    echo "ERROR: Failed to download the archive from $INSTALLER_URL."
    exit 1
fi
echo "-------------------------------------------------"

# Step 4: Extract the Provisioning Script
# ---------------------------------------
echo "[Step 4/6] Extracting all files from the archive..."
# -o flag overwrites existing files without prompting.
unzip -o "$ZIP_FILENAME" || true

if [ -f "$INSTALLER_PATH" ]; then
    echo "Successfully found '$INSTALLER_PATH'."
    rm "$ZIP_FILENAME"
else
    echo "ERROR: Failed to find '$INSTALLER_PATH' after extracting the archive."
    ls -R
    exit 1
fi
echo "-------------------------------------------------"

# Step 5: Create Logging Directory
# --------------------------------
echo "[Step 5/6] Creating MCC logging directory..."
sudo mkdir -p "$LOG_DIR"
echo "Log directory '$LOG_DIR' created."
echo "-------------------------------------------------"

# Step 6: Set Permissions and Run the Provisioning Script
# -------------------------------------------------------
echo "[Step 6/6] Setting permissions and running the MCC provisioning script..."
# Change into the script's directory before executing
cd "$SCRIPT_DIR"

chmod +x "$INSTALLER_FILENAME"
echo "Execute permissions set on '$INSTALLER_FILENAME'."

echo "Running the provisioning script from within '$SCRIPT_DIR'..."
echo "Using the following configuration:"
echo "  - Customer ID:      $CUSTOMER_ID"
echo "  - Cache Node ID:    $CACHE_NODE_ID"
echo "  - Drive & Size:     $DRIVE_PATH_AND_SIZE"
echo ""

# Execute the script with the configured parameters.
sudo ./"$INSTALLER_FILENAME" \
    customerid="$CUSTOMER_ID" \
    cachenodeid="$CACHE_NODE_ID" \
    customerkey="$CUSTOMER_KEY" \
    registrationkey="$REGISTRATION_KEY" \
    drivepathandsizeingb="$DRIVE_PATH_AND_SIZE"

# Return to the original directory
cd ..

echo "================================================="
echo "MCC provisioning script execution finished."
echo "Please check the output above for any errors or success messages."
echo "Deployment complete."
echo "================================================="

exit 0
