FROM debian:jessie
MAINTAINER Liam Martens (hi@liammartens.com)

ENV DEBIAN_FRONTEND=noninteractive

# add www-data user
RUN id -u www-data &>/dev/null || adduser --disabled-password www-data

# run updates
RUN apt-get update && apt-get -y upgrade

# add default packages
RUN apt-get -y install tzdata perl curl bash git

# install PHP7
RUN echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
RUN curl -L https://www.dotdeb.org/dotdeb.gpg | apt-key add -
ENV PHPV=7.0
RUN apt-get update && apt-get -y install \
    openssl \
    php-pear \
    php$PHPV-mcrypt \
    php$PHPV-soap \
    php$PHPV-gmp \
    php$PHPV-odbc \
    php$PHPV-json \
    php$PHPV-dom \
    php$PHPV-pdo \
    php$PHPV-zip \
    php$PHPV-mysqli \
    php$PHPV-sqlite3 \
    php$PHPV-pgsql \
    php$PHPV-bcmath \
    php$PHPV-opcache \
    php$PHPV-intl \
    php$PHPV-mbstring \
    php$PHPV-sockets \
    php$PHPV-xml \
    php$PHPV-gd \
    php$PHPV-odbc \
    php$PHPV-mysql \
    php$PHPV-sqlite \
    php$PHPV-gettext \
    php$PHPV-xmlreader \
    php$PHPV-xmlrpc \
    php$PHPV-bz2 \
    php$PHPV-iconv \
    php$PHPV-curl \
    php$PHPV-ctype \
    php$PHPV-fpm \
    php$PHPV-common \
    php$PHPV-phar \
    php$PHPV-xmlwriter \
    php$PHPV-tokenizer \
    php$PHPV-fileinfo \
    php$PHPV-posix \
    php$PHPV-imagick

# install yaml 2.0.0 extension
RUN apt-get -y install php$PHPV-dev autoconf libyaml-0-2 libyaml-dev build-essential git
RUN pecl install yaml-2.0.0

# install php-redis extension
RUN git clone https://github.com/phpredis/phpredis
RUN cd phpredis && phpize && ./configure && make && make install
RUN rm -rf phpredis

# install phalcon
RUN git clone --single-branch git://github.com/phalcon/cphalcon
RUN cd cphalcon/build && ./install
RUN  rm -rf cphalcon

RUN apt-get -y remove php$PHPV-dev autoconf libyaml-dev build-essential

# install composer globally
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '669656bab3166a7aff8a7506b8cb2d1c292f042046c5a994c43155c0be6190fa0355160742ab2e1c88d40d5be660b410') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer

# create php directory
RUN mkdir -p /etc/php7 /var/log/php7 /usr/lib/php7 /var/www && \
    chown -R www-data:www-data /etc/php7 /var/log/php7 /usr/lib/php7 /var/www

# chown timezone files
RUN touch /etc/timezone /etc/localtime && \
    chown www-data:www-data /etc/localtime /etc/timezone

# set volumes
VOLUME ["/etc/php7", "/var/log/php7", "/var/www"]

# copy run file
COPY scripts/run.sh /home/www-data/run.sh
RUN chmod +x /home/www-data/run.sh
COPY scripts/continue.sh /home/www-data/continue.sh
RUN chmod +x /home/www-data/continue.sh

# PHP BUILD DONE -> CONTINUE WITH MUSY SERVER BUILD
RUN echo "deb http://http.debian.net/debian jessie-backports main contrib non-free" >> /etc/apt/sources.list
RUN apt-get update && apt-get -y install ffmpeg

RUN curl https://sh.rustup.rs -sSf -o rustup.sh && chmod +x rustup.sh && ./rustup.sh -y && rm rustup.sh
RUN apt-get -y install xvfb dbus ttf-freefont udev nodejs npm && dbus-uuidgen > /var/lib/dbus/machine-id

ENTRYPOINT ["/home/www-data/run.sh", "su", "-m", "www-data", "-c", "/home/www-data/continue.sh /bin/sh"]