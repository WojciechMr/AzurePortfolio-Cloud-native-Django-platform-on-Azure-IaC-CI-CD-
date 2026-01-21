output "rg_name" {
  value = azurerm_resource_group.main.name
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  value = {
    public_edge = azurerm_subnet.public_edge.id
    app_private = azurerm_subnet.app_private.id
    db_private  = azurerm_subnet.db_private.id
    ops_private = azurerm_subnet.ops_private.id
  }
}


output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}



output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.law.name
}

output "container_app_environment_name" {
  value = azurerm_container_app_environment.cae.name
}


output "backend_fqdn" {
  value = azurerm_container_app.backend.ingress[0].fqdn
}
