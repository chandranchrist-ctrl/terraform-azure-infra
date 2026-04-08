output "firewall_id" {
  value = azurerm_firewall.fw.id
}

output "firewall_name" {
  value = azurerm_firewall.fw.name
}

output "firewall_pip" {
  value = azurerm_public_ip.fwpip.ip_address
}

output "firewall_mgmt_pip" {
  value = azurerm_public_ip.fwmgmtpip.ip_address
}

output "firewall_private_ips" {
  value = {
    firewall_main       = azurerm_firewall.fw.ip_configuration[0].private_ip_address
    firewall_management = azurerm_firewall.fw.management_ip_configuration[0].private_ip_address
  }
}

output "private_ip" {
  value       = azurerm_firewall.fw.ip_configuration[0].private_ip_address
  description = "Private IP of the Firewall (main IP only)"
}