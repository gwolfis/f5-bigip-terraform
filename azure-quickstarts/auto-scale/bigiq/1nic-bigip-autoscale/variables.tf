#Azure Credentials
variable subscription_id     { default = "" }
variable client_id           { default = "" }
variable client_secret       { default = "" }
variable tenant_id           { default = "" }

# tfvars input
variable "user_name" { default = "admin" }
variable "user_password" { default = "Azure12345!"}
variable "prefix" { default = "test"}
variable "unique_string" { default = "testapp" }
variable "location" { default = "westeurope" }


#Tags
variable "environment" { default = "azure" }
variable "service_discovery_value" { default = "production" }

#Networks
variable "cidr" {default = "10.0.0.0/16"}
variable "subnet_external" {
  type = list(string)
  default = ["10.0.0.0/24"]
}

# BIG-IP Auto Scale Settings
variable "default_instance_count" { default = 2 }
variable "min_instance_count" { default = 2 }
variable "max_instance_count" { default = 10 }

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
variable "DO_URL" { default = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.31.0/f5-declarative-onboarding-1.31.0-6.noarch.rpm" }
variable "AS3_URL" { default = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.38.0/f5-appsvcs-3.38.0-4.noarch.rpm" }
variable "TS_URL" { default = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.30.0/f5-telemetry-1.30.0-1.noarch.rpm" }
variable "INIT_URL" { default = "https://github.com/F5Networks/f5-bigip-runtime-init/releases/download/1.5.1/f5-bigip-runtime-init-1.5.1-1.gz.run" }