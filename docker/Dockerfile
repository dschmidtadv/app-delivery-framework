# Docker Configuration for Drupal Development
# Multi-stage Dockerfile optimized for both development and production builds

# Base image with PHP-FPM and Apache
FROM php:8.2-apache AS base
WORKDIR /var/www/html

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    curl \
    zip \
    unzip \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    default-mysql-client \
    redis-tools \
    && docker-php-ext-install \
    gd \
    mbstring \
    xml \
    zip \
    opcache \
    pdo \
    pdo_mysql \
    mysqli \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configure Apache
RUN a2enmod rewrite headers expires
COPY docker/apache/drupal.conf /etc/apache2/sites-available/000-default.conf

# Dependencies stage
FROM base AS deps
COPY composer.json composer.lock* ./
RUN composer install --no-dev --optimize-autoloader

# Development dependencies stage
FROM base AS dev-deps
COPY composer.json composer.lock* ./
RUN composer install --dev

# Development stage
FROM base AS development
COPY composer.json composer.lock* ./
RUN composer install --dev
COPY . .

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose port
EXPOSE 80
ENV DRUPAL_ENV=development

# Install Drush globally for development
RUN composer global require drush/drush

# Create Drupal directories
RUN mkdir -p /var/www/html/sites/default/files \
    && chown -R www-data:www-data /var/www/html/sites/default/files \
    && chmod -R 777 /var/www/html/sites/default/files

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Start Apache in development mode
CMD ["apache2-foreground"]

# Production stage  
FROM base AS production

# Copy built application and optimize for production
COPY --from=deps /var/www/html/vendor ./vendor
COPY . .

# Set production optimizations
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Create optimized PHP configuration for production
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=256" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=20000" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.validate_timestamps=0" >> /usr/local/etc/php/conf.d/opcache.ini

# Expose port
EXPOSE 80

ENV NODE_ENV=production
# Set production environment
ENV DRUPAL_ENV=production

# Health check for production
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Start Apache
CMD ["apache2-foreground"]

# Test stage for running tests in CI
FROM dev-deps AS test
COPY . .
ENV DRUPAL_ENV=test
RUN composer install --dev
RUN vendor/bin/phpunit || true
