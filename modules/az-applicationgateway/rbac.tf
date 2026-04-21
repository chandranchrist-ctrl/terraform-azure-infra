/* data "azurerm_client_config" "current" {} */

/* 
resource "azurerm_role_assignment" "appgw_kv" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_application_gateway.appgw.identity[0].principal_id
} 
*/

# Access Policy based access to Keyvault
/* 
resource "azurerm_key_vault_access_policy" "appgw_kv" {

  key_vault_id = var.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_application_gateway.appgw.identity[0].principal_id

  certificate_permissions = ["Get", "List"]
} 
*/