#!/bin/bash
# Local Development Setup Script
# This script sets up the local development environment for the App Delivery Framework

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurati-- Create additional databases for testing
CREATE DATABASE app_delivery_test;

-- Create schemas for multi-tenancy simulation
CREATE SCHEMA IF NOT EXISTS public;
CREATE SCHEMA IF NOT EXISTS tenant_1;
CREATE SCHEMA IF NOT EXISTS tenant_2;

-- Create application user with appropriate permissions
CREATE USER app_delivery_app WITH PASSWORD 'app_password';
GRANT ALL PRIVILEGES ON DATABASE app_delivery_dev TO app_delivery_app;
GRANT ALL PRIVILEGES ON DATABASE app_delivery_test TO app_delivery_app;# Configuration
PROJECT_NAME="${PROJECT_NAME:-app-delivery-framework}"
ENVIRONMENT="${ENVIRONMENT:-local}"
AWS_REGION="${AWS_REGION:-us-west-2}"
LOCAL_PORT="${LOCAL_PORT:-8080}"
DRUPAL_VERSION="${DRUPAL_VERSION:-10}"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_deps=()
    
    if ! command_exists docker; then
        missing_deps+=("docker")
    fi
    
    if ! command_exists docker-compose; then
        missing_deps+=("docker-compose")
    fi
    
    if ! command_exists composer; then
        missing_deps+=("composer")
    fi
    
    if ! command_exists php; then
        missing_deps+=("php")
    fi
    
    if ! command_exists git; then
        missing_deps+=("git")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_error "Please install the missing dependencies and run this script again."
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker and try again."
        exit 1
    fi
    
    print_success "All prerequisites satisfied"
}

# Function to setup AWS credentials
setup_aws_credentials() {
    print_status "Setting up AWS credentials..."
    
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_warning "AWS credentials not configured or expired"
        print_status "Please run 'aws configure' or 'aws sso login' to setup your credentials"
        
        # Prompt user to configure AWS
        read -p "Press Enter after configuring AWS credentials..."
        
        if ! aws sts get-caller-identity >/dev/null 2>&1; then
            print_error "AWS credentials still not working. Please check your configuration."
            exit 1
        fi
    fi
    
    print_success "AWS credentials configured"
}

# Function to create .env file from AWS Secrets Manager
setup_environment_file() {
    print_status "Setting up environment variables..."
    
    local env_file=".env.local"
    
    # Check if .env.local already exists
    if [[ -f "$env_file" ]]; then
        print_warning "$env_file already exists"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Skipping environment file setup"
            return 0
        fi
    fi
    
    print_status "Fetching secrets from AWS Secrets Manager..."
    
    # Create temporary script to fetch secrets
    cat > fetch_secrets.sh << 'EOF'
#!/bin/bash
SECRET_NAME="app-delivery-framework/local/env"
REGION="us-west-2"

# Fetch secret from AWS Secrets Manager
SECRET_JSON=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    --query 'SecretString' \
    --output text 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$SECRET_JSON" ]; then
    # Parse JSON and convert to .env format
    echo "$SECRET_JSON" | jq -r 'to_entries[] | "\(.key)=\(.value)"' > .env.local
    echo "Successfully fetched secrets from AWS Secrets Manager"
else
    echo "Warning: Could not fetch secrets from AWS Secrets Manager"
    echo "Creating .env.local with default values..."
    
    # Create default .env file
    cat > .env.local << 'ENVEOF'
# Local Development Environment Variables
DRUPAL_ENV=development
PHP_MEMORY_LIMIT=512M
PHP_MAX_EXECUTION_TIME=300

# Database Configuration (MariaDB - matches Aurora MySQL in AWS)
DATABASE_URL=mysql://drupal:password@mariadb:3306/app_delivery_dev
DB_HOST=mariadb
DB_PORT=3306
DB_NAME=app_delivery_dev
DB_USER=drupal
DB_PASSWORD=password

# Valkey Configuration (Redis-compatible cache - matches AWS ElastiCache for Valkey)
VALKEY_URL=redis://valkey:6379
VALKEY_HOST=valkey
VALKEY_PORT=6379
REDIS_HOST=valkey
REDIS_PORT=6379

# JWT Configuration
JWT_SECRET=your-local-jwt-secret-change-this-in-production
JWT_EXPIRES_IN=24h

# API Keys (replace with real values)
API_KEY=local-development-api-key

# Feature Flags
ENABLE_DEBUG_LOGGING=true
ENABLE_HOT_RELOAD=true

# AWS Configuration for local development
AWS_REGION=us-west-2
AWS_ACCESS_KEY_ID=localstack
AWS_SECRET_ACCESS_KEY=localstack
AWS_ENDPOINT_URL=http://localstack:4566

# Application URLs
APP_URL=http://localhost:3000
API_URL=http://localhost:3000/api
ENVEOF
fi
EOF
    
    chmod +x fetch_secrets.sh
    bash fetch_secrets.sh
    rm fetch_secrets.sh
    
    print_success "Environment file created: $env_file"
}

