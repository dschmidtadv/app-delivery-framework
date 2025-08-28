include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/github-repository"
}

# GitHub provider configuration
generate "github_provider" {
  path      = "github_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}
EOF
}

# AWS provider for getting outputs from other environments
generate "aws_provider" {
  path      = "aws_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = var.aws_region
}
EOF
}

# Data sources to get outputs from other environments
dependency "production" {
  config_path = "../production"
  mock_outputs = {
    ecr_registry_url     = "123456789012.dkr.ecr.us-east-1.amazonaws.com"
    ecs_cluster_name     = "app-delivery-framework-prod"
    ecs_service_name     = "app-service-prod"
    rds_endpoint         = "app-db-prod.cluster-xyz.us-east-1.rds.amazonaws.com"
    cache_endpoint       = "app-cache-prod.xyz.cache.amazonaws.com"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "staging" {
  config_path = "../staging"
  mock_outputs = {
    ecr_registry_url     = "123456789012.dkr.ecr.us-east-1.amazonaws.com"
    ecs_cluster_name     = "app-delivery-framework-staging"
    ecs_service_name     = "app-service-staging"
    rds_endpoint         = "app-db-staging.cluster-xyz.us-east-1.rds.amazonaws.com"
    cache_endpoint       = "app-cache-staging.xyz.cache.amazonaws.com"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  repository_name = "app-delivery-framework"
  aws_region      = "us-east-1"
  
  # AWS credentials for GitHub Actions (use environment variables or AWS IAM user)
  aws_access_key_id     = get_env("GITHUB_AWS_ACCESS_KEY_ID", "")
  aws_secret_access_key = get_env("GITHUB_AWS_SECRET_ACCESS_KEY", "")
  
  # Infrastructure outputs from production environment
  ecr_registry      = dependency.production.outputs.ecr_registry_url
  ecs_cluster_name  = dependency.production.outputs.ecs_cluster_name
  ecs_service_name  = dependency.production.outputs.ecs_service_name
  rds_endpoint      = dependency.production.outputs.rds_endpoint
  cache_endpoint    = dependency.production.outputs.cache_endpoint
  
  # Secrets (use environment variables or Terraform Cloud variables)
  database_password = get_env("DATABASE_PASSWORD", "development_password_123")
  drupal_hash_salt  = get_env("DRUPAL_HASH_SALT", "development_salt_123")
  
  prod_database_password = get_env("PROD_DATABASE_PASSWORD", "production_password_456")
  prod_drupal_hash_salt  = get_env("PROD_DRUPAL_HASH_SALT", "production_salt_456")
  
  staging_database_password = get_env("STAGING_DATABASE_PASSWORD", "staging_password_789")
  staging_drupal_hash_salt  = get_env("STAGING_DRUPAL_HASH_SALT", "staging_salt_789")
  
  # Repository settings
  production_reviewers = ["dschmidtadv"]  # Replace with actual GitHub usernames
  required_reviewers   = 1
  
  # Optional integrations
  terraform_api_token = get_env("TF_API_TOKEN", null)
  slack_webhook_url   = get_env("SLACK_WEBHOOK_URL", null)
  
  # Deployment webhooks (optional)
  deployment_webhook_url    = get_env("DEPLOYMENT_WEBHOOK_URL", null)
  deployment_webhook_secret = get_env("DEPLOYMENT_WEBHOOK_SECRET", null)
}
