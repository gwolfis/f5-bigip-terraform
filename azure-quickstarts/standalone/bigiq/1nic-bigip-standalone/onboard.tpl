#!/bin/bash -x

# NOTE: Startup Script is run once / initialization only (Cloud-Init behavior vs. typical re-entrant for Azure Custom Script Extension )
# For 15.1+ and above, Cloud-Init will run the script directly and can remove Azure Custom Script Extension 


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

mkdir -p /config/cloud
  
#curl -o /config/cloud/do_w_admin.json -s --fail --retry 60 -m 10 -L https://raw.githubusercontent.com/f5devcentral/terraform-azure-bigip-module/master/config/onboard_do.json


### write_files:
# Download or Render BIG-IP Runtime Init Config 

cat << 'EOF' > /config/cloud/runtime-init-conf.yaml
---
runtime_parameters:
  - name: USER_NAME
    type: static
    value: ${user_name}
  - name: ADMIN_PASS
    type: static
    value: ${user_password}
  - name: BIGIQ_IP
    type: static
    value: ${bigiq_ip}
  - name: BIGIQ_USER_NAME
    type: static
    value: ${bigiq_user_name}
  - name: BIGIQ_PASSWORD
    type: static
    value: ${bigiq_password}
  - name: HOST_NAME
    type: metadata
    metadataProvider:
      environment: azure
      type: compute
      field: name
  - name: WORKSPACE_ID
    type: static
    value: ${workspace_id}
  - name: UNIQUE_STRING
    type: static
    value: ${unique_string}
  - name: RESOURCE_GROUP_NAME
    type: url
    value: 'http://169.254.169.254/metadata/instance/compute?api-version=2020-09-01'
    query: resourceGroupName
    headers:
      - name: Metadata
        value: true
  - name: SUBSCRIPTION_ID
    type: url
    value: 'http://169.254.169.254/metadata/instance/compute?api-version=2020-09-01'
    query: subscriptionId
    headers:
      - name: Metadata
        value: true
  - name: REGION
    type: url
    value: 'http://169.254.169.254/metadata/instance/compute?api-version=2020-09-01'
    query: location
    headers:
      - name: Metadata
        value: true
