variable "env" {
  description = "Prefix for route table names"
  type        = string
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

variable "use_firewall_public_ip" {
  type = bool
}

variable "firewall_public_ip_id" {
  type = string
}

variable "sku" {
  type = string
}

variable "tunneling_enabled" {
  type = bool
}

variable "ip_connect_enabled" {
  type = bool
}

variable "copy_paste_enabled" {
  type = bool
}

variable "file_copy_enabled" {
  type = bool
}

variable "zones" {
  type    = list(string)
  default = null
}

variable "kerberos_enabled" {
  type = bool
}

variable "subnet_id" {
  type = string
}