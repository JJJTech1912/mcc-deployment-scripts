#!/bin/bash

# ==============================================================================
# Microsoft Connected Cache (MCC) Automated Deployment Script (v8)
#
# Location: Frankfort, KY
#
# Description:
# This script automates the setup and provisioning of a Microsoft Connected
# Cache node on an Ubuntu server. It performs the following steps:
#   1. Updates the system's package lists and upgrades existing packages.
#   2. Installs/updates CA certificates to prevent SSL errors.
#   3. Installs the 'unzip' utility if it is not already present.
#   4. Downloads the official MCC installation ZIP archive from Microsoft.
#   5. Extracts the contents of the ZIP archive.
#   6. Creates the cache drive directory required by the MCC script.
#   7. Creates the necessary logging directory for the MCC script.
#   8. Changes into the script directory and runs the provisioning script.
#
# ==============================================================================

# --- Script Configuration ---
# Exit immediately if a command exits with a non-zero status.
set -e

# --- User Configuration - Frankfort, KY Node ---
CUSTOMER_ID="6477d052-c32e-42fc-8c0a-b25b46fa5a79"
CACHE_NODE_ID="04216d80-4782-47b1-9082-f5a716e11594"
CUSTOMER_KEY="a329105f-1c09-46ce-9f6b-c5a9dedfa207"
REGISTRATION_KEY="306456d6-da5a-4feb-9059-ea31c26b831d"
DRIVE_PATH_AND_SIZE="/cachenode/node1,450"

# --- Script Variables ---
INSTALLER_URL="https://aka.ms/MCC-Ent-InstallScript-Linux"
ZIP_FILENAME="mccscripts.zip"
SCRIPT_DIR="MccScripts"
INSTALLER_FILENAME="provisionmcc.sh"
INSTALLER_PATH="${SCRIPT_DIR}/${INSTALLER_FILENAME}"
LOG_DIR="/etc/mccresourcecreation"
# Parse the drive path from the combined variable
CACHE_DRIVE_PATH=$(echo "$DRIVE_PATH_AND_SIZE" | cut -d',' -f1)


# --- Main Execution ---

echo "================================================="
echo "Starting Microsoft Connected Cache Deployment"
echo "Target Node: Frankfort, KY"
echo "================================================="

# Step 1: Update the System
# -------------------------
echo "[Step 1/8] Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y
echo "System update complete."
echo "-------------------------------------------------"

# Step 2: Install/Update CA Certificates
# --------------------------------------
echo "[Step 2/8] Ensuring CA certificates are up to date..."
sudo apt-get install -y ca-certificates
sudo update-ca-certificates
echo "CA certificates are up to date."
echo "-------------------------------------------------"

# Step 3: Ensure 'unzip' is installed
# -----------------------------------
echo "[Step 3/8] Checking for 'unzip' utility..."
if ! command -v unzip &> /dev/null
then
    echo "'unzip' could not be found. Installing..."
    sudo apt-get install unzip -y
    echo "'unzip' installed successfully."
else
    echo "'unzip' is already installed."
fi
echo "-------------------------------------------------"

# Step 4: Download the MCC Installer ZIP
# --------------------------------------
echo "[Step 4/8] Downloading the MCC installation archive..."
if wget -L "$INSTALLER_URL" -O "$ZIP_FILENAME"; then
    echo "Archive downloaded successfully as '$ZIP_FILENAME'."
else
    echo "ERROR: Failed to download the archive from $INSTALLER_URL."
    exit 1
fi
echo "-------------------------------------------------"

# Step 5: Extract the Provisioning Script
# ---------------------------------------
echo "[Step 5/8] Extracting all files from the archive..."
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

# Step 6: Create Cache Drive Directory
# ------------------------------------
echo "[Step 6/8] Creating cache drive directory..."
sudo mkdir -p "$CACHE_DRIVE_PATH"
echo "Cache drive directory '$CACHE_DRIVE_PATH' created."
echo "-------------------------------------------------"

# Step 7: Create Logging Directory
# --------------------------------
echo "[Step 7/8] Creating MCC logging directory..."
sudo mkdir -p "$LOG_DIR"
echo "Log directory '$LOG_DIR' created."
echo "-------------------------------------------------"

# Step 8: Set Permissions and Run the Provisioning Script
# -------------------------------------------------------
echo "[Step 8/8] Setting permissions and running the MCC provisioning script..."
cd "$SCRIPT_DIR"

chmod +x "$INSTALLER_FILENAME"
echo "Execute permissions set on '$INSTALLER_FILENAME'."

echo "Running the provisioning script from within '$SCRIPT_DIR'..."
echo "Using the following configuration:"
echo "  - Customer ID:      $CUSTOMER_ID"
echo "  - Cache Node ID:    $CACHE_NODE_ID"
echo "  - Drive & Size:     $DRIVE_PATH_AND_SIZE"
echo ""

sudo ./"$INSTALLER_FILENAME" \
    customerid="$CUSTOMER_ID" \
    cachenodeid="$CACHE_NODE_ID" \
    customerkey="$CUSTOMER_KEY" \
    registrationkey="$REGISTRATION_KEY" \
    drivepathandsizeingb="$DRIVE_PATH_AND_SIZE"

cd ..

echo "================================================="
echo "MCC provisioning script execution finished."
echo "Please check the output above for any errors or success messages."
echo "Deployment complete."
echo "================================================="

exit 0
