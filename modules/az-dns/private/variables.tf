variable "zones" {
  description = "List of private DNS zones"
  type        = list(string)
}

variable "resource_group_name" {
  type = string
}

variable "vnet_ids" {
  description = "List of VNet IDs to link DNS zones"
  type        = list(string)
}