pre_onboard_enabled:
  - name: provision_rest
    type: inline
    commands:
      - /usr/bin/setdb provision.extramb 500
      - /usr/bin/setdb restjavad.useextramb true
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
        async: true
        label: Standalone 1NIC BIG-IP declaration for DO with BIGIQ
        Common: 
          class: Tenant
          dbVars:
            class: DbVariables
            restjavad.useextramb: true
            provision.extramb: 2048
            ui.advisory.enabled: true
            ui.advisory.color: orange
            ui.advisory.text: "BIG-IP 1-NIC Stand-Alone BIGIQ"
            #config.allow.rfc3927: enable
          mySystem:
            autoPhonehome: true
            class: System
            hostname: '{{{HOST_NAME}}}.local'
          myProvisioning:
            class: Provision
            ltm: nominal
            asm: nominal
          myNtp:
            class: NTP
            servers:
              - pool.ntp.org
            timezone: Europe/Amsterdam
          myDNS:
            class: DNS
            nameServers:
              - 168.63.129.16
          '{{{ USER_NAME }}}':
            class: User
            userType: regular
            partitionAccess:
              all-partitions:
                role: admin
            password: '{{{ ADMIN_PASS }}}'
            shell: bash
          My_License:
            class: License
            hypervisor: azure
            licenseType: licensePool
            licensePool: byol-pool
            bigIqHost: '{{{BIGIQ_IP}}}'
            bigIqUsername: '{{{BIGIQ_USER_NAME}}}'
            bigIqPassword: '{{{BIGIQ_PASSWORD}}}'
            tenant: myTenant
            skuKeyword1: F5-BIG-MSP-BT-200M
            unitOfMeasure: yearly
            reachable: false
            overwrite: false
    - extensionType: as3
      type: inline
      value:
        schemaVersion: 3.0.0
        class: ADC
        remark: HTTPS_WAF_App_Service_Discovery
        label: HTTPS_WAF_App_Service_Discovery
        Tenant_1:
          class: Tenant
          Shared:
            class: Application
            template: shared
            telemetry_local_rule:
              remark: Only required when TS is a local listener
              class: iRule
              iRule: |-
                when CLIENT_ACCEPTED {
                  node 127.0.0.1 6514
                }
            telemetry_local:
              remark: Only required when TS is a local listener
              class: Service_TCP
              virtualAddresses:
                - 255.255.255.254
              virtualPort: 6514
              iRules:
                - telemetry_local_rule
            telemetry:
              class: Pool
              members:
                - enable: true
                  serverAddresses:
                    - 255.255.255.254
                  servicePort: 6514
              monitors:
                - bigip: "/Common/tcp"
            telemetry_hsl:
              class: Log_Destination
              type: remote-high-speed-log
              protocol: tcp
              pool:
                use: telemetry
            telemetry_formatted:
              class: Log_Destination
              type: splunk
              forwardTo:
                use: telemetry_hsl
            telemetry_publisher:
              class: Log_Publisher
              destinations:
                - use: telemetry_formatted
            telemetry_asm_security_log_profile:
              class: Security_Log_Profile
              application:
                localStorage: false
                remoteStorage: splunk
                servers:
                  - address: 255.255.255.254
                    port: '6514'
                storageFilter:
                  requestType: all
            shared_pool:
              class: Pool
              remark: Service 1 shared pool
              members:
                - addressDiscovery: azure
                  addressRealm: private
                  resourceGroup: '{{{ RESOURCE_GROUP_NAME }}}'
                  resourceId: '{{{ UNIQUE_STRING }}}-app-vmss'
                  resourceType: scaleSet
                  servicePort: 80
                  subscriptionId: '{{{ SUBSCRIPTION_ID }}}'
                  updateInterval: 60
                  useManagedIdentity: true
              monitors:
                - http
          HTTPS_Service:
            class: Application
            template: https
            serviceMain:
              class: Service_HTTPS
              virtualAddresses:
                - 0.0.0.0
              policyWAF:
                use: WAFPolicy
              pool: /Tenant_1/Shared/shared_pool
              securityLogProfiles:
                - bigip: "/Common/Log all requests"
                - use: "/Tenant_1/Shared/telemetry_asm_security_log_profile"
              serverTLS:
                bigip: /Common/clientssl
              redirect80: true
            WAFPolicy:
              class: WAF_Policy
              url: >-
                https://raw.githubusercontent.com/F5Networks/f5-azure-arm-templates-v2/v1.4.0.0/examples/autoscale/bigip-configurations/Rapid_Deployment_Policy_13_1.xml
              enforcementMode: blocking
              ignoreChanges: false
    - extensionType: ts
      type: inline
      value:
        class: Telemetry
        controls:
          class: Controls
          logLevel: info
        My_Metrics_Namespace:
          class: Telemetry_Namespace
          My_System_Poller:
            class: Telemetry_System_Poller
            interval: 60
            actions:
              - includeData: {}
                locations:
                  system:
                    cpu: true
          My_Scaling_Endpoints:
            class: Telemetry_Endpoints
            items:
              throughputIn:
                name: throughputIn
                path: /mgmt/tm/sys/performance/throughput?$top=1&$select=Current
              hostname:
                name: hostname
                path: /mgmt/tm/sys/global-settings?$select=hostname
          My_Custom_Endpoints_Poller:
            class: Telemetry_System_Poller
            interval: 60
            endpointList:
              - My_Scaling_Endpoints/hostname
              - My_Scaling_Endpoints/throughputIn
          My_Telemetry_System:
            class: Telemetry_System
            systemPoller:
              - My_System_Poller
              - My_Custom_Endpoints_Poller
          My_Azure_Application_Insights:
            appInsightsResourceName: '{{{ UNIQUE_STRING }}}-insights'
            class: Telemetry_Consumer
            maxBatchIntervalMs: 5000
            maxBatchSize: 250
            type: Azure_Application_Insights
            useManagedIdentity: true
        My_Remote_Logs_Namespace:
          class: Telemetry_Namespace
          My_Listener:
            class: Telemetry_Listener
            port: 6514
          My_Azure_Log_Analytics:
            class: Telemetry_Consumer
            type: Azure_Log_Analytics
            workspaceId: '{{{ WORKSPACE_ID }}}'
            useManagedIdentity: true
            region: '{{{ REGION }}}'
post_onboard_enabled: []
EOF
# # Download
#PACKAGE_URL='https://github.com/F5Networks/f5-bigip-runtime-init/releases/download/1.6.0/f5-bigip-runtime-init-1.6.0-1.gz.run'
for i in {1..30}; do
    curl -fv --retry 1 --connect-timeout 5 -L ${INIT_URL} -o "/var/config/rest/downloads/f5-bigip-runtime-init-1.6.0-1.gz.run" && break || sleep 10
done
# Install
bash /var/config/rest/downloads/f5-bigip-runtime-init-1.6.0-1.gz.run -- '--cloud azure'
# Run
f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml