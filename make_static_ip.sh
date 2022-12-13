echo "This script will make static IP addres of the virtual machine."
mcedit ~/vm_scripts/static_template.yaml
sudo mv /etc/netplan/00-installer-config.yaml ~/vm_scripts
sudo cp ~/vm_scripts/static_template.yaml /etc/netplan/00-installer-config.yaml
sudo netplan apply