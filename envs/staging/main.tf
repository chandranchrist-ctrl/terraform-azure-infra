# terraform {
#   cloud {
#     organization = "hbcdev"

#     workspaces {
#       name = "staging"
#     }
#   }

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "uatstatehoteltf04"
    container_name       = "tfstate"
    key                  = "staging.terraform.tfstate"
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
  subscription_id = "348e7e81-d6e0-436e-a3e4-bdebb9bd9e5b" # change manually when needed
}

locals {
  env      = "uat"
  workload = "hotel"
}

# Phase 1 — Foundation (NO compute)

module "rg" {
  source = "../../modules/az-rg"
  # source = "git::https://github.com/chandl/terraform-azure-infra.git//modules/az-rg?ref=main"

  env      = local.env
  workload = local.workload

  # Input Variables
  resource_group_name     = "${local.env}-rg"
  resource_group_location = "eastus"

  tags = {
    environment = "uat"
    #project     = "webapp"
    #owner       = "devops"
  }
}

module "virtual_network" {
  source = "../../modules/az-network"

  env = local.env
  workload = local.workload

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  # VNet CIDR
  vnet_address_space = {                # VNet key must match the corresponding key in subnet_address_space to map subnets to the correct VNet
    hub   = ["10.0.0.0/16"]
    spoke = ["10.1.0.0/16"]
  }

  # Subnet CIDR

  /*
  =========================================================
  IMPORTANT GLOBAL RULE (DO NOT MODIFY WITHOUT CODE CHANGE)

  This module depends on subnet tags for automation:

    type = "infra"     → excluded from NSG/ASG creation
    type = "workload"  → included for NSG/ASG + security rules

  If you change/remove these values, you MUST update:
    - NSG filtering logic
    - ASG creation logic
    - subnet_map conditions
  =========================================================
  */

subnet_address_space = {            # Subnet key must align with the VNet key to ensure subnets are created within the correct VNet
  hub = {
    AzureFirewallSubnet = {
      cidr = ["10.0.0.0/26"]
      tags = { type = "infra" }
    }

    AppGatewaySubnet = {
      cidr = ["10.0.2.0/24"]
      tags = { type = "infra" }
    }

    AzureFirewallManagementSubnet = {
      cidr = ["10.0.3.0/26"]
      tags = { type = "infra" }
    }

    AzureBastionSubnet = {
      cidr = ["10.0.4.0/26"]
      tags = { type = "infra" }
    }
  }

  spoke = {
    web = {
      cidr = ["10.1.1.0/26"]
      tags = { type = "workload" }
    }

    app = {
      cidr = ["10.1.1.64/26"]
      tags = { type = "workload" }
    }

    db = {
      cidr = ["10.1.1.128/26"]
      tags = { type = "workload" }
      }
    }
  }
}

module "vnet_peering" {
  source = "../../modules/az-vnet-peering"


  peerings = {
    hub_to_spoke = {
      name                    = "${local.env}-hub-to-spoke"
      resource_group          = module.rg.resource_group_name
      vnet_name               = module.virtual_network.vnets["hub"].name # use name, not ID
      remote_vnet_id          = module.virtual_network.vnets["spoke"].id
      allow_vnet_access       = true
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },
    spoke_to_hub = {
      name                    = "${local.env}-spoke-to-hub"
      resource_group          = module.rg.resource_group_name
      vnet_name               = module.virtual_network.vnets["spoke"].name # use name, not ID
      remote_vnet_id          = module.virtual_network.vnets["hub"].id
      allow_vnet_access       = true
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    }
  }
  depends_on = [module.virtual_network]
}

# Phase 2 — Security & Core Services

module "storage_account" {
  source = "../../modules/az-storage"

  storage_account_name = "${local.env}storageaccdiag06"                # Storage Account names must be globally unique across Azure.

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
    module.virtual_network.subnets["spoke-web"].id,
    module.virtual_network.subnets["spoke-app"].id,
    module.virtual_network.subnets["spoke-db"].id
  ]
  allowed_ip_rules = ["49.37.211.249"] # adjust in real lab
}


module "key_vault" {
  source = "../../modules/az-keyvault"

  name = "${local.env}-${local.workload}-kv-06"         # Key Vault names must be globally unique across Azure.

  location            = module.rg.resource_group_location
  resource_group_name = module.rg.resource_group_name
  tags                = module.rg.tags

  sku_name = "standard" # Standard or Premium

  soft_delete_retention_days = 7          # 7 - 90 Days
  purge_protection_enabled   = false

  enabled_for_deployment          = true
  enabled_for_template_deployment = true

  public_network_access_enabled = true
  network_acls_default_action   = "Deny" # Deny by default, then allow specific IPs or subnets below

