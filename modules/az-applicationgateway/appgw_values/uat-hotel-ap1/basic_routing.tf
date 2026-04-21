locals {
  basic_app_name = "uat-hotel-ap1"

  basic_routing = {

    enabled    = true
    skip_in_tf = false # Set true if you want to keep module in TF state but ignore it

    backend_pools = [
      {
        name         = "${local.basic_app_name}-basic-be"
        ip_addresses = []
      }
    ]

    http_settings = [
      {
        name                  = "${local.basic_app_name}-basic-httphst"
        port                  = 80
        protocol              = "Http"
        cookie_based_affinity = "Disabled"
        request_timeout       = 60
        probe_name            = null
      }
    ]

    routing_rules = [
      {
        name                       = "${local.basic_app_name}-basic-rule"
        listener_name              = "${var.env}-common-lsn"
        backend_pool_name          = "${local.basic_app_name}-basic-be"
        backend_http_settings_name = "${local.basic_app_name}-basic-httphst"
        rule_type                  = "Basic"
        priority                   = 10
      }
    ]

  }
}

output "basic_routing" {
  value = local.basic_routing
}