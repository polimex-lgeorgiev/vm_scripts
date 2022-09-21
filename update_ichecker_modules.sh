# vars
ODOO_DATABASE=15_polimexodoo
ODOO_USER=odoo15
ODOO_SERVICE=odoo15
ODOO_MODULE=ichecker

echo 'Stop Odoo Service before update'
sudo systemctl stop ${ODOO_SERVICE}
echo 'Downloading Polimex modules'
sudo -H -u ${ODOO_USER} bash -c 'cd /opt/odoo15/custom-addons/polimex-rfid/ && git pull'
echo 'Updating Polimex modules in database'
sudo -H -u ${ODOO_USER} bash -c "/opt/odoo15/venv/bin/python3 /opt/odoo15/odoo/odoo-bin -d ${ODOO_DATABASE} --addons-path /opt/odoo15/odoo/addons,/opt/odoo15/addons -u ${ODOO_MODULE} --stop-after-init"
echo 'Removing current Odoo sessions (need browser refresh)'
sudo -H -u ${ODOO_USER} bash -c 'cd /opt/odoo15/.local/share/Odoo/sessions/ && rm *.sess'
sudo systemctl start ${ODOO_SERVICE}
tail -f /var/log/${ODOO_DATABASE}.log