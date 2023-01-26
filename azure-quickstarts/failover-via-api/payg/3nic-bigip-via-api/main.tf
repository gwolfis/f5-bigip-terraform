terraform {
  required_version = "> 1.1.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">2.94.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">3.1.0"
    }
    template = {
      source  = "hashicorp/template"
      version = ">2.1.2"
    }
    null = {
      source  = "hashicorp/null"
      version = ">2.1.2"
    }
    local = {
      source  = "hashicorp/local"
      version = ">2.1.0"
    }
  }
}

locals {
  tags = {
    "Owner" = var.owner
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  /*  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  */
}


# Create a random id
resource "random_id" "id" {
  byte_length = 2
}

#Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.prefix
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "cfe_storage" {
  name                     = "${random_id.id.hex}cfestorage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = merge({
    name                    = "${var.prefix}-cfe-storage"
    environment             = var.environment
    f5_cloud_failover_label = "${var.prefix}-failover-label"
    },
  local.tags)
}

#Create Azure Managed User Identity and Role Definition
resource "azurerm_user_assigned_identity" "user_identity" {
  name                = "${var.prefix}-ident"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags
}

# resource "azurerm_role_assignment" "rg_contributor" {
#   scope                = azurerm_resource_group.rg.id
#   role_definition_name = "Contributor"
#   principal_id         = azurerm_user_assigned_identity.user_identity.principal_id
# }

data "azurerm_subscription" "rg" {}

resource "azurerm_role_assignment" "bigip0_contributor" {
  //name                 = azurerm_linux_virtual_machine.bigip0.id
  scope              = data.azurerm_subscription.rg.id
  role_definition_id = "${data.azurerm_subscription.rg.id}${data.azurerm_role_definition.contributor.id}"
  principal_id       = lookup(azurerm_linux_virtual_machine.bigip0.identity[0], "principal_id")
}

resource "azurerm_role_assignment" "bigip1_contributor" {
  //name                 = azurerm_linux_virtual_machine.bigip1.id
  scope              = data.azurerm_subscription.rg.id
  role_definition_id = "${data.azurerm_subscription.rg.id}${data.azurerm_role_definition.contributor.id}"
  principal_id       = lookup(azurerm_linux_virtual_machine.bigip1.identity[0], "principal_id")
}

data "azurerm_role_definition" "contributor" {
  name = "Contributor"
}
