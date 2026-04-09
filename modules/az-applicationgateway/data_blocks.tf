# ############################################################
# # ssl_routing.tf
# # BizTalk UAT App Gateway SSL Routing Configuration
# ############################################################

data "azurerm_key_vault" "kv" {
  name                = "my-keyvault"
  resource_group_name = "my-keyvault-rg"
}

data "azurerm_key_vault_certificate" "biztalk_ssl" {
  name         = "biztalk-uat-ssl-cert"
  key_vault_id = data.azurerm_key_vault.kv.id
}