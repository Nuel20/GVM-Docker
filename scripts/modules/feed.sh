#!/usr/bin/env bash
su -c "gvmd --migrate" gvm

if [ $DB_PASSWORD != "none" ]; then
	su -c "psql --dbname=gvmd --command=\"alter user gvm password '$DB_PASSWORD';\"" postgres
fi

echo "Updating NVTs and other data"
chmod 777 /usr/local/var/run/
if [ -f /usr/local/var/run/feed-update.lock ]; then
        echo "Removing feed-update.lock"
	rm /usr/local/var/run/feed-update.lock
fi


if [ $QUIET == "TRUE" ] || [ $QUIET == "true" ]; then
	QUIET="true"
	echo " Fine, ... we'll be quiet, but we warn you if there are errors"
	echo " syncing the feeds, you'll miss them."
else
	QUIET="false"
fi

if [ $QUIET == "true" ]; then 
	echo " Pulling NVTs from greenbone" 
	su -c "/usr/local/bin/greenbone-nvt-sync" gvm 2&> /dev/null
	sleep 2
	echo " Pulling scapdata from greenbone"
	su -c "/usr/local/sbin/greenbone-scapdata-sync" gvm 2&> /dev/null
	sleep 2
	echo " Pulling cert-data from greenbone"
	su -c "/usr/local/sbin/greenbone-certdata-sync" gvm 2&> /dev/null
	sleep 2
	echo " Pulling latest GVMD Data from greenbone" 
	su -c "/usr/local/sbin/greenbone-feed-sync --type GVMD_DATA " gvm 2&> /dev/null

else
	echo " Pulling NVTs from greenbone" 
	su -c "/usr/local/bin/greenbone-nvt-sync" gvm
	sleep 2
	echo " Pulling scapdata from greenboon"
	su -c "/usr/local/sbin/greenbone-scapdata-sync" gvm
	sleep 2
	echo " Pulling cert-data from greenbone"
	su -c "/usr/local/sbin/greenbone-certdata-sync" gvm
	sleep 2
	echo " Pulling latest GVMD Data from Greenbone" 
	su -c "/usr/local/sbin/greenbone-feed-sync --type GVMD_DATA " gvm

fi