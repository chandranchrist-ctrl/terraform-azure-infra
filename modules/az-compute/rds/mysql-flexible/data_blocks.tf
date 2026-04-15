data "azurerm_key_vault_secret" "mysql_credentials" {
  name         = var.mysql_credentials_secret_name
  key_vault_id = var.key_vault_id
}

locals {
  mysql_creds = jsondecode(data.azurerm_key_vault_secret.mysql_credentials.value)
}