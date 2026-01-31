# =============================================================================
# Outputs
# Project: {{PROJECT_NAME}}
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "public_subnet_name" {
  description = "Name of the public subnet"
  value       = azurerm_subnet.public.name
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = azurerm_subnet.public.id
}

output "private_subnet_name" {
  description = "Name of the private subnet"
  value       = azurerm_subnet.private.name
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = azurerm_subnet.private.id
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT gateway"
  value       = azurerm_public_ip.nat.ip_address
}
