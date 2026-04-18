variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "soft_delete_retention_days" {
  type = number
}

variable "purge_protection_enabled" {
  type = bool
}

variable "enabled_for_deployment" {
  type = bool
}

variable "enabled_for_template_deployment" {
  type = bool
}

variable "allowed_ip_ranges" {
  type = list(string)
}

variable "allowed_subnet_ids" {
  type = list(string)
}

variable "network_acls_default_action" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "certificates" {
  type = list(object({
    name     = string
    pfx_path = string
    password = string
  }))
}

variable "secrets" {
  type = map(string)
}

variable "ssh_public_key" {
  type = string
}

variable "ssh_secret_name" {
  type    = string
  default = "linux-ssh-public-key"
}


variable "public_network_access_enabled" {
  type        = bool
  description = "Enable or disable public network access to the Key Vault"
}

variable "audit_storage_account_name" {
  type = string
}

variable "audit_storage_account_rg" {
  type = string
}

variable "tde_key_name" {
  type    = string
  default = "sql-tde-key"
}