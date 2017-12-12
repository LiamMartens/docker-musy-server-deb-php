#!/bin/bash
chown -R www:www-data /var/www /etc/php/7.1 /home/www
chmod -R 755 /var/www /etc/php/7.1 /home/www && chmod -R g+w /var/www /etc/php/7.1 /home/www && chmod -R g+s /var/www /etc/php/7.1 /home/www
if [[ -d /var/www/stream/video/build ]]; then
    chmod -R 755 /var/www/stream/video/build && chmod -R g+ws /var/www/stream/video/build
fi