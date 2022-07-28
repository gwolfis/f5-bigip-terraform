# BIG-IP

locals {
  bigip_onboard = templatefile("${path.module}/onboard.tpl", {
    INIT_URL      = var.INIT_URL
    DO_URL        = var.DO_URL
    AS3_URL       = var.AS3_URL
    TS_URL        = var.TS_URL
    DO_VER        = split("/", var.DO_URL)[7]
    AS3_VER       = split("/", var.AS3_URL)[7]
    TS_VER        = split("/", var.TS_URL)[7]
    user_name     = var.user_name
    user_password = var.user_password
    unique_string = var.unique_string
    workspace_id  = azurerm_log_analytics_workspace.law.workspace_id
  })
}

# 
# Create F5 BIG-IP VMSS
resource "azurerm_linux_virtual_machine_scale_set" "f5vmss" {
  name                            = "${var.prefix}-f5vmss"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  sku                             = var.instance_type
  instances                       = var.min_instance_count
  admin_username                  = var.user_name
  admin_password                  = var.user_password
  disable_password_authentication = false
  custom_data                     = base64encode(local.bigip_onboard)

  # automatic rolling upgrade
  
  upgrade_mode  = "Rolling"

  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 20
    pause_time_between_batches              = "PT0S"
  }

  # required when using rolling upgrade policy
  health_probe_id = azurerm_lb_probe.alb_probe_http.id

  depends_on = [azurerm_lb_rule.alb_rule_http]

  plan {
    name      = var.image_name
    publisher = "f5-networks"
    product   = var.product
  }

  source_image_reference {
    publisher = "f5-networks"
    offer     = var.product
    sku       = var.image_name
    version   = var.bigip_version
  }

  os_disk {
    caching              = "None"
    storage_account_type = "Premium_LRS"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.user_identity.id]
  }

  network_interface {
    name                      = "external"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.extnsg.id

    ip_configuration {
      name                                   = "external"
      primary                                = true
      subnet_id                              = azurerm_subnet.external.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bigip_backend_pool.id]

      public_ip_address {
        name = "${var.prefix}-ext-ip"
      }
    }
  }
 
}

resource "azurerm_monitor_autoscale_setting" "f5vm_autoscale" {
  name                = "myAutoscaleSetting"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.f5vmss.id

  profile {
    name = "defaultProfile"

    capacity {
      default = var.default_instance_count
      minimum = var.min_instance_count
      maximum = var.max_instance_count
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.f5vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        dimensions {
          name     = "AppName"
          operator = "Equals"
          values   = ["App1"]
        }
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.f5vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
      custom_emails                         = ["admin@contoso.com"]
    }
  }
}