resource "azurerm_key_vault_secret" "ssh_key" {
  name         = "vm-ssh-key"
  value        = tls_private_key.ssh.private_key_pem
  key_vault_id = azurerm_key_vault.kv.id
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault_secret" "vm_username" {
  name         = "vm-username"
  value        = var.admin_username
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "vm_password" {
  name         = "vm-password"
  value        = var.admin_password
  key_vault_id = azurerm_key_vault.kv.id
}