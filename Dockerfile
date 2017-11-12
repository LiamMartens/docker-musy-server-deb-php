FROM node:8.4.0
LABEL maintainer="hi@liammartens.com"
ENV DEBIAN_FRONTEND=noninteractive

# install pre deps
RUN apt-get update && apt-get -y upgrade && apt-get -y install debconf apt-transport-https lsb-release ca-certificates

# include debian backports
RUN echo 'deb http://deb.debian.org/debian jessie-backports main' > /etc/apt/sources.list.d/backports.list
# include dotdeb
RUN echo 'deb https://packages.sury.org/php jessie main' > /etc/apt/sources.list.d/sury-php.list
RUN curl -L https://packages.sury.org/php/apt.gpg | apt-key add -

# update for new repos
RUN apt-get update

# install some dependencies
RUN apt-get -y install tzdata curl perl bash git nano \
                        libgtk2.0-0 libgconf-2-4 libasound2 \
                        libxtst6 libxss1 libnss3 xvfb \
                        software-properties-common python-software-properties

# install PHP7
ENV PHPV=7.1
RUN apt-get -y install \
        php$PHPV-common \
        php$PHPV-mcrypt \
        php$PHPV-soap \
        php$PHPV-gmp \
        php$PHPV-odbc \
        php$PHPV-mysql \
        php$PHPV-pgsql \
        php$PHPV-sqlite3 \
        php$PHPV-sqlite3 \
        php$PHPV-json \
        php$PHPV-xml \
        php$PHPV-zip \
        php$PHPV-bcmath \
        php$PHPV-opcache \
        php$PHPV-intl \
        php$PHPV-mbstring \
        php$PHPV-gd \
        php$PHPV-xmlrpc \
        php$PHPV-bz2 \
        php$PHPV-curl \
        php$PHPV-phar \
        php$PHPV-fpm \
        php$PHPV-imagick \
        php-yaml

# install development packages
RUN apt-get -y install php$PHPV-dev autoconf make gcc libpcre3-dev g++ build-essential

# build fffmpeg
RUN apt-get -y install automake libfreetype6 libfreetype6-dev liblcms2-2 liblcms2-dev zlib1g zlib1g-dev \
                        libjpeg-dev libpng12-0 libpng12-dev libtiff5 libtiff5-dev \
                        libwebp-dev libwebp5 libopenjpeg-dev libopenjpeg5 \
                        libass-dev libsdl2-dev libtheora-dev libtool libva-dev \
                        libvdpau-dev libvorbis-dev libxcb-util0-dev texinfo \
                        wget yasm nasm libx264-dev libx265-dev libmp3lame-dev librtmp-dev \
                        libopus-dev libvpx-dev pulseaudio pulseaudio-utils pavucontrol

RUN mkdir /ffmpeg && cd /ffmpeg && \
    wget http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && tar xjvf ffmpeg-snapshot.tar.bz2 && \
    cd ffmpeg && \
    ./configure --prefix=/usr \
                --enable-avresample \
                --enable-avfilter \
                --enable-gpl \
                --enable-libmp3lame \
                --enable-librtmp \
                --enable-libvorbis \
                --enable-libvpx \
                --enable-libx264 \
                --enable-libx265 \
                --enable-libtheora \
                --enable-postproc \
                --enable-pic \
                --enable-pthreads \
                --enable-shared \
                --disable-stripping \
                --disable-static \
                --enable-vaapi \
                --enable-libopus \
                --enable-libfreetype \
                --enable-libfontconfig \
                --enable-libpulse \
                --disable-debug && \
    make && make install && cd / && rm -rf /ffmpeg

# install php-redis extension
RUN git clone https://github.com/phpredis/phpredis
RUN cd phpredis && phpize && ./configure && make && make install
RUN rm -rf phpredis

# install phalcon
# RUN git clone --single-branch git://github.com/phalcon/cphalcon
# RUN cd cphalcon/build && ./install
# RUN rm -rf cphalcon
RUN curl -s "https://packagecloud.io/install/repositories/phalcon/stable/script.deb.sh" | bash
RUN apt-get install -y php7.1-phalcon

# remove build packages
# keep gcc, g++, build-essential for cargo compiling on docker
RUN apt-get -y remove php$PHPV-dev libpcre3-dev

# install composer globally
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \ 
    php composer-setup.php && php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer

# create additional user
ENV USER=www
RUN useradd -md /home/$USER -p "" -s /bin/bash $USER && \
        usermod -aG www-data $USER && \
        usermod -aG audio $USER
ENV HOME=/home/www
WORKDIR /home/www
# install rust
RUN curl https://sh.rustup.rs -sSf | sh -s - -y
RUN chown -R $USER:$USER /home/$USER/.cargo

# more install
RUN apt-get -y install libpulse0 alsa-utils

# create directories
RUN mkdir -p /etc/php/$PHPV /usr/lib/php/$PHPV /var/log/php/$PHPV /var/www && \
        chown -R $USER:www-data /etc/php/$PHPV /var/log/php/$PHPV /usr/lib/php/$PHPV /var/www

# chown timezone files
RUN touch /etc/timezone /etc/localtime && \
    chown $USER:www-data /etc/localtime /etc/timezone

# set volumes
VOLUME ["/etc/php/$PHPV", "/var/log/php/$PHPV", "/var/www"]

# copy run file
COPY scripts/run.sh /home/$USER/run.sh
RUN chmod +x /home/$USER/run.sh

# copy own file
COPY scripts/own.sh /home/$USER/own.sh
RUN chmod +x /home/$USER/own.sh

# dbus and x11
RUN dbus-uuidgen > /var/lib/dbus/machine-id
RUN mkdir /tmp/.X11-unix && chown -R root:root /tmp/.X11-unix && chmod -R 1777 /tmp/.X11-unix

ENTRYPOINT ["/home/www/run.sh"];