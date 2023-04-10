#!/bin/bash

# Function to display the help screen
usage() {
    echo "Usage: $0 [-u user] [source_folder] [destination_folder]"
    echo
    echo "Options:"
    echo "  -u  Run the script as a specific user (default: current user)"
    echo
    echo "This script creates symlinks for all subfolders containing a __manifest__.py file."
    echo "Default source folder: /opt/odoo15/custom-addons"
    echo "Default destination folder: /opt/odoo15/addons"
    exit 1
}

# Parse command-line options
user="$USER"
while getopts ":u:" opt; do
    case $opt in
        u)
            user="$OPTARG"
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# Set default source and destination folder values if not provided
src_folder="${1:-/opt/odoo15/custom-addons}"
dest_folder="${2:-/opt/odoo15/addons}"

# Check if folders exist
if [ ! -d "$src_folder" ] || [ ! -d "$dest_folder" ]; then
    echo "Error: Source or destination folder does not exist."
    exit 1
fi

# Find all subfolders with a __manifest__.py file and create symlinks
find "$src_folder" -type f -name "__manifest__.py" -exec dirname {} \; | while read -r folder; do
    folder_name=$(basename "$folder")
    symlink_target="$dest_folder/$folder_name"

    if [ -L "$symlink_target" ]; then
        echo "Skipped symlink creation: $symlink_target already exists"
    else
        sudo -u "$user" ln -s "$folder" "$symlink_target"
        echo "Created symlink: $symlink_target -> $folder"
    fi
done