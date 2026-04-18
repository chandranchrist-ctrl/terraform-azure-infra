output "application_gateway_id" {
  value = azurerm_application_gateway.appgw.id
}

output "application_gateway_name" {
  value = azurerm_application_gateway.appgw.name
}

output "application_gateway_frontend_ip" {
  value = azurerm_application_gateway.appgw.frontend_ip_configuration[0].private_ip_address
}

output "application_gateway_backend_pools" {
  value = [for b in azurerm_application_gateway.appgw.backend_address_pool : b.name]
}

output "all_active_routing" {
  value = local.active_configs
}

