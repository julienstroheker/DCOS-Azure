output "Resource Group Name" {
  value = "${azurerm_resource_group.dcos.name}"
}

output "Resource Group Location" {
  value = "${azurerm_resource_group.dcos.location}"
}

output "Storage Account Name" {
  value = "${azurerm_storage_account.dcos.name}"
}

output "Account Blob Endpoint" {
  value = "${azurerm_storage_account.dcos.primary_blob_endpoint}"
}

output "Virtual Network Name" {
  value = "${azurerm_virtual_network.dcos.name}"
}
