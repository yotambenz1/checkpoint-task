variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "172.23.0.0/16"
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {
    Project     = "checkpoint"
    ManagedBy   = "terraform"
  }
} 