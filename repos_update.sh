#!/bin/sh

# vars
ODOO_USER=odoo15

echo 'Stop Odoo Service before update'
sudo systemctl stop ${ODOO_SERVICE}
echo 'Downloading Polimex modules'
sudo -H -u ${ODOO_USER} bash -c 'cd /opt/odoo15/custom-addons/polimex-rfid/ && git pull'

if [ ! "$1" = "" ] ; then

   if [ "$GITREPO" = "" -a -d "/opt/${ODOO_USER}/custom-addons" ] ; then
      GITREPO="/opt/${ODOO_USER}/custom-addons"
   fi

   if [ "$GITREPO" != "" ] ; then

      echo "Git repositories found in $GITREPO"
      echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-"

      DIRS="`/bin/ls -1 $GITREPO`"

      for dir in $DIRS ; do

         if [ -d $GITREPO/$dir/.git ] ; then
            echo "$dir -> git $1"
#            cd $GITREPO/$dir ; git $@
            sudo -H -u ${ODOO_USER} bash -c "cd ${GITREPO}/${dir} && git pull"
            echo
         fi

      done
   else

      echo "Git repositories not found."

   fi
fi