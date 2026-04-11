data "azurerm_client_config" "current" {}

data "azurerm_storage_account" "kv_audit" {
  name                = var.audit_storage_account_name
  resource_group_name = var.audit_storage_account_rg
}