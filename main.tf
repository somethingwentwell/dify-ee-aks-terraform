variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Add the Helm provider
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  }
}

resource "azurerm_resource_group" "main" {
  name     = "dify-ee-tf-${random_string.suffix.result}"
  location = "Southeast Asia"
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "dify-aks-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "dify-aks"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Azure Blob Storage
resource "azurerm_storage_account" "blob" {
  name                     = "difyblobstorage${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "blob_container" {
  name                  = "difydata"
  storage_account_id    = azurerm_storage_account.blob.id
  container_access_type = "container"
}

# Azure Redis Cache
# resource "azurerm_redis_cache" "redis" {
#   name                = "dify-redis-${random_string.suffix.result}"
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
#   capacity            = 1
#   family              = "C"
#   sku_name            = "Basic"
# }

# Azure PostgreSQL
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                = "dify-postgres-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  administrator_login = "adminuser"
  administrator_password = "P@ssw0rd1234"

  storage_mb            = 32768
  version               = "13"
  sku_name              = "GP_Standard_D2s_v3"
  zone                  = "3"

  delegated_subnet_id = null # Add subnet if needed
}

# Database: dify
resource "azurerm_postgresql_flexible_server_database" "dify_db" {
  name                = "dify"
  server_id           = azurerm_postgresql_flexible_server.postgres.id
  collation           = "en_US.utf8"
  charset             = "UTF8"
}

# Database: enterprise
resource "azurerm_postgresql_flexible_server_database" "enterprise_db" {
  name                = "enterprise"
  server_id           = azurerm_postgresql_flexible_server.postgres.id
  collation           = "en_US.utf8"
  charset             = "UTF8"
}

# Install Traefik using Helm
resource "helm_release" "traefik" {
  name       = "traefik"
  namespace  = "traefik"
  chart      = "traefik"
  repository = "https://helm.traefik.io/traefik"
  version    = "20.3.0"

  values = [
    <<EOF
service:
  type: LoadBalancer
EOF
  ]
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_all_ips" {
  name             = "AllowAllIPs"
  server_id        = azurerm_postgresql_flexible_server.postgres.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

resource "azurerm_postgresql_flexible_server_configuration" "pgcrypto" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "PGCRYPTO, UUID-OSSP"
}

output "aks_credentials" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "blob_account_url" {
  value = azurerm_storage_account.blob.primary_blob_endpoint
}

output "blob_account_key" {
  value     = azurerm_storage_account.blob.primary_access_key
  sensitive = true
}

# output "redis_hostname" {
#   value = azurerm_redis_cache.redis.hostname
# }

# output "redis_primary_key" {
#   value     = azurerm_redis_cache.redis.primary_access_key
#   sensitive = true
# }

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.postgres.fqdn
}

output "postgres_admin_user" {
  value = azurerm_postgresql_flexible_server.postgres.administrator_login
}

output "postgres_admin_password" {
  value     = azurerm_postgresql_flexible_server.postgres.administrator_password
  sensitive = true
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
} 