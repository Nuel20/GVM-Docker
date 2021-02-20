#!/usr/bin/env bash
set -Eeuo pipefail

USERNAME=${USERNAME:-admin}
PASSWORD=${PASSWORD:-admin}
TIMEOUT=${TIMEOUT:-15}
RELAYHOST=${RELAYHOST:-smtp}
SMTPPORT=${SMTPPORT:-25}

HTTPS=${HTTPS:-true}
TZ=${TZ:-UTC}
SSHD=${SSHD:-false}
DB_PASSWORD=${DB_PASSWORD:-none}


if [ ! -d "/run/redis" ]; then
	mkdir /run/redis
fi
if  [ -S /run/redis/redis.sock ]; then
        rm /run/redis/redis.sock
fi

redis-server --unixsocket /run/redis/redis.sock --unixsocketperm 700 \
             --timeout 0 --databases $REDISDBS --maxclients 4096 --daemonize yes \
             --port 6379 --bind 0.0.0.0

echo "Wait for redis socket to be created..."
while  [ ! -S /run/redis/redis.sock ]; do
        sleep 1
done

echo "Testing redis status..."
X="$(redis-cli -s /run/redis/redis.sock ping)"
while  [ "${X}" != "PONG" ]; do
        echo "Redis not yet ready..."
        sleep 1
        X="$(redis-cli -s /run/redis/redis.sock ping)"
done
echo "Redis ready."


if  [ ! -d /data/database ]; then
	echo "Creating Data and database folder..."
	mv /var/lib/postgresql/12/main /data/database
	ln -s /data/database /var/lib/postgresql/12/main
	chown postgres:postgres -R /var/lib/postgresql/12/main
	chown postgres:postgres -R /data/database
fi



if [ ! -L /var/lib/postgresql/12/main ]; then
	echo "Fixing Database folder..."
	rm -rf /var/lib/postgresql/12/main
	ln -s /data/database /var/lib/postgresql/12/main
	chown postgres:postgres -R /var/lib/postgresql/12/main
	chown postgres:postgres -R /data/database
fi

