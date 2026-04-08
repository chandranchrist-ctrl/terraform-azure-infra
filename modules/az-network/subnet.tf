locals {
  subnet_map = merge([
    for vnet_key, subnets in var.subnet_address_space : {
      for subnet_key, cidr in subnets :
      "${vnet_key}-${subnet_key}" => {
        vnet_key   = vnet_key
        subnet_key = subnet_key
        cidr       = cidr
      }
    }
  ]...)
}

resource "azurerm_subnet" "subnet" {
  for_each = local.subnet_map

  name = (
    can(regex("subnet$", lower(each.value.subnet_key)))
    ? each.value.subnet_key
    : "${var.prefix}-${each.value.vnet_key}-${each.value.subnet_key}-subnet"
  )

  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.vnet_key].name
  address_prefixes     = each.value.cidr
}