# F5 BIG-IP in Azure by using Terraform

**This is a community based project. As such, F5 does not provide any offical support for this project**

-----

**Latest Updates 8 March 2023**

All azure deployments have been updated to the latest F5 Automation ToolChain (ATC) packages:
* Declarative Onboarding (DO): [v1.36.0](https://github.com/F5Networks/f5-declarative-onboarding/releases)
* Application Services 3 Extension (AS3): [v3.43.0](https://github.com/F5Networks/f5-appsvcs-extension/releases)
* Telemetry Streaming (TS): [v1.32.0](https://github.com/F5Networks/f5-telemetry-streaming/releases)
* Cloud Failover Extension (CFE): [v1.14.0](https://github.com/F5Networks/f5-cloud-failover-extension/releases)
* BIG-IP Runtime-Init: [1.6.0](https://github.com/F5Networks/f5-bigip-runtime-init/releases)

**TMOS version**

All BIG-IPs are currently running with TMOS version 16.1.20200. 

When deploying the Terraform scripts with the latest TMOS version 16.1.30200 Telemetry Streaming will fail event log data due to the following error as described in the here: [K05413010: After an upgrade, iRules using the loopback address may fail and log TCL errors](https://my.f5.com/manage/s/article/K05413010).

-----

## Introduction
This collection of Terraform scripts are focussed on how to deploy an F5 BIG-IP into Azure public cloud.

There are two sections available:
- Azure Quick Starts;
- Azure Use Cases.

## Azure Quick Starts

Quick starts are developed to deliver a quick and easy way to deploy F5 BIG-IP solutions in Azure. It provides a full deployment, including a BIG-IP configuration which delivers application services like availability, health, SSL/TLS offloading and application security, together with a demo application.

One or more F5 BIG-IPs will get deployed in a pre-canned design and provide a full functional solution by just deploying the Terraform script.

Delivered pre-canned designs are:
- Standalone;
- Failover;
- auto-scale.

Go: [Azure Quick Starts](/azure-quickstarts/)

