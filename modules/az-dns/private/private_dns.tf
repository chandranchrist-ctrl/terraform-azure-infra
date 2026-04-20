# 1. CREATE PRIVATE DNS ZONES
resource "azurerm_private_dns_zone" "zones" {
  for_each = toset(var.zones)

  name                = each.value
  resource_group_name = var.resource_group_name
}


# 2. PREPARE ZONE ↔ VNET COMBINATIONS
locals {
  zone_vnet_links = flatten([
    for zone in var.zones : [
      for idx, vnet_id in var.vnet_ids : {
        key     = "${replace(zone, ".", "-")}-vnet-${idx}" # static key
        zone    = zone
        vnet_id = vnet_id
      }
    ]
  ])
}

# 3. LINK DNS ZONES TO VNets
resource "azurerm_private_dns_zone_virtual_network_link" "links" {
  for_each = {
    for item in local.zone_vnet_links :
    item.key => item
  }

  name = each.key

  resource_group_name   = var.resource_group_name
  private_dns_zone_name = each.value.zone
  virtual_network_id    = each.value.vnet_id

  registration_enabled = false
}