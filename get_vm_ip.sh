#!/bin/bash

VM_NAME="ubuntu-vm"

# Function to get IP address
get_vm_ip() {
    virsh domifaddr "$VM_NAME" | awk '/ipv4/ {print $4}' | cut -d'/' -f1
}

# Wait for IP address (timeout after 60 seconds)
timeout=60
echo "Waiting for VM to get an IP address (timeout: ${timeout}s)..."
for i in $(seq 1 $timeout); do
    IP=$(get_vm_ip)
    if [ -n "$IP" ]; then
        echo "VM IP address: $IP"
        exit 0
    fi
    sleep 1
done

echo "Timeout reached. Unable to get VM IP address."
exit 1