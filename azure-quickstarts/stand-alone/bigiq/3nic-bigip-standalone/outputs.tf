# Output

output "App_Services" {
  value = <<EOF

      bigip-mgmt       : ${azurerm_network_interface.management.private_ip_address} => https://${azurerm_public_ip.mgmt_pip.ip_address}
      application-vip1 : https://${element(azurerm_linux_virtual_machine.bigip.public_ip_addresses, 2)}
    EOF
}