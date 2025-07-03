# Output the web app URLs
output "as1_url" {
  value = "https://${azurerm_linux_web_app.as1.default_hostname}"
}

output "as2_url" {
  value = "https://${azurerm_linux_web_app.as2.default_hostname}"
}
# Output the resource group name
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
# Output the service plan ID
output "service_plan_id" {
  value = azurerm_service_plan.asp.id
}
# Output the location of the resource group
output "resource_group_location" {
  value = azurerm_resource_group.rg.location
}   