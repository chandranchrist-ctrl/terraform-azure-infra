resource "azurerm_storage_account_network_rules" "storage_network_rules" {
  storage_account_id = azurerm_storage_account.storage_account.id

  default_action = "Deny"
  bypass         = ["AzureServices"]

  virtual_network_subnet_ids = var.allowed_subnet_ids
  ip_rules                   = var.allowed_ip_rules
}

resource "azurerm_storage_management_policy" "storage_management_policy" {
  storage_account_id = azurerm_storage_account.storage_account.id

  rule {
    name    = "diagnostic-data-cleanup"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
      prefix_match = [
        "bootdiagnostics",
        "insights-logs"
      ]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 1
      }
    }
  }
}

resource "azurerm_storage_account" "storage_account" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_kind             = var.account_kind
  account_tier             = var.account_tier
  account_replication_type = var.replication_type

  dns_endpoint_type             = var.dns_endpoint_type
  public_network_access_enabled = var.public_network_access

  allow_nested_items_to_be_public = false

  # ---------------------------
  # BLOB PROPERTIES (versioning + retention)
  # ---------------------------
  blob_properties {

    versioning_enabled = var.blob_versioning_enabled

    delete_retention_policy {
      days = var.blob_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.container_delete_retention_days
    }
  }

  # ---------------------------
  # IMMUTABILITY (WORM compliance)
  # ---------------------------
  #   immutability_policy {
  #     allow_protected_append_writes = true
  #     state                         = "Unlocked"
  #     period_since_creation_in_days = var.immutability_period_days
  #   }

  tags = var.tags
}


/*
What is blob and container in Azure Storage?

You can say:

A container is a logical grouping of blobs inside a storage account, similar to a folder.
A blob is the actual data object stored inside a container, such as logs, images, or files.
*/