if [ ! -L /usr/local/var/lib  ]; then
	echo "Fixing local/var/lib ... "
	if [ ! -d /data/var-lib ]; then
		mkdir /data/var-lib
	fi
	cp -rf /usr/local/var/lib/* /data/var-lib
	rm -rf /usr/local/var/lib
	ln -s /data/var-lib /usr/local/var/lib
fi
if [ ! -L /usr/local/share ]; then
	echo "Fixing local/share ... "
	if [ ! -d /data/local-share ]; then mkdir /data/local-share; fi
	cp -rf /usr/local/share/* /data/local-share/
	rm -rf /usr/local/share 
	ln -s /data/local-share /usr/local/share 
fi


if [ ! -f "/setup" ]; then
	echo "Creating postgresql.conf and pg_hba.conf"

	echo "listen_addresses = '*'" >> /data/database/postgresql.conf
	echo "port = 5432" >> /data/database/postgresql.conf
	echo -e "host\tall\tall\t0.0.0.0/0\ttrust" >> /data/database/pg_hba.conf
	echo -e "host\tall\tall\t::0/0\ttrust" >> /data/database/pg_hba.conf
	echo -e "local\tall\tall\ttrust"  >> /data/database/pg_hba.conf
fi

echo "Starting PostgreSQL..."
su -c "/usr/lib/postgresql/12/bin/pg_ctl -D /data/database start" postgres


if [ ! -f "/setup" ]; then
	echo "Running first start configuration..."
	useradd --home-dir /usr/local/share/gvm gvm
	chown gvm:gvm -R /usr/local/share/gvm
	if [ ! -d /usr/local/var/lib/gvm/cert-data ]; then 
		mkdir -p /usr/local/var/lib/gvm/cert-data; 
	fi


fi
if [ ! -f "/data/setup" ]; then
	echo "Creating Greenbone Vulnerability Manager database"
	su -c "createuser -DRS gvm" postgres
	su -c "createdb -O gvm gvmd" postgres
	su -c "psql --dbname=gvmd --command='create role dba with superuser noinherit;'" postgres
	su -c "psql --dbname=gvmd --command='grant dba to gvm;'" postgres
	su -c "psql --dbname=gvmd --command='create extension \"uuid-ossp\";'" postgres
	su -c "psql --dbname=gvmd --command='create extension \"pgcrypto\";'" postgres
	chown postgres:postgres -R /data/database
	su -c "/usr/lib/postgresql/12/bin/pg_ctl -D /data/database restart" postgres
	if [ ! /data/var-lib/gvm/CA/servercert.pem ]; then
		echo "Generating certs..."
    	gvm-manage-certs -a
	fi
	touch /data/setup
fi



chown gvm:gvm -R /usr/local/var/lib/gvm
chmod 770 -R /usr/local/var/lib/gvm
chown gvm:gvm -R /usr/local/var/log/gvm
chown gvm:gvm -R /usr/local/var/run	

if [ -d /usr/local/var/lib/gvm/data-objects/gvmd/20.08/report_formats ]; then
	echo "Creating dir structure for feed sync"
	for dir in configs port_lists report_formats; do 
		su -c "mkdir -p /usr/local/var/lib/gvm/data-objects/gvmd/20.08/${dir}" gvm
	done
fi


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

echo "Starting Greenbone Vulnerability Manager..."
su -c "gvmd --osp-vt-update=/tmp/ospd.sock" gvm

until su -c "gvmd --get-users" gvm; do
	echo "Waiting for gvmd"
	sleep 1
done

echo "Checking for $USERNAME"
set +e
su -c "gvmd --get-users | grep -qis $USERNAME " gvm
if [ $? -ne 0 ]; then
	echo "$USERNAME does not exist"
	echo "Creating Greenbone Vulnerability Manager admin user as $USERNAME"
	su -c "gvmd --role=\"Super Admin\" --create-user=\"$USERNAME\" --password=\"$PASSWORD\"" gvm
	echo "admin user created"
	ADMINUUID=$(su -c "gvmd --get-users --verbose | awk '{print \$2}' " gvm)
	echo "admin user UUID is $ADMINUUID"
	echo "Granting admin access to defaults"
	su -c "gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value $ADMINUUID" gvm
fi
echo "reset "
set -Eeuo pipefail
touch /setup

chown -R gvm:gvm /data/var-lib 


if [ -f /var/run/ospd.pid ]; then
  rm /var/run/ospd.pid
fi


echo "Starting Postfix for report delivery by email"

sed -i "s/^relayhost.*$/relayhost = ${RELAYHOST}:${SMTPPORT}/" /etc/postfix/main.cf
# Start the postfix  bits
service postfix start

if [ -S /tmp/ospd.sock ]; then
  rm /tmp/ospd.sock
fi
echo "Starting Open Scanner Protocol daemon for OpenVAS..."
ospd-openvas --log-file /usr/local/var/log/gvm/ospd-openvas.log \
             --unix-socket /tmp/ospd.sock --log-level INFO --socket-mode 666


while  [ ! -S /tmp/ospd.sock ]; do
	sleep 1
done


if [ ! -L /var/run/ospd/ospd.sock ]; then
	echo "Fixing the ospd socket ..."
	rm -f /var/run/ospd/ospd.sock
	ln -s /tmp/ospd.sock /var/run/ospd/ospd.sock 
fi





echo "Starting Greenbone Security Assistant..."
su -c "gsad --verbose --http-only --no-redirect --port=9392" gvm
GVMVER=$(su -c "gvmd --version" gvm ) 
echo "++++++++++++++++++++++++++++++++++++++++++++++"
echo "+ Your GVM/openvas/postgresql container is now ready to use! +"
echo "++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo "gvmd --version"
echo "$GVMVER"
echo ""
echo "++++++++++++++++"
echo "+ Tailing logs +"
echo "++++++++++++++++"
tail -F /usr/local/var/log/gvm/*
