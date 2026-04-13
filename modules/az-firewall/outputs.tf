output "firewall_id" {
  value       = azurerm_firewall.fw.id
  description = "The ID of the Azure Firewall"
}

output "firewall_name" {
  value       = azurerm_firewall.fw.name
  description = "The name of the Azure Firewall"
}

output "firewall_pip" {
  value       = azurerm_public_ip.fwpip.ip_address
  description = "Public IP of the Firewall"
}

output "firewall_pip_id" {
  value = azurerm_public_ip.fwpip.id
}

output "firewall_mgmt_pip" {
  value       = azurerm_public_ip.fwmgmtpip.ip_address
  description = "Management Public IP of the Firewall"
}

output "firewall_private_ips" {
  value = {
    firewall_main       = azurerm_firewall.fw.ip_configuration[0].private_ip_address
    firewall_management = azurerm_firewall.fw.management_ip_configuration[0].private_ip_address
  }
  description = "Private IPs of the Firewall (main & management)"
}

output "private_ip" {
  value       = azurerm_firewall.fw.ip_configuration[0].private_ip_address
  description = "Private IP of the Firewall (main IP only)"
}