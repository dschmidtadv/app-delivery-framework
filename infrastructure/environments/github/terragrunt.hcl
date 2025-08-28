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
  profile = "terraform-user"  # Use your terraform-user profile
}
EOF
}

# Local values to read AWS credentials from local config
locals {
  # AWS profile to use
  aws_profile = "terraform-user"
}

inputs = {
  # Repository configuration
  repository_name = "app-delivery-framework"
  aws_region      = "us-east-1"
  
  # GitHub configuration (set these as environment variables)
  github_token = get_env("GITHUB_TOKEN", "")
  github_owner = get_env("GITHUB_OWNER", "dschmidtadv")
  
  # AWS credentials for GitHub Actions (read from environment or use static for demo)
  aws_access_key_id     = get_env("AWS_ACCESS_KEY_ID", "")
  aws_secret_access_key = get_env("AWS_SECRET_ACCESS_KEY", "")
  
  # Infrastructure endpoints (using static values for initial setup)
  ecr_registry      = "123456789012.dkr.ecr.us-east-1.amazonaws.com"
  ecs_cluster_name  = "app-delivery-framework-prod"
  ecs_service_name  = "app-service-prod"
  rds_endpoint      = "app-db-prod.cluster-xyz.us-east-1.rds.amazonaws.com"
  cache_endpoint    = "app-cache-prod.xyz.cache.amazonaws.com"
  
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
  terraform_api_token = get_env("TF_API_TOKEN", "") != "" ? get_env("TF_API_TOKEN", "") : null
  slack_webhook_url   = get_env("SLACK_WEBHOOK_URL", "") != "" ? get_env("SLACK_WEBHOOK_URL", "") : null
  
  # Deployment webhooks (optional)
  deployment_webhook_url    = get_env("DEPLOYMENT_WEBHOOK_URL", "") != "" ? get_env("DEPLOYMENT_WEBHOOK_URL", "") : null
  deployment_webhook_secret = get_env("DEPLOYMENT_WEBHOOK_SECRET", "") != "" ? get_env("DEPLOYMENT_WEBHOOK_SECRET", "") : null
}
