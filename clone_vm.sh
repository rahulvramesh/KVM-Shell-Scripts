#!/bin/bash

set -e

# Configuration variables
SOURCE_VM="ubuntu-vm"
CLONE_NAME_PREFIX="ubuntu-clone"
NUM_CLONES=1
WORK_DIR="/var/lib/libvirt/images"

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Function to generate a unique MAC address
generate_mac() {
    printf '52:54:00:%02X:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
}

# Function to clone VM
clone_vm() {
    local source_vm="$1"
    local clone_name="$2"
    local clone_mac=$(generate_mac)

    echo "Cloning $source_vm to $clone_name..."

    # Clone the VM
    virt-clone --original "$source_vm" --name "$clone_name" --auto-clone

    # Generate new machine-id
    virt-sysprep -d "$clone_name" --operations machine-id

    # Set new hostname
    virt-sysprep -d "$clone_name" --hostname "$clone_name"

    # Set new MAC address
    virsh dumpxml "$clone_name" | sed "s|<mac address='.*'/>|<mac address='$clone_mac'/>|" | virsh define /dev/stdin

    echo "Clone $clone_name created successfully."
}

# Check if source VM exists and is running
if ! virsh dominfo "${SOURCE_VM}" &> /dev/null; then
    echo "Source VM ${SOURCE_VM} does not exist." >&2
    exit 1
fi

# Create clones
for i in $(seq 1 $NUM_CLONES); do
    clone_name="${CLONE_NAME_PREFIX}-${i}"
    clone_vm "$SOURCE_VM" "$clone_name"
done

echo "Cloning process completed successfully!"