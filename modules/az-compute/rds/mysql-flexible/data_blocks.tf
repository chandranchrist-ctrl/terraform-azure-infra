data "azurerm_key_vault_secret" "mysql_username" {
  name         = var.mysql_username_secret_name
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "mysql_password" {
  name         = var.mysql_password_secret_name
  key_vault_id = var.key_vault_id
}
