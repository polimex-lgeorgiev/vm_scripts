#!/bin/bash

# vars
ODOO_DATABASE=15_polimexodoo
ODOO_USER=odoo15
ODOO_SERVICE=odoo15
ODOO_MODULE=hr_rfid

echo 'Stop Odoo Service before update'
sudo systemctl stop ${ODOO_SERVICE}
echo 'Downloading Polimex modules'
sudo -H -u ${ODOO_USER} bash -c "cd /opt/${ODOO_USER}/custom-addons/polimex-rfid/ && git pull"
echo 'Updating Polimex modules in database'
sudo -H -u ${ODOO_USER} bash -c "/opt/${ODOO_USER}/venv/bin/python3 /opt/${ODOO_USER}/odoo/odoo-bin -d ${ODOO_DATABASE} --addons-path /opt/${ODOO_USER}/odoo/addons,/opt/${ODOO_USER}/addons -u ${ODOO_MODULE} --stop-after-init"
echo 'Removing current Odoo sessions (need browser refresh)'
sudo -H -u ${ODOO_USER} bash -c "cd /opt/${ODOO_USER}/.local/share/Odoo/sessions/ && rm *.sess"
sudo systemctl start ${ODOO_SERVICE}
tail -f /var/log/${ODOO_USER}.log