# OPTIONAL PUBLIC IP (ONLY IF NOT USING FIREWALL IP)
resource "azurerm_public_ip" "bastion_pip" {
  name                = "${var.env}-bastion-pip"
  location            = var.location
  resource_group_name = var.resource_group_name

  allocation_method = "Static"
  sku               = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "${var.env}-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  sku = var.sku

  tunneling_enabled  = var.tunneling_enabled
  ip_connect_enabled = var.ip_connect_enabled
  copy_paste_enabled = var.copy_paste_enabled
  file_copy_enabled  = var.file_copy_enabled

  zones = var.zones

  # Explicitly disabled (your requirement)
  kerberos_enabled = var.kerberos_enabled

  ip_configuration {
    name                 = "${var.env}-bastion-ipconfig"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}