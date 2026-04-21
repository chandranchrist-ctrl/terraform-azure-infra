locals {
  path_app_name = "uat-hotel"

  path_based_routing = {

    enabled    = false
    skip_in_tf = false # Set true if you want to keep module in TF state but ignore it

    backend_pools = [
      {
        name         = "${local.path_app_name}-ap1"
        ip_addresses = [] # 
      },
      {
        name         = "${local.path_app_name}-api"
        ip_addresses = ["10.0.2.11"]
      }
    ]

    routing_rules = [
      {
        name              = "${local.path_app_name}-rule"
        listener_name     = "${var.env}-common-lsn"
        rule_type         = "PathBasedRouting"
        priority          = 15
        url_path_map_name = "${local.path_app_name}-urlpathmap"
      }
    ]

    http_settings = [
      {
        name                  = "${local.path_app_name}-ap1-httphst"
        port                  = 80
        protocol              = "Http"
        cookie_based_affinity = "Disabled"
        request_timeout       = 60
        probe_name            = "${local.path_app_name}-ap1-probe"
      },
      {
        name                  = "${local.path_app_name}-api-httphst"
        port                  = 80
        protocol              = "Http"
        cookie_based_affinity = "Disabled"
        request_timeout       = 60
        probe_name            = "${local.path_app_name}-api-probe"
      }
    ]

    url_path_maps = [
      {
        name = "${local.path_app_name}-urlpathmap"

        default_backend_address_pool_name  = "${local.path_app_name}-ap1"
        default_backend_http_settings_name = "${local.path_app_name}-ap1-httphst"

        path_rules = [
          {
            name                       = "ap1-rule"
            paths                      = ["/*"]
            backend_address_pool_name  = "${local.path_app_name}-ap1"
            backend_http_settings_name = "${local.path_app_name}-ap1-httphst"
          },
          {
            name                       = "api-rule"
            paths                      = ["/api/*"]
            backend_address_pool_name  = "${local.path_app_name}-api"
            backend_http_settings_name = "${local.path_app_name}-api-httphst"
          }
        ]
      }
    ]

    probes = [
      {
        name     = "${local.path_app_name}-ap1-probe"
        protocol = "Http"
        path     = "/"
        host     = "uat-hotel-ap1.hbdev.co.in"
      },
      {
        name     = "${local.path_app_name}-api-probe"
        protocol = "Http"
        path     = "/health"
        host     = "uat-hotel-api.hbdev.co.in"
      }
    ]
  }
}

output "path_based_routing" {
  value = local.path_based_routing
}