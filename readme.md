sudo apt update
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients virtinst cloud-image-utils



## Creating A Machine
```bash
chmod +x create_vm.sh
sudo ./create_vm.sh
```

## Conosle SSH

```bash
virsh console ubuntu-vm
```


```bash
#IP Adress 
virsh domifaddr ubuntu-vm
```

### Listing Network
sudo virsh net-list --all

### List all
virsh list --all

### Edit Machine
virsh edit ubuntu24.04-3

### Exporting XML
virsh dumpxml ubuntu24.04-3 > ubuntu24.04-3.xml

### Creating New from XML
virsh define ubuntu24.04-3.xml

### Resource Utlization 
```bash
virsh ubuntu-vm --cpu-total
```