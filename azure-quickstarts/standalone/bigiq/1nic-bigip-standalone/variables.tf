#Azure Credentials
variable subscription_id     { default = "" }
variable client_id           { default = "" }
variable client_secret       { default = "" }
variable tenant_id           { default = "" }

# # Tmp file
# variable "tmpfile" {
#   description = "The tmp file in yaml format"
#   type        = string
#   default     = "files/tmp.yml"
# }

# tfvars input
variable "user_name" {}
variable "user_password" {}
variable "prefix" {}
variable "unique_string" {}
variable "location" {}

#Tags
variable "environment" {}
variable "deployment" {}
variable "service_discovery_value" {}
variable "owner" {}

#Networks
variable "cidr" {default = "10.0.0.0/16"}
variable "subnet_external" {
  type = list(string)
  default = ["10.0.0.0/24"]
}
variable "source_ip" {
  type    = string
  default = "*"
}

# BIGIP Image BYOL/BIG-IQ
variable "instance_type"     {}
variable "image_name"        {}
variable "product"           {}
variable "bigip_version"     {}

# BIGIQ
variable "bigiq_ip" {}
variable "bigiq_user_name" {}
variable "bigiq_password" {}

#F5 Automation Toolchain
variable "DO_URL" { default = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.36.0/f5-declarative-onboarding-1.36.0-4.noarch.rpm" }
variable "AS3_URL" { default = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.43.0/f5-appsvcs-3.43.0-2.noarch.rpm" }
variable "TS_URL" { default = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.32.0/f5-telemetry-1.32.0-2.noarch.rpm" }
variable "INIT_URL" { default = "https://github.com/F5Networks/f5-bigip-runtime-init/releases/download/1.6.0/f5-bigip-runtime-init-1.6.0-1.gz.run" }