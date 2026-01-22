resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.env}"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project}-${var.env}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_cidr]
}

resource "azurerm_subnet" "public_edge" {
  name                 = "snet-public-edge"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.0.0/24"]
}

resource "azurerm_subnet" "app_private" {
  name                 = "snet-app-private"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "db_private" {
  name                 = "snet-db-private"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_subnet" "ops_private" {
  name                 = "snet-ops-private"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.3.0/24"]
}

resource "azurerm_subnet" "aca_infra" {
  name                 = "snet-aca-infra"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.4.0/24"]

  delegation {
    name = "aca-delegation"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}






############################################
# Network Security Groups (NSG)
############################################

# Public edge NSG (dla przyszłego Application Gateway)
resource "azurerm_network_security_group" "public_edge" {
  name                = "nsg-public-edge"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-http-internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https-internet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# App private NSG (compute)
resource "azurerm_network_security_group" "app_private" {
  name                = "nsg-app-private"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Jawny allow app -> db:5432 (outbound)
  security_rule {
    name                       = "allow-app-to-db-5432"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.10.1.0/24"
    destination_address_prefix = "10.10.2.0/24"
  }
}

# DB private NSG (Postgres VM)
resource "azurerm_network_security_group" "db_private" {
  name                = "nsg-db-private"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # tylko app -> db:5432
  security_rule {
    name                       = "allow-app-to-db-5432"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.10.1.0/24"
    destination_address_prefix = "10.10.2.0/24"
  }
}

# Ops private NSG (Prom/Grafana VM)
resource "azurerm_network_security_group" "ops_private" {
  name                = "nsg-ops-private"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # ops -> app metrics (na start: 8000)
  security_rule {
    name                       = "allow-ops-to-app-metrics-8000"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "10.10.3.0/24"
    destination_address_prefix = "10.10.1.0/24"
  }
}

############################################
# Associate NSGs to subnets
############################################

resource "azurerm_subnet_network_security_group_association" "public_edge" {
  subnet_id                 = azurerm_subnet.public_edge.id
  network_security_group_id = azurerm_network_security_group.public_edge.id
}

resource "azurerm_subnet_network_security_group_association" "app_private" {
  subnet_id                 = azurerm_subnet.app_private.id
  network_security_group_id = azurerm_network_security_group.app_private.id
}

resource "azurerm_subnet_network_security_group_association" "db_private" {
  subnet_id                 = azurerm_subnet.db_private.id
  network_security_group_id = azurerm_network_security_group.db_private.id
}

resource "azurerm_subnet_network_security_group_association" "ops_private" {
  subnet_id                 = azurerm_subnet.ops_private.id
  network_security_group_id = azurerm_network_security_group.ops_private.id
}



############################################
# Azure Container Registry (ACR)
############################################

resource "azurerm_container_registry" "acr" {
  name                = "acr${lower(var.project)}${var.env}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku           = "Basic"
  admin_enabled = false
}





############################################
# Log Analytics (Azure Monitor Logs)
############################################

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.project}-${var.env}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  sku               = "PerGB2018"
  retention_in_days = 30
}

############################################
# Container Apps Environment (ECS/Fargate analog)
############################################

resource "azurerm_container_app_environment" "cae" {
  name                       = "cae-${var.project}-${var.env}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}






############################################
# Backend Container App (Django)
############################################

resource "azurerm_user_assigned_identity" "backend" {
  name                = "id-backend-${var.project}-${var.env}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_role_assignment" "backend_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.backend.principal_id
}

resource "azurerm_container_app" "backend" {
  name = "ca-be-${lower(var.project)}-${var.env}"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.cae.id
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.backend.id]
  }

  ingress {
    external_enabled = true
    target_port      = 8000

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.backend.id
  }

  template {
    container {
      name   = "backend"
      image  = var.backend_image
      cpu    = 0.5
      memory = "1Gi"

      dynamic "env" {
        for_each = var.backend_env
        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }

  depends_on = [azurerm_role_assignment.backend_acr_pull]
}
