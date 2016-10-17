FROM nginx:latest

# Certificate renewal
RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list
RUN apt-get update && apt-get install -y certbot -t jessie-backports 
RUN mkdir -p /var/www/reminisce.me
COPY renew_certificate.sh /
RUN chmod +x renew_certificate.sh

# Configuration
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/
COPY .htpasswd /etc/nginx

# Maintenance on/off
COPY maintenance_off.html /var/www/maintenance/
COPY maintenance_on.sh /
RUN chmod +x maintenance_on.sh
COPY maintenance_off.sh /
RUN chmod +x maintenance_off.sh
