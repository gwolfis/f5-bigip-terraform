# Output

output "App_Services" {
  value = <<EOF

      bigip-mgmt       : ${azurerm_network_interface.external.private_ip_address} => https://${azurerm_public_ip.ext_pip.ip_address}:8443
      application-vip1 : https://${azurerm_public_ip.ext_pip.ip_address}
    EOF
}