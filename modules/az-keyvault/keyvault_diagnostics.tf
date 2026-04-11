resource "azurerm_monitor_diagnostic_setting" "kv_audit" {
  name               = "${var.name}-audit"
  target_resource_id = azurerm_key_vault.kv.id

  storage_account_id = data.azurerm_storage_account.kv_audit.id

  enabled_log {
    category = "AuditEvent"
  }
}