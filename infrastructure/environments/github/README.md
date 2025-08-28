# GitHub Secrets Management with Terraform

This module manages GitHub repository secrets, environments, and branch protection rules using Terraform. It ensures that your CI/CD pipelines have secure access to AWS resources and environment-specific configurations.

## Overview

The Terraform configuration in this directory will:

1. **Set up GitHub Actions secrets** for AWS access and application configuration
2. **Create GitHub environments** (production, staging) with protection rules
3. **Configure branch protection** for the main branch
4. **Set up environment-specific secrets** for different deployment targets

## Prerequisites

### 1. GitHub Personal Access Token

Create a GitHub Personal Access Token with the following permissions:
- `repo` (Full control of private repositories)
- `admin:repo_hook` (Full control of repository hooks)
- `admin:org` (Full control of organizations - if using organization repositories)

### 2. AWS IAM User for GitHub Actions

Create an IAM user specifically for GitHub Actions with the following policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:PutImage"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:UpdateService",
                "ecs:DescribeServices",
                "ecs:DescribeTaskDefinition",
                "ecs:RegisterTaskDefinition"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "arn:aws:iam::*:role/ecsTaskExecutionRole"
        }
    ]
}
```

### 3. Environment Variables

Set up the following environment variables before running Terraform:

```bash
# GitHub configuration
export TF_VAR_github_token="ghp_xxxxxxxxxxxxxxxxxxxx"
export TF_VAR_github_owner="your-github-username"

# AWS credentials for GitHub Actions
export GITHUB_AWS_ACCESS_KEY_ID="AKIAXXXXXXXXXXXXXXXXX"
export GITHUB_AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Database passwords (use strong, unique passwords)
export DATABASE_PASSWORD="development_secure_password_123"
export STAGING_DATABASE_PASSWORD="staging_secure_password_456"
export PROD_DATABASE_PASSWORD="production_secure_password_789"

# Drupal hash salts (generate unique salts for each environment)
export DRUPAL_HASH_SALT="development_salt_abcdefghijklmnopqrstuvwxyz123456"
export STAGING_DRUPAL_HASH_SALT="staging_salt_zyxwvutsrqponmlkjihgfedcba654321"
export PROD_DRUPAL_HASH_SALT="production_salt_mnbvcxzasdfghjklpoiuytrewq987654"

# Optional: Terraform Cloud token
export TF_API_TOKEN="your-terraform-cloud-token"

# Optional: Slack webhook for notifications
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
```

## Quick Start

1. **Navigate to the GitHub environment directory:**
   ```bash
   cd infrastructure/environments/github
   ```

2. **Set environment variables:**
   ```bash
   source ../../../scripts/setup-github-secrets.sh  # We'll create this script
   ```

3. **Initialize and apply Terraform:**
   ```bash
   terragrunt init
   terragrunt plan
   terragrunt apply
   ```

## Generated Secrets

The following secrets will be created in your GitHub repository:

### Repository Secrets (Available to all workflows)
- `AWS_ACCESS_KEY_ID` - AWS access key for deployments
- `AWS_SECRET_ACCESS_KEY` - AWS secret key for deployments  
- `AWS_DEFAULT_REGION` - AWS region (default: us-east-1)
- `ECR_REGISTRY` - ECR registry URL for Docker images
- `ECS_CLUSTER_NAME` - ECS cluster name for deployments
- `ECS_SERVICE_NAME` - ECS service name for deployments
- `RDS_ENDPOINT` - Database endpoint
- `CACHE_ENDPOINT` - Cache endpoint (Valkey/Redis)
- `DATABASE_PASSWORD` - Development/staging database password
- `DRUPAL_HASH_SALT` - Development/staging Drupal hash salt

### Environment-Specific Secrets

#### Production Environment
- `DATABASE_PASSWORD` - Production database password
- `DRUPAL_HASH_SALT` - Production Drupal hash salt

#### Staging Environment  
- `DATABASE_PASSWORD` - Staging database password
- `DRUPAL_HASH_SALT` - Staging Drupal hash salt

## Security Features

### Branch Protection
- **Required status checks** before merging to main
- **Required pull request reviews** (configurable number)
- **Dismiss stale reviews** when new commits are pushed
- **Require code owner reviews** for sensitive changes
- **Require conversation resolution** before merging

### Environment Protection
- **Production environment** requires manual approval from specified reviewers
- **Staging environment** allows automatic deployments
- **Branch restrictions** limit which branches can deploy to each environment

### Secret Management
- All sensitive values are marked as `sensitive` in Terraform
- Secrets are encrypted in GitHub
- Environment-specific secrets provide isolation between environments

## Customization

### Adding New Secrets

To add new secrets, modify `infrastructure/modules/github-repository/main.tf`:

```hcl
resource "github_actions_secret" "custom_secret" {
  repository      = var.repository_name
  secret_name     = "CUSTOM_SECRET"
  plaintext_value = var.custom_secret
}
```

Add the corresponding variable in `variables.tf`:

```hcl
variable "custom_secret" {
  description = "Custom secret description"
  type        = string
  sensitive   = true
}
```

### Modifying Branch Protection

Update the `github_branch_protection` resource in the main module to change:
- Required status checks
- Review requirements
- Admin enforcement

### Environment Configuration

Modify the `github_repository_environment` resources to:
- Add new environments
- Change deployment branch policies
- Update reviewer requirements

## Troubleshooting

### Common Issues

1. **Invalid GitHub token**: Ensure your token has the required permissions
2. **AWS credentials**: Verify the IAM user has the necessary policies
3. **Repository not found**: Check the repository name and GitHub owner
4. **Dependencies**: Ensure production and staging environments exist

### Validation Commands

```bash
# Check Terraform plan
terragrunt plan

# Validate configuration
terragrunt validate

# Show current state
terragrunt show

# List all secrets (after apply)
gh secret list --repo dschmidtadv/app-delivery-framework
```

## Next Steps

After setting up GitHub secrets:

1. **Update CI/CD workflows** to use the configured secrets
2. **Deploy infrastructure** using the production and staging environments
3. **Test deployments** to ensure secrets are working correctly
4. **Set up monitoring** for failed deployments and security alerts

## Security Best Practices

- Rotate secrets regularly (especially AWS access keys)
- Use least-privilege IAM policies
- Monitor secret usage in GitHub Actions logs
- Enable security alerts for the repository
- Use environment-specific secrets for isolation
- Consider using OIDC instead of long-lived AWS credentials
