resource "azurerm_monitor_diagnostic_setting" "mysql" {
  count = var.enable_diagnostics ? 1 : 0

  name               = "${var.db_servername}-diag"
  target_resource_id = azurerm_mysql_flexible_server.mysql.id

  storage_account_id = var.diagnostic_storage_account_id

  enabled_log {
    category = "MySqlAuditLogs"
  }

  enabled_log {
    category = "MySqlErrorLogs"
  }

  enabled_log {
    category = "MySqlSlowQueryLogs"
  }
}