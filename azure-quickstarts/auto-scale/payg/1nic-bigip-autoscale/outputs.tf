# Outputs

output "App_Services" {
  value = <<EOF
      
      application-vip : http://${azurerm_public_ip.alb_pip.ip_address}
      application-vip : https://${azurerm_public_ip.alb_pip.ip_address}
    EOF
}