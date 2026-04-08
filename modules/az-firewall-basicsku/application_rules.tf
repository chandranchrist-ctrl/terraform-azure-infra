locals {
  application_rules = [
    for r in [
      {
        name              = "block-social"
        enabled           = true
        source_addresses  = var.all_vm_cidrs
        destination_fqdns = ["*.youtube.com", "*.facebook.com", "*.instagram.com"]
      },
      {
        name              = "block-github"
        enabled           = false
        source_addresses  = var.all_vm_cidrs
        destination_fqdns = ["*.github.com"]
      }
    ] : r if r.enabled
  ]
}

resource "azurerm_firewall_application_rule_collection" "app" {
  for_each = { for r in local.application_rules : r.name => r }

  name                = each.value.name
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.resource_group_name
  priority            = 300
  action              = "Deny"

  rule {
    name             = each.value.name
    source_addresses = each.value.source_addresses
    target_fqdns     = each.value.destination_fqdns

    protocol {
      type = "Http"
      port = 80
    }
    protocol {
      type = "Https"
      port = 443
    }

  }
}