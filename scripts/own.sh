#!/bin/bash
chown -R :www-data /var/www /etc/php/7.1 /home/www/.config /home/www
chmod -R 755 /var/www /etc/php/7.1 /home/www && chmod -R g+w /var/www /etc/php/7.1 /home/www && chmod -R g+s /var/www /etc/php/7.1 /home/www
if [[ -d /var/www/stream/video/musy-stream ]]; then
    chmod -R 755 /var/www/stream/video/musy-stream
fi