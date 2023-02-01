#!/usr/bin/env python3

import requests
import os
import re
import fileinput

url = 'http://ifconfig.me/ip'

response = requests.get(url)

# print (response.content)

with fileinput.input(files="terraform.tfvars",inplace=True) as input:
    for line in input:
        input_line = ''
        search_string = re.findall(r'trusted_IP',line.strip())
        if len(search_string) >0 :
            input_line = "trusted_IP       = \"" + str(response.text)+"/32\""
            print(input_line)
        else:
            print(line.strip())

# os.system("terraform apply -target module.remote_access.module.external-network-security-group-public.aws_security_group_rule.ingress_rules[0] -auto-approve")
# for x in range (1,4):
#    os_command="terraform apply -target module.remote_access.module.mgmt-network-security-group.aws_security_group_rule.ingress_with_cidr_blocks["+str(x)+"] -auto-approve"
#    os.system(os_command)
