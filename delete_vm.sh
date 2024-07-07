#!/bin/bash

set -e

# Configuration variables
VM_NAME="ubuntu-vm"
WORK_DIR="/var/lib/libvirt/images"

# Derived variables
VM_IMAGE="${WORK_DIR}/${VM_NAME}.qcow2"
CLOUD_INIT_ISO="${WORK_DIR}/${VM_NAME}-cloud-init.iso"
CLOUD_INIT_CONFIG="${WORK_DIR}/${VM_NAME}-cloud-init.yml"

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Function to safely remove a file
safe_remove() {
    if [ -f "$1" ]; then
        echo "Removing $1"
        rm -f "$1"
    else
        echo "$1 does not exist, skipping"
    fi
}

# Check if VM exists
if virsh dominfo "${VM_NAME}" &> /dev/null; then
    echo "Shutting down VM ${VM_NAME} (if running)..."
    virsh destroy "${VM_NAME}" &> /dev/null || true

    echo "Undefining VM ${VM_NAME}..."
    virsh undefine "${VM_NAME}" --remove-all-storage

    echo "VM ${VM_NAME} has been deleted."
else
    echo "VM ${VM_NAME} does not exist. Skipping VM deletion."
fi

# Remove associated files
safe_remove "${VM_IMAGE}"
safe_remove "${CLOUD_INIT_ISO}"
safe_remove "${CLOUD_INIT_CONFIG}"

echo "Cleanup completed successfully!"