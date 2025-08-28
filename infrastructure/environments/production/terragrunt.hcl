# Production Environment Configuration
# This file configures the production environment using Terragrunt

include "root" {
  path = find_in_parent_folders()
}

# Dependencies - these modules must be applied first
dependencies {
  paths = ["../shared/networking", "../shared/security", "../shared/monitoring"]
}

locals {
  # Environment-specific configuration
  environment = "production"
  
  # Load common variables
  common_vars = yamldecode(file("${find_in_parent_folders("common.yaml")}"))
  
  # Production-specific overrides
  production_config = {
    # Compute configuration
    min_capacity = 2
    max_capacity = 20
    desired_count = 3
    
    # Resource allocation
    cpu = 512
    memory = 1024
    
    # Auto-scaling thresholds
    cpu_target = 70
    memory_target = 80
    
    # Database configuration
    db_instance_class = "db.serverless"
    db_min_capacity = 0.5
    db_max_capacity = 16
    backup_retention_period = 35
    
    # Cache configuration
    cache_node_type = "cache.serverless"
    
    # Domain configuration
    domain_name = "app.${local.common_vars.root_domain}"
    certificate_arn = "arn:aws:acm:us-west-2:${get_aws_account_id()}:certificate/${local.common_vars.ssl_certificate_id}"
    
    # Security configuration
    enable_waf = true
    enable_shield_advanced = false # Enable for DDoS protection (additional cost)
    
    # Monitoring configuration
    log_level = "warn"
    enable_xray = true
    enable_detailed_monitoring = true
    
    # Cost optimization
    enable_scheduled_scaling = true
    scheduled_min_capacity_night = 1
    scheduled_max_capacity_night = 5
  }
}

# Input variables
inputs = merge(
  local.common_vars,
  local.production_config,
  {
    environment = local.environment
    
    # Container image (will be overridden by CI/CD)
    container_image = "${local.common_vars.ecr_repository}:latest"
    
    # Network configuration
    vpc_id = dependency.networking.outputs.vpc_id
    private_subnet_ids = dependency.networking.outputs.private_subnet_ids
    public_subnet_ids = dependency.networking.outputs.public_subnet_ids
    
    # Security groups
    security_group_ids = dependency.security.outputs.security_group_ids
    
    # Monitoring
    sns_topic_arn = dependency.monitoring.outputs.alerts_topic_arn
    
    # Database
    database_subnet_group = dependency.networking.outputs.database_subnet_group_name
    
    # Load balancer
    load_balancer_arn = dependency.networking.outputs.load_balancer_arn
    load_balancer_listener_arn = dependency.networking.outputs.https_listener_arn
    load_balancer_security_group_id = dependency.security.outputs.load_balancer_security_group_id
    
    # Route53
    hosted_zone_id = local.common_vars.hosted_zone_id
    
    # Secrets
    secrets_kms_key_id = dependency.security.outputs.secrets_kms_key_id
  }
)

# Generate backend configuration
generate "backend" {
  path = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  backend "s3" {
    bucket         = "${local.common_vars.project_name}-terraform-state-${get_aws_account_id()}"
    key            = "environments/production/terraform.tfstate"
    region         = "${local.common_vars.aws_region}"
    encrypt        = true
    dynamodb_table = "${local.common_vars.project_name}-terraform-locks"
  }
}
EOF
}

# Terraform configuration
terraform {
  source = "../../modules//ecs-service"
}

# Before/after hooks for production safety
terraform {
  before_hook "production_safety_check" {
    commands = ["apply", "plan"]
    execute = ["bash", "-c", <<-EOF
      echo "🔒 Production Environment Safety Check"
      echo "Environment: ${local.environment}"
      echo "Account ID: $(aws sts get-caller-identity --query Account --output text)"
      echo "Region: ${local.common_vars.aws_region}"
      echo ""
      
      # Verify we're in the correct AWS account
      CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
      EXPECTED_ACCOUNT="${local.common_vars.production_account_id}"
      
      if [[ "$CURRENT_ACCOUNT" != "$EXPECTED_ACCOUNT" ]]; then
        echo "❌ ERROR: Wrong AWS account!"
        echo "Current: $CURRENT_ACCOUNT"
        echo "Expected: $EXPECTED_ACCOUNT"
        exit 1
      fi
      
      echo "✅ AWS account verified"
      
      # Check for required tags
      if [[ "${local.production_config.enable_deletion_protection}" == "true" ]]; then
        echo "✅ Deletion protection enabled"
      fi
      
      echo "✅ Safety checks passed"
    EOF
    ]
  }
  
  after_hook "production_validation" {
    commands = ["apply"]
    execute = ["bash", "-c", <<-EOF
      echo "🚀 Production Deployment Validation"
      
      # Wait for service to be stable
      echo "Waiting for ECS service to stabilize..."
      aws ecs wait services-stable \
        --cluster "${local.common_vars.project_name}-${local.environment}" \
        --services "web-app" \
        --region "${local.common_vars.aws_region}"
      
      # Validate health checks
      echo "Validating health checks..."
      HEALTH_URL="https://${local.production_config.domain_name}/health"
      
      for i in {1..10}; do
        if curl -f "$HEALTH_URL" >/dev/null 2>&1; then
          echo "✅ Health check passed"
          break
        fi
        echo "Attempt $i: Health check failed, retrying in 30s..."
        sleep 30
      done
      
      # Send notification (implement your notification logic here)
      echo "📢 Production deployment completed successfully"
      
      # Update deployment tracking
      echo "$(date): Production deployment successful" >> deployment-log.txt
    EOF
    ]
  }
}

# Skip certain operations in CI/CD for faster execution
skip_outputs = get_env("CI", "") != ""
