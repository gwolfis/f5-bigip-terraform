terraform {
  required_version = "~>1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.41.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.4.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~>2.2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~>3.2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~>2.3.0"
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
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id  
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

resource "azurerm_ssh_public_key" "f5_key" {
  name                = format("%s-pubkey-%s", var.prefix, random_id.id.hex)
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_key          = file("~/.ssh/id_rsa.pub")
  tags                = local.tags
}
#Create Azure Managed User Identity and Role Definition
resource "azurerm_user_assigned_identity" "bigip_user_identity" {
  name                = "${var.prefix}-ident"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags
}

resource "azurerm_role_assignment" "rg_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.bigip_user_identity.principal_id
}

