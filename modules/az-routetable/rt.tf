locals {
  route_tables_map = { for rt in local.route_definitions : rt.name => rt }
}

resource "azurerm_route_table" "rt" {
  for_each = var.create_rt ? local.route_tables_map : {}

  name                = "${var.prefix}-${each.key}-rt"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

locals {
  all_routes = flatten([
    for rt in local.route_definitions : [
      for r in rt.routes : {
        rt_name = rt.name
        route   = r
      }
    ]
  ])
}

resource "azurerm_route" "dynamic_routes" {
  for_each = var.create_rt ? { for r in local.all_routes : "${r.rt_name}-${r.route.name}" => r } : {}

  name                   = each.value.route.name
  route_table_name       = azurerm_route_table.rt[each.value.rt_name].name
  resource_group_name    = var.resource_group_name
  address_prefix         = each.value.route.address_prefix
  next_hop_type          = each.value.route.next_hop_type
  next_hop_in_ip_address = lookup(each.value.route, "next_hop_ip_address", var.firewall_ip)
}

locals {
  all_subnet_associations = flatten([
    for rt in local.route_definitions : [
      for sk in rt.subnet_keys : {
        rt_name   = rt.name
        subnet_id = var.subnets_map[sk].id # picks the correct subnet
      }
    ]
  ])
}

resource "azurerm_subnet_route_table_association" "rt_assoc" {
  for_each = var.create_rt ? { for a in local.all_subnet_associations : "${a.rt_name}-${a.subnet_id}" => a } : {}

  subnet_id      = each.value.subnet_id
  route_table_id = azurerm_route_table.rt[each.value.rt_name].id
}