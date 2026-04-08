resource "azurerm_application_security_group" "asg" {
  count = var.create_asg ? 1 : 0 # creates ASG only if true

  name                = "${var.prefix}-${var.application_name}-asg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}