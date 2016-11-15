#!/bin/bash

certbot renew --webroot -w /var/www/reminisce.me
nginx -s reload
