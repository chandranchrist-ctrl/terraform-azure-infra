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

variable "vnet_address_space" {
  type = map(list(string))
}

variable "subnet_address_space" {
  type = map(map(list(string)))
}

variable "asg" {
  description = "Optional ASG to attach to this NSG. Pass null if no ASG is required."
  type = object({
    id    = string
    name  = string
    ports = list(number)
  })
  default = null
}