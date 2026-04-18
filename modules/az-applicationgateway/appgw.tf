# Public IP for Application Gateway
resource "azurerm_public_ip" "appgw-pip" {
  count               = var.enable_public_ip ? 1 : 0 # count = 0 → resource is not created if enable_public_ip = false.
  name                = "${var.env}-appgw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.allocation_method
  sku                 = var.sku
}

# Application Gateway
resource "azurerm_application_gateway" "appgw" {
  name                = "${var.env}-appgw"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  # SKU configuration for Application Gateway
  sku {
    name     = var.sku_name     # The SKU name (Standard_v2, WAF_v2, etc.)
    tier     = var.sku_tier     # The SKU tier (Standard_v2, WAF_v2)
    capacity = var.sku_capacity # Capacity: Number of instances for the gateway
  }

  # Gateway IP Configuration
  gateway_ip_configuration {
    name      = "${var.env}-appgw-subnet" # Logical name for the gateway IP configuration
    subnet_id = var.subnet_id             # Subnet ID where the Application Gateway will be deployed
  }

  # identity {
  #   type = "SystemAssigned"
  # }

  # dynamic "frontend_ip_configuration" {
  #   for_each = var.frontend_ip_name != null ? [var.frontend_ip_name] : []
  #   content {
  #     name = "${var.env}-appgw-fe-ip"

  #     # Attach public IP only if toggle is true
  #     public_ip_address_id = var.enable_public_ip ? azurerm_public_ip.appgw-pip[0].id : null

  #     # Private IP allocation type
  #     private_ip_address_allocation = var.private_ip_allocation
  #   }
  # }

  # dynamic "frontend_port" {
  #   for_each = var.frontend_port_name != null ? [var.frontend_port_name] : []
  #   content {
  #     name = "${var.env}-appgw-fe-port"
  #     port = var.port
  #   }
  # }

  #   frontend_ip_configuration {
  #   name                 = "${var.env}-appgw-fe-ip"
  #   # public_ip_address_id = var.enable_public_ip ? azurerm_public_ip.appgw-pip[0].id : null
  #   public_ip_address_id = var.enable_public_ip ? azurerm_public_ip.appgw-pip[0].id : null
  # }

  # Public Frontend
  dynamic "frontend_ip_configuration" {
    for_each = var.enable_public_ip ? [1] : []

    content {
      name                 = "${var.env}-appgw-public-fe"
      public_ip_address_id = azurerm_public_ip.appgw-pip[0].id
    }
  }

  # Private Frontend
  dynamic "frontend_ip_configuration" {
    for_each = var.enable_private_ip ? [1] : []

    content {
      name                          = "${var.env}-appgw-private-fe"
      subnet_id                     = var.subnet_id
      private_ip_address_allocation = var.private_ip_allocation
      private_ip_address            = var.private_ip_address
    }
  }

  frontend_port {
    name = "${var.env}-appgw-fe-port"
    port = var.port
  }

  frontend_port {
    name = "${var.env}-appgw-fe-port-80"
    port = var.port_http
  }

  # SSL Certificate for SSL Termination 
  # Note: This tells Azure: “Attach this certificate to Application Gateway frontend listener for HTTPS termination.”
  # ssl_certificate {
  #   name                = "${var.env}-${var.workload}-ssl-cert"
  #   key_vault_secret_id = var.ssl_cert_secret_id
  # }

  ssl_certificate {
    name     = "${var.env}-appgw-ssl-cert"
    data     = filebase64("${path.module}/certs/certificate.pfx")
    password = var.ssl_cert_password
  }

  # For SSL upload from GIT.
  # ssl_certificate {
  #   name     = "biztalk-uat-ssl-cert"
  #   data     = filebase64("${path.module}/certs/biztalk.pfx")
  #   password = var.ssl_cert_password
  # }

  # -------------------------------
  # Backend Address Pool
  # - Purpose: Holds the list of backend servers (VMs, VMSS, or IP addresses) that the Application Gateway will route traffic to
  # - Notes: You can have multiple backend pools for different routing rules
  # -------------------------------
  dynamic "backend_address_pool" {
    for_each = local.backend_pools
    content {
      name         = backend_address_pool.value.name
      ip_addresses = lookup(backend_address_pool.value, "ip_addresses", [])
      fqdns        = lookup(backend_address_pool.value, "fqdns", [])
    }
  }

  dynamic "backend_http_settings" {
    for_each = local.http_settings
    content {
      name                  = backend_http_settings.value.name                  # Name of the backend HTTP setting. Must be unique within the Application Gateway.
      port                  = backend_http_settings.value.port                  # Port on the backend server that Application Gateway will send traffic to.  
      protocol              = backend_http_settings.value.protocol              # Protocol to use (Http or Https) when communicating with backend.
      cookie_based_affinity = backend_http_settings.value.cookie_based_affinity # Enable or disable cookie-based affinity (Session Persistence). Options: "Enabled" or "Disabled".
      request_timeout       = backend_http_settings.value.request_timeout       # Time (in seconds) that the Application Gateway waits for a response from the backend before timing out.
      # probe_name            = backend_http_settings.value.probe_name            # Name of the health probe to associate with this backend HTTP setting. Must match a defined health probe in the Application Gateway.
      probe_name = backend_http_settings.value.probe_name != null ? backend_http_settings.value.probe_name : null
    }
  }

  dynamic "probe" {
    for_each = local.probes
    content {
      name                = probe.value.name
      protocol            = probe.value.protocol
      path                = probe.value.path
      interval            = lookup(probe.value, "interval", 30)
      timeout             = lookup(probe.value, "timeout", 30)
      unhealthy_threshold = lookup(probe.value, "unhealthy_threshold", 3)

      host = lookup(probe.value, "host", null)
    }
  }


  # Dynamic block to create HTTP listeners for the Application Gateway
  # Supports single-site and multi-site routing based on the host_name property

  dynamic "http_listener" {
    for_each = local.listeners # Iterates over a map or list of listener definitions from local.listeners
    content {
      name                           = http_listener.value.name                           # Name of the HTTP listener (must be unique in the Application Gateway)
      frontend_ip_configuration_name = http_listener.value.frontend_ip_configuration_name # Name of the frontend IP configuration to associate with this listener (must match a defined frontend IP configuration)  
      frontend_port_name             = http_listener.value.frontend_port_name             # Name of the frontend port to associate with this listener (must match a defined frontend port)
      protocol                       = http_listener.value.protocol                       # Protocol to use for the listener (Http or Https)
      host_name                      = lookup(http_listener.value, "host_name", null)     # Optional host name for multi-site hosting scenarios (e.g., www.example.com). If not specified, the listener will accept traffic for any host.

      ssl_certificate_name = lookup(http_listener.value, "ssl_certificate_name", null)
    }
  }

  dynamic "request_routing_rule" {
    for_each = local.routing_rules
    content {
      name               = request_routing_rule.value.name          # Name of the request routing rule (must be unique in the Application Gateway) 
      rule_type          = request_routing_rule.value.rule_type     # Type of routing rule: "Basic", "PathBasedRouting", "MultiSite", or "Redirect"
      priority           = request_routing_rule.value.priority      # Priority of the rule (lower numbers have higher priority). Required for "Basic", "PathBasedRouting", and "MultiSite" rules. Ignored for "Redirect" rules.
      http_listener_name = request_routing_rule.value.listener_name # Name of the HTTP listener to associate with this routing rule (must match a defined HTTP listener)

      backend_address_pool_name  = lookup(request_routing_rule.value, "backend_pool_name", null)          # Name of the backend address pool to route traffic to (must match a defined backend address pool). Required for "Basic", "PathBasedRouting", and "MultiSite" rules. Ignored for "Redirect" rules.
      backend_http_settings_name = lookup(request_routing_rule.value, "backend_http_settings_name", null) # Name of the backend HTTP settings to use for this routing rule (must match a defined backend HTTP setting). Required for "Basic", "PathBasedRouting", and "MultiSite" rules. Ignored for "Redirect" rules.

      redirect_configuration_name = lookup(request_routing_rule.value, "redirect_name", null) # Name of the redirect configuration to use for this routing rule (must match a defined redirect configuration). Required for "Redirect" rules. Ignored for "Basic", "PathBasedRouting", and "MultiSite" rules.

      url_path_map_name = lookup(request_routing_rule.value, "url_path_map_name", null)
    }
  }

  dynamic "redirect_configuration" {
    for_each = local.redirects # Iterates over a list of redirect configurations from local.redirects
    content {
      name          = redirect_configuration.value.name # Name of the redirect configuration (must be unique in the Application Gateway) 
      redirect_type = redirect_configuration.value.type # Type of redirect: "Permanent" (301), "Found" (302), "SeeOther" (303), or "Temporary" (307)
      target_url    = redirect_configuration.value.url  # URL to which the request should be redirected
    }
  }

  dynamic "url_path_map" {
    for_each = local.url_path_maps # Iterates over a list of URL path maps from local.url_path_maps  
    content {
      name                               = url_path_map.value.name                               # Name of the URL path map (must be unique in the Application Gateway)  
      default_backend_address_pool_name  = url_path_map.value.default_backend_address_pool_name  # Name of the default backend address pool to route traffic to if no path rules match (must match a defined backend address pool)
      default_backend_http_settings_name = url_path_map.value.default_backend_http_settings_name # Name of the default backend HTTP settings to use if no path rules match (must match a defined backend HTTP setting)

      dynamic "path_rule" {
        for_each = url_path_map.value.path_rules # Iterates over a list of path rules defined within each URL path map (url_path_map.value.path_rules) 
        content {
          name                       = path_rule.value.name                       # Name of the path rule (must be unique within the URL path map)
          paths                      = path_rule.value.paths                      # List of URL path patterns to match for this rule (e.g., ["/api/*", "/images/*"]). The Application Gateway will route requests that match these paths to the specified backend.
          backend_address_pool_name  = path_rule.value.backend_address_pool_name  # Name of the backend address pool to route traffic to if the path matches (must match a defined backend address pool)
          backend_http_settings_name = path_rule.value.backend_http_settings_name # Name of the backend HTTP settings to use if the path matches (must match a defined backend HTTP setting)
        }
      }
    }
  }
}