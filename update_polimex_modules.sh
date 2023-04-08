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
    echo "This script must be run with sudo privileges." >&2
    exit 1
  fi
}

# function to display help screen
function show_help() {
  echo "Polimex Holding Ltd."
  echo ""
  echo "Usage: ./update_module.sh [module_name]"
  echo "Updates the specified Odoo module or the default 'hr_rfid' module."
  echo ""
  echo "Arguments:"
  echo "  module_name   The name of the module to update."
  echo "                If not specified, the default 'hr_rfid' module will be updated."
  echo ""
  echo "Options:"
  echo "  -h, --help    Display this help screen and exit."
}

# check for sudo rights
check_sudo

# check for help option
if [[ $1 == "-h" || $1 == "--help" ]]; then
  show_help
  exit 0
fi

# vars
ODOO_DATABASE=15_polimexodoo
ODOO_USER=odoo15
ODOO_SERVICE=odoo15
ODOO_MODULE=${1:-hr_rfid}

echo 'Downloading Polimex modules'
sudo -H -u ${ODOO_USER} bash -c "cd /opt/${ODOO_USER}/custom-addons/polimex-rfid/ && git fetch"
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})

if [ $LOCAL = $REMOTE ]; then
  echo "No updates available. Skipping module update and session removal."
else
  echo 'Stop Odoo Service before update'
  sudo systemctl stop ${ODOO_SERVICE}
  echo 'Updating Polimex modules in database'
  sudo -H -u ${ODOO_USER} bash -c "/opt/${ODOO_USER}/venv/bin/python3 /opt/${ODOO_USER}/odoo/odoo-bin -d ${ODOO_DATABASE} --addons-path /opt/${ODOO_USER}/odoo/addons,/opt/${ODOO_USER}/addons -u ${ODOO_MODULE} --stop-after-init"
  echo 'Removing current Odoo sessions (need browser refresh)'
  sudo -H -u ${ODOO_USER} bash -c "cd /opt/${ODOO_USER}/.local/share/Odoo/sessions/ && rm *.sess"
  sudo systemctl start ${ODOO_SERVICE}
fi

tail -f /var/log/${ODOO_USER}.log
