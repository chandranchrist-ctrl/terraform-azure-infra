locals {
  nat_rules = [
    for r in [
      {
        name                  = "http-to-web"
        priority              = 400
        enabled               = true
        source_addresses      = ["*"]
        destination_addresses = [local.firewall_address]
        destination_ports     = ["80"]
        translated_address    = "10.2.1.70"
        translated_port       = "80"
        protocols             = ["TCP"]
      },
      {
        name                  = "https-to-web"
        priority              = 410
        enabled               = true
        source_addresses      = ["*"]
        destination_addresses = [local.firewall_address]
        destination_ports     = ["443"]
        translated_address    = "10.2.1.70"
        translated_port       = "443"
        protocols             = ["TCP"]
      }
    ] : r if r.enabled
  ]
}

locals {
  firewall_address = var.firewall_mode == "public" ? azurerm_public_ip.fwpip[0].ip_address : azurerm_firewall.fw.ip_configuration[0].private_ip_address
}

resource "azurerm_firewall_nat_rule_collection" "nat" {
  for_each = { for r in local.nat_rules : r.name => r }

  name                = each.value.name
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.resource_group_name
  priority            = each.value.priority
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