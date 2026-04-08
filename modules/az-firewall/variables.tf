variable "prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "subnets_map" {
  type        = map(string)
  description = "Map of subnet name → subnet ID"
}

variable "allocation_method" {
  type        = string
  description = "Allocation method for public IP addresses"
  default     = "Static"
}

variable "sku" {
  type        = string
  description = "SKU for the public IP addresses"
  default     = "Standard"
}

variable "sku_name" {
  type        = string
  description = "Azure Firewall SKU name"
  default     = "AZFW_VNet"
}

variable "sku_tier" {
  type        = string
  description = "Tier of Azure Firewall: Basic, Standard, Premium"
  default     = "Standard"
}

variable "zones" {
  type        = list(string)
  description = "Optional list of zones for Azure Firewall"
  default     = []
}

variable "firewall_policy_id" {
  type        = string
  default     = null
  description = "Firewall Policy ID (required for Standard/Premium)"
}