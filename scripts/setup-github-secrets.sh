#!/bin/bash

# GitHub Secrets Setup Script
# This script helps you set up environment variables for Terraform to manage GitHub secrets

set -e

echo "🔐 GitHub Secrets Setup for Terraform"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to prompt for input with default value
prompt_input() {
    local var_name=$1
    local description=$2
    local default_value=$3
    local is_secret=$4
    
    if [ "$is_secret" = "true" ]; then
        echo -e "${BLUE}$description${NC}"
        read -s -p "Enter value (input hidden): " value
        echo
    else
        if [ -n "$default_value" ]; then
            read -p "$description [$default_value]: " value
            value=${value:-$default_value}
        else
            read -p "$description: " value
        fi
    fi
    
    if [ -n "$value" ]; then
        export $var_name="$value"
        echo -e "${GREEN}✓ $var_name set${NC}"
    else
        echo -e "${RED}✗ $var_name not set${NC}"
    fi
}

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to generate random salt
generate_salt() {
    openssl rand -base64 48 | tr -d "=+/" | cut -c1-55
}

echo
echo -e "${YELLOW}Step 1: GitHub Configuration${NC}"
echo "----------------------------------------"

# Check if GitHub CLI is installed and authenticated
if command -v gh &> /dev/null; then
    if gh auth status &> /dev/null; then
        echo -e "${GREEN}✓ GitHub CLI is authenticated${NC}"
        GITHUB_OWNER=$(gh api user --jq '.login')
        echo -e "Detected GitHub owner: ${GREEN}$GITHUB_OWNER${NC}"
        export TF_VAR_github_owner="$GITHUB_OWNER"
    else
        echo -e "${YELLOW}⚠ GitHub CLI not authenticated. Please run 'gh auth login' first.${NC}"
        prompt_input "TF_VAR_github_owner" "GitHub username or organization" "dschmidtadv" false
    fi
else
    echo -e "${YELLOW}⚠ GitHub CLI not found. Install it for easier setup.${NC}"
    prompt_input "TF_VAR_github_owner" "GitHub username or organization" "dschmidtadv" false
fi

prompt_input "TF_VAR_github_token" "GitHub Personal Access Token (needs repo, admin:repo_hook permissions)" "" true

echo
echo -e "${YELLOW}Step 2: AWS Credentials for GitHub Actions${NC}"
echo "----------------------------------------"
echo "These are AWS credentials that will be stored as GitHub secrets for CI/CD"

prompt_input "GITHUB_AWS_ACCESS_KEY_ID" "AWS Access Key ID for GitHub Actions" "" true
prompt_input "GITHUB_AWS_SECRET_ACCESS_KEY" "AWS Secret Access Key for GitHub Actions" "" true

echo
echo -e "${YELLOW}Step 3: Database Passwords${NC}"
echo "----------------------------------------"
echo "Generate secure passwords for each environment"

echo -e "${BLUE}Would you like to generate random passwords? (y/n)${NC}"
read -p "Generate passwords automatically? [y]: " auto_generate
auto_generate=${auto_generate:-y}

if [ "$auto_generate" = "y" ] || [ "$auto_generate" = "Y" ]; then
    echo -e "${GREEN}Generating secure passwords...${NC}"
    export DATABASE_PASSWORD=$(generate_password)
    export STAGING_DATABASE_PASSWORD=$(generate_password)
    export PROD_DATABASE_PASSWORD=$(generate_password)
    echo -e "${GREEN}✓ Database passwords generated${NC}"
else
    prompt_input "DATABASE_PASSWORD" "Development database password" "" true
    prompt_input "STAGING_DATABASE_PASSWORD" "Staging database password" "" true
    prompt_input "PROD_DATABASE_PASSWORD" "Production database password" "" true
fi

echo
echo -e "${YELLOW}Step 4: Drupal Hash Salts${NC}"
echo "----------------------------------------"
echo "Generate unique hash salts for Drupal security"

