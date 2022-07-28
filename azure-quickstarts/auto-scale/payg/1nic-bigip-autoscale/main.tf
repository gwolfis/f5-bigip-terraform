terraform {
  required_version = "~> 1.1.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.94.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
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
      version = "2.1.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  //subscription_id = local.tmp.subscription_id
  //client_id       = local.tmp.client_id
  //client_secret   = local.tmp.client_secret
  //tenant_id       = local.tmp.tenant_id
}

# locals {
#   tmp = yamldecode(file(var.tmpfile))
# }

# Create a random id
resource "random_id" "storage_account" {
  byte_length = 2
}

#Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.prefix
  location = var.location
}

resource "azurerm_storage_account" "bigip_storage" {
  name                     = "${random_id.storage_account.hex}bigipstorage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    name        = "${var.prefix}-bigip-storage"
    environment = var.environment

  }
}

#Create Azure Managed User Identity and Role Definition
resource "azurerm_user_assigned_identity" "user_identity" {
  name                = "${var.prefix}-ident"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_role_assignment" "rg_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.user_identity.principal_id
}

