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

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
