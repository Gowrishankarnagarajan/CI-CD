resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = "UK South"
}

data "azurerm_client_config" "current" {}

resource "random_id" "kv" {
  byte_length = 4
}
# This Terraform configuration sets up an Azure Key Vault with purge protection enabled.
# It uses the current Azure client configuration to set the tenant ID and other properties.
# Data source to get the current Azure client configuration
resource "azurerm_key_vault" "keyvault" {
  name = "${var.prefix}-keyvault-${random_id.kv.hex}"
  # Ensure the name is globally unique by appending a random ID
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = true
}


# Use the new resource type
resource "azurerm_service_plan" "asp" {
  name                = "${var.prefix}-asp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
  depends_on          = [azurerm_resource_group.rg]
}

resource "azurerm_linux_web_app" "as1" {
  name                = "${var.prefix}-webapp1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.asp.id
  depends_on          = [azurerm_service_plan.asp]
  site_config {

    always_on = false

  }
}

resource "azurerm_linux_web_app" "as2" {
  name                = "${var.prefix}-webapp2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.asp.id
  depends_on          = [azurerm_service_plan.asp]
  site_config {

    always_on = false
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "storageaccountname"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "Devops"
  }
}
  