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

# BIG-IP Auto Scale Settings
variable "default_instance_count" { default = 2 }
variable "min_instance_count" { default = 2 }
variable "max_instance_count" { default = 10 }

# BIGIP Image PAYG
variable "instance_type" { default = "Standard_DS3_v2" }
variable "image_name" { default = "f5-big-best-plus-hourly-25mbps" }
variable "product" { default = "f5-big-ip-best" }
variable "bigip_version" { default = "16.1.302000" }

#F5 Automation Toolchain
variable "DO_URL" { default = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.36.0/f5-declarative-onboarding-1.36.0-4.noarch.rpm" }
variable "AS3_URL" { default = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.43.0/f5-appsvcs-3.43.0-2.noarch.rpm" }
variable "TS_URL" { default = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.32.0/f5-telemetry-1.32.0-2.noarch.rpm" }
variable "INIT_URL" { default = "https://github.com/F5Networks/f5-bigip-runtime-init/releases/download/1.6.0/f5-bigip-runtime-init-1.6.0-1.gz.run" }