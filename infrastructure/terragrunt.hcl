# Terragrunt Configuration for Multi-Environment Management
# This file defines common configuration that gets inherited by all environments

# Remote state configuration - shared across all environments
remote_state {
  backend = "s3"
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  
  config = {
    bucket         = "${get_env("PROJECT_NAME", "app-delivery-framework")}-terraform-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "${get_env("PROJECT_NAME", "app-delivery-framework")}-terraform-locks"
  }
}

# Common variables that all environments will use
inputs = {
  project_name = get_env("PROJECT_NAME", "app-delivery-framework")
  team_name    = get_env("TEAM_NAME", "platform-team")
  cost_center  = get_env("COST_CENTER", "engineering")
  
  # Common networking configuration
  vpc_cidr = "10.0.0.0/16"
  
  # Common tags applied to all resources
  common_tags = {
    Project    = get_env("PROJECT_NAME", "app-delivery-framework")
    ManagedBy  = "Terraform"
    Repository = "https://github.com/yourorg/app-delivery-framework"
  }
  
  # Domain configuration
  root_domain = get_env("ROOT_DOMAIN", "yourdomain.com")
  
  # Monitoring configuration
  enable_detailed_monitoring = true
  log_retention_days        = 30
  
  # Security configuration
  enable_encryption = true
  deletion_protection = true
}

# Retry configuration for flaky AWS API calls
retryable_errors = [
  "(?s).*RequestLimitExceeded.*",
  "(?s).*Throttling.*",
  "(?s).*TooManyRequestsException.*"
]
