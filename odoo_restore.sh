#!/bin/bash

# vars
BACKUP_DIR=~/odoo_backups
ODOO_DATABASE=14_polimexodoo
ADMIN_PASSWORD=dbadmin

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    exit 0
fi

curl -F "master_pwd=${ADMIN_PASSWORD}" -F backup_file=@${BACKUP_DIR}/$1 -F 'copy=true' -F "name=${ODOO_DATABASE}" http://localhost:8014/web/database/restore
