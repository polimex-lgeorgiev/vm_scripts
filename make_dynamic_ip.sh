echo "This script will make IP address dynamic of the virtual machine."
sudo cp ~/vm_scripts/dhcp_template.yaml /etc/netplan/00-installer-config.yaml
sudo netplan apply