echo -e "${BLUE}Would you like to generate random hash salts? (y/n)${NC}"
read -p "Generate salts automatically? [y]: " auto_generate_salts
auto_generate_salts=${auto_generate_salts:-y}

if [ "$auto_generate_salts" = "y" ] || [ "$auto_generate_salts" = "Y" ]; then
    echo -e "${GREEN}Generating secure hash salts...${NC}"
    export DRUPAL_HASH_SALT=$(generate_salt)
    export STAGING_DRUPAL_HASH_SALT=$(generate_salt)
    export PROD_DRUPAL_HASH_SALT=$(generate_salt)
    echo -e "${GREEN}✓ Drupal hash salts generated${NC}"
else
    prompt_input "DRUPAL_HASH_SALT" "Development Drupal hash salt" "" true
    prompt_input "STAGING_DRUPAL_HASH_SALT" "Staging Drupal hash salt" "" true
    prompt_input "PROD_DRUPAL_HASH_SALT" "Production Drupal hash salt" "" true
fi

echo
echo -e "${YELLOW}Step 5: Optional Integrations${NC}"
echo "----------------------------------------"

echo -e "${BLUE}Configure optional integrations (press Enter to skip):${NC}"
prompt_input "TF_API_TOKEN" "Terraform Cloud API Token (optional)" "" true
prompt_input "SLACK_WEBHOOK_URL" "Slack Webhook URL for notifications (optional)" "" true

echo
echo -e "${GREEN}✅ Environment Variables Setup Complete!${NC}"
echo "===========================================" 

# Save to .env file for future use
ENV_FILE=".env.github-secrets"
echo -e "${BLUE}Saving configuration to $ENV_FILE${NC}"

cat > "$ENV_FILE" << EOF
# GitHub Configuration
export TF_VAR_github_token="$TF_VAR_github_token"
export TF_VAR_github_owner="$TF_VAR_github_owner"

# AWS Credentials for GitHub Actions
export GITHUB_AWS_ACCESS_KEY_ID="$GITHUB_AWS_ACCESS_KEY_ID"
export GITHUB_AWS_SECRET_ACCESS_KEY="$GITHUB_AWS_SECRET_ACCESS_KEY"

# Database Passwords
export DATABASE_PASSWORD="$DATABASE_PASSWORD"
export STAGING_DATABASE_PASSWORD="$STAGING_DATABASE_PASSWORD"
export PROD_DATABASE_PASSWORD="$PROD_DATABASE_PASSWORD"

# Drupal Hash Salts
export DRUPAL_HASH_SALT="$DRUPAL_HASH_SALT"
export STAGING_DRUPAL_HASH_SALT="$STAGING_DRUPAL_HASH_SALT"
export PROD_DRUPAL_HASH_SALT="$PROD_DRUPAL_HASH_SALT"

# Optional Integrations
export TF_API_TOKEN="$TF_API_TOKEN"
export SLACK_WEBHOOK_URL="$SLACK_WEBHOOK_URL"
EOF

echo -e "${GREEN}✓ Configuration saved to $ENV_FILE${NC}"
echo -e "${YELLOW}⚠ Keep this file secure and add it to .gitignore${NC}"

# Add to .gitignore if not already there
if ! grep -q ".env.github-secrets" ../../../.gitignore 2>/dev/null; then
    echo ".env.github-secrets" >> ../../../.gitignore
    echo -e "${GREEN}✓ Added $ENV_FILE to .gitignore${NC}"
fi

echo
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Review the generated $ENV_FILE file"
echo "2. Source the environment: source $ENV_FILE"
echo "3. Run terraform: terragrunt init && terragrunt apply"
echo "4. Verify secrets in GitHub: gh secret list --repo $TF_VAR_github_owner/app-delivery-framework"

echo
echo -e "${GREEN}🚀 Ready to deploy GitHub secrets with Terraform!${NC}"
