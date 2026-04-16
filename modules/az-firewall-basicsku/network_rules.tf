locals {
  network_allow = [
    for r in [
      {
        name                  = "Allow-DNS"
        priority              = 200
        enabled               = true
        source_addresses      = var.all_vm_cidrs
        destination_addresses = ["*"]
        destination_ports     = ["53"]
        protocols             = ["TCP", "UDP"]
      },
      {
        name                  = "Allow-Internet"
        priority              = 201
        enabled               = true
        source_addresses      = var.all_vm_cidrs
        destination_addresses = ["0.0.0.0/0"]
        destination_ports     = ["80", "443"]
        protocols             = ["TCP"]
      }
    ] : r if r.enabled
  ]

  network_deny = [
    for r in [
      {
        name                  = "Block-Google-DNS"
        priority              = 100
        enabled               = false
        source_addresses      = var.all_vm_cidrs
        destination_addresses = ["8.8.8.8"]
        destination_ports     = ["53"]
        protocols             = ["TCP", "UDP"]
      }
    ] : r if r.enabled
  ]
}

resource "azurerm_firewall_network_rule_collection" "allow" {
  for_each = { for r in local.network_allow : r.name => r }

  name                = each.value.name
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.resource_group_name
  priority            = each.value.priority
  action              = "Allow"

  rule {
    name                  = each.value.name
    source_addresses      = each.value.source_addresses
    destination_addresses = each.value.destination_addresses
    destination_ports     = each.value.destination_ports
    protocols             = each.value.protocols
  }
}

resource "azurerm_firewall_network_rule_collection" "deny" {
  for_each = { for r in local.network_deny : r.name => r }

  name                = each.value.name
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.resource_group_name
  priority            = each.value.priority
  action              = "Deny"

  rule {
    name                  = each.value.name
    source_addresses      = each.value.source_addresses
    destination_addresses = each.value.destination_addresses
    destination_ports     = each.value.destination_ports
    protocols             = each.value.protocols
  }
}