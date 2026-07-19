FROM composer:2 AS composer

FROM php:8.5-fpm-trixie AS base

ARG WWWUSER=1000
ARG WWWGROUP=1000

WORKDIR /var/www/html

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        libpq-dev \
        libzip-dev \
        make \
        unzip \
        zip \
    && docker-php-ext-install -j"$(nproc)" bcmath pcntl pdo_pgsql zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN groupadd --force --gid "${WWWGROUP}" laravel \
    && useradd --uid "${WWWUSER}" --gid "${WWWGROUP}" --create-home --shell /bin/bash laravel

COPY docker/app/php.ini /usr/local/etc/php/conf.d/99-laravel.ini

RUN chown -R laravel:laravel /var/www/html /home/laravel

USER laravel

CMD ["php-fpm"]

FROM base AS development

USER root

RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

COPY docker/app/xdebug.ini /usr/local/etc/php/conf.d/98-xdebug.ini

USER laravel

FROM base AS production

USER root

COPY --chown=laravel:laravel composer.json composer.lock artisan ./
COPY --chown=laravel:laravel app ./app
COPY --chown=laravel:laravel bootstrap ./bootstrap
COPY --chown=laravel:laravel config ./config
COPY --chown=laravel:laravel database ./database
COPY --chown=laravel:laravel public ./public
COPY --chown=laravel:laravel resources ./resources
COPY --chown=laravel:laravel routes ./routes
COPY --chown=laravel:laravel storage ./storage

USER laravel

RUN composer install --no-dev --prefer-dist --no-interaction --no-progress --optimize-autoloader
