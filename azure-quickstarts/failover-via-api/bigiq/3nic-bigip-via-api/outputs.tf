# Output

output "App_Services" {
  value = <<EOF

      bigip0-mgmt     : ${azurerm_network_interface.bigip0_management.private_ip_address} => https://${azurerm_public_ip.bigip0_mgmt_pip.ip_address}
      bigip1-mgmt     : ${azurerm_network_interface.bigip1_management.private_ip_address} => https://${azurerm_public_ip.bigip1_mgmt_pip.ip_address}
      application-vip1 : https://${element(azurerm_linux_virtual_machine.bigip0.public_ip_addresses, 2)}
    EOF
}