resource "azurerm_public_ip" "agent_public" {
  name                         = "publicAgentsPublicIP"
  location                     = "${azurerm_resource_group.dcos.location}"
  resource_group_name          = "${azurerm_resource_group.dcos.name}"
  public_ip_address_allocation = "Dynamic"
  domain_name_label            = "${var.publicAgentFQDN}-${var.resource_suffix}"
}

resource "azurerm_lb" "agent_public" {
  name                = "dcos-agent-public-lb"
  location            = "${azurerm_resource_group.dcos.location}"
  resource_group_name = "${azurerm_resource_group.dcos.name}"

  frontend_ip_configuration {
    name                 = "dcos-agent-public-lbFrontEnd"
    public_ip_address_id = "${azurerm_public_ip.agent_public.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "agent_public" {
  resource_group_name = "${azurerm_resource_group.dcos.name}"
  loadbalancer_id     = "${azurerm_lb.agent_public.id}"
  name                = "dcos-agent-public-pool"
}

resource "azurerm_lb_probe" "agent_public_http" {
  resource_group_name = "${azurerm_resource_group.dcos.name}"
  loadbalancer_id     = "${azurerm_lb.agent_public.id}"
  name                = "tcpHTTPProbe"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "agent_public_http" {
  resource_group_name            = "${azurerm_resource_group.dcos.name}"
  loadbalancer_id                = "${azurerm_lb.agent_public.id}"
  name                           = "LBRuleHTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  frontend_ip_configuration_name = "dcos-agent-public-lbFrontEnd"
  backend_port                   = 80
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.agent_public.id}"
  probe_id                       = "${azurerm_lb_probe.agent_public_http.id}"
  idle_timeout_in_minutes        = 5
  load_distribution              = "Default"
  enable_floating_ip             = false
}

resource "azurerm_lb_probe" "agent_public_https" {
  resource_group_name = "${azurerm_resource_group.dcos.name}"
  loadbalancer_id     = "${azurerm_lb.agent_public.id}"
  name                = "tcpHTTPSProbe"
  port                = 443
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "agent_public_https" {
  resource_group_name            = "${azurerm_resource_group.dcos.name}"
  loadbalancer_id                = "${azurerm_lb.agent_public.id}"
  name                           = "LBRuleHTTPS"
  protocol                       = "Tcp"
  frontend_port                  = 443
  frontend_ip_configuration_name = "dcos-agent-public-lbFrontEnd"
  backend_port                   = 443
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.agent_public.id}"
  probe_id                       = "${azurerm_lb_probe.agent_public_https.id}"
  idle_timeout_in_minutes        = 5
  load_distribution              = "Default"
  enable_floating_ip             = false
}

resource "azurerm_lb_probe" "agent_public_8080" {
  resource_group_name = "${azurerm_resource_group.dcos.name}"
  loadbalancer_id     = "${azurerm_lb.agent_public.id}"
  name                = "tcpPort8080Probe"
  port                = 8080
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "agent_public_8080" {
  resource_group_name            = "${azurerm_resource_group.dcos.name}"
  loadbalancer_id                = "${azurerm_lb.agent_public.id}"
  name                           = "LBRulePort8080"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  frontend_ip_configuration_name = "dcos-agent-public-lbFrontEnd"
  backend_port                   = 8080
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.agent_public.id}"
  probe_id                       = "${azurerm_lb_probe.agent_public_8080.id}"
  idle_timeout_in_minutes        = 5
  load_distribution              = "Default"
  enable_floating_ip             = false
}

resource "azurerm_lb_probe" "agent_public_9090" {
  resource_group_name = "${azurerm_resource_group.dcos.name}"
  loadbalancer_id     = "${azurerm_lb.agent_public.id}"
  name                = "tcpPort9090Probe"
  port                = 9090
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "agent_public_9090" {
  resource_group_name            = "${azurerm_resource_group.dcos.name}"
  loadbalancer_id                = "${azurerm_lb.agent_public.id}"
  name                           = "LBRulePort9090"
  protocol                       = "Tcp"
  frontend_port                  = 9090
  frontend_ip_configuration_name = "dcos-agent-public-lbFrontEnd"
  backend_port                   = 9090
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.agent_public.id}"
  probe_id                       = "${azurerm_lb_probe.agent_public_9090.id}"
  idle_timeout_in_minutes        = 5
  load_distribution              = "Default"
  enable_floating_ip             = false
}

resource "azurerm_storage_account" "agent_public" {
  name                = "${substr(sha1(uuid()), 0, 20)}"
  resource_group_name = "${azurerm_resource_group.dcos.name}"
  location            = "${azurerm_resource_group.dcos.location}"
  count               = 5
  account_type        = "Standard_LRS"
  
  lifecycle {
    ignore_changes = ["name"]
  }
}

resource "azurerm_virtual_machine_scale_set" "agent_public" {
  name                = "agent-public-vmss"
  location            = "${azurerm_resource_group.dcos.location}"
  resource_group_name = "${azurerm_resource_group.dcos.name}"
  depends_on          = ["azurerm_virtual_machine.master", "azurerm_virtual_machine_extension.master", "azurerm_storage_account.agent_public"]
  upgrade_policy_mode = "Manual"

  sku {
    name     = "${var.agent_size}"
    tier     = "Standard"
    capacity = "${var.agent_public_count}"
  }

  os_profile {
    computer_name_prefix = "publicagent"
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
    name    = "agentNodeNic"
    primary = true

    ip_configuration {
      name                                    = "nicipconfig"
      subnet_id                               = "${azurerm_subnet.dcospublic.id}"
      load_balancer_backend_address_pool_ids  = ["${azurerm_lb_backend_address_pool.agent_public.id}"]
    }
  }

  storage_profile_os_disk {
    name           = "vmssosdisk"
    caching        = "ReadWrite"
    create_option  = "FromImage"
    vhd_containers = ["${element(azurerm_storage_account.agent_public.*.primary_blob_endpoint, 0)}vhds", "${element(azurerm_storage_account.agent_public.*.primary_blob_endpoint, 1)}vhds", "${element(azurerm_storage_account.agent_public.*.primary_blob_endpoint, 2)}vhds", "${element(azurerm_storage_account.agent_public.*.primary_blob_endpoint, 3)}vhds", "${element(azurerm_storage_account.agent_public.*.primary_blob_endpoint, 4)}vhds"]
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
        "commandToExecute": "bash install.sh '172.16.0.8' 'slave_public'"
    }
SETTINGS
  }   
}

output "Public FQDN" {
  value = "${azurerm_public_ip.agent_public.fqdn}"
}