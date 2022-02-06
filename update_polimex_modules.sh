echo 'Stop Odoo Service before update'
sudo systemctl stop odoo14
echo 'Downloading Polimex modules'
sudo -H -u odoo14 bash -c '/opt/odoo14/custom-addons/polimex/git pull'
echo 'Updating Polimex modules in database'
sudo -H -u odoo14 bash -c '/opt/odoo14/venv/bin/python3 /opt/odoo14/odoo/odoo-bin -d 14_polimexodoo --addons-path /opt/odoo14/odoo/addons,/opt/odoo14/addons -u hr_rfid --stop-after-init'
echo 'Removing current Odoo sessions (need browser refresh'
sudo -H -u odoo14 bash -c '/opt/odoo14/.local/share/Odoo/sessions/rm *.sess'
sudo systemctl start odoo14
tail -f /var/log/odoo14.log