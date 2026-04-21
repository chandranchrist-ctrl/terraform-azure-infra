variable "env" {
  description = "Prefix for route table names"
  type        = string
}

variable "workload" {
  type = string
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

# Variables for Public IP configuration of Application Gateway
variable "subnet_id" {
  description = "Subnet ID where Application Gateway is deployed"
  type        = string
}

variable "frontend_ip_name" {
  type        = string
  description = "Name of the existing frontend IP configuration in Application Gateway"
}

variable "sku" {
  type        = string
  description = "SKU for the public IP addresses"
  default     = "Standard"
}

variable "allocation_method" {
  type        = string
  description = "Allocation method for public IP addresses"
  default     = "Static"
}

# ---- AppGW Configuration Variables
variable "enable_public_ip" {
  description = "Toggle to create a public IP for Application Gateway. true = public, false = internal only"
  type        = bool
  default     = true
}

variable "private_ip_allocation" {
  description = "Private IP allocation type for Application Gateway frontend (Dynamic or Static)"
  type        = string
  default     = "Dynamic"
}

variable "sku_name" {
  description = "Application Gateway SKU name"
  type        = string
  default     = "Standard_v2"
}

variable "sku_tier" {
  description = "Application Gateway SKU tier"
  type        = string
  default     = "Standard_v2"
}

variable "sku_capacity" {
  description = "Instance count for Application Gateway"
  type        = number
  default     = 1
}

variable "port" {
  description = "Frontend port for Application Gateway"
  type        = number
  default     = 443
}

variable "port_http" {
  description = "Frontend port for Application Gateway"
  type        = number
  default     = 80
}

# Routing toggles
variable "enable_basic_routing" {
  type    = bool
  default = true
}

variable "enable_path_routing" {
  type    = bool
  default = false
}

variable "enable_multisite_routing" {
  type    = bool
  default = false
}

variable "enable_redirect_routing" {
  type    = bool
  default = false
}

variable "enable_ssl_routing" {
  type    = bool
  default = false
}

# variable "key_vault_id" {
#   type        = string
#   description = "The resource ID of the Key Vault containing the SSL certificate for Application Gateway SSL termination"
# }

# variable "ssl_cert_secret_id" {
#   type        = string
#   description = "Key Vault secret ID for SSL certificate"
# }

variable "ssl_cert_password" {
  type        = string
  description = "Password for PFX certificate"
}

variable "frontend_port_name" {
  type        = string
  description = "Name of the existing frontend port in Application Gateway"
}

variable "enable_private_ip" {
  type    = bool
  default = false
}

variable "private_ip_address" {
  type    = string
  default = null
}

variable "backend_ips" {
  description = "List of backend VM private IPs"
  type        = list(string)
  default     = []
}