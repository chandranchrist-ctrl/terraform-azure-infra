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

variable "lb_name" {
  type = string
}

variable "sku" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "frontend_ip_type" {
  type = string
}

variable "subnet_id" {
  type    = string
  default = ""
}

variable "public_ip_name" {
  type    = string
  default = ""
}

variable "allocation_method" {
  type = string
}

variable "backend_address_pool_name" {
  type        = string
  description = "Default backend pool name"
  default     = "lb-backend-pool"
}