# BIG-IP Failover via-lb

# Public IP BIGIP1
resource "azurerm_public_ip" "bigip1_mgmt_pip" {
  name                = "${var.prefix}-bigip1-mgmt-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "bigip1_ext_pip" {
  name                = "${var.prefix}-bigip1-ext-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "bigip1_ext_vpip" {
  name                = "${var.prefix}-bigip1-ext-vpip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

# Network Interfaces BIGIP1
resource "azurerm_network_interface" "bigip1_management" {
  name                = "${var.prefix}-bigip1-mgmt-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "${var.prefix}-bigip1-mgmt-ip"
    subnet_id                     = azurerm_subnet.management.id
    primary                       = true
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bigip1_mgmt_pip.id
  }
}

resource "azurerm_network_interface" "bigip1_external" {
  name                          = "${var.prefix}-bigip1-ext-nic"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "${var.prefix}-bigip1-ext-ip"
    subnet_id                     = azurerm_subnet.external.id
    primary                       = true
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bigip1_ext_pip.id
  }

  ip_configuration {
    name                          = "${var.prefix}-bigip1-ext-vip"
    subnet_id                     = azurerm_subnet.external.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bigip1_ext_vpip.id
  }

  tags = {
    f5_cloud_failover_label   = "${var.prefix}-failover-label"
    f5_cloud_failover_nic_map = "external"
  }
}

resource "azurerm_network_interface" "bigip1_internal" {
  name                          = "${var.prefix}-bigip1-int-nic"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "${var.prefix}-bigip1-int-ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }

  tags = {
    f5_cloud_failover_label   = "${var.prefix}-failover-label"
    f5_cloud_failover_nic_map = "internal"
  }
}

# Associate NSG with Network Interfaces
resource "azurerm_network_interface_security_group_association" "bigip1_mgmtnsg" {
  network_interface_id      = azurerm_network_interface.bigip1_management.id
  network_security_group_id = azurerm_network_security_group.mgmtnsg.id
}

resource "azurerm_network_interface_security_group_association" "bigip1_extnsg" {
  network_interface_id      = azurerm_network_interface.bigip1_external.id
  network_security_group_id = azurerm_network_security_group.extnsg.id
}

resource "azurerm_network_interface_security_group_association" "bigip1_intnsg" {
  network_interface_id      = azurerm_network_interface.bigip1_internal.id
  network_security_group_id = azurerm_network_security_group.intnsg.id
}

# Onboard Template BIGIP1
locals {
  bigip_onboard1 = templatefile("${path.module}/onboard.tpl", {
    INIT_URL                = var.INIT_URL
    DO_URL                  = var.DO_URL
    AS3_URL                 = var.AS3_URL
    CFE_URL                 = var.CFE_URL
    TS_URL                  = var.TS_URL
    DO_VER                  = split("/", var.DO_URL)[7]
    AS3_VER                 = split("/", var.AS3_URL)[7]
    CFE_VER                 = split("/", var.CFE_URL)[7]
    TS_VER                  = split("/", var.TS_URL)[7]
    user_name               = var.user_name
    user_password           = var.user_password
    host_name               = "${var.prefix}-bigip1"
    host_name_0             = "${var.prefix}-bigip0" 
    host_name_1             = "${var.prefix}-bigip1"
    remote_host_int         = azurerm_network_interface.bigip0_internal.private_ip_address 
    self_ip_external        = azurerm_network_interface.bigip1_external.private_ip_address
    self_ip_internal        = azurerm_network_interface.bigip1_internal.private_ip_address
    management_gateway      = cidrhost(azurerm_subnet.management.address_prefix, 1)
    external_gateway        = cidrhost(azurerm_subnet.external.address_prefix, 1)
    f5_cloud_failover_label = "${var.prefix}-failover-label"
    vip                     = element(azurerm_network_interface.bigip0_external.private_ip_addresses, 1)
    unique_string           = var.unique_string
    workspace_id            = azurerm_log_analytics_workspace.law.workspace_id
  })
}

# BIGIP1 VM
resource "azurerm_linux_virtual_machine" "bigip1" {
  name                            = "${var.prefix}-bigip1"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = var.instance_type
  zone                            = 2
  disable_password_authentication = false
  admin_username                  = var.user_name
  admin_password                  = var.user_password
  network_interface_ids           = [azurerm_network_interface.bigip1_management.id, azurerm_network_interface.bigip1_external.id, azurerm_network_interface.bigip1_internal.id]
  custom_data                     = base64encode(local.bigip_onboard1)

  identity {
    type         = "SystemAssigned"
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

