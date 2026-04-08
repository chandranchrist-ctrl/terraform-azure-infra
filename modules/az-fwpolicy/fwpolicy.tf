resource "azurerm_firewall_policy" "fwpolicy" {
  name                = "${var.prefix}-fwpolicy"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "main" {
  name               = "${var.prefix}-rcg"
  firewall_policy_id = azurerm_firewall_policy.fwpolicy.id
  priority           = 100

  ##################################
  # NETWORK RULE COLLECTIONS
  ##################################
  dynamic "network_rule_collection" {
    for_each = length([for r in local.network_allow.rules : r if r.enabled]) > 0 ? [local.network_allow] : []
    content {
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = [for r in network_rule_collection.value.rules : r if r.enabled]
        content {
          name                  = rule.value.name
          source_addresses      = rule.value.source_addresses
          destination_addresses = rule.value.destination_addresses
          destination_ports     = rule.value.destination_ports
          protocols             = rule.value.protocols
        }
      }
    }
  }

  dynamic "network_rule_collection" {
    for_each = length([for r in local.network_deny.rules : r if r.enabled]) > 0 ? [local.network_deny] : []
    content {
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = [for r in network_rule_collection.value.rules : r if r.enabled]
        content {
          name                  = rule.value.name
          source_addresses      = rule.value.source_addresses
          destination_addresses = rule.value.destination_addresses
          destination_ports     = rule.value.destination_ports
          protocols             = rule.value.protocols
        }
      }
    }
  }

  ##################################
  # APPLICATION RULES
  ##################################
  dynamic "application_rule_collection" {
    for_each = length([for r in local.application_rules.rules : r if r.enabled]) > 0 ? [local.application_rules] : []
    content {
      name     = application_rule_collection.value.name
      priority = application_rule_collection.value.priority
      action   = application_rule_collection.value.action

      dynamic "rule" {
        for_each = [for r in local.application_rules.rules : r if r.enabled]
        content {
          name             = rule.value.name
          source_addresses = rule.value.source_addresses

          protocols {
            type = "Http"
            port = 80
          }
          protocols {
            type = "Https"
            port = 443
          }

          destination_fqdns = rule.value.destination_fqdns
        }
      }
    }
  }

  ##################################
  # NAT RULE COLLECTIONS
  ##################################
  dynamic "nat_rule_collection" {
    for_each = length([for r in local.nat_rules.rules : r if r.enabled]) > 0 ? [local.nat_rules] : []
    content {
      name     = nat_rule_collection.value.name
      priority = nat_rule_collection.value.priority
      action   = nat_rule_collection.value.action

      dynamic "rule" {
        for_each = [for r in nat_rule_collection.value.rules : r if r.enabled]
        content {
          name                = rule.value.name
          source_addresses    = rule.value.source_addresses
          destination_address = rule.value.destination_address
          destination_ports   = rule.value.destination_ports
          translated_address  = rule.value.translated_address
          translated_port     = rule.value.translated_port
          protocols           = rule.value.protocols
        }
      }
    }
  }
}