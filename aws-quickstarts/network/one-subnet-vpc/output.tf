# Output

# Output

output "AWS_BIG-IP_Deployment" {
  value = <<EOF
      vpc-cidr  : ${aws_vpc.vpc.cidr_block}
      subnet    : ${aws_subnet.mgmt.cidr_block}
    EOF
}