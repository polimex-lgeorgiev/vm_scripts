#!/bin/bash
# Script to clean up disk space on Ubuntu

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

# Clean cache from various applications
echo "Cleaning application cache..."
sudo apt install -y bleachbit
bleachbit --clean --preset

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

