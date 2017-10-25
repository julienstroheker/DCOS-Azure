resource "azurerm_resource_group" "dcos" {
  name     = "${var.resource_base_name}${var.resource_suffix}"
  location = "${var.location}"

  tags {
    owner = "${var.owner}"
    expiration = "${var.expiration}"

  }

}

resource "azurerm_storage_account" "dcos" {
  name                     = "sa${var.resource_base_name}${var.resource_suffix}"
  resource_group_name      = "${azurerm_resource_group.dcos.name}"
  location                 = "${azurerm_resource_group.dcos.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "state" {
  name                  = "terraform-state"
  resource_group_name   = "${azurerm_resource_group.dcos.name}"
  storage_account_name  = "${azurerm_storage_account.dcos.name}"
  container_access_type = "private"
}

output "Primary Access Key" {
  value = "${azurerm_storage_account.dcos.primary_access_key}"
}
