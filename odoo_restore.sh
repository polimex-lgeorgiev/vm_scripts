#!/bin/bash

# vars
BACKUP_DIR=~/odoo_backups
ODOO_DATABASE=15_polimexodoo
ODOO_HOST=localhost
ODOO_PORT=8015
ADMIN_PASSWORD=dbadmin

if [ $# -eq 0 ]
  then
    echo "No backup file supplied!"
    exit 0
fi

curl -F "master_pwd=${ADMIN_PASSWORD}" -F backup_file=@${BACKUP_DIR}/$1 -F 'copy=true' -F "name=${ODOO_DATABASE}" http://${ODOO_HOST}:${ODOO_PORT}/web/database/restore
