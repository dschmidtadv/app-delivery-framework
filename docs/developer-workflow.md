# Developer Workflow Guide
# Comprehensive guide for developers working with the App Delivery Framework

## Getting Started

### Prerequisites
Before you begin, ensure you have the following installed:
- Docker Desktop (latest version)
- Node.js (version 18 or higher)
- AWS CLI (configured with appropriate permissions)
- Git
- curl (for testing endpoints)

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourorg/app-delivery-framework.git
   cd app-delivery-framework
   ```

2. **Run the local setup script:**
   ```bash
   chmod +x scripts/local-setup.sh
   ./scripts/local-setup.sh
   ```

3. **Verify the setup:**
   ```bash
   curl http://localhost:3000/health
   ```

## Daily Development Workflow

### Starting Your Development Environment

```bash
# Start all services
./scripts/dev.sh start

# View logs
./scripts/dev.sh logs

# Or start with docker-compose directly
docker-compose up -d
```

### Making Code Changes

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** - The application will automatically reload thanks to hot reloading

3. **Run tests locally:**
   ```bash
   ./scripts/dev.sh test
   ```

4. **Check the health endpoint:**
   ```bash
   curl http://localhost:3000/health
   ```

### Working with the Database

#### Connecting to the Database
```bash
# Open PostgreSQL shell
./scripts/dev.sh db

# Or use external tools
# Host: localhost
# Port: 5432
# Database: app_delivery_dev
# Username: postgres
# Password: password
```

#### Running Migrations
```bash
# Run database migrations
./scripts/dev.sh migrate

# Or manually
docker-compose exec app npm run migrate
```

#### Seeding Data
```bash
# Seed the database with test data
./scripts/dev.sh seed
```

### Working with Redis

```bash
# Open Redis CLI
./scripts/dev.sh redis

# Test Redis connection
redis-cli ping
```

## Testing Strategy

### Unit Tests
```bash
# Run unit tests
npm test

# Run tests with coverage
npm run test:coverage

# Run tests in watch mode
npm run test:watch
```

### Integration Tests
```bash
# Run integration tests
npm run test:integration

# Run against local environment
TEST_BASE_URL=http://localhost:3000 npm run test:integration
```

### End-to-End Tests
```bash
# Run E2E tests
npm run test:e2e

# Run E2E tests against ephemeral environment
TEST_BASE_URL=https://pr-123.yourdomain.com npm run test:e2e
```

## Deployment Workflows

### Feature Development (PR-based Ephemeral Environments)

1. **Create a pull request:**
   - Push your feature branch to GitHub
   - Create a pull request against `main` or `staging`
   - An ephemeral environment will be automatically created

2. **Test your changes:**
   - Check the PR comment for the environment URL
   - Run integration tests against the ephemeral environment
   - Perform manual testing

3. **Merge when ready:**
   - Once approved, merge the PR
   - The ephemeral environment will be automatically destroyed

### Staging Deployment

1. **Merge to staging branch:**
   ```bash
   git checkout staging
   git merge main
   git push origin staging
   ```

2. **Monitor the deployment:**
   - Check GitHub Actions for deployment status
   - Verify the staging environment: https://staging.yourdomain.com

### Production Deployment

1. **Create a release:**
   ```bash
   git checkout main
   git tag -a v1.2.3 -m "Release version 1.2.3"
   git push origin v1.2.3
   ```

2. **Monitor the production deployment:**
   - Check GitHub Actions for deployment status
   - Verify the production environment: https://app.yourdomain.com
   - Monitor metrics and logs

## Environment Management

### Environment Types

| Environment | Purpose | Branch | URL Pattern | Auto-Deploy |
|-------------|---------|--------|-------------|-------------|
| Local | Development | any | localhost:3000 | N/A |
| Ephemeral | PR Testing | feature/* | pr-{number}.yourdomain.com | Yes |
| Staging | Integration Testing | staging | staging.yourdomain.com | Yes |
| Production | Live Application | main | app.yourdomain.com | Yes |

### Environment Configuration

Each environment has specific configurations:

#### Local Development
- **Resources:** Minimal (shared Docker containers)
- **Database:** Local PostgreSQL with test data
- **Cache:** Local Redis
- **Monitoring:** Basic logging
- **Debug:** Full debug logging enabled

#### Ephemeral (PR Environments)
- **Resources:** 256 CPU, 512MB RAM, 1 instance
- **Database:** Shared Aurora with isolated schema
- **Cache:** Shared ElastiCache
- **Monitoring:** Basic CloudWatch
- **Lifecycle:** Auto-created on PR, destroyed on merge/close
- **Timeout:** 7 days maximum

#### Staging
- **Resources:** 512 CPU, 1GB RAM, 2-5 instances
- **Database:** Aurora Serverless v2 (shared with prod structure)
- **Cache:** ElastiCache for Valkey
- **Monitoring:** Full CloudWatch + alerts
- **Data:** Anonymized production data

#### Production
- **Resources:** 512 CPU, 1GB RAM, 2-20 instances (auto-scaling)
- **Database:** Aurora Serverless v2 with read replicas
- **Cache:** ElastiCache for Valkey with cluster mode
- **Monitoring:** Full observability stack
- **Backup:** Daily automated backups
- **Security:** WAF, SSL, encryption at rest/transit

## Debugging and Troubleshooting

### Application Logs

```bash
# View application logs
./scripts/dev.sh logs app

