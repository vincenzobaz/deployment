#!/bin/bash

certbot renew --webroot -w /var/www/reminisce.me
/etc/init.d/nginx reload
