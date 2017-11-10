#!/bin/bash
chown -R www:www-data /var/www /etc/php/7.1 /home/www
chmod -R 755 /var/www /etc/php/7.1 /home/www && chmod -R g+w /var/www /etc/php/7.1 /home/www && chmod -R g+s /var/www /etc/php/7.1 /home/www
chmod 755 /var/www/stream/video/build/* && chmod g+w /var/www/stream/video/build/*