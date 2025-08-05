#!/bin/bash

# ==============================================================================
# Microsoft Connected Cache (MCC) GA Re-installation Script v1.1
#
# Location: Chicago, IL (Production)
# Node ID:  1d9a4cf7-a4a8-47fa-ac2d-4abe65f301ee
#
# Description:
# This script automates the complete removal and re-installation of an
# unhealthy MCC node to resolve operational issues.
#
# It performs the following steps:
#   1. Downloads the latest GA deployment scripts from Microsoft.
#   2. Extracts the scripts (including the uninstaller).
#   3. Runs the 'uninstallmcc.sh' script to completely remove the old installation.
#   4. Proceeds with a full, clean re-installation using the validated GA process.
#   5. Sets final permissions and restarts the container.
#
# ==============================================================================

# --- Script Configuration ---
# Exit immediately if a command exits with a non-zero status.
set -e

# --- User Configuration - Production Chicago Node ---
CUSTOMER_ID="6477d052-c32e-42fc-8c0a-b25b46fa5a79"
CACHE_NODE_ID="1d9a4cf7-a4a8-47fa-ac2d-4abe65f301ee"
CUSTOMER_KEY="a329105f-1c09-46ce-9f6b-c5a9dedfa207"
REGISTRATION_KEY="2164d480-73dc-4036-b4df-58af692e10a4"
DRIVE_PATH_AND_SIZE="/cachenode/node1,450"

# --- Script Variables ---
INSTALLER_URL="https://aka.ms/mcc-ent-linux-deploy-scripts"
ZIP_FILENAME="mcc-ent-linux-deploy-scripts.zip"
SCRIPT_DIR="MccScripts"
INSTALLER_FILENAME="deploymcc.sh"
UNINSTALLER_FILENAME="uninstallmcc.sh"
INSTALLER_PATH="${SCRIPT_DIR}/${INSTALLER_FILENAME}"
LOG_DIR="/etc/mccresourcecreation"
CACHE_DRIVE_PATH=$(echo "$DRIVE_PATH_AND_SIZE" | cut -d',' -f1)


# --- Main Execution ---

echo "================================================="
echo "Starting MCC Re-installation for Production Chicago Node"
echo "================================================="

# Step 1: Update System & Download Scripts
# ----------------------------------------
echo "[Step 1/5] Updating system and downloading GA scripts..."
sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" upgrade -y
sudo apt-get install -y ca-certificates unzip
if wget -L "$INSTALLER_URL" -O "$ZIP_FILENAME"; then
    echo "Archive downloaded successfully."
else
    echo "ERROR: Failed to download the archive."
    exit 1
fi
echo "-------------------------------------------------"

# Step 2: Extract Scripts
# -----------------------
echo "[Step 2/5] Extracting scripts..."
unzip -o "$ZIP_FILENAME" || true
if [ -f "${SCRIPT_DIR}/${UNINSTALLER_FILENAME}" ]; then
    echo "Successfully extracted uninstaller and other scripts."
    rm "$ZIP_FILENAME"
else
    echo "ERROR: Failed to find scripts after extracting the archive."
    exit 1
fi
echo "-------------------------------------------------"

# Step 3: Run Uninstaller
# -----------------------
echo "[Step 3/5] Running the MCC uninstaller..."
cd "$SCRIPT_DIR"
chmod +x "$UNINSTALLER_FILENAME"
sudo ./"$UNINSTALLER_FILENAME"
echo "Uninstallation process complete. Waiting 15 seconds before re-installing..."
sleep 15
cd ..
echo "-------------------------------------------------"

# Step 4: Run Clean Re-installation
# ---------------------------------
echo "[Step 4/5] Starting clean re-installation of MCC..."
# Re-create directories that the uninstaller may have removed
sudo mkdir -p "$CACHE_DRIVE_PATH"
sudo mkdir -p "$LOG_DIR"
# Pre-install IoT Edge packages
sudo apt-get install -y --allow-downgrades aziot-edge aziot-identity-service

cd "$SCRIPT_DIR"
chmod +x "$INSTALLER_FILENAME"

sudo ./"$INSTALLER_FILENAME" \
    customerid="$CUSTOMER_ID" \
    cachenodeid="$CACHE_NODE_ID" \
    customerkey="$CUSTOMER_KEY" \
    registrationkey="$REGISTRATION_KEY" \
    drivepathandsizeingb="$DRIVE_PATH_AND_SIZE"

echo "GA installer script finished."
cd ..
echo "-------------------------------------------------"

# Step 5: Finalize Installation
# -----------------------------
echo "[Step 5/5] Finalizing installation..."
sudo chmod 777 -R "$CACHE_DRIVE_PATH"
echo "Permissions set on cache drive."
echo "Waiting 30 seconds for container to initialize..."
sleep 30
sudo iotedge restart MCC
echo "MCC container restart command issued."
echo "-------------------------------------------------"

echo "================================================="
echo "MCC Re-installation complete."
echo "Please verify the node's status in the Azure portal."
echo "================================================="

exit 0
