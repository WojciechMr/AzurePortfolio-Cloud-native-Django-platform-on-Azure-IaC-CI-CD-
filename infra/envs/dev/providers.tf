terraform {
  required_version = ">= 1.5.0"

backend "azurerm" {
  resource_group_name  = "rg-AzurePortfolio-tfstate"
  storage_account_name = "stazureportfoliodevtf"
  container_name       = "tfstate"
  key                  = "dev.terraform.tfstate"

  use_azuread_auth = true
}


  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {}
}
