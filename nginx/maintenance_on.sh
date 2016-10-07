#!/bin/bash

if [ -f /var/www/maintenance/maintenance_off.html ]; then
	mv /var/www/maintenance/maintenance_off.html /var/www/maintenance/maintenance_on.html;
fi
