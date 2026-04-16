variable "env" {
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

# Variables for Firewall Public IP creation
variable "allocation_method" {
  type    = string
  default = "Static"
}

variable "sku" {
  type    = string
  default = "Standard"
}


#  Variables for Firewall configuration 
variable "sku_name" {
  type    = string
  default = "AZFW_VNet"
}

variable "sku_tier" {
  type = string
}

variable "zones" {
  type    = list(string)
  default = []
}

variable "all_vm_cidrs" {
  type        = list(string)
  description = "List of VM CIDRs to use in rules"
}

variable "firewall_subnet_id" {
  type = string
}

variable "firewall_management_subnet_id" {
  type = string
}

variable "firewall_mode" {
  type        = string
  description = "public or private firewall mode"
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.firewall_mode)
    error_message = "firewall_mode must be either public or private"
  }
}