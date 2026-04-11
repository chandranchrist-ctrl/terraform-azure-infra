terraform {
  cloud {
    organization = "hbcdev"

    workspaces {
      name = "staging"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.67.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "xxxx-xxxx-xxxx" # change manually when needed
}

locals {
  prefix = "uat"
}

module "rg" {
  source = "../../modules/az-rg"

  prefix = local.prefix

  # Input Variables
  resource_group_name     = "${local.prefix}-rg"
  resource_group_location = "eastus"

  tags = {
    environment = "uat"
    #project     = "webapp"
    #owner       = "devops"
  }
}

module "virtual_network" {
  source = "../../modules/az-network"

  prefix              = local.prefix
  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  # VNet CIDR
  vnet_address_space = {
    hub   = ["10.0.0.0/16"]
    spoke = ["10.1.0.0/16"]
  }

  # Subnet CIDR
  subnet_address_space = {
    hub = {
      AzureFirewallSubnet           = ["10.0.0.0/26"]
      AppGatewaySubnet              = ["10.0.2.0/24"]
      AzureFirewallManagementSubnet = ["10.0.3.0/26"]
    }
    spoke = {
      web = ["10.1.1.0/26"] #  If subnet name is changed, update the "subnet_keys" in rtvalues.tf accordingly
      app = ["10.1.1.64/26"]
      db  = ["10.1.1.128/26"]
    }
  }

  # Optional ASG from root
  asg = module.asg.asg # attach the ASG to the network module for NSG rule creation
}

module "asg" {
  source = "../../modules/az-asg"

  prefix = local.prefix

  application_name = "biztalk"

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  create_asg = false           # set to true to create ASGs
  ports      = [80, 443, 1433] # ports this ASG allows
}

module "firewall_basic" {
  source = "../../modules/az-firewall-basicsku"

  prefix              = local.prefix
  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  # Optional: Public IP allocation and zones
  allocation_method = "Static"
  sku               = "Standard"

  #FW Configuration
  sku_name = "AZFW_VNet"
  sku_tier = "Basic"
  zones    = []

  all_vm_cidrs = concat(["10.2.1.0/26"], ["10.2.1.64/26"])

  # Only subnets needed for firewall
  subnets_map = module.virtual_network.subnets
}

# # Below code is for creating Azure Firewall (required for Standard/Premium SKU)

# module "firewall" {
#   source = "../../modules/az-firewall"

#   prefix = "${local.prefix}-firewall"

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   # FW PIP & MGMT PIP Configuration
#   allocation_method = "Static"
#   sku               = "Standard"

#   #FW Configuration
#   sku_name = "AZFW_VNet"
#   sku_tier = "Standard"
#   zones = [] # Optional: for zone redundancy; # zones = ["1", "2", "3"] # Optional: for zone redundancy

#   firewall_policy_id = module.fw_policy.policy_id  # Required for Standard/Premium

#   # Only subnets needed for firewall
#   subnets_map = module.virtual_network.subnets
# }

# module "fw_policy" {
#   source = "../../modules/az-fwpolicy"

#   prefix = local.prefix

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   all_vm_cidrs       = concat(["10.2.1.0/26"], ["10.2.1.64/26"]) # example CIDRs for VM subnets; adjust as needed  

#   firewall_public_ip = module.firewall.firewall_pip
# }

module "route_tables" {
  source = "../../modules/az-routetable"

  create_rt = false

  prefix              = "${local.prefix}-rt"
  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  subnets_map = module.virtual_network.subnets

  # optional: pass it if submodule declares it
  # firewall_ip = "10.1.0.4"
  # firewall_ip = module.firewall.private_ip    # enable if firewal is standard sku.
  firewall_ip = module.firewall_basic.private_ip
}

module "vnet_peering" {
  source = "../../modules/az-vnet-peering"


  peerings = {
    hub_to_spoke = {
      name                    = "${local.prefix}-hub-to-spoke"
      resource_group          = module.rg.resource_group_name
      vnet_name               = module.virtual_network.vnets["hub"].name # use name, not ID
      remote_vnet_id          = module.virtual_network.vnets["spoke"].id
      allow_vnet_access       = true
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },
    spoke_to_hub = {
      name                    = "${local.prefix}-spoke-to-hub"
      resource_group          = module.rg.resource_group_name
      vnet_name               = module.virtual_network.vnets["spoke"].name # use name, not ID
      remote_vnet_id          = module.virtual_network.vnets["hub"].id
      allow_vnet_access       = true
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    }
  }
}

module "loadbalancer" {
  source = "../../modules/az-loadbalancer"

  prefix = local.prefix

  lb_name = "${local.prefix}-lb-Public" # change to "${local.prefix}-lb-Private" for private LB

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  # Public IP
  allocation_method = "Static"
  sku               = "Standard"

  # LB Configuration
  sku_name         = "Standard" # Standard or Basic
  frontend_ip_type = "Public"   # Public or Private
  subnet_id        = ""         # Empty means Public LB
  #subnet_id               = module.virtual_network.subnets["spoke"]["web"]  # For Private LB # Works if subnet output exists with spoke\web key; adjust if subnet naming is different.
}

module "appgw" {
  source = "../../modules/az-applicationgateway"

  prefix = local.prefix

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  # appgw Public IP
  allocation_method = "Static"
  sku               = "Standard"

  # SKU configuration for Application Gateway
  sku_name     = "${local.prefix}-appgw-Standard_v2" # The SKU name (Standard_v2, WAF_v2, etc.)
  sku_tier     = "Standard_v2"                       # The SKU tier (Standard_v2, WAF_v2)
  sku_capacity = 1                                   # Capacity: Number of instances for the gateway 

  # Gateway IP Configuration
  subnet_id = module.virtual_network.subnets["hub"]["AppGatewaySubnet"] # Subnet ID where the Application Gateway will be deployed 

  key_vault_id = module.key_vault.key_vault_id


  # Frontend IP Configuration
  enable_public_ip      = true     # set to false to create internal-only App Gateway without public IP
  private_ip_allocation = "Static" # Private IP allocation type for Application Gateway frontend (Dynamic or Static)

  # Frontend Port
  application_gateway_hostname = "uat.biztalk.com" # The hostname that the redirect listener will catch; this should match the host header of incoming requests that you want to redirect from IP to FQDN.
  port                         = 80                # Port number for incoming traffic (e.g., 80 for HTTP, 443 for HTTPS)

  # Required variables for routing modules
  appgw_hostname     = "uat.biztalk.com"
  frontend_ip_name   = "${local.prefix}-appgw-frontend-ip"
  frontend_port_name = "${local.prefix}-appgw-frontend-port"
}

module "windows_vm" {
  source = "../../modules/az-compute/windows_vm"

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  vm_name  = "${local.prefix}-biztalk-ap"
  vm_count = 2

  vm_size   = "Standard_B2s"
  image_sku = "2019-Datacenter"

  # 🔐 KEY VAULT INPUTS (NEW)
  key_vault_name = "your-kv-name" # change manually when needed; ensure this KV exists and has the necessary secrets for admin username and password
  key_vault_rg   = module.rg.resource_group_name
  key_vault_id   = module.key_vault.key_vault_id

  admin_username_secret_name = "admin-username-secret"
  admin_password_secret_name = "admin-password-secret"

  subnet_id = module.virtual_network.subnets["spoke"]["app"]

  private_ip_allocation = "static"

  os_disk_storage_type = "Standard_LRS"

  enable_availability_set = false
  availability_set_name   = "biztalk-avset"

  license_type = "Windows_Server" # Sample: "Windows_Server", "RHEL", "SLES", "Windows_Client"; adjust based on your image and licensing needs


  zones = [] # Sample: ["1", "2", "3"] 


  enable_public_ip = false

  enable_boot_diagnostics               = true
  boot_diagnostics_mode                 = "create" # "none", "existing", or "create"
  boot_diagnostics_storage_account_name = "uatbiztalkdiag"

  data_disks = [
    {
      size_gb      = 128
      lun          = 0
      caching      = "ReadWrite"
      storage_type = "Standard_LRS"
    }
  ]
}

module "linux_vm" {
  source = "../../modules/az-compute/linux_vm"

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  vm_name  = "${local.prefix}-nginx-lnx"
  vm_count = 1
  vm_size  = "Standard_B2s"

  image_sku = "24_04-lts"

  subnet_id = module.virtual_network.subnets["spoke"]["web"]

  private_ip_allocation = "static"

  os_disk_storage_type = "Standard_LRS"

  enable_public_ip = false

  enable_availability_set = false

  availability_set_name = "biztalk-avset"

  zones = [] # Sample: ["1", "2", "3"] 

  enable_boot_diagnostics               = true
  boot_diagnostics_mode                 = "create" # "none", "existing", or "create"
  boot_diagnostics_storage_account_name = "uatbiztalkdiag"

  # 🔐 KEY VAULT INPUTS (NEW)
  key_vault_name = "your-kv-name" # change manually when needed; ensure this KV exists and has the necessary secrets for admin username and password
  key_vault_rg   = module.rg.resource_group_name
  key_vault_id   = module.key_vault.key_vault_id

  auth_mode = "ssh" # "password" or "ssh"


  admin_username_secret_name = "admin-username-secret"
  admin_password_secret_name = "admin-password-secret"
  ssh_public_key_secret_name = "linux-ssh-public-key"

  #   data_disks = [
  #   {
  #     # size_gb = 128
  #     # lun     = 0
  #     # caching = "ReadWrite"
  #     # storage_type = "Standard_LRS"
  #   }
  # ]
}

module "key_vault" {
  source = "../../modules/az-keyvault"

  name = "${local.prefix}-kv"

  location            = module.rg.resource_group_location
  resource_group_name = module.rg.resource_group_name
  tags                = module.rg.tags

  sku_name = "standard" # Standard or Premium

  soft_delete_retention_days = 1
  purge_protection_enabled   = false

  enabled_for_deployment          = true
  enabled_for_template_deployment = true

  public_network_access_enabled = true
  network_acls_default_action   = "Allow" # Deny by default, then allow specific IPs or subnets below

  allowed_ip_ranges = ["49.37.215.245/32"] # Example: allow only specific IPs; adjust as needed

  # For subnet restrictions, ensure the subnets exist and are correctly referenced.
  # service_endpoints = ["Microsoft.KeyVault"] is enabled on those subnets in the network module.

  allowed_subnet_ids = [
    module.virtual_network.subnets["spoke"]["app"],
    module.virtual_network.subnets["hub"]["AppGatewaySubnet"]
  ]

  admin_username = "HBAdmin"
  admin_password = "Qwerty123!"

  certificates = [
    {
      name     = "appgw-cert"
      pfx_path = "./certs/certificate.pfx"
      password = "ChangeMe123!"
    }
  ]

  # Diagnostics Settings Inputs
  audit_storage_account_name = "kvlogstorage"
  audit_storage_account_rg   = "rg-logging"

}

module "storage_account" {
  source = "../../modules/az-storage"

  storage_account_name = "${local.prefix}-storageacc"

  location            = module.rg.resource_group_location
  resource_group_name = module.rg.resource_group_name
  tags                = module.rg.tags

  account_kind          = "StorageV2" # StorageV2, Storage, BlobStorage, FileStorage, BlockBlobStorage
  account_tier          = "Standard"  # Standard or Premium
  replication_type      = "LRS"       # LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS
  dns_endpoint_type     = "Standard"  # Standard or MicrosoftEndpointsOnly
  public_network_access = false       # disable public endpoint for enhanced security; access will be via private endpoint or service endpoints from allowed subnets

  # retention / governance
  blob_versioning_enabled         = false # enable blob versioning for data protection and recovery
  blob_delete_retention_days      = 1     # enable soft delete for blobs with a retention period of 1 day; adjust as needed
  container_delete_retention_days = 1     # enable soft delete for containers with a retention period of 1 day; adjust as needed

  # immutability
  # immutability_period_days = 1

  # network rules
  allowed_subnet_ids = [
    module.virtual_network.subnets["spoke"]["web"],
    module.virtual_network.subnets["spoke"]["app"],
    module.virtual_network.subnets["spoke"]["db"]
  ]
  allowed_ip_rules = ["49.37.215.245/32"] # adjust in real lab
}
