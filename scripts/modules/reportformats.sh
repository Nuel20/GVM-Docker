#!/usr/bin/env bash

if [ ! -d /usr/local/var/lib/gvm/data-objects/gvmd/20.08/report_formats ]; then
	echo "Creating dir structure for feed sync"
	for dir in configs port_lists report_formats; do 
		su -c "mkdir -p /usr/local/var/lib/gvm/data-objects/gvmd/20.08/${dir}" gvm
	done
fi