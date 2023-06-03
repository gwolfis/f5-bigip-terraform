provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.region
}

locals {
  tags = {
    "prefix"      = var.prefix
    "environment" = var.environment
    "deployment"  = var.deployment
    "owner"       = var.owner
  }
}