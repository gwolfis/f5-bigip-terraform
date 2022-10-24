# BIG-IP Failover via-lb

# Public IP
resource "azurerm_public_ip" "bigip0_mgmt_pip" {
    name                = "${var.prefix}-bigip0-mgmt-pip"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    sku                 = "Standard"
    allocation_method   = "Static"
}

resource "azurerm_public_ip" "bigip0_ext_pip" {
    name                = "${var.prefix}-bigip0-ext-pip"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    sku                 = "Standard"
    allocation_method   = "Static"
}

resource "azurerm_public_ip" "bigip0_ext_vpip" {
    name                = "${var.prefix}-bigip0-ext-vpip"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    sku                 = "Standard"
    allocation_method   = "Static"
}

# Network Interfaces
resource "azurerm_network_interface" "bigip0_management" {
  name                = "${var.prefix}-bigip0-mgmt-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  
  ip_configuration {
    name                          = "${var.prefix}-bigip0-mgmt-ip"
    subnet_id                     = azurerm_subnet.management.id
    primary                       = true
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bigip0_mgmt_pip.id
  }
  depends_on = [ azurerm_resource_group.rg ]
}

resource "azurerm_network_interface" "bigip0_external" {
  name                          = "${var.prefix}-bigip0-ext-nic"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  enable_accelerated_networking = true
  
  ip_configuration {
    name                          = "${var.prefix}-bigip0-ext-ip"
    subnet_id                     = azurerm_subnet.external.id
    primary                       = true
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bigip0_ext_pip.id
  }

  ip_configuration {
    name                          = "${var.prefix}-bigip0-ext-vip"
    subnet_id                     = azurerm_subnet.external.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [ azurerm_resource_group.rg ]
}

resource "azurerm_network_interface" "bigip0_internal" {
  name                          = "${var.prefix}-bigip0-int-nic"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  enable_accelerated_networking = true
  
  ip_configuration {
    name                          = "${var.prefix}-bigip0-int-ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }
  depends_on = [ azurerm_resource_group.rg ]
}

resource "azurerm_network_interface" "bigip0_ha" {
  name                          = "${var.prefix}-bigip0-ha-nic"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  enable_accelerated_networking = true
  
  ip_configuration {
    name                          = "${var.prefix}-bigip0-ha-ip"
    subnet_id                     = azurerm_subnet.ha.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }
  depends_on = [ azurerm_resource_group.rg ]
}

resource "azurerm_network_interface_security_group_association" "bigip0_mgmtnsg" {
  network_interface_id      = azurerm_network_interface.bigip0_management.id
  network_security_group_id = azurerm_network_security_group.mgmtnsg.id
}

resource "azurerm_network_interface_security_group_association" "bigip0_extnsg" {
  network_interface_id      = azurerm_network_interface.bigip0_external.id
  network_security_group_id = azurerm_network_security_group.extnsg.id
}

resource "azurerm_network_interface_security_group_association" "bigip0_intnsg" {
  network_interface_id      = azurerm_network_interface.bigip0_internal.id
  network_security_group_id = azurerm_network_security_group.intnsg.id
}

resource "azurerm_network_interface_security_group_association" "bigip0_hansg" {
  network_interface_id      = azurerm_network_interface.bigip0_ha.id
  network_security_group_id = azurerm_network_security_group.hansg.id
}

# Connect BIG-IP to ALB
resource "azurerm_network_interface_backend_address_pool_association" "bigip0_backend_address_pool" {
  network_interface_id    = azurerm_network_interface.bigip0_external.id
  ip_configuration_name   = "${var.prefix}-bigip0-ext-vip"
  backend_address_pool_id = azurerm_lb_backend_address_pool.bigip_backend_pool.id
  depends_on = [ azurerm_resource_group.rg ]
}

# Onboard Template
locals {
  bigip_onboard0 = templatefile("${path.module}/onboard.tpl", {
    INIT_URL           = var.INIT_URL
    DO_URL             = var.DO_URL
    AS3_URL            = var.AS3_URL
    TS_URL             = var.TS_URL
    DO_VER             = split("/", var.DO_URL)[7]
    AS3_VER            = split("/", var.AS3_URL)[7]
    TS_VER             = split("/", var.TS_URL)[7]
    host_name          = "${var.prefix}-bigip0"
    remote_host_name   = "${var.prefix}-bigip1"
    host_name_0        = "${var.prefix}-bigip0"
    host_name_1        = "${var.prefix}-bigip1"
    user_name          = var.user_name
    user_password      = var.user_password
    self_ip_external   = azurerm_network_interface.bigip0_external.private_ip_address
    self_ip_internal   = azurerm_network_interface.bigip0_internal.private_ip_address
    self_ip_ha         = azurerm_network_interface.bigip0_ha.private_ip_address
    remote_ha_int      = azurerm_network_interface.bigip1_ha.private_ip_address 
    management_gateway = cidrhost(azurerm_subnet.management.address_prefix, 1)
    external_gateway   = cidrhost(azurerm_subnet.external.address_prefix, 1)
    vip0               = element(azurerm_network_interface.bigip0_external.private_ip_addresses, 1)
    vip1               = element(azurerm_network_interface.bigip1_external.private_ip_addresses, 1)
    unique_string      = var.unique_string
  })
}

# BIG-IP VM
resource "azurerm_linux_virtual_machine" "bigip0" {
  name                            = "${var.prefix}-bigip0"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = var.instance_type
  zone                            = 1
  disable_password_authentication = false
  admin_username                  = var.user_name
  admin_password                  = var.user_password
  network_interface_ids           = [azurerm_network_interface.bigip0_management.id, azurerm_network_interface.bigip0_external.id, azurerm_network_interface.bigip0_internal.id, azurerm_network_interface.bigip0_ha.id]
  custom_data                     = base64encode(local.bigip_onboard0)
  depends_on = [
    azurerm_network_interface_security_group_association.bigip0_mgmtnsg, azurerm_network_interface_security_group_association.bigip0_extnsg, azurerm_network_interface_security_group_association.bigip0_intnsg, azurerm_network_interface_security_group_association.bigip0_hansg 
  ]

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.bigip_user_identity.id]
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

