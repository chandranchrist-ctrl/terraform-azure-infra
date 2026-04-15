variable "env" {
  description = "Prefix for route table names"
  type        = string
}

variable "workload" {
  type = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}


variable "db_servername" {
  type = string
}

variable "db_name" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "delegated_subnet_id" {
  type = string
}

# variable "key_vault_id" {
#   type = string
# }

variable "mysql_credentials_secret_name" {
  type    = string
}

variable "key_vault_id" {
  type = string
}

variable "zone" {
  type    = string
  default = null
}

variable "allowed_ips" {
  type    = list(string)
  default = []
}

# =========================
# MySQL Config (NO DEFAULTS)
# =========================

variable "sku_name" {
  type = string
}

variable "db_version" {
  type = string
}

variable "backup_retention_days" {
  type = number
}

variable "geo_redundant_backup_enabled" {
  type = bool
}

variable "enable_private_dns" {
  type = bool
}

variable "enable_private_network" {
  type = bool
}

variable "storage_size_gb" {
  type = number
}

variable "enable_ha" {
  type = bool
}

variable "ha_mode" {
  type = string
}

variable "maintenance_day" {
  type = number
}

variable "maintenance_hour" {
  type = number
}


variable "replication_role" {
  type = string
}

variable "create_mode" {
  type = string
}

variable "source_server_id" {
  type = string
}

variable "replica_location" {
  type = string
}

variable "server_configurations" {
  type = map(object({
    value = string
  }))
  default = {}
}

variable "enable_diagnostics" {
  type    = bool
  default = false
}

variable "diagnostic_storage_account_id" {
  type    = string
  default = null
}