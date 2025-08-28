# ECS Service Module Variables
# This file defines all the input variables for the ECS service module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., production, staging, dev)"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Container Configuration
variable "container_image" {
  description = "Docker image for the container"
  type        = string
}

variable "container_port" {
  description = "Port that the container exposes"
  type        = number
  default     = 3000
}

variable "cpu" {
  description = "CPU units for the task"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory for the task in MB"
  type        = number
  default     = 512
}

variable "memory_reservation" {
  description = "Soft memory limit for the container in MB"
  type        = number
  default     = 256
}

# Service Configuration
variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "health_check_path" {
  description = "Health check path for ALB target group"
  type        = string
  default     = "/health"
}

variable "health_check_command" {
  description = "Health check command for container"
  type        = string
  default     = "curl -f http://localhost:3000/health || exit 1"
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
}

# Auto Scaling Configuration
variable "enable_auto_scaling" {
  description = "Enable auto scaling for the service"
  type        = bool
  default     = true
}

variable "min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 10
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for auto scaling"
  type        = number
  default     = 70
}

variable "memory_target_value" {
  description = "Target memory utilization percentage for auto scaling"
  type        = number
  default     = 80
}

variable "scale_in_cooldown" {
  description = "Scale in cooldown period in seconds"
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "Scale out cooldown period in seconds"
  type        = number
  default     = 300
}

# Deployment Configuration
variable "max_capacity_during_deployment" {
  description = "Maximum percentage of tasks during deployment"
  type        = number
  default     = 200
}

variable "min_capacity_during_deployment" {
  description = "Minimum percentage of healthy tasks during deployment"
  type        = number
  default     = 50
}

# Load Balancer Configuration
variable "domain_name" {
  description = "Domain name for the service"
  type        = string
}

variable "listener_priority" {
  description = "Priority for the ALB listener rule"
  type        = number
}

variable "path_pattern" {
  description = "Path pattern for ALB routing (optional)"
  type        = string
  default     = null
}

variable "enable_stickiness" {
  description = "Enable session stickiness"
  type        = bool
  default     = false
}

# Environment Variables and Secrets
variable "environment_variables" {
  description = "Environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secrets" {
  description = "Secrets to inject into the container"
  type = list(object({
    name = string
    arn  = string
  }))
  default = []
}

variable "secrets_arns" {
  description = "ARNs of secrets that the task can access"
  type        = list(string)
  default     = []
}

# Service Discovery and Service Connect
variable "enable_service_connect" {
  description = "Enable AWS Service Connect"
  type        = bool
  default     = false
}

# Monitoring and Logging
variable "log_retention_days" {
  description = "CloudWatch log retention period"
  type        = number
  default     = 30
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}
