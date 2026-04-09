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
      db  = ["10.1.1.64/26"]
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

  lb_name             = "${local.prefix}-lb-Public"     # change to "${local.prefix}-lb-Private" for private LB

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  # Public IP
  allocation_method = "Static"
  sku               = "Standard"

  # LB Configuration
  sku_name                  = "Standard"       # Standard or Basic
  frontend_ip_type          = "Public"         # Public or Private
  subnet_id                 = ""               # Empty means Public LB
  #subnet_id               = module.virtual_network.subnets["spoke"]["web"]  # For Private LB # Works if subnet output exists with spoke\web key; adjust if subnet naming is different.
}

module "appgw" {
  source = "../../modules/az-applicationgateway"

  prefix              = local.prefix

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  # appgw Public IP
  allocation_method = "Static"
  sku               = "Standard"

  # SKU configuration for Application Gateway
  sku_name     = "${local.prefix}-appgw-Standard_v2"          # The SKU name (Standard_v2, WAF_v2, etc.)
  sku_tier     = "Standard_v2"                                # The SKU tier (Standard_v2, WAF_v2)
  sku_capacity = 1                                            # Capacity: Number of instances for the gateway 

  # Gateway IP Configuration
  subnet_id           = module.virtual_network.subnets["hub"] ["AppGatewaySubnet"]          # Subnet ID where the Application Gateway will be deployed 

  # Frontend IP Configuration
  enable_public_ip    = true                                          # set to false to create internal-only App Gateway without public IP
  private_ip_allocation = "Static"                                    # Private IP allocation type for Application Gateway frontend (Dynamic or Static)

  # Frontend Port
  application_gateway_hostname     = "uat.biztalk.com" # The hostname that the redirect listener will catch; this should match the host header of incoming requests that you want to redirect from IP to FQDN.
  port = 80                                                           # Port number for incoming traffic (e.g., 80 for HTTP, 443 for HTTPS)

  # Required variables for routing modules
  appgw_hostname      = "uat.biztalk.com"
  frontend_ip_name    = "${local.prefix}-appgw-frontend-ip"
  frontend_port_name  = "${local.prefix}-appgw-frontend-port"
}