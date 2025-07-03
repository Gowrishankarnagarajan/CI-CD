

provider "azurerm" {
  # subscription_id = var.subscription_id
  # client_id       = var.client_id
  # client_secret   = var.client_secret
  # tenant_id       = var.tenant_id
  features {}
}
# This Terraform configuration sets up an Azure App Service with a resource group, app service plan, and two web apps (frontend and backend).
# terraform { 
#   cloud { 
    
#     organization = "gs-devops" 

#     workspaces { 
#       name = "Devops" 
#     } 
#   } 
# }

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}