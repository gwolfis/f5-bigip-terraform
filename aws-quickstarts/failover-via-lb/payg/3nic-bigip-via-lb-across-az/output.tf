# Output

output "AWS_BIG-IP_Deployment" {
  value = <<EOF
      bigip-0-mgmt     : ${element(aws_network_interface.mgmt.*.private_ip, 0)} => https://${element(aws_eip.mgmt.*.public_ip, 0)} 
      bigip-1-mgmt     : ${element(aws_network_interface.mgmt.*.private_ip, 1)} => https://${element(aws_eip.mgmt.*.public_ip, 1)}
      application-http : http://${aws_lb.nlb.dns_name}
      application-https: https://${aws_lb.nlb.dns_name}
    EOF
}