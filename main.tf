resource "azurerm_public_ip" "public_ip" {
  name                = var.lb_public_ip_name
  resource_group_name = var.resource_group_name
  location            = var.location
  ip_version          = var.ip_version
  sku                 = var.public_ip_sku
  sku_tier            = var.public_ip_sku_tier
  allocation_method   = var.allocation_method

}

resource "azurerm_lb" "loadbalancer" {

  name                = var.lb_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.lb_sku
  sku_tier            = var.lb_sku_tier
  frontend_ip_configuration {
    name                 = azurerm_public_ip.public_ip.name
    public_ip_address_id = azurerm_public_ip.public_ip.id

  }

}

resource "azurerm_lb_backend_address_pool" "backend_address_pool" {
  name            = var.backend_name
  loadbalancer_id = azurerm_lb.loadbalancer.id
}

resource "azurerm_lb_rule" "lb_rule" {
  name                           = var.lb_rule_name
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  frontend_ip_configuration_name = azurerm_public_ip.public_ip.name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_address_pool.id]
  protocol                       = var.protocol
  frontend_port                  = var.frontend_port
  backend_port                   = var.backend_port
  idle_timeout_in_minutes        = var.idle_timeout_in_minutes
  enable_tcp_reset               = var.enable_tcp_reset
  enable_floating_ip             = var.enable_floating_ip

}

#Creating SQL server

resource "random_string" "mysql_server_suffix" {
  length  = 8
  special = false
  upper   = false
  lower   = true
  number  = true
}
resource "random_password" "mysql_password" {
  length           = 16
  special          = true
  upper            = true
  lower            = true
  number           = true
  override_special = "-_!#^~%@"
}

resource "azurerm_mysql_server" "mysql_server" {
  name                              = "${var.mysql_server_name}-${random_string.mysql_server_suffix.id}"
  location                          = var.location
  resource_group_name               = var.resource_group_name
  administrator_login               = var.administrator_login
  administrator_login_password      = random_password.mysql_password.result
  sku_name                          = var.sku_name
  storage_mb                        = var.storage_mb
  version                           = var.mysql_version
  auto_grow_enabled                 = var.auto_grow_enabled
  backup_retention_days             = var.backup_retention_days
  geo_redundant_backup_enabled      = var.geo_redundant_backup_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  public_network_access_enabled     = var.public_network_access_enabled
  ssl_enforcement_enabled           = var.ssl_enforcement_enabled
  ssl_minimal_tls_version_enforced  = var.ssl_minimal_tls_version_enforced
  threat_detection_policy {
    enabled = true
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_private_dns_zone" "mysql_dns_zone" {
  count               = length(var.mysql_server_name) > 0 ? 1 : 0
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = var.resource_group_name

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

data "azurerm_virtual_network" "vnet_data" {
  name                = var.vnet_name
  resource_group_name = var.vnet_resource_group_name
}

# Creating Redis
resource "azurerm_redis_cache" "azurerm_redis_cache" {
  name                          = var.redis_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  capacity                      = var.capacity
  family                        = var.family
  sku_name                      = var.redis_sku_name
  enable_non_ssl_port           = false
  public_network_access_enabled = var.redis_public_network_access_enabled
  redis_version                 = var.redis_version

  redis_configuration {
  }

  dynamic "identity" {
    for_each = var.identity ? [{}] : []
    content {
      type = var.type
    }
  }
  dynamic "patch_schedule" {
    for_each = var.patch_schedule ? [{}] : []
    content {
      day_of_week = var.day_of_week
    }
  }
}

# CLuster Creation

resource "azurerm_kubernetes_cluster" "cluster" {
  name                          = var.aks_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  dns_prefix                    = var.dns_prefix
  private_cluster_enabled       = true
  public_network_access_enabled = false

  default_node_pool {
    name                = "default"
    node_count          = 1
    vm_size             = var.vm_size
    vnet_subnet_id      = var.aks_subnet_id
    os_disk_size_gb     = var.os_disk_size_gb
    zones               = var.zones
    enable_auto_scaling = true
    min_count           = var.primary_min_count
    max_count           = var.primary_max_count
    max_pods            = var.primary_max_pods
    os_sku              = var.os_sku
  }

  network_profile {
    network_plugin = "azure"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks-identity.id]
  }

  depends_on = [
    azurerm_role_assignment.Contributor-role-assignment,
  ]

}


resource "azurerm_kubernetes_cluster_node_pool" "secondary-pool" {
  name                  = "secondary"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.cluster.id
  vm_size               = var.vm_size
  enable_auto_scaling   = true
  os_disk_size_gb       = var.os_disk_size_gb
  workload_runtime      = "OCIContainer"
  zones                 = var.zones
  node_count            = 1
  min_count             = var.secondary_min_count
  max_count             = var.secondary_max_count
  max_pods              = var.secondary_max_pods
  os_sku                = var.os_sku
}



resource "azurerm_user_assigned_identity" "aks-identity" {
  name                = "aks_identity"
  resource_group_name = data.azurerm_resource_group.application-resource-group.name
  location            = var.location
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

data "azurerm_resource_group" "application-resource-group" {
  name = var.resource_group_name
}

resource "azurerm_role_assignment" "Contributor-role-assignment" {
  scope                = data.azurerm_resource_group.application-resource-group.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.aks-identity.principal_id
  depends_on = [
    azurerm_user_assigned_identity.aks-identity
  ]
}
