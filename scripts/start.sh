#!/usr/bin/env bash
set -Eeuo pipefail

USERNAME=${USERNAME:-admin}
PASSWORD=${PASSWORD:-admin}
TIMEOUT=${TIMEOUT:-15}
RELAYHOST=${RELAYHOST:-smtp}
# RELAYHOST=${RELAYHOST:-172.17.0.1}
SMTPPORT=${SMTPPORT:-25}
REDISDBS=${REDISDBS:-512}
QUIET=${QUIET:-false}
HTTPS=${HTTPS:-true}
TZ=${TZ:-UTC}
SSHD=${SSHD:-false}
DB_PASSWORD=${DB_PASSWORD:-none}

/modules/redis.sh

/modules/pre-setup.sh

/modules/setup.sh

chown gvm:gvm -R /usr/local/var/lib/gvm
chmod 770 -R /usr/local/var/lib/gvm
chown gvm:gvm -R /usr/local/var/log/gvm
chown gvm:gvm -R /usr/local/var/run	

/modules/reportformats.sh

mkdir -p /usr/local/var/lib/openvas/plugins
chown -R gvm:gvm /usr/local/var/lib/openva

/modules/feed.sh

/modules/manager.sh

chown -R gvm:gvm /data/var-lib 

/modules/ospd.sh


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
