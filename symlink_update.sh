#!/bin/bash

# Function to display the help screen
usage() {
    echo "Usage: $0 [-u user] [source_folder] [destination_folder]"
    echo
    echo "Options:"
    echo "  -u  Run the script as a specific user (default: odoo15)"
    echo "  -h, --help  Show help information"
    echo
    echo "This script creates symlinks for all subfolders containing a __manifest__.py file."
    echo "Default source folder: /opt/odoo15/custom-addons"
    echo "Default destination folder: /opt/odoo15/addons"
    exit 1
}

# Parse command-line options
user="odoo15"
while getopts ":u:-:" opt; do
    case $opt in
        u)
            user="$OPTARG"
            ;;
        -)
            case $OPTARG in
                help)
                    usage
                    ;;
                *)
                    echo "Unknown option: --$OPTARG"
                    usage
                    ;;
            esac
            ;;
        h)
            usage
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

# Check if folders exist under the specified user
if ! sudo -u "$user" test -d "$src_folder" || ! sudo -u "$user" test -d "$dest_folder"; then
    echo "Error: Source or destination folder does not exist."
    exit 1
fi

# Find all subfolders with a __manifest__.py file and create symlinks
sudo -u "$user" find "$src_folder" -type f -name "__manifest__.py" -exec dirname {} \; | while read -r folder; do
    folder_name=$(basename "$folder")
    symlink_target="$dest_folder/$folder_name"

    if [ -L "$symlink_target" ] && [ "$(readlink -f "$symlink_target")" == "$(readlink -f "$folder")" ]; then
        echo "Skipped symlink creation: $symlink_target already exists"
    elif [ -d "$symlink_target" ]; then
        echo "Skipped symlink creation: $symlink_target exists as a directory"
    else
        sudo -u "$user" ln -s "$folder" "$symlink_target"
        echo "Created symlink: $symlink_target -> $folder"
    fi
done
