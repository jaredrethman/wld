ARG PHP_FPM_VERSION=8.3-fpm-alpine
FROM php:${PHP_FPM_VERSION}

RUN touch /var/log/error_log

RUN docker-php-ext-install mysqli pdo pdo_mysql && docker-php-ext-enable pdo_mysql

# Necessary to allow inter site cURL/HTTP requests over https
COPY ./config/certs/*.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

RUN chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp