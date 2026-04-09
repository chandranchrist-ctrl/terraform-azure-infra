variable "prefix" {
  description = "Prefix for naming all resources"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "location" {
  description = "Location of Application Gateway"
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

variable "frontend_port_name" {
  type        = string
  description = "Name of the existing frontend port in Application Gateway"
}

variable "appgw_hostname" {
  type        = string
  description = "The hostname that this redirect listener will catch; this should match the host header of incoming requests that you want to redirect from IP to FQDN."
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
  default     = 80
}

# Routing toggles

variable "enable_basic_routing" {
  type        = bool
  default     = true
}

variable "enable_path_routing" {
  type        = bool
  default     = false
}

variable "enable_multisite_routing" {
  type        = bool
  default     = false
}

variable "enable_redirect_routing" {
  type        = bool
  default     = false
}

variable "enable_ssl_routing" {
  type        = bool
  default     = false
}

variable "application_gateway_hostname" {
  type        = string
  description = "The hostname that this redirect listener will catch; this should match the host header of incoming requests that you want to redirect from IP to FQDN."
}

/*
# Note: 
1. The following variables are used for SSL termination routing configuration. 

2. They allow you to specify the Key Vault and certificate details for the SSL certificate that will be used by the Application Gateway 
     to terminate SSL/TLS connections for incoming traffic on the specified listener. 

3. This enables secure communication between clients and the Application Gateway while allowing the backend servers to receive unencrypted traffic, 
     simplifying backend configuration and improving performance. 
     
4. You can set these variables in your environment-specific Terraform configuration (e.g., staging/main.tf) to provide the necessary information for SSL termination
     routing.

*/

# variable "key_vault_name" {
#   type        = string
#   description = "Name of the existing Key Vault containing the SSL certificate"
# }

# variable "key_vault_rg" {
#   type        = string
#   description = "Resource group of the existing Key Vault"
# }

# variable "ssl_cert_name" {
#   type        = string
#   description = "Name of the SSL certificate in Key Vault"
# }

# variable "ssl_cert_password" {
#   type        = string
#   description = "Password for the SSL certificate if needed"
#   sensitive   = true
# }

