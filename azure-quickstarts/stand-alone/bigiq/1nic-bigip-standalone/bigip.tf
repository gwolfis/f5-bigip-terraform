# BIG-IP Standalone


# Public IP
resource "azurerm_public_ip" "ext_pip" {
    name                = "${var.prefix}-ext-pip"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    sku                 = "Standard"
    allocation_method   = "Static"
}

# Network External
resource "azurerm_network_interface" "external" {
  name                = "${var.prefix}-ext-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  
  ip_configuration {
    name                          = "${var.prefix}-ext-ip"
    subnet_id                     = azurerm_subnet.external.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ext_pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "extnsg" {
  network_interface_id      = azurerm_network_interface.external.id
  network_security_group_id = azurerm_network_security_group.extnsg.id
}

# Onboard Template
locals {
  bigip_onboard = templatefile("${path.module}/onboard.tpl", {
    INIT_URL           = var.INIT_URL
    DO_URL             = var.DO_URL
    AS3_URL            = var.AS3_URL
    TS_URL             = var.TS_URL
    DO_VER             = split("/", var.DO_URL)[7]
    AS3_VER            = split("/", var.AS3_URL)[7]
    TS_VER             = split("/", var.TS_URL)[7]
    user_name          = var.user_name
    user_password      = var.user_password
    bigiq_ip           = var.bigiq_ip
    bigiq_user_name    = var.bigiq_user_name
    bigiq_password     = var.bigiq_password
    unique_string      = var.unique_string
    workspace_id       = azurerm_log_analytics_workspace.law.workspace_id
    })
}

# BIG-IP VM
resource "azurerm_linux_virtual_machine" "bigip" {
  name                            = "${var.prefix}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = var.instance_type
  disable_password_authentication = false
  admin_username                  = var.user_name
  admin_password                  = var.user_password
  network_interface_ids           = [azurerm_network_interface.external.id]
  custom_data                     = base64encode(local.bigip_onboard)

  admin_ssh_key {
    username   = var.user_name
    public_key = azurerm_ssh_public_key.f5_key.public_key
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.user_identity.id]
  }

  plan {
    name      = var.image_name
    publisher = "f5-networks"
    product   = var.product
  }

  source_image_reference {
    publisher = "f5-networks"
    offer     = var.product
    sku       = var.image_name
    version   = var.bigip_version
  }

  os_disk {
    caching              = "None"
    storage_account_type = "Premium_LRS"
  }
}