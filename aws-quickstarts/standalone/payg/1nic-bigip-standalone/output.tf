# Output

# Output

output "AWS_BIG-IP_Deployment" {
  value = <<EOF
      bigip-mgmt       : ${aws_network_interface.mgmt.private_ip} => https://${aws_eip.mgmt.public_ip}:8443
      application-vip1 : https://${aws_eip.mgmt.public_ip}
    EOF
}