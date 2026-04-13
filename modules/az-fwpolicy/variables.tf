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

# Firewall Policy related Variables
variable "all_vm_cidrs" {
  type        = list(string)
  description = "List of CIDRs for VM subnets / sources"
}

variable "firewall_public_ip" {
  type        = string
  description = "Public IP used for NAT rules"
}