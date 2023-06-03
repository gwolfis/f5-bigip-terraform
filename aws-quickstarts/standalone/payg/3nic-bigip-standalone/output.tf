# Output

output "AWS_BIG-IP_Deployment" {
  value = <<EOF
      bigip-mgmt       : ${aws_network_interface.mgmt.private_ip} => https://${aws_eip.mgmt.public_ip}
      application-vip1 : https://${aws_eip.vip-1.public_ip}
    EOF
}