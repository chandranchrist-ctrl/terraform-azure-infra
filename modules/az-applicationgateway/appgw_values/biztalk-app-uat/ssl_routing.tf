############################################################
# Local configuration for SSL Termination Routing
############################################################
locals {
  ssl_app_name = "uat-biztalk"

  ssl_routing = {
    enabled = true    # Enable SSL routing for this App Gateway configuration

    # Backend pool(s)
    backend_pools = [
      {
        name         = "${local.ssl_app_name}-ssl-be"
        ip_addresses = ["10.0.2.30"]      # IP address of the BizTalk server in UAT
      }
    ]

    # Listeners
    listeners = [
      {
        name                         = "${local.ssl_app_name}-ssl-listener"  
        frontend_ip_configuration_name = var.frontend_ip_name       # Name of the frontend IP configuration to use
        frontend_port_name             = var.frontend_port_name    # Name of the frontend port to use (e.g., "https-port")
        protocol                       = "Https"                  # Use HTTPS protocol for SSL routing
        host_name                      = var.appgw_hostname   ## Optional: Specify the hostname for SNI-based routing (e.g., "biztalk-uat.contoso.com")
      }
    ]

    # HTTP settings
    http_settings = [
      {
        name                  = "${local.ssl_app_name}-ssl-httphst"   # Name of the HTTP settings configuration
        port                  = 443                   # Port on which the backend pool is listening (HTTPS)
        protocol              = "Https"         # Use HTTPS protocol for backend communication
        cookie_based_affinity = "Disabled"        # Optional: Configure cookie-based affinity if needed (e.g., "Enabled" or "Disabled")
        request_timeout       = 60                # Optional: Set request timeout in seconds (default is 20 seconds)
        probe_name            = "${local.ssl_app_name}-ssl-probe"            
      }
    ]

    # Health probes
    probes = [
      {
        name     = "${local.ssl_app_name}-ssl-probe"     # Name of the health probe configuration
        protocol = "Https"                # Use HTTPS protocol for health checks
        path     = "/health"          # Path to check for health status (e.g., "/health" or "/status")
      }
    ]

    # Routing rules
    routing_rules = [
      {
        name                     = "${local.ssl_app_name}-ssl-rule"   # Name of the routing rule configuration
        listener_name            = "${local.ssl_app_name}-ssl-listener"             # Name of the listener to associate with this routing rule
        backend_pool_name        = "${local.ssl_app_name}-ssl-be"                    # Name of the backend pool to route traffic to
        backend_http_settings_name = "${local.ssl_app_name}-ssl-httphst"  # Name of the HTTP settings to use for this routing rule
        rule_type                = "Basic"                    # Type of routing rule (e.g., "Basic" for simple routing or "PathBasedRouting" for path-based routing)
        priority                 = 50                         # Optional: Set priority for the routing rule (lower number means higher priority)
        ssl_certificate_name     = "biztalk-uat-ssl-cert"       # Name of the SSL certificate to use for this routing rule (must match the name of the certificate defined in the App Gateway configuration)
      }
    ]

    # Optional features
    redirects      = []
    url_path_maps  = []
  }
}

############################################################
# Outputs for App Gateway module
############################################################

output "ssl_routing" {
  description = "Full SSL routing configuration for App Gateway"      
  value       = local.ssl_routing           # Output the entire SSL routing configuration as a single object for use in the App Gateway module
}

# output "ssl_config" {
#   description = "SSL certificate configuration for App Gateway"
#   value       = local.ssl_routing.ssl_config
#   sensitive   = true
# }