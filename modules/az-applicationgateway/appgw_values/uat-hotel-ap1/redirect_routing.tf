locals {
  redirect_app_name = "uat-hotel"

  redirect_routing = {
    enabled    = true
    skip_in_tf = false # Set true if you want to keep module in TF state but ignore it

    backend_pools = [] # Not needed for redirect

    routing_rules = [
      {
        name          = "${local.redirect_app_name}-ap1-redirect-rule"
        listener_name = "${var.env}-http-lsn"
        rule_type     = "Basic" # Type of routing rule. "Basic" means that the rule will route traffic based on the listener and backend pool association without any additional conditions. Other types include "PathBasedRouting" and "MultiSite".
        priority      = 5
        redirect_name = "uat-hotel-ap1-redirect"
      }
    ]

    redirects = [
      {
        name = "uat-hotel-ap1-redirect"
        type = "Permanent"
        url  = "https://uat-hotel.hbdev.co.in"
      }
    ]
  }
}

output "redirect_routing" {
  value = local.redirect_routing
}