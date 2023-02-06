#Create the VNET
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [var.cidr]
  tags                = local.tags
}

#Create the Subnets
resource "azurerm_subnet" "management" {
  name                 = "${var.prefix}-mgmt"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_management
}

resource "azurerm_subnet" "external" {
  name                 = "${var.prefix}-ext"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_external
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-int"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_internal
}

# Azure Route Table to Support CFE
resource "azurerm_route_table" "cfe_udr" {
  name = "${var.prefix}-rt-cfe-udr"
  //count                         = var.default_instance_count
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  disable_bgp_route_propagation = false

  route {
    name                   = "internal_route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.bigip0_internal.private_ip_address
  }

  tags = merge({
    f5_cloud_failover_label = "${var.prefix}-failover-label"
    f5_self_ips             = "${azurerm_network_interface.bigip0_internal.private_ip_address}, ${azurerm_network_interface.bigip1_internal.private_ip_address}"
  },
  local.tags)
}