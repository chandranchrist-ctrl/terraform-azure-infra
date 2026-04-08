locals {
  nat_rules = [
    for r in [
      {
        name                = "web-1"
        enabled             = true
        source_addresses    = ["*"]
        destination_address = var.firewall_public_ip
        destination_ports   = ["80"]
        translated_address  = "10.2.1.70"
        translated_port     = "80"
        protocols           = ["TCP"]
      }
    ] : r if r.enabled
  ]
}

resource "azurerm_firewall_nat_rule_collection" "nat" {
  for_each = { for r in local.nat_rules : r.name => r }

  name                = each.value.name
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.resource_group_name
  priority            = 400
  action              = "Dnat"

  rule {
    name                  = each.value.name
    source_addresses      = each.value.source_addresses
    destination_addresses = each.value.destination_addresses
    destination_ports     = each.value.destination_ports
    translated_address    = each.value.translated_address
    translated_port       = each.value.translated_port
    protocols             = each.value.protocols
  }
}