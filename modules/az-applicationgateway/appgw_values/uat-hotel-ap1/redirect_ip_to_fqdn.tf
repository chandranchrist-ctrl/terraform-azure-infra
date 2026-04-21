locals {
  ip_to_fqdn = {
    enabled = true # toggle ON/OFF

    # Backend is empty because we are just redirecting IP to FQDN
    backend_pools = []

    # Listener for the public IP without hostname
    listeners = [
      {
        name     = "ip-listener"
        protocol = "Http"
        # No host_name, so it catches requests by IP
        frontend_ip_configuration_name = "${var.env}-appgw-public-fe"
        frontend_port_name             = "${var.env}-appgw-fe-port-80"
      }
    ]

    # Redirect configuration to FQDN
    redirects = [
      {
        name = "ip-to-fqdn"
        type = "Permanent"                      # Permanent (301) or Temporary (302) redirect
        url  = "https://uat-hotel.hbcdev.co.in" # The FQDN to which IP requests will be redirected
      }
    ]

    # Routing rule to tie listener → redirect
    routing_rules = [
      {
        name          = "ip-redirect-rule"
        listener_name = "ip-listener" # The listener that catches IP requests
        rule_type     = "Basic"       # Basic rule that applies the redirect; no backend pool or HTTP settings needed
        priority      = 7             # Priority of the rule (lower number means higher priority); adjust as needed to ensure it takes precedence over other rules
        redirect_name = "ip-to-fqdn"  # The redirect configuration to apply when this rule matches
      }
    ]

    # No HTTP settings or probes needed
    http_settings = []
    probes        = []
  }
}

output "ip_to_fqdn" {
  value = local.ip_to_fqdn # Output the configuration for reference or use in other modules if needed
}
