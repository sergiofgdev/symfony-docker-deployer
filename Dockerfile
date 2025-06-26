#syntax=docker/dockerfile:1

# ==============================================================================
# Base Stage (frankenphp_base)
#
# This stage sets up the core environment with PHP, essential extensions,
# and system dependencies. It serves as the foundation for both development
# and production stages.
# ==============================================================================

# Start from the official FrankenPHP image with PHP 8.4
FROM dunglas/frankenphp:1-php8.4 AS frankenphp_upstream

# Base FrankenPHP image
FROM frankenphp_upstream AS frankenphp_base

# Set the working directory inside the container
WORKDIR /app

# Create a volume for persistent data, like logs or cache
VOLUME /app/var/

# Install persistent system dependencies
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
	acl \
	file \
	gettext \
	git \
	&& rm -rf /var/lib/apt/lists/*

# Install common PHP extensions
RUN set -eux; \
	install-php-extensions \
		@composer \
		apcu \
		intl \
		opcache \
		zip \
	;

# Install database-specific PHP extensions
# This section is managed by Symfony Flex recipes.
###> doctrine/doctrine-bundle ###
RUN install-php-extensions pdo_pgsql
###< doctrine/doctrine-bundle ###

# Configure Composer to run as root
ENV COMPOSER_ALLOW_SUPERUSER=1

# Configure the transport for the Mercure hub (defaults to Bolt)
ENV MERCURE_TRANSPORT_URL=bolt:///data/mercure.db

# Add a custom PHP configuration directory
ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"

# Copy custom FrankenPHP configurations
COPY --link frankenphp/conf.d/10-app.ini $PHP_INI_DIR/app.conf.d/
COPY --link frankenphp/Caddyfile /etc/frankenphp/Caddyfile

# Health check to ensure the container is running correctly
HEALTHCHECK --start-period=60s CMD curl -f http://localhost:2019/metrics || exit 1

# Default command to run FrankenPHP
CMD [ "frankenphp", "run", "--config", "/etc/frankenphp/Caddyfile" ]


# ==============================================================================
# Development Stage (frankenphp_dev)
#
# This stage is optimized for development. It includes debugging tools
# like Xdebug and enables features like file watching for hot-reloading.
# ==============================================================================
FROM frankenphp_base AS frankenphp_dev

# Set the entrypoint for the container, at first it was on frankenphp_base, but we move it here so it doest not run on
# frankenphp_prod
COPY --link --chmod=755 frankenphp/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
ENTRYPOINT ["docker-entrypoint"]

# Set environment variables for development
ENV APP_ENV=dev
ENV XDEBUG_MODE=off
ENV FRANKENPHP_WORKER_CONFIG=watch

# Use the development PHP configuration file
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# Install development-specific PHP extensions
RUN set -eux; \
	install-php-extensions \
		xdebug \
	;

# Copy development-specific application configuration
COPY --link frankenphp/conf.d/20-app.dev.ini $PHP_INI_DIR/app.conf.d/

# Run FrankenPHP with file watching enabled for development
CMD [ "frankenphp", "run", "--config", "/etc/frankenphp/Caddyfile", "--watch" ]


# ==============================================================================
# Production Stage (frankenphp_prod)
#
# This stage builds a lean, optimized image for production. It installs
# Composer dependencies, builds assets, and warms up the cache.
# ==============================================================================
FROM frankenphp_base AS frankenphp_prod

# Set environment variables for production
ENV APP_ENV=prod

# Use the production PHP configuration file
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Copy production-specific application configuration
COPY --link frankenphp/conf.d/20-app.prod.ini $PHP_INI_DIR/app.conf.d/

# Install Composer dependencies without dev packages for a smaller image
# This layer is cached to speed up subsequent builds.
COPY --link composer.* symfony.* ./
RUN set -eux; \
	composer install --no-cache --prefer-dist --no-dev --no-autoloader --no-scripts --no-progress

# Copy the rest of the application source code \
COPY --link . ./

# Remove the FrankenPHP configuration directory as it's no longer needed
RUN rm -Rf frankenphp/

# Build and optimize the application for production
RUN set -eux; \
	mkdir -p var/cache var/log; \
    # Optimize Composer's autoloader for production for faster class loading.
	composer dump-autoload --classmap-authoritative --no-dev; \
    # Install JavaScript assets (as defined in importmap.php).
    php bin/console importmap:install; \
    # Compile CSS assets with Tailwind.
    php bin/console tailwind:build --minify; \
    # Compile the final AssetMapper manifest.
    php bin/console asset-map:compile; \
    # Warm up all caches for production (the most robust way to prevent 500 errors).
    php bin/console cache:warmup; \
    # Set final permissions.
	chmod +x bin/console;  \
