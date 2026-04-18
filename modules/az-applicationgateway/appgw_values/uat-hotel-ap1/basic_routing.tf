/*
================================================================================
FRONTEND IP & PORT HANDLING IN BASIC, PATH-BASED, MULTI-SITE, REDIRECT, SSL ROUTING
================================================================================

1. Overview:
   - All standard routing modules (basic, path-based, multi-site, redirect, SSL termination)
     require a listener to attach traffic to a frontend IP and port.
   - The frontend IP and frontend port are defined at the Application Gateway level (appgw.tf)
     and act as shared resources across multiple listeners.

2. How it's handled in routing modules:
   a) Listener Definition:
      - Each routing module defines its own listener name and attaches it to a frontend IP
        and port by referencing the corresponding names (e.g., "${local.basic_app_name}-basic-feip").
      - These names are not the actual IP or port values but logical references used
        by the Application Gateway to bind the listener to the correct frontend configuration.

   b) Dynamic Listener Creation in appgw.tf:
      - The dynamic "http_listener" block in appgw.tf iterates over all listeners
        from active routing modules.
      - It creates listeners on the Application Gateway using the provided listener names,
        and associates them with the specified frontend IP and frontend port.
      - This allows multiple routing modules to share the same frontend IP/port or use separate ones if required.

   c) Routing Rule Association:
      - Routing rules (request_routing_rule) in each module reference the listener by name.
      - This decouples the routing logic from the actual frontend configuration,
        allowing modular and reusable routing definitions.
      - Each module can independently define backend pools, path maps, HTTP settings, and rules,
        while still attaching to shared or dedicated frontend IP/port.

3. Key Principles:
   - Frontend IP and port are shared or dedicated resources, never duplicated.
   - Listeners are module-specific but reference common frontend IP/port names.
   - Dynamic blocks in appgw.tf materialize listeners first, then attach routing rules.
   - This modular approach allows enabling/disabling routing configurations without affecting others.

4. Takeaway:
   - Always provide listener names and frontend IP/port names explicitly in each routing module.
   - Routing modules remain independent and modular while correctly binding to the Application Gateway’s frontend configuration.
================================================================================
*/

locals {
  basic_app_name = "uat-hotel-ap1" # Base name for all resources related to this application. Used as a prefix in resource names to ensure uniqueness and easy identification.

  basic_routing = {

    enabled    = true  # Set to true to enable this routing configuration, false to disable it. This allows you to easily toggle the routing setup without removing it from the code.
    skip_in_tf = false # Set true if you want to keep module in TF state but ignore it

    backend_pools = [
      {
        name         = "${local.basic_app_name}-basic-be"
        ip_addresses = ["10.0.2.4"] # List of backend pool members (IP addresses of the application servers). This is where the Application Gateway will route traffic to.                              
      }
    ]

    # listeners = [
    #   {
    #     name                           = "${local.basic_app_name}-basic-lsn"
    #     frontend_ip_configuration_name = "uat-appgw-fe-ip"
    #     frontend_port_name             = "uat-appgw-fe-port"
    #     protocol                       = "Https"            # Protocol for the listener (Http or Https). Determines how the Application Gateway listens for incoming traffic.
    #     host_name                      = "uat-hotel.hbcdev.co.in" # Host name for the listener. This is used for routing decisions based on the host header in incoming requests.
    #     ssl_certificate_name           = "uat-appgw-ssl-cert"
    #   }
    # ]

    http_settings = [
      {
        name                  = "${local.basic_app_name}-basic-httphst"
        port                  = 80         # Port on which the backend pool members are listening. The Application Gateway will forward traffic to this port on the backend servers.
        protocol              = "Http"     # Protocol for communication between the Application Gateway and the backend pool members. This can be Http or Https depending on how your backend servers are configured. 
        cookie_based_affinity = "Disabled" # Determines whether to enable cookie-based session affinity. When enabled, the Application Gateway will route requests from the same client to the same backend pool member based on cookies.
        request_timeout       = 60         # Time (in seconds) that the Application Gateway will wait for a response from the backend pool member before timing out. Adjust this based on the expected response times of your application.
        probe_name            = null       # Name of the health probe to associate with this backend HTTP setting. This is used to determine the health of backend pool members and route traffic only to healthy instances. Set to null if you don't want to associate a probe.
      }
    ]

    routing_rules = [
      {
        name                       = "${local.basic_app_name}-basic-rule"
        listener_name              = "${var.env}-common-lsn"                 # Name of the listener to associate with this routing rule. This must match the name of a defined listener in the Application Gateway.
        backend_pool_name          = "${local.basic_app_name}-basic-be"      # Name of the backend pool to route traffic to when this rule is matched. This must match the name of a defined backend pool in the Application Gateway.
        backend_http_settings_name = "${local.basic_app_name}-basic-httphst" # Name of the backend HTTP settings to use for this routing rule. This must match the name of a defined backend HTTP setting in the Application Gateway.
        rule_type                  = "Basic"                                 # Type of routing rule. "Basic" means that the rule will route traffic based on the listener and backend pool association without any additional conditions. Other types include "PathBasedRouting" and "MultiSite".
        priority                   = 10
      }
    ]

  }
}

output "basic_routing" {
  value = local.basic_routing # Output the basic routing configuration for use in other parts of the Terraform configuration.
}