  allowed_ip_ranges = ["49.37.211.249/32"] # Example: allow only specific IPs; adjust as needed

  # For subnet restrictions, ensure the subnets exist and are correctly referenced.
  # service_endpoints = ["Microsoft.KeyVault"] is enabled on those subnets in the network module.

  allowed_subnet_ids = [
    module.virtual_network.subnets["spoke-app"].id,
    module.virtual_network.subnets["spoke-db"].id,
    module.virtual_network.subnets["hub-AppGatewaySubnet"].id
  ]

  ssh_secret_name = "linux-ssh-public-key"
  ssh_public_key = file("${path.module}/ssh/id_rsa.pub")

secrets = {
  localadmin-credentials = jsonencode({
    admin-username = "HBAdmin",
    admin-password = "Qwerty123!",
  })

  mysql-credentials = jsonencode({
    username = "sqladmin"
    password = "SQLP@ssword!23!"
  })
}

  certificates = [
    {
      name     = "wildcard-cert"
      pfx_path = "./certs/certificate.pfx"
      password = "Y12345Z"
    }
  ]

  # Diagnostics Settings Inputs
  audit_storage_account_name = module.storage_account.storage_account_name          # Ex. "kvlogstorage" to declare the name directly
  audit_storage_account_rg   = module.rg.resource_group_name

  depends_on = [module.storage_account]
}

# module "route_tables" {
#   source = "../../modules/az-routetable"

#   create_rt = false

#   env              = "${local.env}-rt"

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   subnets_map = module.virtual_network.subnet_lookup

#   # optional: pass it if submodule declares it
#   # firewall_ip = "10.1.0.4"
#   firewall_ip = module.firewall.private_ip    # enable if firewal is standard sku.
#   # firewall_ip = module.firewall_basic.private_ip
# }

# module "firewall_basic" {
#   source = "../../modules/az-firewall-basicsku"

#   env = local.env

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   # Optional: Public IP allocation and zones
#   allocation_method = "Static"
#   sku               = "Standard"

#   #FW Configuration
#   sku_name = "AZFW_VNet"            # Firewall deployed in a Virtual Network (not Secure Hub); Basic SKU only supports AZFW_VNet
#   sku_tier = "Basic"
#   zones    = []
#   firewall_mode = "public"
 
#   all_vm_cidrs = concat(["10.1.1.0/26"], ["10.1.1.64/26"])

#   # Only subnets needed for firewall
#   firewall_subnet_id            = module.virtual_network.subnet_lookup["AzureFirewallSubnet"]
#   firewall_management_subnet_id = module.virtual_network.subnet_lookup["AzureFirewallManagementSubnet"]
# }

# # Below code is for creating Azure Firewall (required for Standard/Premium SKU)

# module "firewall" {
#   source = "../../modules/az-firewall"

#   env = local.env

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   # FW PIP & MGMT PIP Configuration
#   allocation_method = "Static"
#   sku               = "Standard"

#   #FW Configuration
#   sku_name = "AZFW_VNet"
#   sku_tier = "Basic"
#   zones = [] # Optional: for zone redundancy; # zones = ["1", "2", "3"] # Optional: for zone redundancy

#   firewall_mode = "public"

#   firewall_policy_id = module.fw_policy.policy_id  # Required for Standard/Premium

#   # Only subnets needed for firewall
#   firewall_subnet_id            = module.virtual_network.subnet_lookup["AzureFirewallSubnet"]
#   firewall_management_subnet_id = module.virtual_network.subnet_lookup["AzureFirewallManagementSubnet"]

# }

# module "fw_policy" {
#   source = "../../modules/az-fwpolicy"

#   env = local.env

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   sku = "Basic"

#   all_vm_cidrs       = concat(["10.1.1.0/26"], ["10.1.1.64/26"]) # example CIDRs for VM subnets; adjust as needed 

#   firewall_public_ip = module.firewall.firewall_pip

# }

# module "bastion" {
#   source = "../../modules/az-bastion"

#   env              = local.env

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   subnet_id = module.virtual_network.subnet_lookup["AzureBastionSubnet"]

#   # firewall_public_ip_id   = module.firewall_basic.firewall_pip_id
#   firewall_public_ip_id   = module.firewall.firewall_pip_id

#   # Bastion SKU
#   sku = "Standard"

#   tunneling_enabled = true
#   ip_connect_enabled = true
#   copy_paste_enabled = true
#   file_copy_enabled  = true

#   zones    = null   # zone = ["1","2","3"]

#   kerberos_enabled = false
# }

# module "windows_vm" {
#   source = "../../modules/az-compute/windows_vm"

#   env = local.env
#   workload = local.workload

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   vm_name  = "${local.env}-${local.workload}-ap"
#   vm_count = 2

