#!/bin/bash

# Usage function
print_usage() {
    echo "Usage: $0 <on|off>"
    echo "  on  : Uncomment the db_name line."
    echo "  off : Comment the db_name line."
}

# Check if the user is root or if the script is run with sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires root access. Please run with sudo."
    exit 1
fi

# Check for the presence of a parameter
if [ $# -eq 0 ]; then
    print_usage
    exit 1
fi

CONFIG_FILE="/etc/odoo15.conf"
DB_NAME_LINE="db_name ="

case "$1" in
    off)
        # Comment the db_name line
        sed -i "/^${DB_NAME_LINE}/s/^/;/" "$CONFIG_FILE"
        echo "db_name line has been commented."
        ;;
    on)
        # Uncomment the db_name line
        sed -i "/^;${DB_NAME_LINE}/s/;//" "$CONFIG_FILE"
        echo "db_name line has been uncommented."
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
