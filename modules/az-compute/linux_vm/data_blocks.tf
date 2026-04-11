data "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_rg
}

data "azurerm_key_vault_secret" "admin_username" {
  name         = var.admin_username_secret_name
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "admin_password" {
  count        = local.use_password ? 1 : 0
  name         = var.admin_password_secret_name
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "ssh_public_key" {
  name         = var.ssh_public_key_secret_name
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_storage_account" "diag" {
  count               = local.use_existing_sa ? 1 : 0
  name                = var.boot_diagnostics_storage_account_name
  resource_group_name = var.resource_group_name
}