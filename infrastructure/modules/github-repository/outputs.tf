output "repository_name" {
  description = "The name of the GitHub repository"
  value       = var.repository_name
}

output "production_environment_name" {
  description = "The name of the production environment"
  value       = github_repository_environment.production.environment
}

output "staging_environment_name" {
  description = "The name of the staging environment"
  value       = github_repository_environment.staging.environment
}

# Commented out since branch protection is disabled
# output "main_branch_protection_id" {
#   description = "The ID of the main branch protection rule"
#   value       = github_branch_protection.main.id
# }

output "secrets_configured" {
  description = "List of configured GitHub Actions secrets"
  value = [
    "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY",
    "AWS_DEFAULT_REGION",
    "ECR_REGISTRY",
    "ECS_CLUSTER_NAME",
    "ECS_SERVICE_NAME",
    "RDS_ENDPOINT",
    "CACHE_ENDPOINT",
    "DATABASE_PASSWORD",
    "DRUPAL_HASH_SALT"
  ]
}

output "environments_configured" {
  description = "List of configured GitHub environments"
  value = [
    github_repository_environment.production.environment,
    github_repository_environment.staging.environment
  ]
}
