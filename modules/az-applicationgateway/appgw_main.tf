/*
Details: about the code in this file.

1. This Terraform configuration defines the main module for an Azure Application Gateway. 

2. It imports routing configurations from a specific application module (Biztalk UAT) and 
aggregates them into a single configuration that can be used to define the Application Gateway resource.

3. The configuration includes backend pools, listeners, HTTP settings, probes, routing rules, redirects, and 
URL path maps based on the active routing configurations defined in the imported module.

*/

/*

1. Update the source path to point to the correct location of your application routing configuration module; whenever adding new routing configurations for different applications. 

Note: This allows you to maintain a modular and organized Terraform codebase where each application's routing configuration is defined in its own module and 
then imported into the main Application Gateway configuration as needed.

*/

module "biztalk_uat" {
  source = "../../modules/az-applicationgateway/appgw_values/biztalk-app-uat"

  frontend_ip_name   = var.frontend_ip_name
  frontend_port_name = var.frontend_port_name
  appgw_hostname     = var.appgw_hostname
  
}


locals {

  # Call each routing module
  all_configs = [      

/*
Note: 
1. Need to update here as well whenever adding new routing configurations for different applications. 
2. This is the list of all routing configurations that will be evaluated to determine which ones are active and should be included in the Application Gateway configuration.
*/ 

  # Biztalk UAT
    module.biztalk_uat.basic_routing,
    module.biztalk_uat.path_based_routing,
    module.biztalk_uat.multisite_routing,
    module.biztalk_uat.redirect_routing,
    module.biztalk_uat.ssl_routing

  # Payment UAT (Example for another application, currently commented out)
    # module.payment_uat.basic_routing,
    # module.payment_uat.path_based_routing,
    # module.payment_uat.multisite_routing,
    # module.payment_uat.redirect_routing,
    # module.payment_uat.ssl_termination_routing

  ]

  #   ssl_config = {
  #   key_vault_rg      = var.key_vault_rg 
  #   key_vault_name    = var.key_vault_name
  #   ssl_cert_name     = var.ssl_cert_name
  #   ssl_cert_password = var.ssl_cert_password
  # }  

  active_configs = [for c in local.all_configs : c if c != null && try(c.enabled, false) && !try(c.skip_in_tf, false)] # Filter the configurations to include only those that are enabled and not marked to be skipped in Terraform. This allows you to easily toggle routing configurations on and off without removing them from the code.
 

# Aggregate all the active routing configurations into a single configuration that can be used to define the Application Gateway resource. This combines the backend pools, listeners, HTTP settings, probes, routing rules, redirects, and URL path maps from all active configurations into a single structure.

  backend_pools  = flatten([for c in local.active_configs : lookup(c, "backend_pools", [])])
  listeners      = flatten([for c in local.active_configs : lookup(c, "listeners", [])])
  http_settings  = flatten([for c in local.active_configs : lookup(c, "http_settings", [])])
  probes         = flatten([for c in local.active_configs : lookup(c, "probes", [])])
  routing_rules  = flatten([for c in local.active_configs : lookup(c, "routing_rules", [])])
  redirects      = flatten([for c in local.active_configs : lookup(c, "redirects", [])])
  url_path_maps  = flatten([for c in local.active_configs : lookup(c, "url_path_maps", [])])
}

output "all_appgw_config" {
  value = local.all_configs # Output the list of all routing configurations for reference. This can be useful for debugging and verification purposes to see which configurations are active and included in the final Application Gateway configuration.
}