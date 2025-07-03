

provider "azurerm" {
  # subscription_id = var.ARM_SUBSCRIPTION_ID
  # client_id       = var.lient_idc
  # client_secret   = var.client_secret
  # tenant_id       = var.tenant_id
    use_cli = false

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