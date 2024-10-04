#!/bin/bash

# Get the current kernel version
current_kernel=$(uname -r)
echo "Current kernel: $current_kernel"

# List all installed linux-modules-extra packages and filter out the current kernel
echo "Finding old linux-modules-extra packages..."
old_modules=$(dpkg --list | grep linux-modules-extra | grep -v "$current_kernel" | awk '{print $2}')

# Check if there are any old modules to remove
if [ -z "$old_modules" ]; then
    echo "No old linux-modules-extra packages found."
else
    echo "The following linux-modules-extra packages will be removed:"
    echo "$old_modules"

    # Remove old linux-modules-extra packages
    for module in $old_modules; do
        echo "Removing $module..."
        sudo apt remove --purge -y $module
    done

    # Autoremove any remaining unnecessary packages
    echo "Running apt autoremove to clean up..."
    sudo apt autoremove -y

    echo "Old linux-modules-extra packages have been removed."
fi
