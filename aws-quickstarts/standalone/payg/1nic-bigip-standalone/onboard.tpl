#!/bin/bash

#!/bin/bash -x

# Send output to log file and serial console
mkdir -p  /var/log/cloud /config/cloud /var/config/rest/downloads
LOG_FILE=/var/log/cloud/startup-script.log
[[ ! -f $LOG_FILE ]] && touch $LOG_FILE || { echo "Run Only Once. Exiting"; exit; }
npipe=/tmp/$$.tmp
trap "rm -f $npipe" EXIT
mknod $npipe p
tee <$npipe -a $LOG_FILE /dev/ttyS0 &
exec 1>&-
exec 1>$npipe
exec 2>&1

cat << 'EOF' > /config/cloud/runtime-init-conf.yaml
---
controls:
  logLevel: info
  logFilename: /var/log/cloud/bigIpRuntimeInit.log
pre_onboard_enabled:
  - name: provision_rest
    type: inline
    commands:
      - /usr/bin/setdb provision.extramb 1000
      - /usr/bin/setdb restjavad.useextramb true
runtime_parameters:
  - name: AWS_ACCESS_KEY
    type: static
    value: ${aws_access_key}
  - name: AWS_SECRET_KEY
    type: static
    value: ${aws_secret_key}
  - name: USER_NAME
    type: static
    value: ${user_name}
  - name: ADMIN_PASS
    type: static
    value: ${user_password}
  - name: HOST_NAME
    type: metadata
    metadataProvider:
      environment: aws
      type: compute
      field: hostname
  - name: REGION
    type: url
    value: http://169.254.169.254/latest/dynamic/instance-identity/document
    query: region
  - name: TAG_KEY
    type: static
    value: ${discovery_tag_key}
  - name: TAG_VALUE
    type: static
    value: ${discovery_tag_value}
bigip_ready_enabled: []
extension_packages:
  install_operations:
    - extensionType: do
      extensionVersion: ${DO_VER}
      extensionUrl: ${DO_URL}
    - extensionType: as3
      extensionVersion: ${AS3_VER}
      extensionUrl: ${AS3_URL}
    - extensionType: ts
      extensionVersion: ${TS_VER}
      extensionUrl: ${TS_URL}
extension_services:
  service_operations:
    - extensionType: do
      type: inline
      value:
        schemaVersion: 1.0.0
        class: Device
        label: >-
          Quickstart 1NIC BIG-IP declaration for Declarative Onboarding with PAYG
          license
        async: true
        Common:
          class: Tenant
          My_DbVariables:
            class: DbVariables
            provision.extramb: 1024
            restjavad.useextramb: true
            config.allow.rfc3927: enable
            ui.advisory.enabled: true
            ui.advisory.color: orange
            ui.advisory.text: "BIG-IP 1-NIC Stand-Alone PAYG"
          My_Provisioning:
            class: Provision
            asm: nominal
            ltm: nominal
          My_Ntp:
            class: NTP
            servers:
              - 169.254.169.253
            timezone: Europe/Amsterdam
          My_Dns:
            class: DNS
            nameServers:
              - 169.254.169.253
          My_System:
            class: System
            autoPhonehome: true
            hostname: '{{{HOST_NAME}}}'
          '{{{USER_NAME}}}':
            class: User
            password: '{{{ADMIN_PASS}}}'
            shell: bash
            userType: regular
    - extensionType: as3
      type: inline
      value:
        class: ADC
        schemaVersion: 3.0.0
        label: Quickstart
        remark: Quickstart
        Tenant_1:
          class: Tenant
          Shared:
            class: Application
            template: shared
            shared_pool:
              class: Pool
              remark: Service 1 shared pool
              members:
                - servicePort: 80
                  addressDiscovery: aws
                  updateInterval: 1
                  tagKey: '{{{TAG_KEY}}}'
                  tagValue: '{{{TAG_VALUE}}}'
                  addressRealm: private
                  accessKeyId: '{{{AWS_ACCESS_KEY}}}'
                  secretAccessKey: '{{{AWS_SECRET_KEY}}}'
                  region: '{{{REGION}}}'
              monitors:
                - http
            Custom_HTTP_Profile:
              class: HTTP_Profile
              xForwardedFor: true
            Custom_WAF_Policy:
              class: WAF_Policy
              url: >-
                https://raw.githubusercontent.com/F5Networks/f5-aws-cloudformation-v2/v2.7.0.0/examples/quickstart/bigip-configurations/Rapid_Deployment_Policy_13_1.xml
              enforcementMode: blocking
              ignoreChanges: false
          HTTP_Service:
            class: Application
            template: http
            serviceMain:
              class: Service_HTTP
              virtualAddresses:
                - '0.0.0.0/0'
              snat: auto
              profileHTTP:
                use: /Tenant_1/Shared/Custom_HTTP_Profile
              policyWAF:
                use: /Tenant_1/Shared/Custom_WAF_Policy
              pool: /Tenant_1/Shared/shared_pool
          HTTPS_Service:
            class: Application
            template: https
            serviceMain:
              class: Service_HTTPS
              virtualAddresses:
                - '0.0.0.0/0'
              snat: auto
              profileHTTP:
                use: /Tenant_1/Shared/Custom_HTTP_Profile
              policyWAF:
                use: /Tenant_1/Shared/Custom_WAF_Policy
              pool: /Tenant_1/Shared/shared_pool
              serverTLS:
                bigip: /Common/clientssl
              redirect80: false
post_onboard_enabled: []
EOF

# Download
for i in {1..30}; do
    curl -fv --retry 1 --connect-timeout 5 -L "${INIT_URL}" -o "/var/config/rest/downloads/f5-bigip-runtime-init.gz.run" && break || sleep 10
done
# Install
bash /var/config/rest/downloads/f5-bigip-runtime-init.gz.run -- "--cloud aws"
# Run
f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml