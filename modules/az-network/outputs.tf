# VNets
output "vnets" {
  value = {
    for k, v in azurerm_virtual_network.vnet :
    k => {
      id   = v.id
      name = v.name
      cidr = v.address_space
    }
  }
}

# Subnets
output "subnets" {
  value = {
    for k, v in azurerm_subnet.subnet :
    k => {
      id   = v.id
      name = v.name
      cidr = v.address_prefixes
    }
  }
}

output "subnet_lookup" {
  value = {
    for k, v in azurerm_subnet.subnet :
    local.subnet_map[k].subnet_key => v.id
  }
}

# output "subnets_map" {
#   value = {
#     for k, v in azurerm_subnet.subnet :
#     k => {
#       id         = v.id
#       vnet_key   = local.subnet_map[k].vnet_key
#       subnet_key = local.subnet_map[k].subnet_key
#       type       = try(local.subnet_map[k].tags.type, "infra")
#     }
#   }
# }

# NSGs
output "nsgs" {
  value = {
    for k, v in azurerm_network_security_group.nsg :
    k => {
      id   = v.id
      name = v.name
    }
  }
}

