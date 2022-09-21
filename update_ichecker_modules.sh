echo 'Stop Odoo Service before update'
sudo systemctl stop odoo15
echo 'Downloading iChecker modules'
sudo -H -u odoo15 bash -c 'cd /opt/odoo15/custom-addons/ichecker/ && git pull'
echo 'Updating iChecker modules in database'
sudo -H -u odoo15 bash -c '/opt/odoo15/venv/bin/python3 /opt/odoo15/odoo/odoo-bin -d 15_polimexodoo --addons-path /opt/odoo15/odoo/addons,/opt/odoo15/addons -u ichecker --stop-after-init'
echo 'Removing current Odoo sessions (need browser refresh)'
sudo -H -u odoo15 bash -c 'cd /opt/odoo15/.local/share/Odoo/sessions/ && rm *.sess'
sudo systemctl start odoo15
tail -f /var/log/odoo15.log