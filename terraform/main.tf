resource "azurerm_storage_container" "dcos" {
  name                  = "dcos1dot9"
  resource_group_name   = "${azurerm_resource_group.dcos.name}"
  storage_account_name  = "${azurerm_storage_account.dcos.name}"
  container_access_type = "private"
}
