# appgw_values/biztalk-uat/redirect_ip_to_fqdn.tf

# This file defines the configuration for redirecting IP-based requests to a specific FQDN in the Application Gateway.

/*
================================================================================
IP-TO-FQDN LISTENER NOTE
================================================================================

1. In the IP-to-FQDN routing module, the listener must reference an actual
   frontend IP configuration and frontend port by their names (e.g., "${var.prefix}-appgw-frontend-ip").

2. Reason:
   - The dynamic http_listener block in appgw.tf only materializes listeners
     defined in the module that provides them (e.g., basic_routing, path_based_routing).
   - IP-to-FQDN is a redirect listener and does not share a listener object from basic_routing.
   - Therefore, we must provide the existing frontend IP & port names explicitly
     so that this redirect listener can attach to the correct IP/port without
     creating a new one.

3. Key point:
   - This does **not** duplicate the frontend IP or port.
   - Multiple listeners (basic, path-based, redirect) can use the same frontend IP & port.
   - By referencing the actual frontend IP & port, the IP-to-FQDN redirect works
     alongside other routing rules on the same Application Gateway.
================================================================================
*/

locals {
  ip_to_fqdn_config = {
    enabled = false # toggle ON/OFF

    # Backend is empty because we are just redirecting IP to FQDN
    backend_pools = []

    # Listener for the public IP without hostname
    listeners = [
      {
        name     = "ip-listener"
        protocol = "Http"
        # No host_name, so it catches requests by IP
        frontend_ip_configuration_name = "${var.prefix}-appgw-frontend-ip"
        frontend_port_name             = "${var.prefix}-appgw-frontend-port"
      }
    ]

    # Redirect configuration to FQDN
    redirects = [
      {
        name = "ip-to-fqdn"
        type = "Permanent"               # Permanent (301) or Temporary (302) redirect
        url  = "https://uat.biztalk.com" # The FQDN to which IP requests will be redirected
      }
    ]

    # Routing rule to tie listener → redirect
    routing_rules = [
      {
        name          = "ip-redirect-rule"
        listener_name = "ip-listener" # The listener that catches IP requests
        rule_type     = "Basic"       # Basic rule that applies the redirect; no backend pool or HTTP settings needed
        priority      = 5             # Priority of the rule (lower number means higher priority); adjust as needed to ensure it takes precedence over other rules
        redirect_name = "ip-to-fqdn"  # The redirect configuration to apply when this rule matches
      }
    ]

    # No HTTP settings or probes needed
    http_settings = []
    probes        = []
  }
}

output "redirect_ip_to_fqdn_config" {
  value = local.ip_to_fqdn_config # Output the configuration for reference or use in other modules if needed
}
