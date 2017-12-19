#!/bin/bash
chown -R :www-data /var/www /etc/php/7.1 && chown www:www-data $HOME && chown -R www:www-data $HOME/.config
chmod -R 755 /var/www /etc/php/7.1 && chmod -R g+w /var/www /etc/php/7.1 && chmod -R g+s /var/www /etc/php/7.1 && chmod 755 $HOME && chmod -R 755 $HOME/.config
if [[ -d /var/www/stream/video/musy-stream ]]; then
    chmod -R 755 /var/www/stream/video/musy-stream
fi