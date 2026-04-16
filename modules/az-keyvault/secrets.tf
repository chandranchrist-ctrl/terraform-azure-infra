# resource "azurerm_key_vault_secret" "ssh_key" {
#   name         = "vm-ssh-key"
#   value        = tls_private_key.ssh.private_key_pem
#   key_vault_id = azurerm_key_vault.kv.id
# }

# resource "tls_private_key" "ssh" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

resource "azurerm_key_vault_secret" "secrets" {
  for_each = var.secrets

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_key_vault_access_policy.me
  ]
}

resource "azurerm_key_vault_secret" "ssh_public_key" {
  name         = var.ssh_secret_name
  value        = var.ssh_public_key
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault_access_policy.me]
}