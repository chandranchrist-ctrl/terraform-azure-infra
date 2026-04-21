locals {
  multisite_app_name = "uat-hotel"

  multisite_routing = {
    enabled    = true
    skip_in_tf = false # Set true if you want to keep module in TF state but ignore it

    backend_pools = [
      { name = "${local.multisite_app_name}-ms1-be", ip_addresses = ["10.0.2.20"] },
      { name = "${local.multisite_app_name}-ms2-be", ip_addresses = ["10.0.2.21"] }
    ],

    listeners = [
      {
        name                           = "${local.multisite_app_name}-ms1-listener",
        frontend_ip_configuration_name = "uat-appgw-public-fe",
        frontend_port_name             = "uat-appgw-fe-port",
        protocol                       = "Https",
        host_name                      = "uat-hotel-ap1.hbdev.co.in"
        ssl_certificate_name           = "uat-appgw-ssl-cert"
      },
      {
        name                           = "${local.multisite_app_name}-ms2-listener",
        frontend_ip_configuration_name = "uat-appgw-public-fe",
        frontend_port_name             = "uat-appgw-fe-port",
        protocol                       = "Https",
        host_name                      = "uat-hotel-api.hbdev.co.in"
        ssl_certificate_name           = "uat-appgw-ssl-cert"
      }
    ],

    routing_rules = [
      {
        name                       = "${local.multisite_app_name}-ms1-rule",
        listener_name              = "${local.multisite_app_name}-ms1-listener",
        backend_pool_name          = "${local.multisite_app_name}-ms1-be",
        backend_http_settings_name = "${local.multisite_app_name}-ms1-httphst",
        rule_type                  = "Basic",
        priority                   = 20
      },
      {
        name                       = "${local.multisite_app_name}-ms2-rule",
        listener_name              = "${local.multisite_app_name}-ms2-listener",
        backend_pool_name          = "${local.multisite_app_name}-ms2-be",
        backend_http_settings_name = "${local.multisite_app_name}-ms2-httphst",
        rule_type                  = "Basic",
        priority                   = 21
      }
    ],

    http_settings = [
      {
        name                  = "${local.multisite_app_name}-ms1-httphst"
        port                  = 80
        protocol              = "Http"
        cookie_based_affinity = "Disabled"
        request_timeout       = 60
        probe_name            = "${local.multisite_app_name}-ms1-probe"
      },
      {
        name                  = "${local.multisite_app_name}-ms2-httphst"
        port                  = 80
        protocol              = "Http"
        cookie_based_affinity = "Disabled"
        request_timeout       = 60
        probe_name            = "${local.multisite_app_name}-ms2-probe"
      }
    ],

    probes = [
      {
        name     = "${local.multisite_app_name}-ms1-probe",
        protocol = "Http",
        path     = "/health",
        host     = "uat-hotel-ap1.hbdev.co.in"
      },
      {
        name     = "${local.multisite_app_name}-ms2-probe",
        protocol = "Http",
        path     = "/health",
        host     = "uat-hotel-api.hbdev.co.in"
      }
    ],

  }
}

output "multisite_routing" {
  value = local.multisite_routing
}