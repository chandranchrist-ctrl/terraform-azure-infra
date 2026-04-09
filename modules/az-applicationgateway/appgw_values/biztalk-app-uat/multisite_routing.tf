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
  multisite_app_name = "uat-biztalk"

  multisite_routing = {
    enabled = false
    skip_in_tf  = false  # Set true if you want to keep module in TF state but ignore it

    backend_pools = [
      { name = "${local.multisite_app_name}-site1-be", ip_addresses = ["10.0.2.20"] },      # List of backend pool members (IP addresses of the application servers). This is where the Application Gateway will route traffic to.
      { name = "${local.multisite_app_name}-site2-be", ip_addresses = ["10.0.2.21"] }
    ],

    listeners = [
      {
        name                           = "${local.multisite_app_name}-ms1-listener",  # Name of the listener to associate with this routing rule. This must match the name of a defined listener in the Application Gateway.
        frontend_ip_configuration_name = "${local.multisite_app_name}-ms1-feip",  # Name of the frontend IP configuration to associate with this listener. This must match the name of a defined frontend IP configuration in the Application Gateway.  
        frontend_port_name             = "${local.multisite_app_name}-ms1-feport",  # Name of the frontend port to associate with this listener. This must match the name of a defined frontend port in the Application Gateway.
        protocol                       = "Http",    # Protocol for the listener (Http or Https). Determines how the Application Gateway listens for incoming traffic.
        host_name                      = "site1.uat.biztalk.com"  # Host name for the listener. This is used for routing decisions based on the host header in incoming requests.
      },
      {
        name                           = "${local.multisite_app_name}-ms2-listener",
        frontend_ip_configuration_name = "${local.multisite_app_name}-ms2-feip",
        frontend_port_name             = "${local.multisite_app_name}-ms2-feport",
        protocol                       = "Http",
        host_name                      = "site2.uat.biztalk.com"
      }
    ],

    routing_rules = [
      {
        name                       = "${local.multisite_app_name}-ms1-rule",   # Name of the routing rule. This is used to identify the rule within the Application Gateway configuration.
        listener_name              = "${local.multisite_app_name}-ms1-listener", # Name of the listener to associate with this routing rule. This must match the name of a defined listener in the Application Gateway.
        backend_pool_name          = "${local.multisite_app_name}-ms1-be", # Name of the backend pool to route traffic to when this rule is matched. This must match the name of a defined backend pool in the Application Gateway.
        backend_http_settings_name = "${local.multisite_app_name}-ms1-httphst", # Name of the backend HTTP settings to use for this routing rule. This must match the name of a defined backend HTTP setting in the Application Gateway.
        rule_type                  = "Basic",   # Type of routing rule. "Basic" means that the rule will route traffic based on the listener and backend pool association without any additional conditions. Other types include "PathBasedRouting" and "MultiSite".
        priority                   = 20        # Priority of the routing rule. This determines the order in which rules are evaluated when processing incoming requests. Lower numbers have higher priority.  
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

    http_settings = [         # Port on which the backend pool members are listening. The Application Gateway will forward traffic to this port on the backend servers.
      { name = "${local.multisite_app_name}-ms1-httphst", port = 80, protocol = "Http", cookie_based_affinity = "Disabled", request_timeout = 60, probe_name = "${local.multisite_app_name}-ms1-probe" },
      { name = "${local.multisite_app_name}-ms2-httphst", port = 80, protocol = "Http", cookie_based_affinity = "Disabled", request_timeout = 60, probe_name = "${local.multisite_app_name}-ms2-probe" }
    ],

    probes = [                # Health probes are used to monitor the health of backend pool members. You can define custom probes that check specific endpoints on your application servers to ensure they are healthy before routing traffic to them.
      { name = "${local.multisite_app_name}-ms1-probe", protocol = "Http", path = "/health" },
      { name = "${local.multisite_app_name}-ms2-probe", protocol = "Http", path = "/health" }
    ],

    redirects    = [],
    url_path_maps = []
  }
}

output "multisite_routing" {
  value = local.multisite_routing # Output the multi-site routing configuration for use in other parts of the Terraform configuration. This allows you to reference this configuration when defining the Application Gateway resource and apply it conditionally based on the "enabled" flag.
}