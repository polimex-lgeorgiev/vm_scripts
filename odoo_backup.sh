#!/bin/bash

# vars
BACKUP_DIR=~/odoo_backups
ODOO_DATABASE=15_polimexodoo
ODOO_HOST=localhost
ODOO_PORT=8015
ADMIN_PASSWORD=dbadmin

# create a backup directory
mkdir -p ${BACKUP_DIR}

# create a backup
curl -X POST \
    -F "master_pwd=${ADMIN_PASSWORD}" \
    -F "name=${ODOO_DATABASE}" \
    -F "backup_format=zip" \
    -o ${BACKUP_DIR}/${ODOO_DATABASE}.$(date +%F).zip \
    http://${ODOO_HOST}:${ODOO_PORT}/web/database/backup


# delete old backups
find ${BACKUP_DIR} -type f -mtime +7 -name "${ODOO_DATABASE}.*.zip" -delete
