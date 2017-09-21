#!/bin/bash
chown -R www:www-data /var/www /etc/php/7.1
chmod -R 755 /var/www /etc/php/7.1 && chmod -R g+w /var/www /etc/php/7.1 && chmod -R g+s /var/www /etc/php/7.1
chmod 755 /var/www/stream/video/build/* && chmod g+w /var/www/stream/video/build/*