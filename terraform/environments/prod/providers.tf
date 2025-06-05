terraform {
  required_version = ">= 1.8.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.88.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.31.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.14.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

provider "aws" {
  alias  = "main-us-west-2"
  region = var.aws_region
} 