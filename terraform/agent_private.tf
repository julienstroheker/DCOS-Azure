resource "azurerm_storage_account" "agent_private" {
  name                     = "${substr(sha1(uuid()), 0, 20)}"
  resource_group_name      = "${azurerm_resource_group.dcos.name}"
  location                 = "${azurerm_resource_group.dcos.location}"
  count                    = 5
  account_tier             = "Standard"
  account_replication_type = "LRS"

  lifecycle {
    ignore_changes = ["name"]
  }
}

resource "azurerm_virtual_machine_scale_set" "agent_private" {
  name                = "agent-private-vmss"
  location            = "${azurerm_resource_group.dcos.location}"
  resource_group_name = "${azurerm_resource_group.dcos.name}"
  depends_on          = ["azurerm_virtual_machine.master", "azurerm_virtual_machine_extension.master","azurerm_storage_account.agent_private"]
  upgrade_policy_mode = "Manual"

  sku {
    name     = "${var.agent_size}"
    tier     = "Standard"
    capacity = "${var.agent_private_count}"
  }

  os_profile {
    computer_name_prefix = "privateagent"
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

  network_profile {
    name    = "agentPrivateNodeNic"
    primary = true

    ip_configuration {
      name      = "nicipconfig"
      subnet_id = "${azurerm_subnet.dcosprivate.id}"
    }
  }

  storage_profile_os_disk {
    name           = "vmssosdisk"
    caching        = "ReadWrite"
    create_option  = "FromImage"
    vhd_containers = ["${element(azurerm_storage_account.agent_private.*.primary_blob_endpoint, 0)}vhds", "${element(azurerm_storage_account.agent_private.*.primary_blob_endpoint, 1)}vhds", "${element(azurerm_storage_account.agent_private.*.primary_blob_endpoint, 2)}vhds", "${element(azurerm_storage_account.agent_private.*.primary_blob_endpoint, 3)}vhds", "${element(azurerm_storage_account.agent_private.*.primary_blob_endpoint, 4)}vhds"]
  }

  storage_profile_image_reference {
    publisher = "${var.image["publisher"]}"
    offer     = "${var.image["offer"]}"
    sku       = "${var.image["sku"]}"
    version   = "${var.image["version"]}"
  }

  extension {
    name                        = "customScript"
    publisher                   = "Microsoft.Azure.Extensions"
    type                        = "CustomScript"
    type_handler_version        = "2.0"
    auto_upgrade_minor_version  = true
    settings = <<SETTINGS
    {
        "fileUris": [
            "${var.install_script_url}"
          ],
        "commandToExecute": "bash install.sh '172.16.0.8' 'slave'"
    }
SETTINGS
  }   
}