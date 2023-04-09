#!/bin/bash
# Script to clean up disk space on Ubuntu

# Function to check if the script is running with sudo rights
check_sudo_rights() {
  if [[ $EUID -ne 0 ]]; then
    echo "This script requires sudo rights. Restarting the script with sudo..."
    exec sudo "$0" "$@"
  fi
}

# Check for sudo rights
check_sudo_rights

# Update package index
echo "Updating package index..."
sudo apt -y update && sudo apt -y upgrade
sudo apt update -y

# Remove old package files and cache
echo "Removing old package files and cache..."
sudo apt autoclean -y
sudo apt autoremove --purge -y
sudo apt-get clean

# Remove old kernels
echo "Removing old kernels..."
sudo apt --purge remove $(dpkg --list | tail -n +6 | grep -E 'linux-image-[0-9]+' | grep -Fv $(uname -r) | awk '{print $2}' | tr '\n' ' ')

# Check if BleachBit is installed, and install it if necessary
if ! dpkg-query -W -f='${Status}' bleachbit 2>/dev/null | grep -q "ok installed"; then
  echo "Installing BleachBit..."
  apt install -y bleachbit
fi

# Clean cache from various applications
echo "Cleaning application cache..."
export DISPLAY="$DISPLAY"
bleachbit --clean --preset &

# Remove temporary files
echo "Removing temporary files..."
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Remove old log files
echo "Removing old log files..."
sudo find /var/log -type f -regex ".*\.gz$" -delete
sudo find /var/log -type f -regex ".*\.[0-9]$" -delete

# Empty Trash
echo "Emptying trash..."
sudo rm -rf ~/.local/share/Trash/files/*

echo "Cleanup complete!"

