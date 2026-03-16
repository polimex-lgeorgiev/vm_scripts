echo "This script will make static IP addres of the virtual machine."
ip a
sudo mv /etc/netplan/01-netcfg.yaml ~/vm_scripts
sudo cp ~/vm_scripts/static_template.yaml /etc/netplan/01-netcfg.yaml
sudo mcedit /etc/netplan/01-netcfg.yaml
sudo netplan apply
ip a