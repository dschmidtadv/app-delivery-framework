include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/ecs-service"
}

inputs = {
  environment = "staging"
  
  # Application configuration
  app_name         = "app-delivery-framework"
  app_port         = 80
  cpu              = 256
  memory           = 512
  desired_count    = 1
  
  # Network configuration
  vpc_id              = "vpc-staging"  # Replace with actual VPC ID
  private_subnet_ids  = ["subnet-staging-1", "subnet-staging-2"]  # Replace with actual subnet IDs
  public_subnet_ids   = ["subnet-staging-public-1", "subnet-staging-public-2"]  # Replace with actual subnet IDs
  
  # Database configuration
  database_name     = "drupal_staging"
  database_username = "drupal"
  database_password = "staging_password_789"  # Use AWS Secrets Manager in production
  
  # Cache configuration
  cache_node_type   = "cache.t3.micro"
  cache_num_nodes   = 1
  
  # Domain configuration
  domain_name = "staging.example.com"  # Replace with actual domain
  
  # SSL configuration
  ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/staging-cert-id"  # Replace with actual certificate ARN
  
  # Tags
  tags = {
    Environment = "staging"
    Project     = "app-delivery-framework"
    ManagedBy   = "terragrunt"
  }
}
