#!/bin/bash

set -e

# Configuration variables
VM_NAME="ubuntu-vm"
RAM_SIZE="2048"
DISK_SIZE="20G"
VCPUS="2"
OS_VARIANT="ubuntu24.04"
UBUNTU_VERSION="24.04"

# Replace this with actual public key
SSH_KEY="ssh-rsa ...."

# Derived variables
WORK_DIR="/var/lib/libvirt/images"
CLOUD_IMAGE="ubuntu-${UBUNTU_VERSION}-server-cloudimg-amd64.img"
CLOUD_IMAGE_URL="https://cloud-images.ubuntu.com/releases/${UBUNTU_VERSION}/release/${CLOUD_IMAGE}"
VM_IMAGE="${WORK_DIR}/${VM_NAME}.qcow2"
CLOUD_INIT_ISO="${WORK_DIR}/${VM_NAME}-cloud-init.iso"
CLOUD_INIT_CONFIG="${WORK_DIR}/${VM_NAME}-cloud-init.yml"
# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Ensure required tools are installed
for cmd in virt-install qemu-img wget cloud-localds; do
    if ! command -v $cmd &> /dev/null; then
        echo "$cmd could not be found, please install it" >&2
        exit 1
    fi
done

# Download Ubuntu cloud image if not present
if [ ! -f "${WORK_DIR}/${CLOUD_IMAGE}" ]; then
    echo "Downloading Ubuntu cloud image..."
    wget -P "${WORK_DIR}" "${CLOUD_IMAGE_URL}"
else
    echo "Ubuntu cloud image already exists, reusing..."
fi

# Create VM image
echo "Creating VM image..."
qemu-img create -f qcow2 -F qcow2 -b "${WORK_DIR}/${CLOUD_IMAGE}" "${VM_IMAGE}" "${DISK_SIZE}"

# Create cloud-init config
echo "Creating cloud-init configuration..."
cat > "${CLOUD_INIT_CONFIG}" <<EOF
#cloud-config
hostname: ${VM_NAME}
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${SSH_KEY}
runcmd:
  - ['sh', '-c', 'curl -fsSL https://tailscale.com/install.sh | sh']
  - ['sh', '-c', "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && sudo sysctl -p /etc/sysctl.d/99-tailscale.conf" ]
  - ['tailscale', 'up', '--authkey=tskey-.....']
  - ['tailscale', 'set', '--ssh']
  - ['tailscale', 'set', '--advertise-exit-node']
EOF

# Generate cloud-init ISO
echo "Generating cloud-init ISO..."
cloud-localds "${CLOUD_INIT_ISO}" "${CLOUD_INIT_CONFIG}"

# Check if VM already exists
if virsh dominfo "${VM_NAME}" &> /dev/null; then
    echo "VM ${VM_NAME} already exists. Skipping creation."
else
    # Create and start the VM
    echo "Creating and starting the VM..."
    virt-install \
        --name "${VM_NAME}" \
        --memory "${RAM_SIZE}" \
        --vcpus "${VCPUS}" \
        --disk "${VM_IMAGE},format=qcow2" \
        --disk "${CLOUD_INIT_ISO},device=cdrom" \
        --os-variant "${OS_VARIANT}" \
        --virt-type kvm \
        --graphics none \
        --network network=default,model=virtio \
        --import \
        --noautoconsole

    echo "VM creation completed successfully!"
fi

echo "You can connect to the VM using: 'virsh console ${VM_NAME}'"
echo "Or SSH into it once it has an IP address."