# Function to setup Docker Compose
setup_docker_compose() {
    print_status "Setting up Docker Compose configuration..."
    
    # Create docker-compose.override.yml for local development
    cat > docker-compose.override.yml << 'EOF'
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: docker/Dockerfile
      target: development
    volumes:
      - .:/var/www/html
      - drupal_files:/var/www/html/sites/default/files
    ports:
      - "${LOCAL_PORT:-8080}:80"
    environment:
      - DRUPAL_ENV=development
      - PHP_MEMORY_LIMIT=512M
    env_file:
      - .env.local
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - app-delivery-local

volumes:
  drupal_files:
    driver: local

networks:
  app-delivery-local:
    driver: bridge

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - app-delivery-local

  # LocalStack for AWS services simulation
  localstack:
    image: localstack/localstack:latest
    environment:
      - SERVICES=s3,secretsmanager,sts,iam
      - DEBUG=1
      - DATA_DIR=/tmp/localstack/data
      - DOCKER_HOST=unix:///var/run/docker.sock
    ports:
      - "4566:4566"
    volumes:
      - localstack_data:/tmp/localstack
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - app-delivery-local

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
  localstack_data:
    driver: local

networks:
  app-delivery-local:
    driver: bridge
EOF
    
    print_success "Docker Compose override file created"
}

