#!/bin/bash

# ==============================================================================
# Microsoft Connected Cache (MCC) GA Deployment Script v3.2
#
# Location: Chicago, IL (DEV)
# Node ID:  07752885-16df-4a3c-a384-47c43dcff0c9
#
# Description:
# This script automates the deployment of a net new Microsoft Connected
# Cache node on an Ubuntu server using the General Availability (GA) release.
#
# It performs the following steps:
#   1. Updates the system's package lists and upgrades existing packages.
#   2. Installs/updates CA certificates to prevent SSL errors.
#   3. Downloads the V2/GA deployment scripts from Microsoft.
#   4. Extracts the scripts from the ZIP archive.
#   5. Creates necessary directories required by the installer.
#   6. Pre-installs IoT Edge components to handle potential downgrades.
#   7. Executes the 'deploymcc.sh' script with the node's specific keys.
#   8. Sets the required permissions on the cache drive.
#   9. Waits for the container to initialize, then restarts it to complete the deployment.
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
# Parse the drive path from the combined variable
CACHE_DRIVE_PATH=$(echo "$DRIVE_PATH_AND_SIZE" | cut -d',' -f1)


# --- Main Execution ---

echo "================================================="
echo "Starting MCC GA Deployment for DEV Chicago Node"
echo "================================================="

# Step 1: Update the System and Certificates
# ------------------------------------------
echo "[Step 1/8] Updating system packages and certificates..."
# Added options to prevent interactive prompts about configuration files
sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" upgrade -y
sudo apt-get install -y ca-certificates unzip
echo "System update complete."
echo "-------------------------------------------------"

# Step 2: Download the New GA Deployment Scripts
# ----------------------------------------------
echo "[Step 2/8] Downloading the new GA deployment scripts..."
if wget -L "$INSTALLER_URL" -O "$ZIP_FILENAME"; then
    echo "Archive downloaded successfully as '$ZIP_FILENAME'."
else
    echo "ERROR: Failed to download the archive from $INSTALLER_URL."
    exit 1
fi
echo "-------------------------------------------------"

# Step 3: Extract the Scripts
# ---------------------------
echo "[Step 3/8] Extracting scripts from the archive..."
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

# Step 4: Create Required Directories
# -----------------------------------
echo "[Step 4/8] Creating required directories..."
sudo mkdir -p "$CACHE_DRIVE_PATH"
sudo mkdir -p "$LOG_DIR"
echo "Required directories are present."
echo "-------------------------------------------------"

# Step 5: Pre-install IoT Edge packages to handle downgrades
# ----------------------------------------------------------
echo "[Step 5/8] Ensuring correct IoT Edge packages are installed..."
# This prevents an error if the installer tries to downgrade a package.
sudo apt-get install -y --allow-downgrades aziot-edge aziot-identity-service
echo "IoT Edge packages are correctly configured."
echo "-------------------------------------------------"

# Step 6: Run the GA Installer
# ----------------------------
echo "[Step 6/8] Running the GA installation script..."
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

# Step 7: Set Cache Drive Permissions
# -----------------------------------
echo "[Step 7/8] Setting required permissions on the cache drive..."
sudo chmod 777 -R "$CACHE_DRIVE_PATH"
echo "Permissions set on '$CACHE_DRIVE_PATH'."
echo "-------------------------------------------------"

# Step 8: Restart the MCC Container
# ---------------------------------
echo "[Step 8/8] Waiting for container to initialize, then restarting..."
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
