<?php

/**
 * @file
 * Drupal site-specific configuration file.
 */

// Database configuration
$databases['default']['default'] = [
  'database' => getenv('DB_NAME') ?: 'app_delivery_dev',
  'username' => getenv('DB_USER') ?: 'drupal',
  'password' => getenv('DB_PASSWORD') ?: 'password',
  'prefix' => '',
  'host' => getenv('DB_HOST') ?: 'mariadb',
  'port' => getenv('DB_PORT') ?: '3306',
  'driver' => 'mysql',
  'namespace' => 'Drupal\\mysql\\Driver\\Database\\mysql',
  'autoload' => 'core/modules/mysql/src/Driver/Database/mysql/',
  'charset' => 'utf8mb4',
  'collation' => 'utf8mb4_unicode_ci',
];

// Salt for one-time login links, cancel links, form tokens, etc.
$settings['hash_salt'] = getenv('DRUPAL_HASH_SALT') ?: 'temporary-salt-change-in-production';

// Configuration directories
$settings['config_sync_directory'] = '../config/sync';

// Private file path
$settings['file_private_path'] = '/tmp/drupal-private';

// Trusted host configuration
$settings['trusted_host_patterns'] = [
  '^localhost$',
  '^127\.0\.0\.1$',
  '^app-delivery-.*\.amazonaws\.com$',
];

// Environment-specific settings
$environment = getenv('DRUPAL_ENV') ?: 'development';

switch ($environment) {
  case 'development':
    // Development settings
    $config['system.logging']['error_level'] = 'verbose';
    $config['system.performance']['css']['preprocess'] = FALSE;
    $config['system.performance']['js']['preprocess'] = FALSE;
    
    // Enable development modules
    $settings['extension_discovery_scan_tests'] = TRUE;
    
    // Skip file system chmod during install
    $settings['skip_permissions_hardening'] = TRUE;
    
    // Disable caching
    $settings['container_yamls'][] = DRUPAL_ROOT . '/sites/development.services.yml';
    $settings['cache']['bins']['render'] = 'cache.backend.null';
    $settings['cache']['bins']['page'] = 'cache.backend.null';
    $settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.null';
    break;
    
  case 'testing':
    // Testing environment settings
    $config['system.logging']['error_level'] = 'hide';
    break;
    
  case 'production':
    // Production settings
    $config['system.logging']['error_level'] = 'hide';
    $config['system.performance']['css']['preprocess'] = TRUE;
    $config['system.performance']['js']['preprocess'] = TRUE;
    
    // Enable aggregation
    $config['system.performance']['css']['gzip'] = TRUE;
    $config['system.performance']['js']['gzip'] = TRUE;
    break;
}

// Valkey configuration (Redis-compatible cache)
if (getenv('VALKEY_HOST') ?: getenv('REDIS_HOST')) {
  $settings['redis.connection']['interface'] = 'PhpRedis';
  $settings['redis.connection']['host'] = getenv('VALKEY_HOST') ?: getenv('REDIS_HOST');
  $settings['redis.connection']['port'] = getenv('VALKEY_PORT') ?: getenv('REDIS_PORT') ?: 6379;
  $settings['cache']['default'] = 'cache.backend.redis';
  $settings['cache_prefix'] = 'drupal_' . (getenv('DRUPAL_ENV') ?: 'local');
}

// File system settings
$settings['file_temp_path'] = '/tmp';

// Configuration override settings
$settings['config_exclude_modules'] = ['devel', 'stage_file_proxy'];

// Load services definition file
$settings['container_yamls'][] = __DIR__ . '/services.yml';

// Include local settings
if (file_exists(__DIR__ . '/settings.local.php')) {
  include __DIR__ . '/settings.local.php';
}

// Automatically generated include for settings managed by ddev.
if (file_exists(__DIR__ . '/settings.ddev.php') && getenv('IS_DDEV_PROJECT') == 'true') {
  include __DIR__ . '/settings.ddev.php';
}