# Function to create database initialization script
setup_database_init() {
    print_status "Creating database initialization script..."
    
    cat > scripts/init-db.sql << 'EOF'
-- Database initialization script for Drupal development (MariaDB)
-- This script sets up the initial database schema and configurations

-- Create additional databases for testing
CREATE DATABASE IF NOT EXISTS app_delivery_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create additional users if needed
CREATE USER IF NOT EXISTS 'app_delivery_app'@'%' IDENTIFIED BY 'app_password';
GRANT ALL PRIVILEGES ON app_delivery_dev.* TO 'app_delivery_app'@'%';
GRANT ALL PRIVILEGES ON app_delivery_test.* TO 'app_delivery_app'@'%';

-- Ensure proper character set and collation for Drupal
ALTER DATABASE app_delivery_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER DATABASE app_delivery_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- MariaDB optimizations for Drupal
SET GLOBAL innodb_file_per_table = 1;
SET GLOBAL innodb_file_format = 'Barracuda';
SET GLOBAL innodb_large_prefix = 1;

-- Create a health check table
USE app_delivery_dev;
CREATE TABLE IF NOT EXISTS health_check (
    id INT AUTO_INCREMENT PRIMARY KEY,
    status VARCHAR(50) NOT NULL DEFAULT 'healthy',
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO health_check (status) VALUES ('healthy') ON DUPLICATE KEY UPDATE status='healthy';

-- Grant usage on extensions
GRANT USAGE ON SCHEMA public TO app_delivery_app;
GRANT CREATE ON SCHEMA public TO app_delivery_app;

-- Example table structure (adjust according to your application)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO users (email, name) VALUES
    ('admin@example.com', 'Admin User'),
    ('developer@example.com', 'Developer User'),
    ('user@example.com', 'Regular User')
ON CONFLICT (email) DO NOTHING;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
EOF
    
    print_success "Database initialization script created"
}

# Function to build and start services
start_services() {
    print_status "Building and starting services..."
    
    # Build the application image
    docker-compose build
    
    # Start all services
    docker-compose up -d
    
    print_status "Waiting for services to be ready..."
    
    # Wait for database to be ready
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker-compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
            break
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    
    if [ $attempt -eq $max_attempts ]; then
        print_error "Database failed to start within expected time"
        exit 1
    fi
    
    # Wait for application to be ready
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if curl -s "http://localhost:${LOCAL_PORT}/health" >/dev/null 2>&1; then
            break
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    
    if [ $attempt -eq $max_attempts ]; then
        print_warning "Application may not be ready yet, but services are running"
    fi
    
    print_success "Services are running!"
}

# Function to run database migrations
run_migrations() {
    print_status "Running database migrations..."
    
    # Check if migrations directory exists
    if [[ -d "migrations" ]] || [[ -d "prisma" ]] || [[ -d "database/migrations" ]]; then
        # Run migrations inside the container
        docker-compose exec app npm run migrate || \
        docker-compose exec app npx prisma migrate dev || \
        docker-compose exec app npx sequelize-cli db:migrate || \
        print_warning "Could not run migrations automatically. Please run them manually."
    else
        print_warning "No migration directory found. Skipping migrations."
    fi
}

# Function to display helpful information
display_info() {
    print_success "🚀 Local development environment is ready!"
    echo
    echo -e "${BLUE}Application URLs:${NC}"
    echo "  • Main site: http://localhost:${LOCAL_PORT:-8080}"
    echo "  • Health check: http://localhost:${LOCAL_PORT:-8080}/health"
    echo "  • Drupal admin: http://localhost:${LOCAL_PORT:-8080}/admin"
    echo
    echo -e "${BLUE}Database Connection (MariaDB):${NC}"
    echo "  • Host: localhost"
    echo "  • Port: 3306"
    echo "  • Database: app_delivery_dev"
    echo "  • Username: drupal"
    echo "  • Password: password"
    echo
    echo -e "${BLUE}Valkey Cache Connection:${NC}"
    echo "  • Host: localhost"
    echo "  • Port: 6379"
    echo "  • Compatible with Redis clients"
    echo
    echo -e "${BLUE}LocalStack (AWS Services):${NC}"
    echo "  • Endpoint: http://localhost:4566"
    echo "  • Services: S3, Secrets Manager, STS, IAM"
    echo
    echo -e "${BLUE}Useful Commands:${NC}"
    echo "  • View logs: docker-compose logs -f"
    echo "  • Stop services: docker-compose down"
    echo "  • Restart services: docker-compose restart"
    echo "  • Shell into app: docker-compose exec app bash"
    echo "  • Database shell: docker-compose exec mariadb mysql -u drupal -ppassword app_delivery_dev"
    echo "  • Valkey shell: docker-compose exec valkey valkey-cli"
    echo "  • Drush commands: docker-compose exec app drush [command]"
    echo "  • Install Drupal: docker-compose exec app drush site-install"
    echo
    echo -e "${YELLOW}Note: Environment variables are loaded from .env.local${NC}"
    echo -e "${YELLOW}Modify docker-compose.override.yml to customize your local setup${NC}"
}

# Function to create helpful scripts
create_helper_scripts() {
    print_status "Creating helper scripts..."
    
    # Create a script to easily run common commands
    cat > scripts/dev.sh << 'EOF'
#!/bin/bash
# Developer helper script

set -e

case "$1" in
    start)
        echo "Starting development environment..."
        docker-compose up -d
        ;;
    stop)
        echo "Stopping development environment..."
        docker-compose down
        ;;
    restart)
        echo "Restarting development environment..."
        docker-compose restart
        ;;
    logs)
        docker-compose logs -f "${2:-app}"
        ;;
    shell)
        docker-compose exec "${2:-app}" bash
        ;;
    db)
        docker-compose exec mariadb mysql -u drupal -ppassword app_delivery_dev
        ;;
    valkey)
        docker-compose exec valkey valkey-cli
        ;;
    redis)
        docker-compose exec valkey valkey-cli
        ;;
    migrate)
        docker-compose exec app drush updb -y
        ;;
    install)
        docker-compose exec app drush site-install standard --account-name=admin --account-pass=admin --site-name="App Delivery Framework" -y
        ;;
    cache-clear)
        docker-compose exec app drush cr
        ;;
    config-export)
        docker-compose exec app drush cex -y
        ;;
    config-import)
        docker-compose exec app drush cim -y
        ;;
    test)
        docker-compose exec app vendor/bin/phpunit
        ;;
    build)
        docker-compose build
        ;;
    clean)
        echo "Cleaning up Docker resources..."
        docker-compose down -v
        docker system prune -f
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs|shell|db|valkey|redis|install|migrate|cache-clear|config-export|config-import|test|build|clean}"
        echo ""
        echo "Commands:"
        echo "  start         - Start all services"
        echo "  stop          - Stop all services"
        echo "  restart       - Restart all services"
        echo "  logs          - Show logs (optionally specify service)"
        echo "  shell         - Open shell in container (default: app)"
        echo "  db            - Open MariaDB shell"
        echo "  valkey        - Open Valkey CLI"
        echo "  redis         - Open Valkey CLI (alias)"
        echo "  install       - Install Drupal"
        echo "  migrate       - Run database updates"
        echo "  cache-clear   - Clear Drupal cache"
        echo "  config-export - Export Drupal configuration"
        echo "  config-import - Import Drupal configuration"
        echo "  test          - Run PHPUnit tests"
        echo "  build         - Build application image"
        echo "  clean         - Clean up all resources"
        exit 1
        ;;
esac
EOF
    
    chmod +x scripts/dev.sh
    
    print_success "Helper scripts created in scripts/dev.sh"
}

# Main execution
main() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║              App Delivery Framework Local Setup                 ║"
    echo "║                                                                  ║"
    echo "║  This script will set up your local development environment     ║"
    echo "║  with all necessary services and configurations.                 ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
    
    check_prerequisites
    setup_aws_credentials
    setup_environment_file
    setup_docker_compose
    setup_database_init
    create_helper_scripts
    start_services
    run_migrations
    display_info
    
    echo
    print_success "Setup complete! Happy coding! 🎉"
}

# Run main function
main "$@"
