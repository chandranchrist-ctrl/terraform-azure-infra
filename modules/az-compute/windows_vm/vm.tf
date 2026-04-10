locals {
  vm_names = [
    for i in range(var.vm_count) :
    format("%s%02d", var.vm_name_prefix, i + 1)
  ]
}

resource "azurerm_network_interface" "nic" {
  for_each = toset(local.vm_names)

  name                = "${each.key}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = var.ip_config_name
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_allocation

    public_ip_address_id = var.enable_public_ip ? azurerm_public_ip.pip[each.key].id : null
  }

  tags = var.tags
}

resource "azurerm_public_ip" "pip" {
  for_each = var.enable_public_ip ? toset(local.vm_names) : toset([])

  name                = "${each.key}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name

  allocation_method = "Static"
  sku               = "Standard"

  tags = var.tags
}

resource "azurerm_availability_set" "this" {
  count = var.enable_availability_set ? 1 : 0

  name                = coalesce(var.availability_set_name, "${var.vm_name_prefix}-avset")
  location            = var.location
  resource_group_name = var.resource_group_name

  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed = true

  tags = var.tags
}

resource "azurerm_storage_account" "diag" {
  count = var.enable_boot_diagnostics ? 1 : 0

  name                     = substr("${lower(replace(var.vm_name_prefix, "-", ""))}diag01", 0, 24)
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_windows_virtual_machine" "vm" {
  for_each = toset(local.vm_names)

  name                = each.key
  computer_name       = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size

  admin_username = data.azurerm_key_vault_secret.admin_username.value
  admin_password = data.azurerm_key_vault_secret.admin_password.value

  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id
  ]

  availability_set_id = var.enable_availability_set ? azurerm_availability_set.this[0].id : null

  zone                = length(var.zones) > 0 ? element(var.zones, index(local.vm_names, each.key) % length(var.zones)) : null
  license_type        = var.license_type

  boot_diagnostics {
    storage_account_uri = var.enable_boot_diagnostics ? azurerm_storage_account.diag[0].primary_blob_endpoint : null
  }

  os_disk {
    name                 = "${each.key}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_type
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.image_sku
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

locals {
  data_disks = {
    for pair in setproduct(local.vm_names, var.data_disks) :
    "${pair[0]}-${pair[1].lun}" => {
      vm  = pair[0]
      disk = pair[1]
    }
  }
}

resource "azurerm_managed_disk" "data_disk" {
  for_each = local.data_disks

  name                 = "${each.value.vm}-datadisk-${each.value.disk.lun}"
  location             = var.location
  resource_group_name  = var.resource_group_name

  storage_account_type = each.value.disk.storage_type
  create_option        = "Empty"
  disk_size_gb         = each.value.disk.size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "attach" {
  for_each = local.data_disks

  managed_disk_id    = azurerm_managed_disk.data_disk[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.vm[each.value.vm].id

  lun     = each.value.disk.lun
  caching = each.value.disk.caching
}