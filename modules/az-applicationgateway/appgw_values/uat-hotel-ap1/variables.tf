variable "frontend_ip_name" {
  type    = string
  default = null # optional
}

variable "frontend_port_name" {
  type    = string
  default = null # optional
}

variable "appgw_hostname" {
  type    = string
  default = null # optional
}

variable "env" {
  description = "Prefix for route table names"
  type        = string
}
