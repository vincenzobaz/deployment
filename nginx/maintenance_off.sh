#!/bin/bash

if [ -f /var/www/maintenance/maintenance_on.html ]; then
	mv /var/www/maintenance/maintenance_on.html /var/www/maintenance/maintenance_off.html;
fi
