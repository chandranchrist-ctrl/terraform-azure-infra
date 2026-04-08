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
  type    = string
  default = "Static"
}

variable "sku" {
  type    = string
  default = "Standard"
}

variable "sku_name" {
  type    = string
  default = "AZFW_VNet"
}

variable "sku_tier" {
  type    = string
  default = "Standard"
}

variable "zones" {
  type    = list(string)
  default = []
}

variable "all_vm_cidrs" {
  type        = list(string)
  description = "List of VM CIDRs to use in rules"
}

variable "firewall_public_ip" {
  type        = string
  description = "Public IP of Firewall"
  default     = null
}