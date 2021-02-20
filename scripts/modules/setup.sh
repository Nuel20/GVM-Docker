#!/usr/bin/env bash

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


echo "Running first start configuration..."
if !  grep -qs gvm /etc/passwd ; then 
	echo "Adding gvm user"
	useradd --home-dir /usr/local/share/gvm gvm
fi
chown gvm:gvm -R /usr/local/share/gvm
if [ ! -d /usr/local/var/lib/gvm/cert-data ]; then 
	mkdir -p /usr/local/var/lib/gvm/cert-data; 
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