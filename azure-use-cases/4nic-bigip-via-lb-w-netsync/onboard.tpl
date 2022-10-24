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
  - name: HOST_NAME
    type: static
    value: ${host_name}
  - name: REMOTE_HOST_NAME
    type: static
    value: ${remote_host_name}
  - name: HOST_NAME_0
    type: static
    value: ${host_name_0}
  - name: HOST_NAME_1
    type: static
    value: ${host_name_1}
  - name: REMOTE_HOST_HA_IP
    type: static
    value: ${remote_ha_int}
  - name: SELF_IP_EXTERNAL
    type: static
    value: ${self_ip_external}
  - name: SELF_IP_INTERNAL
    type: static
    value: ${self_ip_internal}
  - name: SELF_IP_HA
    type: static
    value: ${self_ip_ha}
  - name: MANAGEMENT_GATEWAY
    type: static
    value: ${management_gateway}
  - name: EXTERNAL_GATEWAY
    type: static
    value: ${external_gateway}
  - name: VIP0
    type: static
    value: ${vip0}
  - name: VIP1
    type: static
    value: ${vip1}
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
        label: Failover VIA-LB 4NIC BIG-IP declaration for DO with PAYG
        Common:
          class: Tenant
          dbVars:
            class: DbVariables
            restjavad.useextramb: true
            provision.extramb: 2048
            dhclient.mgmt: disable
            config.allow.rfc3927: enable
            ui.advisory.enabled: true
            ui.advisory.color: green
            ui.advisory.text: "BIG-IP 4-NIC Failover via-api /w netsync PAYG"
          mySystem:
            autoPhonehome: true
            class: System
            hostname: '{{{ HOST_NAME }}}.local'
          myProvisioning:
            class: Provision
            ltm: nominal
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
            password: '{{{ ADMIN_PASS }}}'
            shell: bash
          external:
            class: VLAN
            tag: 10
            mtu: 1500
            interfaces:
              - name: '1.1'
                tagged: false
          external-self:
            class: SelfIp
            address: '{{{ SELF_IP_EXTERNAL }}}/24'
            vlan: external
            allowService: default
            trafficGroup: traffic-group-local-only
          internal:
            class: VLAN
            interfaces:
              - name: '1.2'
                tagged: false
            mtu: 1500
            tag: 20
          internal-self:
            class: SelfIp
            address: '{{{ SELF_IP_INTERNAL }}}/24'
            vlan: internal
            allowService: default
            trafficGroup: traffic-group-local-only
          ha:
            class: VLAN
            interfaces:
              - name: '1.3'
                tagged: false
            mtu: 1500
            tag: 30
          ha-self:
            class: SelfIp
            address: '{{{ SELF_IP_HA }}}/24'
            vlan: ha
            allowService: default
            trafficGroup: traffic-group-local-only
          default:
            class: ManagementRoute
            gw: '{{{ MANAGEMENT_GATEWAY }}}'
            network: default          
          azure-metadata:
            class: ManagementRoute
            gw: '{{{ MANAGEMENT_GATEWAY }}}'
            network: 169.254.169.254/32
          default-route:
            class: Route
            gw: '{{{ EXTERNAL_GATEWAY }}}'
            network: default
            mtu: 1500
          configsync:
            class: ConfigSync
            configsyncIp: /Common/ha-self/address
          failoverAddress:
            class: FailoverUnicast
            address: /Common/ha-self/address
          failoverGroup:
            class: DeviceGroup
            type: sync-failover
            members:
              - '{{{ HOST_NAME_0 }}}.local'
              - '{{{ HOST_NAME_1 }}}.local'
            owner: /Common/failoverGroup/members/0
            autoSync: true
            saveOnAutoSync: false
            networkFailover: true
            fullLoadOnSync: false
            asmSync: false
          mirrorIP:
            class: MirrorIp
            primaryIp: '{{{ SELF_IP_HA }}}'
            secondaryIp: '{{{ SELF_IP_INTERNAL }}}'
          trust:
            class: DeviceTrust
            localUsername: '{{{ USER_NAME }}}'
            localPassword: '{{{ ADMIN_PASS }}}'
            remoteHost: '{{{ REMOTE_HOST_HA_IP }}}'
            remoteUsername: '{{{ USER_NAME }}}'
            remotePassword: '{{{ ADMIN_PASS }}}'
    - extensionType: as3
      type: inline
      value:
        schemaVersion: 3.0.0
        class: ADC
        remark: HTTPS_App_Service_Discovery
        label: HTTPS_App_Service_Discovery
        Tenant_1:
          class: Tenant
          HTTPS_Service:
            class: Application
            template: https
            serviceMain:
              class: Service_HTTPS
              virtualAddresses:
                - '{{{ VIP0 }}}'
                - '{{{ VIP1 }}}'
              pool: web_pool
              serverTLS:
                bigip: /Common/clientssl
              redirect80: true
              mirroring: L4
            web_pool:
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
post_onboard_enabled: []
EOF

# # Download Runtime-init
#PACKAGE_URL='https://github.com/F5Networks/f5-bigip-runtime-init/releases/download/1.5.1/f5-bigip-runtime-init-1.5.1-1.gz.run'
for i in {1..30}; do
    curl -fv --retry 1 --connect-timeout 5 -L ${INIT_URL} -o "/var/config/rest/downloads/f5-bigip-runtime-init-1.5.1-1.gz.run" && break || sleep 10
done
# Install
bash /var/config/rest/downloads/f5-bigip-runtime-init-1.5.1-1.gz.run -- '--cloud azure'
# Run
f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml
