# output "id" {
#   description = "The Load Balancer ID."
#   value       = azurerm_lb.loadbalancer.id
# }

output "id" {
  value = azurerm_redis_cache.azurerm_redis_cache.id
}
# ---- Added producer outputs for DAG wiring (mpaas-ai-module migration) ----
output "public_ip_id" {
  value = azurerm_public_ip.public_ip.id
}
output "public_ip_name" {
  value = azurerm_public_ip.public_ip.name
}
output "public_ip_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}
output "public_ip_fqdn" {
  value = azurerm_public_ip.public_ip.fqdn
}
output "loadbalancer_id" {
  value = azurerm_lb.loadbalancer.id
}
output "loadbalancer_name" {
  value = azurerm_lb.loadbalancer.name
}
output "backend_address_pool_id" {
  value = azurerm_lb_backend_address_pool.backend_address_pool.id
}
output "backend_address_pool_name" {
  value = azurerm_lb_backend_address_pool.backend_address_pool.name
}
output "mysql_server_id" {
  value = azurerm_mysql_server.mysql_server.id
}
output "mysql_server_name" {
  value = azurerm_mysql_server.mysql_server.name
}
output "mysql_server_fqdn" {
  value = azurerm_mysql_server.mysql_server.fqdn
}
output "mysql_dns_zone_id" {
  value = azurerm_private_dns_zone.mysql_dns_zone[*].id
}
output "mysql_dns_zone_name" {
  value = azurerm_private_dns_zone.mysql_dns_zone[*].name
}
output "azurerm_redis_cache_id" {
  value = { for k, v in azurerm_redis_cache.azurerm_redis_cache : k => v.id }
}
output "azurerm_redis_cache_name" {
  value = { for k, v in azurerm_redis_cache.azurerm_redis_cache : k => v.name }
}
output "azurerm_redis_cache_hostname" {
  value = { for k, v in azurerm_redis_cache.azurerm_redis_cache : k => v.hostname }
}
output "azurerm_redis_cache_ssl_port" {
  value = { for k, v in azurerm_redis_cache.azurerm_redis_cache : k => v.ssl_port }
}
output "azurerm_redis_cache_primary_access_key" {
  value     = { for k, v in azurerm_redis_cache.azurerm_redis_cache : k => v.primary_access_key }
  sensitive = true
}
output "cluster_id" {
  value = azurerm_kubernetes_cluster.cluster.id
}
output "cluster_name" {
  value = azurerm_kubernetes_cluster.cluster.name
}
output "cluster_fqdn" {
  value = azurerm_kubernetes_cluster.cluster.fqdn
}
output "cluster_node_resource_group" {
  value = azurerm_kubernetes_cluster.cluster.node_resource_group
}
output "secondary_pool_id" {
  value = azurerm_kubernetes_cluster_node_pool.secondary-pool.id
}
output "secondary_pool_name" {
  value = azurerm_kubernetes_cluster_node_pool.secondary-pool.name
}
output "aks_identity_id" {
  value = azurerm_user_assigned_identity.aks-identity.id
}
output "aks_identity_name" {
  value = azurerm_user_assigned_identity.aks-identity.name
}
output "aks_identity_principal_id" {
  value = azurerm_user_assigned_identity.aks-identity.principal_id
}
output "aks_identity_client_id" {
  value = azurerm_user_assigned_identity.aks-identity.client_id
}
