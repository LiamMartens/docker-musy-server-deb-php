#!/bin/bash
export HOME=/home/www-data

if [ -z "$PHP_PORT" ]; then
	export PHP_PORT=9000
fi

if [ -z "$TIMEZONE" ]; then
	export TIMEZONE='UTC'
fi

# get ip addresses and export them as environment variables
export PHP_TCP=`awk 'END{print $1}' /etc/hosts`

# set timezone
cat /usr/share/zoneinfo/$TIMEZONE > /etc/localtime
echo $TIMEZONE > /etc/timezone

# function to check php.ini config and bak
checkPhpIni() {
	if [[ `cat /etc/php7/php.ini` =~ "^\s*$" ]]; then
		mv /etc/php7/php.ini.bak /etc/php7/php.ini
	else
		rm /etc/php7/php.ini.bak
	fi
}
# function to check fpm www pool and bak
checkPhpPool() {
	if [[ `cat /etc/php7/php-fpm.d/www.conf` =~ "^\s*$" ]]; then
		mv /etc/php7/php-fpm.d/www.conf.bak /etc/php7/php-fpm.d/www.conf
	else
		rm /etc/php7/php-fpm.d/www.conf.bak
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
		perl -p -i.bak -e "s/^$PHP_SETTING\s*=\s*.*/$PHP_SETTING = $VAR_VALUE/gi" /etc/php7/php.ini
		checkPhpIni
	else
		WWWVARS="$WWWVARS"$'\n'"env[$VAR_NAME]=$VAR_VALUE"
	fi
done
echo "$WWWVARS" > /etc/php7/php-fpm.d/env.conf

# set php listen port
perl -p -i.bak -e "s/listen\s*=\s*(.+):.+/listen = $PHP_TCP:$PHP_PORT/gi" /etc/php7/php-fpm.d/www.conf
checkPhpPool

# set timezone
perl -p -i.bak -e "s/;*date.timezone\s*=.*/date.timezone = $TIMEZONE/gi" /etc/php7/php.ini
checkPhpIni

echo "Starting PHP FPM on $PHP_PORT"
php-fpm7

exec "$@"