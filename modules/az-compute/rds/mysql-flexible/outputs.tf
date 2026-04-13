output "mysql_fqdn" {
  value = azurerm_mysql_flexible_server.mysql.fqdn
}

output "mysql_id" {
  value = azurerm_mysql_flexible_server.mysql.id
}

output "private_dns_zone" {
  value = try(azurerm_private_dns_zone.mysql[0].name, null)
}