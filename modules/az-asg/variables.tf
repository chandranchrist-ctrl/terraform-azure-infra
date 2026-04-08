variable "prefix" {
  description = "Prefix for ASG names"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name"
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

variable "create_asg" {
  description = "Flag to control ASG creation"
  type        = bool
  default     = true
}


variable "application_name" {
  description = "Application name, used in ASG naming"
  type        = string
}

variable "ports" {
  description = "Ports this ASG represents (used by NSG)"
  type        = list(number)
  default     = []
}
