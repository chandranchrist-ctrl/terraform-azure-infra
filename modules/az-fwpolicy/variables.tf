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

variable "all_vm_cidrs" {
  type        = list(string)
  description = "List of CIDRs for VM subnets / sources"
}

variable "firewall_public_ip" {
  type        = string
  description = "Public IP used for NAT rules"
}