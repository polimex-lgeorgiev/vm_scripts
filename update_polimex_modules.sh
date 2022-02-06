echo 'Stop Odoo Service before update'
sudo systemctl stop odoo15
echo 'Downloading Polimex modules'
sudo -H -u odoo15 bash -c '/opt/odoo15/custom-addons/polimex-rfid/git pull'
echo 'Updating Polimex modules in database'
sudo -H -u odoo15 bash -c '/opt/odoo15/venv/bin/python3 /opt/odoo15/odoo/odoo-bin -d 15_polimexodoo --addons-path /opt/odoo15/odoo/addons,/opt/odoo15/addons -u hr_rfid --stop-after-init'
echo 'Removing current Odoo sessions (need browser refresh'
sudo -H -u odoo15 bash -c '/opt/odoo15/.local/share/Odoo/sessions/rm *.sess'
sudo systemctl start odoo15
tail -f /var/log/odoo15.log