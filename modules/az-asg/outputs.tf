output "asg" {
  value = var.create_asg ? {
    id    = azurerm_application_security_group.asg[0].id
    name  = azurerm_application_security_group.asg[0].name
    ports = var.ports
  } : null
}