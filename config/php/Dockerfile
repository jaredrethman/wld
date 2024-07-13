ARG PHP_FPM_VERSION
FROM php:${PHP_FPM_VERSION}

RUN touch /var/log/error_log

# Xdebug, Redis
RUN apk update \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS linux-headers libxml2-dev \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && docker-php-ext-install soap \
    && apk del .build-deps

RUN docker-php-ext-install mysqli pdo pdo_mysql 
RUN docker-php-ext-enable pdo_mysql

# ini config
COPY 10-error-reporting.ini \
    20-memory-limit.ini \
    40-xdebug.ini \
    ${PHP_INI_DIR}/conf.d/

# WP CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Entrypoint script
RUN mkdir -p /wld
COPY cli/ /wld
RUN chmod +x -R /wld
RUN chmod +x /wld/after-startup.sh
