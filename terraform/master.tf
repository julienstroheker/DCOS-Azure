resource "azurerm_public_ip" "master" {
  name                         = "masterPublicIP"
  location                     = "${azurerm_resource_group.dcos.location}"
  resource_group_name          = "${azurerm_resource_group.dcos.name}"
  public_ip_address_allocation = "Dynamic"
  domain_name_label            = "${var.masterFQDN}-${var.resource_suffix}"
}

resource "azurerm_lb" "master" {
  name                = "dcos-master-lb"
  location            = "${azurerm_resource_group.dcos.location}"
  resource_group_name = "${azurerm_resource_group.dcos.name}"

  frontend_ip_configuration {
    name                 = "dcos-master-lbFrontEnd"
    public_ip_address_id = "${azurerm_public_ip.master.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "master" {
  resource_group_name = "${azurerm_resource_group.dcos.name}"
  loadbalancer_id     = "${azurerm_lb.master.id}"
  name                = "dcos-master-pool"
}

resource "azurerm_lb_nat_rule" "masterlbrulessh" {
  resource_group_name            = "${azurerm_resource_group.dcos.name}"
  count                          = "${var.master_count}"
  loadbalancer_id                = "${azurerm_lb.master.id}"
  name                           = "dcos-master-lb-SSH-${format("%01d", count.index+1)}"
  protocol                       = "Tcp"
  frontend_port                  = "${lookup(var.master_port, count.index+1)}"
  backend_port                   = 22
  frontend_ip_configuration_name = "dcos-master-lbFrontEnd"
}

/*
resource "azurerm_lb_nat_rule" "masterlbrulehttp" {
  resource_group_name            = "${azurerm_resource_group.dcos.name}"
  count                          = "${var.master_count}"
  loadbalancer_id                = "${azurerm_lb.master.id}"
  name                           = "dcos-master-lb-HTTP-${format("%01d", count.index+1)}"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "dcos-master-lbFrontEnd"
}

resource "azurerm_lb_nat_rule" "masterlbrulehttps" {
  resource_group_name            = "${azurerm_resource_group.dcos.name}"
  count                          = "${var.master_count}"
  loadbalancer_id                = "${azurerm_lb.master.id}"
  name                           = "dcos-master-lb-HTTPS-${format("%01d", count.index+1)}"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "dcos-master-lbFrontEnd"
}
*/

resource "azurerm_network_interface" "master" {
  name                      = "master${format("%01d", count.index+1)}"
  location                  = "${azurerm_resource_group.dcos.location}"
  resource_group_name       = "${azurerm_resource_group.dcos.name}"
  count                     = "${var.master_count}"
  network_security_group_id = "${azurerm_network_security_group.dcosmaster.id}"

  ip_configuration {
    name                                    = "ipConfigNode"
    private_ip_address_allocation           = "static"
    private_ip_address                      = "172.16.0.${var.master_private_ip_address_index + count.index}"
    subnet_id                               = "${azurerm_subnet.dcosmaster.id}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.master.id}"]
    //load_balancer_inbound_nat_rules_ids   = ["${azurerm_lb_nat_rule.masterlbrulessh.*.id}", "${azurerm_lb_nat_rule.masterlbrulehttp.*.id}", "${azurerm_lb_nat_rule.masterlbrulehttps.*.id}"]
    load_balancer_inbound_nat_rules_ids     = ["${element(azurerm_lb_nat_rule.masterlbrulessh.*.id, count.index)}"]
  }
}

resource "azurerm_availability_set" "master" {
  name                = "dcos-master-availabilitySet"
  location            = "${azurerm_resource_group.dcos.location}"
  resource_group_name = "${azurerm_resource_group.dcos.name}"
}

resource "azurerm_storage_account" "master" {
  name                     = "masterstorage${var.resource_suffix}"
  resource_group_name      = "${azurerm_resource_group.dcos.name}"
  location                 = "${azurerm_resource_group.dcos.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_virtual_machine" "master" {
  name                          = "master${format("%01d", count.index+1)}"
  location                      = "${azurerm_resource_group.dcos.location}"
  count                         = "${var.master_count}"
  resource_group_name           = "${azurerm_resource_group.dcos.name}"
  network_interface_ids         = ["${element(azurerm_network_interface.master.*.id, count.index)}"]
  vm_size                       = "${var.master_size}"
  availability_set_id           = "${azurerm_availability_set.master.id}"
  delete_os_disk_on_termination = true
  depends_on                    = ["azurerm_virtual_machine.bootstrap", "azurerm_network_interface.master"]

  lifecycle {
    ignore_changes = ["admin_password"]
  }

  storage_image_reference {
    publisher = "${var.image["publisher"]}"
    offer     = "${var.image["offer"]}"
    sku       = "${var.image["sku"]}"
    version   = "${var.image["version"]}"
  }

  storage_os_disk {
    name          = "master"
    vhd_uri       = "${azurerm_storage_account.master.primary_blob_endpoint}vhds/master${format("%01d", count.index+1)}_os_disk.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "master${format("%01d", count.index+1)}"
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

resource "azurerm_virtual_machine_extension" "master" {
  name                        = "installDCOS${format("%01d", count.index+1)}"
  location                    = "${azurerm_resource_group.dcos.location}"
  count                       = "${var.master_count}"
  depends_on                  = ["azurerm_virtual_machine_extension.bootstrap", "azurerm_virtual_machine.bootstrap", "azurerm_virtual_machine.master"]
  resource_group_name         = "${azurerm_resource_group.dcos.name}"
  virtual_machine_name        = "master${format("%01d", count.index+1)}"
  publisher                   = "Microsoft.Azure.Extensions"
  type                        = "CustomScript"
  type_handler_version        = "2.0"
  auto_upgrade_minor_version  = true

  settings = <<SETTINGS
    {
        "fileUris": [
            "${var.install_script_url}"
          ],
        "commandToExecute": "bash install.sh '172.16.0.8' 'master'"
    }
SETTINGS

}

output "Master IP" {
  value = "${azurerm_public_ip.master.ip_address}"
}