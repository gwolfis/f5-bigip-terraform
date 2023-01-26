#Azure Credentials
variable "subscription_id" { default = "" }
variable "client_id" { default = "" }
variable "client_secret" { default = "" }
variable "tenant_id" { default = "" }

# tfvars input
variable "user_name" {}
variable "user_password" {}
variable "prefix" {}
variable "unique_string" {}
variable "location" {}

# F5 employee required:
variable "owner" {
  type                  = string
  description           = "Employee e-mail address"
}

#Tags
variable "environment" { default = "azure" }
variable "service_discovery_value" { default = "production" }
//variable "f5_cloud_failover_label" { default = "${var.prefix}-failover-label"}

#Networks
variable "cidr" { default = "10.0.0.0/16" }
variable "subnet_management" {
  type    = list(string)
  default = ["10.0.0.0/24"]
}
variable "subnet_external" {
  type    = list(string)
  default = ["10.0.1.0/24"]
}
variable "subnet_internal" {
  type    = list(string)
  default = ["10.0.2.0/24"]
}

#Gateways
variable "management_gateway" { default = "10.0.0.1"}
variable "external_gateway" { default = "10.0.1.1"}

# F5 employee required:
variable "employee_IP" {
  type    = string 
}

# BIGIP Image PAYG
variable "instance_type" { default = "Standard_DS3_v2" }
variable "image_name" { default = "f5-bigip-virtual-edition-25m-best-hourly" }
variable "product" { default = "f5-big-ip-best" }
variable "bigip_version" { default = "16.1.202000" }

#F5 Automation Toolchain

variable "DO_URL" { default = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.31.0/f5-declarative-onboarding-1.31.0-6.noarch.rpm" }
variable "AS3_URL" { default = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.38.0/f5-appsvcs-3.38.0-4.noarch.rpm" }
variable "TS_URL" { default = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.30.0/f5-telemetry-1.30.0-1.noarch.rpm" }
variable "CFE_URL" { default = "https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/v1.11.0/f5-cloud-failover-1.11.0-0.noarch.rpm" }
variable "INIT_URL" { default = "https://github.com/F5Networks/f5-bigip-runtime-init/releases/download/1.5.1/f5-bigip-runtime-init-1.5.1-1.gz.run" }