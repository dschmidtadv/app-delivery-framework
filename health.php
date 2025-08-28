<?php
/**
 * Health check endpoint for Drupal application
 */

// Simple health check that verifies basic functionality
$health_status = [
    'status' => 'healthy',
    'timestamp' => date('c'),
    'checks' => []
];

// Check if we can connect to the database (MariaDB)
try {
    if (file_exists('./sites/default/settings.php')) {
        include_once './sites/default/settings.php';
        
        if (isset($databases['default']['default'])) {
            $db_config = $databases['default']['default'];
            $dsn = "mysql:host={$db_config['host']};port={$db_config['port']};dbname={$db_config['database']};charset=utf8mb4";
            $pdo = new PDO($dsn, $db_config['username'], $db_config['password']);
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            
            // Test a simple query
            $stmt = $pdo->query('SELECT 1');
            if ($stmt) {
                $health_status['checks']['database'] = 'connected';
            } else {
                $health_status['checks']['database'] = 'query_failed';
                $health_status['status'] = 'degraded';
            }
        } else {
            $health_status['checks']['database'] = 'not_configured';
        }
    } else {
        $health_status['checks']['database'] = 'settings_missing';
    }
} catch (Exception $e) {
    $health_status['checks']['database'] = 'failed';
    $health_status['status'] = 'unhealthy';
}

// Check if Valkey/Redis is available
try {
    $valkey_host = getenv('VALKEY_HOST') ?: getenv('REDIS_HOST') ?: 'valkey';
    $valkey_port = getenv('VALKEY_PORT') ?: getenv('REDIS_PORT') ?: 6379;
    
    $socket = @fsockopen($valkey_host, $valkey_port, $errno, $errstr, 1);
    if ($socket) {
        fclose($socket);
        $health_status['checks']['cache'] = 'connected';
    } else {
        $health_status['checks']['cache'] = 'unreachable';
        $health_status['status'] = 'degraded';
    }
} catch (Exception $e) {
    $health_status['checks']['cache'] = 'failed';
    $health_status['status'] = 'degraded';
}

// Check if Drupal files directory is writable
$files_dir = './sites/default/files';
if (is_dir($files_dir) && is_writable($files_dir)) {
    $health_status['checks']['files_directory'] = 'writable';
} else {
    $health_status['checks']['files_directory'] = 'not_writable';
    $health_status['status'] = 'degraded';
}

// Set appropriate HTTP status code
http_response_code($health_status['status'] === 'healthy' ? 200 : 503);

// Return JSON response
header('Content-Type: application/json');
echo json_encode($health_status, JSON_PRETTY_PRINT);
