
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = "UK South"
}

data "azurerm_client_config" "current" {}

resource "random_id" "kv" {
  byte_length = 4
}

resource "azurerm_storage_account" "sa" {
  name                     = "${var.prefix}storage${random_id.kv.hex}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  depends_on               = [azurerm_resource_group.rg]
  tags                     = { environment = "Devops" }
}

resource "azurerm_storage_container" "webapp1_sa" {
  name                  = "${var.prefix}webapp1"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "blob"
  depends_on            = [azurerm_storage_account.sa]
}

resource "azurerm_storage_container" "webapp2_sa" {
  name                  = "${var.prefix}webapp2"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "blob"
  depends_on            = [azurerm_storage_container.webapp1_sa]
}

resource "azurerm_key_vault" "keyvault" {
  name                     = "${var.prefix}-keyvault-${random_id.kv.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = true
  depends_on               = [azurerm_resource_group.rg]
}

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

  identity { type = "SystemAssigned" }

  site_config { always_on = false }

  app_settings = {
    STORAGE_URI = "${azurerm_storage_account.sa.primary_blob_endpoint}${azurerm_storage_container.webapp1_sa.name}/"
  }
}

resource "azurerm_linux_web_app" "as2" {
  name                = "${var.prefix}-webapp2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.asp.id
  depends_on          = [azurerm_linux_web_app.as1]

  identity { type = "SystemAssigned" }

  site_config { always_on = false }

  app_settings = {

    STORAGE_URI = "${azurerm_storage_account.sa.primary_blob_endpoint}${azurerm_storage_container.webapp2_sa.name}/"
  }
}
resource "azurerm_role_assignment" "webapp1_storage_access" {
  principal_id         = azurerm_linux_web_app.as1.identity[0].principal_id
  role_definition_name = "Storage Blob Data Reader"
  scope                = azurerm_storage_account.sa.id
  depends_on           = [azurerm_linux_web_app.as1]
}

resource "azurerm_role_assignment" "webapp2_storage_access" {
  principal_id         = azurerm_linux_web_app.as2.identity[0].principal_id
  role_definition_name = "Storage Blob Data Reader"
  scope                = azurerm_storage_account.sa.id
  depends_on           = [azurerm_linux_web_app.as2, azurerm_role_assignment.webapp1_storage_access]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  depends_on          = [azurerm_resource_group.rg]

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
  depends_on          = [azurerm_network_security_group.nsg]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on           = [azurerm_subnet_network_security_group_association.subnet2_assoc]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "subnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  depends_on           = [azurerm_subnet_network_security_group_association.subnet1_assoc]
}

resource "azurerm_subnet_network_security_group_association" "subnet1_assoc" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on                = [azurerm_network_security_group.nsg]
}

resource "azurerm_subnet_network_security_group_association" "subnet2_assoc" {
  subnet_id                 = azurerm_subnet.subnet2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on                = [azurerm_network_security_group.nsg]
}
