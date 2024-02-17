ARG PHP_FPM_VERSION=8.3-fpm-alpine
FROM php:${PHP_FPM_VERSION}

RUN touch /var/log/error_log

# Update package index and install dependencies
RUN apk update \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS linux-headers \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && apk del .build-deps

RUN docker-php-ext-install mysqli pdo pdo_mysql 
RUN docker-php-ext-enable pdo_mysql

# Necessary to allow inter site cURL/HTTP requests over https
COPY ./config/certs/*.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates

COPY config/php/10-error-reporting.ini \
    config/php/20-memory-limit.ini \
    config/php/40-xdebug.ini \
    ${PHP_INI_DIR}/conf.d/

# WP CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

# Symlink repos
COPY ./cli/docker /tmp/wld

# Make the script executable and run it
RUN chmod +x -R /tmp/wld && \
    sh /tmp/wld/newspack-symlink.sh
