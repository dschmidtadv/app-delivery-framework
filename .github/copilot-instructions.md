# Copilot Instructions for AI Coding Agents

This repository is a blueprint for a modern application delivery framework using AWS, Terraform, ECS, and GitHub. Follow these guidelines to be productive and maintain project conventions.

## Architecture Overview
- **Infrastructure as Code:** All AWS resources are provisioned via Terraform. Use a folder-based structure (e.g., Terragrunt) for DRY environment configs.
- **Container Orchestration:** Applications run on AWS ECS (Fargate for serverless). Docker is used for building and local development.
- **CI/CD:** GitHub Actions automate builds, tests, deployments, and environment management.
- **Serverless-First:** Prefer AWS serverless services (Fargate, Aurora Serverless v2, ElastiCache for Valkey, CloudFront, Secrets Manager).

## Key Developer Workflows
- **CI/CD Pipeline:**
  - Triggered on `git push` and pull requests.
  - Builds Docker images, pushes to AWS ECR.
  - Deploys to ECS using environment-specific configs.
  - Creates ephemeral environments for PRs; destroys on merge/close.
  - Blue/green deployments and automated/manual rollbacks.
- **Environment Management:**
  - Use branching and environment variables to manage staging/production/dev.
  - Aurora Serverless v2 is used for shared RDS; schema isolation and data seeding strategies are required.
  - Automated scripts for copying databases/files between environments.
- **Local Development:**
  - Use Docker Compose to mirror production locally.
  - Secrets are fetched from AWS Secrets Manager (never hardcoded).

## Project-Specific Patterns
- **Terraform Structure:**
  - Organize by environment folders (e.g., `/environments/staging`, `/environments/production`).
  - Use Terragrunt or similar for config inheritance and DRY principles.
- **Secrets Management:**
  - All secrets (DB credentials, API keys) are stored in AWS Secrets Manager.
  - Scripts/utilities must fetch secrets securely for local and CI/CD use.
- **Database Handling:**
  - Aurora Serverless v2 is the default RDS engine.
  - Prefer schema isolation for ephemeral/dev environments.
  - Data seeding uses anonymized production data or fixtures.
- **Deployment Strategies:**
  - Blue/green deployments for app and DB.
  - Rollback is automated on failure, with manual override possible.
- **CDN and Caching:**
  - CloudFront is provisioned via Terraform and integrated with ALB and ACM for SSL.
  - ElastiCache for Valkey is used for scalable, serverless caching.

## Example File/Directory References
- `prompt.md`: Architectural requirements and workflow details.
- `.github/`: Place CI/CD workflows and copilot instructions here.
- `/environments/`: Organize Terraform configs by environment.

## Conventions
- Never hardcode secrets; always use AWS Secrets Manager.
- Keep environment configs DRY using inheritance tools (Terragrunt).
- Use ephemeral environments for PRs and destroy them after merge/close.
- Prefer serverless AWS services for all components.

---

For questions or unclear patterns, review `prompt.md` or ask for clarification. Update this file as new conventions emerge.
