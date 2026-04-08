# Public IP (only for Public LB)
resource "azurerm_public_ip" "lb_public_ip" {
  count               = var.frontend_ip_type == "Public" ? 1 : 0
  name                = var.public_ip_name != "" ? var.public_ip_name : "${var.lb_name}-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.allocation_method
  sku                 = var.sku
}

# Load Balancer
resource "azurerm_lb" "lb" {
  name                = var.lb_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku_name

  frontend_ip_configuration {
    name                 = "${var.lb_name}-fe"
    subnet_id            = var.frontend_ip_type == "Private" ? var.subnet_id : null
    public_ip_address_id = var.frontend_ip_type == "Public" && length(azurerm_public_ip.lb_public_ip) > 0 ? azurerm_public_ip.lb_public_ip[0].id : null
  }
}

# Backend Pools
resource "azurerm_lb_backend_address_pool" "backend_pools" {
  for_each = { for bp in local.backend_pools : bp.name => bp }
  name            = each.value.name
  loadbalancer_id = azurerm_lb.lb.id
}

# Flatten all probes
locals {
  all_probes = flatten([
    for bp in local.backend_pools : [
      for p in bp.probes : merge(p, { pool = bp.name })
    ]
  ])
}

resource "azurerm_lb_probe" "probes" {
  for_each = { for p in local.all_probes : p.name => p }

  name                = each.value.name
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = each.value.protocol
  port                = each.value.port
  interval_in_seconds = each.value.interval_in_seconds
  number_of_probes    = each.value.number_of_probes
}

# Flatten all LB rules
locals {
  all_lb_rules = flatten([
    for bp in local.backend_pools : [
      for r in bp.lb_rules : merge(r, { backend_pool = bp.name })
    ]
  ])
}

resource "azurerm_lb_rule" "lb_rules" {
  for_each = { for r in local.all_lb_rules : r.name => r }

  name                           = each.value.name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pools[each.value.backend_pool].id]
  probe_id                       = lookup(azurerm_lb_probe.probes, each.value.probe_name, null) != null ? azurerm_lb_probe.probes[each.value.probe_name].id : null
}

# Flatten all NAT Pools
locals {
  all_nat_pools = flatten([
    for bp in local.backend_pools : [
      for np in bp.nat_pools : merge(np, { pool = bp.name })
    ]
  ])
}

resource "azurerm_lb_nat_pool" "nat_pools" {
  for_each = { for np in local.all_nat_pools : np.name => np }

  name                           = each.value.name
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = each.value.protocol
  frontend_port_start            = each.value.frontend_port_start
  frontend_port_end              = each.value.frontend_port_end
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
}

# Flatten all NAT Rules
locals {
  all_nat_rules = flatten([
    for bp in local.backend_pools : [
      for nr in bp.nat_rules : merge(nr, { pool = bp.name })
    ]
  ])
}

resource "azurerm_lb_nat_rule" "nat_rules" {
  for_each = { for nr in local.all_nat_rules : nr.name => nr }

  name                           = each.value.name
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
}

# Outbound Rule (Internet)
resource "azurerm_lb_outbound_rule" "out_rules" {
  for_each = { for o in local.outbound_rules : o.name => o }

  name            = each.value.name
  loadbalancer_id = azurerm_lb.lb.id
  protocol        = each.value.protocol
  allocated_outbound_ports = each.value.allocated_outbound_ports
  backend_address_pool_id  = values(azurerm_lb_backend_address_pool.backend_pools)[0].id

  frontend_ip_configuration {
    name = "${var.lb_name}-fe"
  }
}