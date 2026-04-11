resource "azurerm_role_assignment" "appgw_kv" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_application_gateway.appgw.identity[0].principal_id
}