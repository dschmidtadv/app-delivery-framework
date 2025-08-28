variable "repository_name" {
  description = "The name of the GitHub repository"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token with repo and admin:repo_hook permissions"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub repository owner (username or organization)"
  type        = string
  default     = "dschmidtadv"
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID for GitHub Actions"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for GitHub Actions"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region for deployments"
  type        = string
  default     = "us-east-1"
}

variable "ecr_registry" {
  description = "ECR registry URL"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "rds_endpoint" {
  description = "RDS Aurora endpoint"
  type        = string
}

variable "cache_endpoint" {
  description = "ElastiCache Valkey endpoint"
  type        = string
}

variable "database_password" {
  description = "Database password for development/staging"
  type        = string
  sensitive   = true
}

variable "drupal_hash_salt" {
  description = "Drupal hash salt for development/staging"
  type        = string
  sensitive   = true
}

variable "prod_database_password" {
  description = "Production database password"
  type        = string
  sensitive   = true
}

variable "prod_drupal_hash_salt" {
  description = "Production Drupal hash salt"
  type        = string
  sensitive   = true
}

variable "staging_database_password" {
  description = "Staging database password"
  type        = string
  sensitive   = true
}

variable "staging_drupal_hash_salt" {
  description = "Staging Drupal hash salt"
  type        = string
  sensitive   = true
}

variable "dev_database_password" {
  description = "Development database password"
  type        = string
  sensitive   = true
}

variable "dev_drupal_hash_salt" {
  description = "Development Drupal hash salt"
  type        = string
  sensitive   = true
}

variable "production_reviewers" {
  description = "List of GitHub usernames required to review production deployments"
  type        = list(string)
  default     = []
}

variable "required_reviewers" {
  description = "Number of required reviewers for pull requests"
  type        = number
  default     = 1
}

variable "terraform_api_token" {
  description = "Terraform Cloud/Enterprise API token (optional)"
  type        = string
  sensitive   = true
  default     = null
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications (optional)"
  type        = string
  sensitive   = true
  default     = null
}

variable "deployment_webhook_url" {
  description = "Webhook URL for deployment notifications (optional)"
  type        = string
  default     = null
}

variable "deployment_webhook_secret" {
  description = "Secret for deployment webhook (optional)"
  type        = string
  sensitive   = true
  default     = null
}
