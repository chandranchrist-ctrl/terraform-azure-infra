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