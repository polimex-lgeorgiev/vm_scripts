#!/bin/bash

# Save the current directory
start_dir=$(pwd)

# Set the directory to search for Git repositories
root_dir=""

# Check for optional root_dir argument
if [ $# -eq 1 ]; then
    if [ $1 == "-h" ]; then
        # Display help message
        echo "Usage: $0 [root_dir]"
        echo ""
        echo "Description:"
        echo "  This script searches for Git repositories in the specified directory and its subdirectories, excluding directories with the names 'odoo', 'polimex-rfid', and containing 'venv' in their names. It then updates each repository using 'git pull'."
        echo ""
        echo "Arguments:"
        echo "  root_dir (optional) - The directory where the script will search for Git repositories. If not provided, the default value '/opt/odoo15/custom-addons' will be used. If this directory does not exist or there are multiple directories in /opt, the script will prompt the user to choose one."
        echo ""
        echo "Options:"
        echo "  -h  Display this help message and exit."
        exit 0
    else
        root_dir=$1
    fi
else
    # Set the default root directory
    root_dir="/opt/odoo15/custom-addons"
fi

# Check if root_dir exists or there are more than one folder in /opt
if [ ! -d "$root_dir" ]; then
    opt_dirs=(/opt/*/)
    if [ ${#opt_dirs[@]} -eq 1 ]; then
        root_dir=${opt_dirs[0]}custom-addons
    else
        echo "Please choose a directory from the list below:"
        select choice in /opt/*/; do
            if [ -n "$choice" ]; then
                root_dir=$choice"custom-addons"
                break
            else
                echo "Invalid selection. Please choose a valid directory."
            fi
        done
    fi
fi

# Extract the user name from the root directory path
user_name=$(echo "$root_dir" | sed 's:.*/\([^/]*\)/.*:\1:')

# Find Git repositories and update them
sudo -u "$user_name" bash -c "find \"$root_dir\" -type d -name \".git\" \
  -not -path \"*/odoo/*\" \
  -not -path \"*/polimex-rfid/*\" \
  -not -path \"*/venv/*\" | while read dir; do
    echo \"Updating \$(dirname \"\$dir\")\"
    sudo -u \"$user_name\" bash -c \"cd '\$(dirname \"\$dir\")' && git pull\"
done"

# Return to the original directory
cd $start_dir
