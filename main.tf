resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = "UK South"
}

# This Terraform configuration sets up an Azure Key Vault with purge protection enabled.
# It uses the current Azure client configuration to set the tenant ID and other properties.
data "azurerm_client_config" "current" {}

resource "random_id" "kv" {
  byte_length = 4
}
# This Terraform configuration sets up an Azure Storage Account and two containers for web applications.
# It uses a random ID to ensure the storage account name is globally unique.
resource "azurerm_storage_account" "sa" {
  name                     = "${var.prefix}storage${random_id.kv.hex}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "Devops"
  }
}
resource "azurerm_storage_container" "webapp1-sa" {
  name                  = "${var.prefix}webapp1"# This is the name of the container for webapp1
  storage_account_id = azurerm_storage_account.sa.id
  container_access_type = "blob" # or "blob", "container" for public access
}
resource "azurerm_storage_container" "webapp2-sa" {
  name                  = "${var.prefix}webapp2"
  storage_account_id = azurerm_storage_account.sa.id
  container_access_type = "blob" # or "blob", "container" for public access
}

resource "azurerm_role_assignment" "webapp1_storage_access" {
  principal_id         = azurerm_linux_web_app.as1.identity.principal_id
  role_definition_name = "Storage Blob Data Reader"
  scope                = azurerm_storage_account.sa.id
}

resource "azurerm_role_assignment" "webapp2_storage_access" {
  principal_id         = azurerm_linux_web_app.as2.identity.principal_id
  role_definition_name = "Storage Blob Data Reader"
  scope                = azurerm_storage_account.sa.id
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

  identity {
  type = "SystemAssigned"
}

  site_config {

    always_on = false

  }
   app_settings = { "STORAGE_URI" = "${azurerm_storage_account.sa.primary_blob_endpoint}${azurerm_storage_container.webapp1_sa.name}/"
  }
}

resource "azurerm_linux_web_app" "as2" {
  name                = "${var.prefix}-webapp2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.asp.id
  depends_on          = [azurerm_service_plan.asp]
  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = false
  }

  app_settings = {
    "STORAGE_URI" = "${azurerm_storage_account.sa.primary_blob_endpoint}${azurerm_storage_container.webapp2_sa.name}/"
  }

}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.rg.location
  # Use the resource group location for the virtual network
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  #dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnet {
    name             = "subnet1"
    address_prefixes = ["10.0.1.0/24"]
    security_group   = azurerm_network_security_group.nsg.id
  }

  subnet {
    name             = "subnet2"
    address_prefixes = ["10.0.2.0/24"]
    security_group   = azurerm_network_security_group.nsg.id
  }

  tags = {
    environment = "Devops"
  }
}
