# Public IP for Firewall
resource "azurerm_public_ip" "fwpip" {
  name                = "${var.prefix}-fwpip-${var.sku_tier}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.allocation_method
  sku                 = var.sku
}

# Public IP for Firewall Management
resource "azurerm_public_ip" "fwmgmtpip" {
  name                = "${var.prefix}-fwmgmtpip-${var.sku_tier}"
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

# Azure Firewall
resource "azurerm_firewall" "fw" {
  name                = "${var.prefix}-fw-${var.sku_tier}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  sku_tier            = var.sku_tier
  zones               = var.zones

  # Firewall IP Configuration
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