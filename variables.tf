variable "cloud_provider" {
  description = "Cloud provider to use: aws, azure, or gcp"
  type        = string
  default     = "aws"

  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "cloud_provider must be one of: aws, azure, gcp."
  }
}

# AWS
variable "aws_region" {
  description = "AWS region (used when cloud_provider = aws)"
  type        = string
  default     = "us-east-1"
}

# Azure
variable "azure_location" {
  description = "Azure location (used when cloud_provider = azure)"
  type        = string
  default     = "East US"
}

variable "azure_subscription_id" {
  description = "Azure subscription ID (used when cloud_provider = azure)"
  type        = string
  default     = ""
}

# GCP
variable "gcp_project" {
  description = "GCP project ID (used when cloud_provider = gcp)"
  type        = string
  default     = ""
}

variable "gcp_region" {
  description = "GCP region (used when cloud_provider = gcp)"
  type        = string
  default     = "us-central1"
}

# Shared
variable "environment" {
  description = "Deployment environment: dev, staging, or prod"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "my-project"
}
