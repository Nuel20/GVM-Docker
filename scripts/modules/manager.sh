#!/usr/bin/env bash

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