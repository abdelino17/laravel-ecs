# Build Stage 1
# Compile Composer dependencies
FROM composer:1.9 AS composer
WORKDIR /var/www
COPY . /var/www
RUN composer install --ignore-platform-reqs --no-interaction --no-dev --prefer-dist --optimize-autoloader

# Build Stage 2
# Compile NPM assets
FROM node:12.13.0-alpine AS build-npm
WORKDIR /var/www
COPY --from=composer /var/www /var/www
RUN npm install --silent --no-progress
RUN npm run prod --silent --no-progress
RUN rm -rf node_modules

# Build Stage 3
# PHP Alpine image, we install Apache on top of it
FROM alpine:3.10

# Concatenated RUN commands
RUN apk add --no-cache zip unzip libzip-dev libpng-dev libxml2-dev libmcrypt-dev curl gnupg apache2 \
     php7 php7-apache2 php7-mbstring php7-session php7-json php7-openssl php7-tokenizer php7-pdo php7-pdo_mysql php7-fileinfo php7-ctype \
     php7-xmlreader php7-xmlwriter php7-xml php7-simplexml php7-gd php7-bcmath php7-zip php7-dom php7-posix php7-calendar libc6-compat libstdc++ \
    && mkdir -p /run/apache2 \
    && rm  -rf /tmp/*

# Apache configuration
COPY apache.conf /etc/apache2/conf.d

# PHP configuration
RUN wget https://elasticache-downloads.s3.amazonaws.com/ClusterClient/PHP-7.3/latest-64bit
RUN tar -zxvf latest-64bit
RUN mv amazon-elasticache-cluster-client.so /usr/lib/php7/modules/
COPY 00_php.ini /etc/php7/conf.d

# Script permission
ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Copy files from NPM
WORKDIR /var/www
COPY --from=build-npm /var/www /var/www

# Run script
EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]