#   vm_size   = "Standard_B2s"
#   image_sku = "2019-datacenter-gensecond"

#   subnet_id = module.virtual_network.subnet_lookup["app"]

#   private_ip_allocation = "Dynamic"

#   os_disk_storage_type = "Standard_LRS"
#   os_disk_size_gb      = 127

#   enable_public_ip = false

#   enable_availability_set = false
#   availability_set_name   = "biztalk-avset"

#   zones = null # Sample: ["1", "2", "3"] or null

#   enable_boot_diagnostics               = true
#   boot_diagnostics_mode                 = "existing" # "none", "existing", or "create"
#   boot_diagnostics_storage_account_name = module.storage_account.storage_account_name          # "uatbiztalkdiag"


#   # KEY VAULT INPUTS (NEW)
#   key_vault_id = module.key_vault.key_vault_id                   # change manually when needed; ensure this KV exists and has the necessary secrets for admin username and password
  
#   localadmin_credentials_secret_name = "localadmin-credentials"

#   enable_asg = false

#   enable_lb = false

#   # Scenario 2: Existing LB
#   # lb_name              = "existing-lb-name"
#   # lb_backend_pool_name = "backend-pool-name"

#   lb_backend_pool_id = module.loadbalancer.backend_pool_id

#   license_type = "Windows_Server" # Sample: "Windows_Server", "RHEL", "SLES", "Windows_Client"; adjust based on your image and licensing needs

#   data_disks = [
#     {
#       size_gb      = 127
#       lun          = 0
#       caching      = "ReadWrite"
#       storage_type = "Standard_LRS"
#     }
#   ]

#   # Backup
#   enable_backup = false

#   # Recovery Serivce Vault Configuration
#   recovery_services_vault_name = "existing-rsv"
#   backup_policy_vm  = "existing-policy"

#   # Depends
#   depends_on = [
#   module.key_vault,
#   module.storage_account
# ]
# }

# module "linux_vm" {
#   source = "../../modules/az-compute/linux_vm"

#   env = local.env
#   workload = local.workload

  

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   vm_name  = "${local.env}-nginx-lnx"
#   vm_count = 1

#   vm_size  = "Standard_B2s"
#   image_sku = "18.04-LTS"

#   subnet_id = module.virtual_network.subnet_lookup["web"]

#   private_ip_allocation = "Dynamic"

#   os_disk_storage_type = "Standard_LRS"
#   os_disk_size_gb      = 127

#   enable_public_ip = false

#   enable_availability_set = false

#   availability_set_name = "biztalk-avset"

#   zones = null # Sample: ["1", "2", "3"] or null

#   enable_boot_diagnostics               = true
#   boot_diagnostics_mode                 = "existing" # "none", "existing", or "create"
#   boot_diagnostics_storage_account_name =  module.storage_account.storage_account_name          # "uatbiztalkdiag"

#   # 🔐 KEY VAULT INPUTS (NEW)
#   key_vault_id = module.key_vault.key_vault_id # change manually when needed; ensure this KV exists and has the necessary secrets for admin username and password

#   auth_mode = "ssh" # "password" or "ssh"

#   localadmin_credentials_secret_name = "localadmin-credentials"

#   ssh_public_key_secret_name = "linux-ssh-public-key"

#   enable_asg = false

#   enable_lb = false

#   # Scenario 2: Existing LB
#   # lb_name              = "existing-lb-name"
#   # lb_backend_pool_name = "backend-pool-name"

#   lb_backend_pool_id = module.loadbalancer.backend_pool_id        # null

#   #   data_disks = [
#   #   {
#   #     # size_gb = 128
#   #     # lun     = 0
#   #     # caching = "ReadWrite"
#   #     # storage_type = "Standard_LRS"
#   #   }
#   # ]

#     # Backup
#   enable_backup = false

#   # Recovery Serivce Vault Configuration
#   recovery_services_vault_name = "existing-rsv"
#   backup_policy_vm  = "existing-policy"

#     # Depends
#   depends_on = [
#   module.key_vault,
#   module.storage_account
# ]
# }


# module "loadbalancer" {
#   source = "../../modules/az-loadbalancer"

#   env = local.env
#   workload = local.workload

#   lb_name = "${local.env}-${local.workload}-lb-pub" # change to "${local.env}-lb-Private" for private LB

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   # Public IP
#   allocation_method = "Static"
#   sku               = "Standard"

#   # LB Configuration
#   sku_name         = "Standard" # Standard or Basic
#   frontend_ip_type = "Public"   # Public or Private
#   subnet_id        = null         # Empty means Public LB
#   # subnet_id         = module.virtual_network.subnet_lookup["web"]  # For Private LB # Works if subnet output exists with spoke\web key; adjust if subnet naming is different.
# }

