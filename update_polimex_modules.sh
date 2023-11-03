#!/bin/bash

# COPYRIGHT NOTICE
#
# (C) 2023 Polimex Holding Ltd. All rights reserved.
#
# This software is the property of Polimex Holding Ltd.
# It may not be copied, modified, or distributed without the express
# permission of Polimex Holding Ltd.

# function to check if the user has sudo rights
function check_sudo() {
  if [ "$(id -u)" != "0" ]; then
    echo "This script requires sudo privileges. Please enter your sudo password:"
    sudo "$0" "$@"
    exit $?
  fi
}

# function to display help screen
function show_help() {
  echo "Polimex Holding Ltd."
  echo ""
  echo "Usage: ./update_polimex_module.sh [options]"
  echo "Updates the specified Odoo module."
  echo ""
  echo "Options:"
  echo "  -h, --help       Display this help screen and exit."
  echo "  -d, --database   Specify the Odoo database name to update. Default is '15_polimexodoo'."
  echo "  -m, --module     Specify the Odoo module name to update. Default is 'hr_rfid'."
}

# default values
DEFAULT_DATABASE='15_polimexodoo'
DEFAULT_MODULE='hr_rfid'
ODOO_DATABASE="$DEFAULT_DATABASE"
ODOO_MODULE="$DEFAULT_MODULE"
FORCE_UPDATE=false

# Parse command line options
while [[ "$#" -gt 0 ]]; do
    echo "Current parameter: $1"  # Debug line
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -d|--database)
            ODOO_DATABASE="$2"
            FORCE_UPDATE=true
            echo "FORCE_UPDATE set to $FORCE_UPDATE after option parsing"
            shift
            shift
            ;;
        -m|--module)
            ODOO_MODULE="$2"
            shift
            shift
            ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
    shift
done

# check for sudo rights
#check_sudo

# rest of the script variables
ODOO_USER=odoo15
ODOO_SERVICE=odoo15

echo "Force parameter: $FORCE_UPDATE"

echo 'Downloading Polimex modules'
sudo -H -u ${ODOO_USER} bash -c "cd /opt/${ODOO_USER}/custom-addons/polimex-rfid/ && git fetch"
LOCAL=$(sudo -H -u ${ODOO_USER} bash -c "cd /opt/${ODOO_USER}/custom-addons/polimex-rfid/ && git rev-parse @")
REMOTE=$(sudo -H -u ${ODOO_USER} bash -c "cd /opt/${ODOO_USER}/custom-addons/polimex-rfid/ && git rev-parse @{u}")

if [ "$FORCE_UPDATE" = false ] && [ "$LOCAL" = "$REMOTE" ]; then
  echo "No updates available for $ODOO_MODULE. Skipping module update and session removal."
else
  echo 'Stop Odoo Service before update'
  sudo systemctl stop ${ODOO_SERVICE}
  echo 'Updates are available for $ODOO_MODULE. Pulling changes from remote'
  sudo -H -u ${ODOO_USER} bash -c "cd /opt/${ODOO_USER}/custom-addons/polimex-rfid/ && git pull"
  echo 'Update symlinks if new modules added (TODO)'
  echo "Updating $ODOO_MODULE module in database $ODOO_DATABASE"
  sudo -H -u ${ODOO_USER} bash -c "/opt/${ODOO_USER}/venv/bin/python3 /opt/${ODOO_USER}/odoo/odoo-bin -d ${ODOO_DATABASE} --addons-path /opt/${ODOO_USER}/odoo/addons -u ${ODOO_MODULE}"
  echo 'Removing current Odoo sessions (need browser refresh)'
  sudo -H -u ${ODOO_USER} bash -c "cd /opt/${ODOO_USER}/.local/share/Odoo/sessions/ && rm *.sess"
  sudo systemctl start ${ODOO_SERVICE}
fi

tail -f /var/log/${ODOO_USER}.log
