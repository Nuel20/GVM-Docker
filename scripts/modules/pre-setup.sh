#!/usr/bin/env bash

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