# module "appgw" {
#   source = "../../modules/az-applicationgateway"

#   env = local.env
#   workload = local.workload

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   # appgw Public IP
#   allocation_method = "Static"
#   sku               = "Standard"

#   # SKU configuration for Application Gateway
#   sku_name     = "${local.env}-appgw-Standard_v2" # The SKU name (Standard_v2, WAF_v2, etc.)
#   sku_tier     = "Standard_v2"                       # The SKU tier (Standard_v2, WAF_v2)
#   sku_capacity = 1                                   # Capacity: Number of instances for the gateway 

#   # Gateway IP Configuration
#   subnet_id = module.virtual_network.subnets["hub"]["AppGatewaySubnet"] # Subnet ID where the Application Gateway will be deployed 

#   key_vault_id = module.key_vault.key_vault_id
#   ssl_cert_secret_id = module.key_vault.certificate_secret_ids["wildcard-cert"]

#   # Frontend IP Configuration
#   enable_public_ip      = true     # set to false to create internal-only App Gateway without public IP
#   private_ip_allocation = "Static" # Private IP allocation type for Application Gateway frontend (Dynamic or Static)

#   # Frontend Port
#   application_gateway_hostname = "uat.biztalk.com" # The hostname that the redirect listener will catch; this should match the host header of incoming requests that you want to redirect from IP to FQDN.
#   port                         = 80                # Port number for incoming traffic (e.g., 80 for HTTP, 443 for HTTPS)

#   # Required variables for routing modules
#   appgw_hostname     = "uat.biztalk.com"
#   frontend_ip_name   = "${local.env}-appgw-fe-ip"
#   frontend_port_name = "${local.env}-appgw-fe-port"

#   depends_on = [
#     module.key_vault
#   ]  
# }






# module "mysql" {
#   source = "../../modules/az-compute/rds/mysql-flexible"

#   env = local.env
#   workload = local.workload

#   db_servername = "${local.env}-${local.workload}-db1"
#   db_name = "${local.env}_${local.workload}_db1"


#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   # Server Configuration

#   sku_name = "GP_Standard_D2ds_v4"
#   db_version = "8.0"  
#   zone = null

#   # DB Server to be deployed as public or private 
#   enable_private_network = false
#   enable_private_dns = false

#   vnet_id = module.virtual_network.vnets["spoke"].id
#   delegated_subnet_id  = module.virtual_network.subnets["db"].id

#   # DB allow NACLs from public inbound
#   allowed_ips = ["49.37.211.249"]

#   storage_size_gb = 2


#   # Enable High Availability (HA)
#   enable_ha = false               # false → single instance (no failover); true  → enables standby replica automatically (managed by Azure)
#   ha_mode = "ZoneRedundant"       # HA mode (only used when enable_ha = true); ZoneRedundant → primary + standby in different AZs (best for production); SameZone → primary + standby in same AZ (lower cost, less resilient)
#   replication_role = "None"     # Replication role of this server; None  → standalone server (normal case); Replica → read replica (used for scaling reads)
#   replica_location = null     # Location for replica server (only used when replication_role = "Replica"); Must be a valid Azure region (e.g., "East US", "Central India"); null → not used when replication is disabled


#   # Key Vault Configuration
#   key_vault_id = module.key_vault.key_vault_id
#   mysql_credentials_secret_name = "mysql-credentials"


#   # Backup Config
#   backup_retention_days = 7
#   geo_redundant_backup_enabled = false  # Stores backups in: Another Azure region


#   # Maintenance Window
#   maintenance_day = 7       # Day of week for planned maintenance (Azure patching, updates); maintenance_day = 7   # Sunday
#   maintenance_hour = 1    # Hour of day (UTC) when maintenance starts; # Example: # Range: 0–23; 1 = 01:00 UTC

#   enable_diagnostics = true
#   diagnostic_storage_account_id = module.storage_account.storage_account_id

#   /*
#   Restore / Create Mode
#   Defines how the MySQL server is created
#   Options:
#     Default              → brand new server (normal case)
#     PointInTimeRestore   → restore from backup at specific time
#     GeoRestore           → restore from geo-redundant backup
#     Replica              → create read replica

#   Source server ID (required for restore/replica scenarios)
#     Used when:
#     - Replica
#     - PointInTimeRestore
#     - GeoRestore
#     Example:
#       "/subscriptions/xxx/resourceGroups/rg/providers/Microsoft.DBforMySQL/flexibleServers/server1"
#   */

#   create_mode = "Default"   
#   source_server_id = null 

#   # Depends
#   depends_on = [module.key_vault]
# }