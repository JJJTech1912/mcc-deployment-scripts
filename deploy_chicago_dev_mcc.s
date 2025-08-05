#!/bin/bash

# ==============================================================================
# Microsoft Connected Cache (MCC) GA Deployment Script v3.3
#
# Location: Chicago, IL (DEV)
# Node ID:  07752885-16df-4a3c-a384-47c43dcff0c9
#
# Description:
# This script automates the deployment of a net new Microsoft Connected
# Cache node on an Ubuntu server using the General Availability (GA) release.
#
# ==============================================================================

# --- Script Configuration ---
# Exit immediately if a command exits with a non-zero status.
set -e

# --- User Configuration - DEV Chicago Node ---
CUSTOMER_ID="6477d052-c32e-42fc-8c0a-b25b46fa5a79"
CACHE_NODE_ID="07752885-16df-4a3c-a384-47c43dcff0c9"
CUSTOMER_KEY="a329105f-1c09-46ce-9f6b-c5a9dedfa207"
REGISTRATION_KEY="6e8c1ffd-7334-46a4-a16e-516221d317f5"
DRIVE_PATH_AND_SIZE="/cachenode/node1,100"

# --- Script Variables ---
INSTALLER_URL="https://aka.ms/mcc-ent-linux-deploy-scripts"
ZIP_FILENAME="mcc-ent-linux-deploy-scripts.zip"
SCRIPT_DIR="MccScripts"
INSTALLER_FILENAME="deploymcc.sh"
INSTALLER_PATH="${SCRIPT_DIR}/${INSTALLER_FILENAME}"
LOG_DIR="/etc/mccresourcecreation"
CACHE_DRIVE_PATH=$(echo "$DRIVE_PATH_AND_SIZE" | cut -d',' -f1)


# --- Main Execution ---

echo "================================================="
echo "Starting MCC GA Deployment for DEV Chicago Node"
echo "================================================="

# Step 1: Update System and Install Prerequisites
# -----------------------------------------------
echo "[Step 1/9] Updating system packages and installing prerequisites..."
sudo apt-get update
sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" upgrade -y
sudo apt-get install -y ca-certificates unzip wget
echo "System update complete."
echo "-------------------------------------------------"

# Step 2: Add Microsoft Package Repository
# ----------------------------------------
echo "[Step 2/9] Adding Microsoft package repository..."
# This is required for the server to find the 'aziot-edge' packages.
wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
# Update package lists again to include the new repository
sudo apt-get update
echo "Microsoft package repository added."
echo "-------------------------------------------------"

# Step 3: Download the New GA Deployment Scripts
# ----------------------------------------------
echo "[Step 3/9] Downloading the new GA deployment scripts..."
if wget -L "$INSTALLER_URL" -O "$ZIP_FILENAME"; then
    echo "Archive downloaded successfully as '$ZIP_FILENAME'."
else
    echo "ERROR: Failed to download the archive from $INSTALLER_URL."
    exit 1
fi
echo "-------------------------------------------------"

# Step 4: Extract the Scripts
# ---------------------------
echo "[Step 4/9] Extracting scripts from the archive..."
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

# Step 5: Create Required Directories
# -----------------------------------
echo "[Step 5/9] Creating required directories..."
sudo mkdir -p "$CACHE_DRIVE_PATH"
sudo mkdir -p "$LOG_DIR"
echo "Required directories are present."
echo "-------------------------------------------------"

# Step 6: Pre-install IoT Edge packages to handle downgrades
# ----------------------------------------------------------
echo "[Step 6/9] Ensuring correct IoT Edge packages are installed..."
# This prevents an error if the installer tries to downgrade a package.
sudo apt-get install -y --allow-downgrades aziot-edge aziot-identity-service
echo "IoT Edge packages are correctly configured."
echo "-------------------------------------------------"

# Step 7: Run the GA Installer
# ----------------------------
echo "[Step 7/9] Running the GA installation script..."
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

# Step 8: Set Cache Drive Permissions
# -----------------------------------
echo "[Step 8/9] Setting required permissions on the cache drive..."
sudo chmod 777 -R "$CACHE_DRIVE_PATH"
echo "Permissions set on '$CACHE_DRIVE_PATH'."
echo "-------------------------------------------------"

# Step 9: Restart the MCC Container
# ---------------------------------
echo "[Step 9/9] Waiting for container to initialize, then restarting..."
# Add a grace period to allow the IoT Edge agent to deploy the container
sleep 30
sudo iotedge restart MCC
echo "MCC container restart command issued."
echo "-------------------------------------------------"

echo "================================================="
echo "MCC GA Deployment complete."
echo "The node should now be running the GA release container."
echo "Please verify its status in the Azure portal."
echo "================================================="

exit 0
