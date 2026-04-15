resource "azurerm_private_dns_zone" "mysql" {
  count = var.enable_private_dns ? 1 : 0
  name  = "privatelink.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  count = var.enable_private_dns ? 1 : 0

  name                  = "${var.env}-mysql-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mysql[0].name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_mysql_flexible_server_firewall_rule" "allow_ips" {
  for_each = toset(var.allowed_ips)

  name                = replace("${each.value}-allow", ".", "-")
  resource_group_name = var.resource_group_name
  server_name        = azurerm_mysql_flexible_server.mysql.name

  start_ip_address = each.value
  end_ip_address   = each.value
}

resource "azurerm_mysql_flexible_server" "mysql" {
  name                = var.db_servername
  resource_group_name = var.resource_group_name
  location            = var.location

  administrator_login    = local.mysql_creds.username
  administrator_password = local.mysql_creds.password

  sku_name   = var.sku_name
  version    = var.db_version

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  zone = var.zone

  delegated_subnet_id = var.enable_private_network ? var.delegated_subnet_id : null

  private_dns_zone_id = var.enable_private_dns ? azurerm_private_dns_zone.mysql[0].id : null
  
  dynamic "high_availability" {
    for_each = var.enable_ha ? [1] : []
    content {
      mode = var.ha_mode
    }
  }

  storage {
    size_gb = var.storage_size_gb
  }

  maintenance_window {
    day_of_week  = var.maintenance_day
    start_hour   = var.maintenance_hour
    start_minute = 0
  }

  replication_role = var.replication_role

  tags = var.tags
}

# Database creation
resource "azurerm_mysql_flexible_database" "db" {
  name                = var.db_name
  resource_group_name = var.resource_group_name
  server_name        = azurerm_mysql_flexible_server.mysql.name
  charset            = "utf8mb4"
  collation          = "utf8mb4_unicode_ci"
}

# Optional restore / replica logic
resource "azurerm_mysql_flexible_server" "replica" {
  count = (var.create_mode == "Replica" && var.source_server_id != null && var.replica_location != null) ? 1 : 0

  name                = "${var.db_servername}-replica"
  resource_group_name = var.resource_group_name
  location            = var.replica_location

  create_mode = var.create_mode
  source_server_id  = var.source_server_id

  sku_name = var.sku_name

  tags = var.tags
}

resource "azurerm_mysql_flexible_server_configuration" "config" {
  for_each = var.server_configurations

  name                = each.key
  resource_group_name = var.resource_group_name
  server_name        = azurerm_mysql_flexible_server.mysql.name
  value              = each.value.value

  timeouts {
    create = "30m"
    read   = "5m"
    update = "30m"
    delete = "30m"
  }
}