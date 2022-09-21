#!/bin/sh
if [ ! "$1" = "" ] ; then

   if [ "$GITREPO" = "" -a -d "$HOME/custom-addons" ] ; then
      GITREPO="$HOME/custom-addons"
   fi

   if [ "$GITREPO" != "" ] ; then

      echo "Git repositories found in $GITREPO"
      echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-"

      DIRS="`/bin/ls -1 $GITREPO`"

      for dir in $DIRS ; do

         if [ -d $GITREPO/$dir/.git ] ; then
            echo "$dir -> git $1"
            cd $GITREPO/$dir ; git $@
            echo
         fi

      done
   else

      echo "Git repositories not found."

   fi
fi