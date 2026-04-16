# Using Access Policies instead of RBAC due to restricted RBAC role assignment permissions in this environment

# RBAC User permission
# resource "azurerm_role_assignment" "kv_secret_reader" {
#   scope                = azurerm_key_vault.kv.id
#   role_definition_name = "Key Vault Secrets User"
#   principal_id         = data.azurerm_client_config.current.object_id
# }


/* Access Policy grants Key Vault access to the current Terraform execution identity.
Used instead of RBAC because RBAC role assignments are restricted in my environment. */

resource "azurerm_key_vault_access_policy" "me" {
  key_vault_id = azurerm_key_vault.kv.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete"
  ]

  certificate_permissions = [
    "Get",
    "List",
    "Create",
    "Import",
    "Delete"
  ]

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Encrypt",
    "Decrypt"
  ]
}