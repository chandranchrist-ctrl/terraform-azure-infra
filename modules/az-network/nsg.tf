locals {
  nsg_map = merge([
    for vnet_key, subnets in var.subnet_address_space : {
      for subnet_key in keys(subnets) :
      "${vnet_key}-${subnet_key}" => {
        vnet_key   = vnet_key
        subnet_key = subnet_key
      }
      # if !strcontains(lower(subnet_key), "subnet")
      if !can(regex("subnet$", lower(subnet_key)))
    }
  ]...)
}

resource "azurerm_network_security_group" "nsg" {
  for_each = local.nsg_map

  name                = "${var.prefix}-${each.value.vnet_key}-${each.value.subnet_key}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = local.nsg_map

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

locals {
  nsg_rules_flat = merge([
    for subnet_key, rules in local.nsg_rules : {
      for rule in rules :
      "${subnet_key}-${rule.name}" => {
        subnet_key = subnet_key
        rule       = rule
      }
    }
  ]...)
}

resource "azurerm_network_security_rule" "nsg_rule" {
  for_each = local.nsg_rules_flat

  name      = each.value.rule.name
  priority  = each.value.rule.priority
  direction = each.value.rule.direction
  access    = each.value.rule.access
  protocol  = each.value.rule.protocol

  source_port_range          = each.value.rule.source_port_range
  destination_port_range     = each.value.rule.destination_port_range
  source_address_prefix      = each.value.rule.source_address_prefix
  destination_address_prefix = each.value.rule.destination_address_prefix

  # Attach ASG if provided
  destination_application_security_group_ids = var.asg != null ? [var.asg.id] : null

  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[each.value.subnet_key].name
}