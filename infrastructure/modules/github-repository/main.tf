terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# GitHub repository secrets for CI/CD
resource "github_actions_secret" "aws_access_key_id" {
  repository      = var.repository_name
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = var.aws_access_key_id
}

resource "github_actions_secret" "aws_secret_access_key" {
  repository      = var.repository_name
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = var.aws_secret_access_key
}

resource "github_actions_secret" "aws_region" {
  repository      = var.repository_name
  secret_name     = "AWS_DEFAULT_REGION"
  plaintext_value = var.aws_region
}

resource "github_actions_secret" "ecr_registry" {
  repository      = var.repository_name
  secret_name     = "ECR_REGISTRY"
  plaintext_value = var.ecr_registry
}

resource "github_actions_secret" "ecs_cluster_name" {
  repository      = var.repository_name
  secret_name     = "ECS_CLUSTER_NAME"
  plaintext_value = var.ecs_cluster_name
}

resource "github_actions_secret" "ecs_service_name" {
  repository      = var.repository_name
  secret_name     = "ECS_SERVICE_NAME"
  plaintext_value = var.ecs_service_name
}

resource "github_actions_secret" "rds_endpoint" {
  repository      = var.repository_name
  secret_name     = "RDS_ENDPOINT"
  plaintext_value = var.rds_endpoint
}

resource "github_actions_secret" "cache_endpoint" {
  repository      = var.repository_name
  secret_name     = "CACHE_ENDPOINT"
  plaintext_value = var.cache_endpoint
}

# Environment-specific secrets
resource "github_actions_secret" "database_password" {
  repository      = var.repository_name
  secret_name     = "DATABASE_PASSWORD"
  plaintext_value = var.database_password
}

resource "github_actions_secret" "drupal_hash_salt" {
  repository      = var.repository_name
  secret_name     = "DRUPAL_HASH_SALT"
  plaintext_value = var.drupal_hash_salt
}

# Terraform Cloud/Enterprise secrets (if using remote state)
resource "github_actions_secret" "terraform_api_token" {
  count           = var.terraform_api_token != null ? 1 : 0
  repository      = var.repository_name
  secret_name     = "TF_API_TOKEN"
  plaintext_value = var.terraform_api_token
}

# Slack notifications (optional)
resource "github_actions_secret" "slack_webhook_url" {
  count           = var.slack_webhook_url != null ? 1 : 0
  repository      = var.repository_name
  secret_name     = "SLACK_WEBHOOK_URL"
  plaintext_value = var.slack_webhook_url
}

# GitHub environment secrets for production
resource "github_repository_environment" "production" {
  repository  = var.repository_name
  environment = "production"

  # Require reviews for production deployments
  reviewers {
    users = var.production_reviewers
  }

  # Restrict to main branch only
  deployment_branch_policy {
    protected_branches     = true
    custom_branch_policies = false
  }
}

resource "github_actions_environment_secret" "prod_database_password" {
  repository    = var.repository_name
  environment   = github_repository_environment.production.environment
  secret_name   = "DATABASE_PASSWORD"
  plaintext_value = var.prod_database_password
}

resource "github_actions_environment_secret" "prod_drupal_hash_salt" {
  repository    = var.repository_name
  environment   = github_repository_environment.production.environment
  secret_name   = "DRUPAL_HASH_SALT"
  plaintext_value = var.prod_drupal_hash_salt
}

# Staging environment
resource "github_repository_environment" "staging" {
  repository  = var.repository_name
  environment = "staging"

  # Staging can be deployed from develop or main branches
  deployment_branch_policy {
    protected_branches     = true
    custom_branch_policies = true
  }
}

resource "github_actions_environment_secret" "staging_database_password" {
  repository    = var.repository_name
  environment   = github_repository_environment.staging.environment
  secret_name   = "DATABASE_PASSWORD"
  plaintext_value = var.staging_database_password
}

resource "github_actions_environment_secret" "staging_drupal_hash_salt" {
  repository    = var.repository_name
  environment   = github_repository_environment.staging.environment
  secret_name   = "DRUPAL_HASH_SALT"
  plaintext_value = var.staging_drupal_hash_salt
}

# Repository branch protection rules
resource "github_branch_protection" "main" {
  repository_id = var.repository_name
  pattern       = "main"

  required_status_checks {
    strict = true
    contexts = [
      "ci/tests",
      "ci/security-scan",
      "ci/build"
    ]
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = var.required_reviewers
  }

  enforce_admins                = false
  allows_deletions             = false
  allows_force_pushes          = false
  require_signed_commits       = false
  require_conversation_resolution = true
}

# Repository webhook for deployments (optional)
resource "github_repository_webhook" "deployment_webhook" {
  count      = var.deployment_webhook_url != null ? 1 : 0
  repository = var.repository_name

  configuration {
    url          = var.deployment_webhook_url
    content_type = "json"
    insecure_ssl = false
    secret       = var.deployment_webhook_secret
  }

  active = true

  events = [
    "deployment",
    "deployment_status",
    "push",
    "pull_request"
  ]
}
