# F5 BIG-IP in Azure by using Terraform

**This is a community based project. As such, F5 does not provide any offical support for this project**

This collection of Terraform scripts are focussed on how to deploy an F5 BIG-IP into Azure public cloud.

There are two sections available:
- Azure Quick Starts;
- Azure Use Cases.

## Azure Quick Starts

Quick starts are developed to deliver a quick and easy way to deploy F5 BIG-IP solutions in Azure. It provides a full deployment, including a BIG-IP configuration which delivers application services like availability, health, SSL/TLS offloading and application security, together with a demo application.

One or more F5 BIG-IPs will get deployed in a pre-canned design and provide a full functional solution by just deploying the Terraform script.

Delivered pre-canned designs are:
- Stand-Alone;
- Failover;
- auto-scale.

Go: [Azure Quick Starts](/azure-quickstarts/)

________

## Azure Use Cases

The part of the repo provides BIG-IP use cases.

Sometimes a pre-canned design does not deliver upon the stated requirements. In that it might mean that special solution needs to get developed to show how BIG-IP is still able to support the use case.

That is what this section includes.

Current use cases are:
- BIG-IP Failover via-lb with failover-sync and mirroring enabled

Go: [Azure Use Cases](/azure-use-cases/)