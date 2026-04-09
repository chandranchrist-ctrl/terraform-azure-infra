# # Optional: Fetch SSL certificate from Azure Key Vault
# data "azurerm_key_vault" "kv" {
#   name                = "my-keyvault"
#   resource_group_name = "my-keyvault-rg"
# }

# data "azurerm_key_vault_certificate" "biztalk_ssl" {
#   name         = "biztalk-uat-ssl-cert"
#   key_vault_id = data.azurerm_key_vault.kv.id
# }

############################################################
# Local configuration for SSL Termination Routing
############################################################
locals {
  ssl_routing = {
    enabled = true

    # Backend pool(s)
    backend_pools = [
      {
        name         = "uat-biztalk-ssl-be"
        ip_addresses = ["10.0.2.30"]
      }
    ]

    # Listeners
    listeners = [
      {
        name                         = "uat-biztalk-ssl-listener"
        frontend_ip_configuration_name = var.frontend_ip_name
        frontend_port_name             = var.frontend_port_name
        protocol                       = "Https"
        host_name                      = var.appgw_hostname
      }
    ]

    # # SSL Configuration - Metadata
    # ssl_config = {
    #   ssl_cert_name     = data.azurerm_key_vault_certificate.biztalk_ssl.name
    #   key_vault_name    = data.azurerm_key_vault.kv.name
    #   key_vault_rg      = data.azurerm_key_vault.kv.resource_group_name

    # # THIS is the important part
    #   secret_id      = data.azurerm_key_vault_certificate.biztalk_ssl.secret_id

    # }

    # HTTP settings
    http_settings = [
      {
        name                  = "uat-biztalk-ssl-httphst"
        port                  = 443
        protocol              = "Https"
        cookie_based_affinity = "Disabled"
        request_timeout       = 60
        probe_name            = "uat-biztalk-ssl-probe"
      }
    ]

    # Health probes
    probes = [
      {
        name     = "uat-biztalk-ssl-probe"
        protocol = "Https"
        path     = "/health"
      }
    ]

    # Routing rules
    routing_rules = [
      {
        name                     = "uat-biztalk-ssl-rule"
        listener_name            = "uat-biztalk-ssl-listener"
        backend_pool_name        = "uat-biztalk-ssl-be"
        backend_http_settings_name = "uat-biztalk-ssl-httphst"
        rule_type                = "Basic"
        priority                 = 50
        ssl_certificate_name     = "biztalk-uat-ssl-cert"
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
  value       = local.ssl_routing
}

# output "ssl_config" {
#   description = "SSL certificate configuration for App Gateway"
#   value       = local.ssl_routing.ssl_config
#   sensitive   = true
# }