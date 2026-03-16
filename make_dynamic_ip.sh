echo "This script will make IP address dynamic of the virtual machine."
ip a
sudo cp ~/vm_scripts/dhcp_template.yaml /etc/netplan/01-netcfg.yaml
sudo netplan apply
ip a