# Public IP for Firewall
resource "azurerm_public_ip" "fwpip" {
  name                = "${var.env}-fwpip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.allocation_method
  sku                 = var.sku
}

# Public IP for Management
resource "azurerm_public_ip" "fwmgmtpip" {
  name                = "${var.env}-fwmgmtpip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.allocation_method
  sku                 = var.sku
}

# Pick subnets automatically
locals {
  subnet_firewall_id   = lookup(var.subnets_map, "AzureFirewallSubnet", null)
  subnet_management_id = lookup(var.subnets_map, "AzureFirewallManagementSubnet", null)
}

# Validation - ensure required subnets exist
locals {
  valid_subnets = (
    local.subnet_firewall_id != null && local.subnet_management_id != null
  )
}

# Azure Firewall
resource "azurerm_firewall" "fw" {
  name                = "${var.env}-fw"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  sku_tier            = var.sku_tier
  zones               = var.zones

  firewall_policy_id = var.firewall_policy_id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = local.subnet_firewall_id
    public_ip_address_id = azurerm_public_ip.fwpip.id
  }

  management_ip_configuration {
    name                 = "management"
    subnet_id            = local.subnet_management_id
    public_ip_address_id = azurerm_public_ip.fwmgmtpip.id
  }
}