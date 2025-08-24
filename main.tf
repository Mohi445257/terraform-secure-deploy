terraform {
  required_version = ">=1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
  }

  backend "local" {} # for now using local backend (you can later switch to Azure Storage)
}

provider "azurerm" {
  features {}
}

# -------------------------------
# Resource Group
# -------------------------------
resource "azurerm_resource_group" "rg" {
  name     = "secure-rg"
  location = "East US"
}

# -------------------------------
# Storage Account (secured)
# -------------------------------
resource "azurerm_storage_account" "storage" {
  name                     = "securestor${random_integer.rand.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Security
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public    = false  # replaces deprecated allow_blob_public_access
  shared_access_key_enabled          = false  # disables classic access keys

  blob_properties {
    delete_retention_policy {
      days = 7  # soft delete enabled
    }
  }
}

# -------------------------------
# Key Vault (with purge protection)
# -------------------------------
resource "azurerm_key_vault" "kv" {
  name                        = "securekv${random_integer.rand.result}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"

  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
}

# -------------------------------
# Data for current client
# -------------------------------
data "azurerm_client_config" "current" {}

# -------------------------------
# Random suffix (to avoid name clashes)
# -------------------------------
resource "random_integer" "rand" {
  min = 10000
  max = 99999
}
