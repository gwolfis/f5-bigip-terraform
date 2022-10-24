# Output

output "App_Services" {
  value = <<EOF

      bigip0-mgmt : ${azurerm_network_interface.bigip0_management.private_ip_address} => https://${azurerm_public_ip.bigip0_mgmt_pip.ip_address}
      bigip1-mgmt : ${azurerm_network_interface.bigip1_management.private_ip_address} => https://${azurerm_public_ip.bigip1_mgmt_pip.ip_address}
      application-vip : http://${azurerm_public_ip.alb_pip.ip_address}
      application-vip : https://${azurerm_public_ip.alb_pip.ip_address}
    EOF
}