# AWS Credentials
variable "aws_access_key" {}
variable "aws_secret_key" {}

# tfvars input
variable "prefix" {}
variable "region" {}
variable "environment" {}
variable "deployment" {}
variable "owner" {}
variable "ec2_key_name" {}
variable "user_name" {}
variable "user_password" {}

# Networks
variable "cidr" {default = "10.0.0.0/16"}
# variable "subnet_mgmt" { default = "10.0.0.0/24"}
# variable "subnet_external" { default = "10.0.1.0/24"}
# variable "subnet_internal" { default = "10.0.2.0/24"}
# //variable "az1" { default = "eu-central-1b"}
variable "azs" {
  type = list (string)
  default = ["eu-central-1b", "eu-central-1c"]
}

# BIG-IP
variable "f5_ami" {
  description = "F5 BIGIP-16.1.3.3* PAYG-Best Plus 25Mbps - eu-central(Frankfurt)"
  type        = string
  default     = "ami-06a1ac7387c01fd2f"
}
variable "f5_ami_search_name" {
  description = "BIG-IP AMI name to search for"
  type        = string
  default     = "F5 BIGIP-16.1.3.3* PAYG-Best Plus 25Mbps*"
}
variable "ec2_instance_type" {}
variable "default_instance_count" { default = 2 }
variable "number_of_vips" { default = 2}

# Application
variable "server_count" {}
variable "discovery_tag_key" { default = "auto-discovery"}
variable "discovery_tag_value" { default = "discover"}

#F5 Automation Toolchain
variable "DO_URL" { default = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.36.0/f5-declarative-onboarding-1.36.0-4.noarch.rpm" }
variable "AS3_URL" { default = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.43.0/f5-appsvcs-3.43.0-2.noarch.rpm" }
variable "TS_URL" { default = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.32.0/f5-telemetry-1.32.0-2.noarch.rpm" }
variable "INIT_URL" { default = "https://github.com/F5Networks/f5-bigip-runtime-init/releases/download/1.6.0/f5-bigip-runtime-init-1.6.0-1.gz.run" }