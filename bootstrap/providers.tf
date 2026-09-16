terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.5.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}