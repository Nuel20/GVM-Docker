#!/usr/bin/env bash

if [ -f /var/run/ospd.pid ]; then
  rm /var/run/ospd.pid
fi

echo "Starting Postfix for report delivery by email"

sed -i "s/^relayhost.*$/relayhost = ${RELAYHOST}:${SMTPPORT}/" /etc/postfix/main.cf
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
	mkdir -p /var/run/ospd
	echo "Fixing the ospd socket ..."
	rm -f /var/run/ospd/ospd.sock
	ln -s /tmp/ospd.sock /var/run/ospd/ospd.sock 
fi