# View all services logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f postgres
docker-compose logs -f redis
```

### Database Debugging

```bash
# Check database connection
docker-compose exec app node -e "
const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
pool.query('SELECT NOW()', (err, res) => {
  console.log(err ? err : res.rows[0]);
  pool.end();
});
"

# Check database tables
./scripts/dev.sh db
\dt
```

### Performance Debugging

```bash
# Check container resource usage
docker stats

# Check application metrics
curl http://localhost:3000/metrics

# Monitor database performance
docker-compose exec postgres psql -U postgres -d app_delivery_dev -c "
SELECT query, calls, total_time, mean_time 
FROM pg_stat_statements 
ORDER BY total_time DESC 
LIMIT 10;
"
```

### Remote Environment Debugging

#### Staging/Production Log Access
```bash
# AWS CLI access to CloudWatch logs
aws logs tail /ecs/app-delivery-framework/production/web-app --follow

# Get recent errors
aws logs filter-log-events \
  --log-group-name "/ecs/app-delivery-framework/production/web-app" \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s)000
```

#### ECS Task Debugging
```bash
# List running tasks
aws ecs list-tasks --cluster app-delivery-framework-production

# Get task details
aws ecs describe-tasks \
  --cluster app-delivery-framework-production \
  --tasks <task-arn>

# Execute command in running container
aws ecs execute-command \
  --cluster app-delivery-framework-production \
  --task <task-arn> \
  --container web-app \
  --interactive \
  --command "/bin/bash"
```

## Common Issues and Solutions

### Port Already in Use
```bash
# Find process using port 3000
lsof -ti:3000

# Kill the process
kill -9 $(lsof -ti:3000)

# Or use a different port
LOCAL_PORT=3001 docker-compose up
```

### Database Connection Issues
```bash
# Reset database
docker-compose down -v
docker-compose up -d postgres
# Wait for database to be ready
./scripts/dev.sh migrate
```

### AWS Credentials Issues
```bash
# Check current credentials
aws sts get-caller-identity

# Refresh SSO credentials
aws sso login

# Check permissions
aws iam get-user
```

### Build Issues
```bash
# Clear Docker cache
docker system prune -f

# Rebuild without cache
docker-compose build --no-cache app

# Clear Node modules
docker-compose exec app rm -rf node_modules
docker-compose exec app npm install
```

## Security Best Practices

### Local Development Security

1. **Never commit secrets** - Use `.env.local` for local secrets
2. **Use AWS Secrets Manager** - Fetch secrets dynamically
3. **Rotate local credentials** - Regular AWS credential rotation
4. **Scan dependencies** - Use `npm audit` regularly

### Code Security

```bash
# Run security audit
npm audit

# Fix vulnerabilities
npm audit fix

# Check for hardcoded secrets
git secrets --scan

# Lint for security issues
npm run lint:security
```

## Performance Optimization

### Local Development Performance

1. **Use Docker volume caching:**
   ```yaml
   volumes:
     - .:/app:cached
   ```

2. **Enable polling for file watching:**
   ```bash
   export CHOKIDAR_USEPOLLING=true
   ```

3. **Allocate more resources to Docker Desktop:**
   - Memory: 4GB minimum
   - CPU: 4 cores minimum

### Application Performance

1. **Database query optimization:**
   ```bash
   # Enable query logging
   docker-compose exec postgres psql -U postgres -c "
   ALTER SYSTEM SET log_statement = 'all';
   SELECT pg_reload_conf();
   "
   ```

2. **Cache optimization:**
   ```bash
   # Monitor Redis performance
   ./scripts/dev.sh redis
   INFO stats
   ```

3. **Monitor resource usage:**
   ```bash
   # Application metrics
   curl http://localhost:3000/metrics

   # Container metrics
   docker stats app-delivery-app
   ```

## Useful Commands Reference

### Docker Commands
```bash
# Remove all containers and volumes
docker-compose down -v

# Rebuild specific service
docker-compose build app

# View container logs
docker-compose logs -f app

# Shell into container
docker-compose exec app bash

# Restart specific service
docker-compose restart app
```

### Database Commands
```bash
# Database shell
docker-compose exec postgres psql -U postgres -d app_delivery_dev

# Create database backup
docker-compose exec postgres pg_dump -U postgres app_delivery_dev > backup.sql

# Restore database backup
docker-compose exec -T postgres psql -U postgres -d app_delivery_dev < backup.sql

# Check database size
docker-compose exec postgres psql -U postgres -c "
SELECT pg_database.datname,
       pg_database_size(pg_database.datname) as size
FROM pg_database;
"
```

### Git Commands
```bash
# Create feature branch
git checkout -b feature/your-feature

# Interactive rebase
git rebase -i HEAD~3

# Squash commits
git reset --soft HEAD~3
git commit -m "Your consolidated commit message"

# Cherry-pick specific commit
git cherry-pick <commit-hash>
```

This workflow guide should help developers be productive quickly while maintaining consistency across the team.
