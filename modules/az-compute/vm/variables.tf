variable "location" {}
variable "resource_group_name" {}

variable "vm_name_prefix" {
  description = "Prefix for VM names"
}

variable "vm_count" {
  type        = number
  description = "Number of VMs to create"
}

variable "vm_size" {}

# variable "admin_username" {}
# variable "admin_password" {
#   sensitive = true
# }

variable "subnet_id" {}

variable "ip_config_name" {
  default = "internal"
}

variable "private_ip_allocation" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "os_disk_storage_type" {}

# variable "data_disk_storage_type" {
#   default = "Standard_LRS"
# }

variable "image_sku" {}

variable "license_type" {
  type    = string
  default = null
}

variable "zones" {
  type    = list(string)
  default = []
}

variable "enable_public_ip" {
  type = bool
}

variable "data_disks" {
  type = list(object({
    size_gb = number
    lun     = number
    caching = string
    storage_type = string
  }))
  default = []
}

variable "key_vault_name" {
  type = string
}

variable "key_vault_rg" {
  type = string
}

variable "admin_username_secret_name" {
  type = string
}

variable "admin_password_secret_name" {
  type = string
}

variable "availability_set_name" {
  type = string
}

variable "enable_availability_set" {
  type    = bool
  default = true
}

variable "enable_boot_diagnostics" {
  type    = bool
  default = false
}