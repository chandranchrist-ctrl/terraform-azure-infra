variable "location" {}

variable "resource_group_name" {}

variable "vm_name" {
  description = "Name for the VM"
}

variable "vm_count" {
  type        = number
  description = "Number of VMs to create"
}

variable "vm_size" {}


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

variable "image_sku" {}

variable "zones" {
  type    = list(string)
  default = []
}

variable "enable_public_ip" {
  type = bool
}

variable "data_disks" {
  type = list(object({
    size_gb      = number
    lun          = number
    caching      = string
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

variable "ssh_public_key_secret_name" {
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

variable "auth_mode" {
  type = string

  validation {
    condition     = contains(["ssh", "password"], var.auth_mode)
    error_message = "auth_mode must be 'ssh' or 'password'"
  }
}

variable "boot_diagnostics_storage_account_name" {
  type    = string
  default = null
}

variable "boot_diagnostics_mode" {
  type    = string
  default = "create"

  validation {
    condition     = contains(["create", "existing", "none"], var.boot_diagnostics_mode)
    error_message = "boot_diagnostics_mode must be create, existing, or none"
  }
}

variable "key_vault_id" {
  type        = string
  description = "The resource ID of the Key Vault containing the SSL certificate for Application Gateway SSL termination"
}