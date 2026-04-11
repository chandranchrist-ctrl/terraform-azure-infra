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

resource "azurerm_availability_set" "avset" {
  count = var.enable_availability_set ? 1 : 0

  name                = coalesce(var.availability_set_name, "${var.vm_name}-avset")
  location            = var.location
  resource_group_name = var.resource_group_name

  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true

  tags = var.tags
}

locals {
  use_boot_diag   = var.boot_diagnostics_mode != "none"
  use_existing_sa = var.boot_diagnostics_mode == "existing"
  use_create_sa   = var.boot_diagnostics_mode == "create"
}

resource "azurerm_storage_account" "diag" {
  count = local.use_create_sa ? 1 : 0

  name = coalesce(
    var.boot_diagnostics_storage_account_name,
    substr("${lower(replace(var.vm_name, "-", ""))}diag", 0, 24)
  )

  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

locals {
  vm_names = [
    for i in range(var.vm_count) :
    format("%s%02d", var.vm_name, i + 1)
  ]
}

locals {
  use_ssh      = var.auth_mode == "ssh"
  use_password = var.auth_mode == "password"
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = toset(local.vm_names)

  name                = each.key
  computer_name       = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size

  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id
  ]

  disable_password_authentication = local.use_ssh

  admin_username = data.azurerm_key_vault_secret.admin_username.value
  admin_password = local.use_password ? data.azurerm_key_vault_secret.admin_password[0].value : null

  dynamic "admin_ssh_key" {
    for_each = local.use_ssh ? [1] : []

    content {
      username   = data.azurerm_key_vault_secret.admin_username.value
      public_key = data.azurerm_key_vault_secret.ssh_public_key.value
    }
  }

  availability_set_id = var.enable_availability_set && length(var.zones) == 0 ? azurerm_availability_set.avset[0].id : null

  zone = length(var.zones) > 0 ? element(var.zones, index(local.vm_names, each.key) % length(var.zones)) : null

  os_disk {
    name                 = "${each.key}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = var.image_sku
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = local.use_boot_diag ? (
      local.use_existing_sa
      ? data.azurerm_storage_account.diag[0].primary_blob_endpoint
      : azurerm_storage_account.diag[0].primary_blob_endpoint
    ) : null
  }

  identity {
    type = "SystemAssigned"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init.tpl", {
    hostname = each.key
  }))

  tags = var.tags
}

locals {
  data_disks = {
    for pair in setproduct(local.vm_names, var.data_disks) :
    "${pair[0]}-${pair[1].lun}" => {
      vm   = pair[0]
      disk = pair[1]
    }
  }
}

resource "azurerm_managed_disk" "data_disk" {
  for_each = local.data_disks

  name                = "${each.value.vm}-datadisk${each.value.disk.lun}"
  location            = var.location
  resource_group_name = var.resource_group_name

  storage_account_type = each.value.disk.storage_type
  create_option        = "Empty"
  disk_size_gb         = each.value.disk.size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "attach" {
  for_each = local.data_disks

  managed_disk_id    = azurerm_managed_disk.data_disk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.vm[each.value.vm].id

  lun     = each.value.disk.lun
  caching = each.value.disk.caching
}