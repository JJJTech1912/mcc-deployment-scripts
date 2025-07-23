#!/bin/bash

# ==============================================================================
# Microsoft Connected Cache (MCC) GA Migration Script v3.1
#
# Location: SGS DEV LAB
# Node ID:  8691455e-3725-4325-a51e-afe23ed5d94a
#
# Description:
# This script automates the migration of an existing Preview MCC node to the
# General Availability (GA) release. It uses the V2 deployment script
# ('deploymcc.sh') and the full set of provisioning keys.
#
# It performs the following steps:
#   1. Updates the system's package lists and upgrades existing packages.
#   2. Installs/updates CA certificates to prevent SSL errors.
#   3. Downloads the new V2/GA deployment scripts from Microsoft.
#   4. Extracts the scripts from the ZIP archive.
#   5. Creates necessary directories required by the installer.
#   6. Executes the 'deploymcc.sh' script with the node's specific keys.
#   7. Sets the required permissions on the cache drive.
#   8. Restarts the MCC container to complete the migration.
#
# ==============================================================================

# --- Script Configuration ---
# Exit immediately if a command exits with a non-zero status.
set -e

# --- User Configuration - SGS LAB NODE ---
CUSTOMER_ID="6477d052-c32e-42fc-8c0a-b25b46fa5a79"
CACHE_NODE_ID="8691455e-3725-4325-a51e-afe23ed5d94a"
CUSTOMER_KEY="a329105f-1c09-46ce-9f6b-c5a9dedfa207"
REGISTRATION_KEY="37ee0eb6-6099-4f84-a015-d4b51b5dbb74"
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
echo "Starting MCC GA Migration for SGS LAB NODE"
echo "================================================="

# Step 1: Update the System and Certificates
# ------------------------------------------
echo "[Step 1/7] Updating system packages and certificates..."
# Added options to prevent interactive prompts about configuration files
sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" upgrade -y
sudo apt-get install -y ca-certificates unzip
echo "System update complete."
echo "-------------------------------------------------"

# Step 2: Download the New GA Deployment Scripts
# ----------------------------------------------
echo "[Step 2/7] Downloading the new GA deployment scripts..."
if wget -L "$INSTALLER_URL" -O "$ZIP_FILENAME"; then
    echo "Archive downloaded successfully as '$ZIP_FILENAME'."
else
    echo "ERROR: Failed to download the archive from $INSTALLER_URL."
    exit 1
fi
echo "-------------------------------------------------"

# Step 3: Extract the Scripts
# ---------------------------
echo "[Step 3/7] Extracting scripts from the archive..."
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
echo "[Step 4/7] Creating required directories..."
sudo mkdir -p "$CACHE_DRIVE_PATH"
sudo mkdir -p "$LOG_DIR"
echo "Required directories are present."
echo "-------------------------------------------------"

# Step 5: Run the GA Installer
# ----------------------------
echo "[Step 5/7] Running the GA installation script..."
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

# Step 6: Set Cache Drive Permissions
# -----------------------------------
echo "[Step 6/7] Setting required permissions on the cache drive..."
sudo chmod 777 -R "$CACHE_DRIVE_PATH"
echo "Permissions set on '$CACHE_DRIVE_PATH'."
echo "-------------------------------------------------"

# Step 7: Restart the MCC Container
# ---------------------------------
echo "[Step 7/7] Restarting the MCC container to apply changes..."
sudo iotedge restart MCC
echo "MCC container restart command issued."
echo "-------------------------------------------------"

echo "================================================="
echo "MCC GA Migration complete."
echo "The node should now be running the GA release container."
echo "Please verify its status in the Azure portal."
echo "================================================="

exit 0
