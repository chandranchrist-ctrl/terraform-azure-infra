locals {
  redirect_app_name = "uat-hotel"

  redirect_routing = {
    enabled    = true
    skip_in_tf = false # Set true if you want to keep module in TF state but ignore it

    backend_pools = [] # Not needed for redirect

    # listeners = [
    #   {
    #     name                           = "${local.redirect_app_name}-ap1-redirect-lsn"
    #     protocol                       = "Http"                 # Protocol for the listener (Http or Https). Determines how the Application Gateway listens for incoming traffic. For redirects, this is typically Http since we're redirecting to an HTTPS endpoint.
    #     frontend_ip_configuration_name = var.frontend_ip_name   # e.g., existing App Gateway frontend IP
    #     frontend_port_name             = var.frontend_port_name # e.g., port 80
    #     host_name                      = "uat-hotel-ap1.hbdev.co.in"     # This tells the gateway to catch requests for this domain
    #   },
    #   {
    #     name                           = "${local.redirect_app_name}-api-redirect-lsn"
    #     protocol                       = "Http"                 # Protocol for the listener (Http or Https). Determines how the Application Gateway listens for incoming traffic. For redirects, this is typically Http since we're redirecting to an HTTPS endpoint.
    #     frontend_ip_configuration_name = var.frontend_ip_name   # e.g., existing App Gateway frontend IP
    #     frontend_port_name             = var.frontend_port_name # e.g., port 80
    #     host_name                      = "uat-hotel-api.hbdev.co.in"     # This tells the gateway to catch requests for this domain
    #   }
    # ]

    routing_rules = [
      {
        name          = "${local.redirect_app_name}-ap1-redirect-rule"
        listener_name = "${var.env}-http-lsn"
        rule_type     = "Basic" # Type of routing rule. "Basic" means that the rule will route traffic based on the listener and backend pool association without any additional conditions. Other types include "PathBasedRouting" and "MultiSite".
        priority      = 5
        redirect_name = "uat-hotel-ap1-redirect" # Name of the redirect configuration to use for this routing rule. This must match the name of a defined redirect configuration in the Application Gateway. The redirect configuration specifies the type of redirect (e.g., Permanent, Found) and the target URL to which traffic should be redirected.
      }
    ]

    redirects = [
      {
        name = "uat-hotel-ap1-redirect"
        type = "Permanent"                     # IP → FQDN
        url  = "https://uat-hotel.hbdev.co.in" # Target URL for the redirect. This is the URL to which incoming traffic will be redirected when this rule is matched. In this case, we're redirecting to the HTTPS endpoint of the application.
      }
    ]
  }
}

output "redirect_routing" {
  value = local.redirect_routing # Output the redirect routing configuration for use in other parts of the Terraform configuration. This allows you to reference this configuration when defining the Application Gateway resource and apply it conditionally based on the "enabled" flag.
}