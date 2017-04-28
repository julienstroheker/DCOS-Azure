resource "azurerm_public_ip" "bootstrap" {
  name                         = "bootstrapPublicIP"
  location                     = "${azurerm_resource_group.dcos.location}"
  resource_group_name          = "${azurerm_resource_group.dcos.name}"
  public_ip_address_allocation = "Dynamic"
}

resource "azurerm_network_interface" "bootstrap" {
  name                = "bootstrapnic"
  location            = "${azurerm_resource_group.dcos.location}"
  resource_group_name = "${azurerm_resource_group.dcos.name}"
  depends_on          = ["azurerm_subnet.dcosmaster", "azurerm_public_ip.bootstrap"]

  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "static"
    private_ip_address            = "172.16.0.8"
    subnet_id                     = "${azurerm_subnet.dcosmaster.id}"
    public_ip_address_id          = "${azurerm_public_ip.bootstrap.id}"
  }
}

resource "azurerm_storage_account" "bootstrap" {
  name                = "bootstrapstorage${var.resource_suffix}"
  resource_group_name = "${azurerm_resource_group.dcos.name}"
  location            = "${azurerm_resource_group.dcos.location}"
  account_type        = "Standard_LRS"
}

resource "azurerm_virtual_machine" "bootstrap" {
  name                          = "bootstrapVM"
  location                      = "${azurerm_resource_group.dcos.location}"
  resource_group_name           = "${azurerm_resource_group.dcos.name}"
  network_interface_ids         = ["${azurerm_network_interface.bootstrap.id}"]
  vm_size                       = "${var.bootstrap_size}"
  delete_os_disk_on_termination = true
  depends_on                    = ["azurerm_network_interface.bootstrap"]

  lifecycle {
    ignore_changes = ["admin_password"]
  }

  storage_os_disk {
    name            = "bootstrapVMDisk"
    caching         = "ReadWrite"
    create_option   = "FromImage"
    os_type         = "linux"
    vhd_uri         = "${azurerm_storage_account.bootstrap.primary_blob_endpoint}vhds/bootstrap_os_disk.vhd"                
  }

  storage_image_reference {
    publisher = "${var.image["publisher"]}"
    offer     = "${var.image["offer"]}"
    sku       = "${var.image["sku"]}"
    version   = "${var.image["version"]}"
  }

  os_profile {
    computer_name  = "bootstrap"
    admin_username = "${var.vm_user}"
    admin_password = "${uuid()}"
 }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.vm_user}/.ssh/authorized_keys"
      key_data = "${file(var.public_key_path)}"
    }
  }
}

resource "azurerm_virtual_machine_extension" "bootstrap" {
  name                        = "dcosConfiguration"
  location                    = "${azurerm_resource_group.dcos.location}"
  resource_group_name         = "${azurerm_resource_group.dcos.name}"
  depends_on                  = ["azurerm_virtual_machine.bootstrap"]
  virtual_machine_name        = "${azurerm_virtual_machine.bootstrap.name}"
  publisher                   = "Microsoft.Azure.Extensions"
  type                        = "CustomScript"
  type_handler_version        = "2.0"
  auto_upgrade_minor_version  = true

  settings = <<SETTINGS
    {
        "fileUris": [
            "${var.bootstrap_script_url}"
          ],
        "commandToExecute": "bash bootstrap.sh '172.16.0.8' '${var.dcos_download_url}'"
    }
SETTINGS

}