#!/bin/bash

# own files
$HOME/own.sh >/dev/null 2>&1 &

if [ -z "$PHP_PORT" ]; then
    export PHP_PORT=9000
fi

if [ -z "$TIMEZONE" ]; then
    export TIMEZONE='UTC'
fi

# get ip addresses and export them as environment variables
export PHP_TCP=`awk 'END{print $1}' /etc/hosts`

# set timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/timezone

# function to check php.ini config and bak
checkPhpIni() {
    if [[ `cat /etc/php/7.1/fpm/php.ini` =~ "^\s*$" ]]; then
        mv /etc/php/7.1/fpm/php.ini.bak /etc/php/7.1/fpm/php.ini
    else
        rm /etc/php/7.1/fpm/php.ini.bak
    fi
}
# function to check fpm www pool and bak
checkPhpPool() {
    if [[ `cat /etc/php/7.1/fpm/fpm.d/www.conf` =~ "^\s*$" ]]; then
        mv /etc/php/7.1/fpm/fpm.d/www.conf.bak /etc/php/7.1/fpm/fpm.d/www.conf
    else
        rm /etc/php/7.1/fpm/fpm.d/www.conf.bak
    fi
}

#
# set php variables
#
# PHP_MEMORY_LIMIT -> memory_limit
# PHP_ZLIB__OUTPUT_COMPRESSION -> zlib.output_compression
#
WWWVARS='[www]'
ENV_VARS=($(env))
for VAR in "${ENV_VARS[@]}"; do
    VAR_NAME=$(echo $VAR | cut -d'=' -f 1)
    VAR_VALUE=$(echo $VAR | cut -d'=' -f 2)
    if [[ "$VAR_NAME" =~ "PHP_"* ]] && [[ "$VAR_NAME" != "PHP_PORT" ]]; then
        PHP_SETTING=$(echo $VAR_NAME | cut -d'_' -f 2-)
        PHP_SETTING=$(echo $PHP_SETTING | awk '{print tolower($0)}')
        PHP_SETTING=$(echo $PHP_SETTING | perl -pe "s/__/./")
        perl -p -i.bak -e "s/^$PHP_SETTING\s*=\s*.*/$PHP_SETTING = $VAR_VALUE/gi" /etc/php/7.1/fpm/php.ini
        checkPhpIni
    else
        WWWVARS="$WWWVARS"$'\n'"env[$VAR_NAME]=$VAR_VALUE"
    fi
done
echo "$WWWVARS" > /etc/php/7.1/fpm/fpm.d/env.conf

# set php listen port
perl -p -i.bak -e "s/listen\s*=\s*(.+):.+/listen = $PHP_TCP:$PHP_PORT/gi" /etc/php/7.1/fpm/fpm.d/www.conf
checkPhpPool

# set timezone
perl -p -i.bak -e "s/;*date.timezone\s*=.*/date.timezone = $TIMEZONE/gi" /etc/php/7.1/fpm/php.ini
checkPhpIni

# alsa
cat <<EOF > ~/.asoundrc
pcm.output {
    type hw
    card 0
}

ctl.input {
    type hw
    card 0
}

pcm.!default {
    type plug
    slave {
        pcm output
        rate 44100
    }
}

ctl.!default {
    type plug
    slave {
        pcm input
        rate 44100
    }
}
EOF
chown www:www ~/.asoundrc

# start PHP FPM and take ownership
echo "Starting PHP FPM on $PHP_PORT"
/etc/init.d/php7.1-fpm start

# switch user to run musy startup scripts
su - -m www -c 'run-parts --regex=musy_.* /etc/init.d'

# end switch user
su - -m www