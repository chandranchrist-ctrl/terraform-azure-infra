resource "azurerm_role_assignment" "kv_diag_storage_writer" {
  scope                = data.azurerm_storage_account.kv_audit.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}