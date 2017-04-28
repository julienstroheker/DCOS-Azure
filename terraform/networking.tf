resource "azurerm_virtual_network" "dcos" {
  name                = "vnet${azurerm_resource_group.dcos.name}"
  resource_group_name = "${azurerm_resource_group.dcos.name}"
  location            = "${azurerm_resource_group.dcos.location}"
  address_space       = ["172.16.0.0/24", "10.0.0.0/8"]
}

resource "azurerm_subnet" "dcosmaster" {
  name                      = "dcos-masterSubnet"
  resource_group_name       = "${azurerm_resource_group.dcos.name}"
  virtual_network_name      = "${azurerm_virtual_network.dcos.name}"
  address_prefix            = "172.16.0.0/24"
}
resource "azurerm_subnet" "dcospublic" {
  name                      = "dcos-agentPublicSubnet"
  resource_group_name       = "${azurerm_resource_group.dcos.name}"
  virtual_network_name      = "${azurerm_virtual_network.dcos.name}"
  network_security_group_id = "${azurerm_network_security_group.dcospublic.id}"
  address_prefix            = "10.0.0.0/11"
}
resource "azurerm_subnet" "dcosprivate" {
  name                      = "dcos-agentPrivateSubnet"
  resource_group_name       = "${azurerm_resource_group.dcos.name}"
  virtual_network_name      = "${azurerm_virtual_network.dcos.name}"
  network_security_group_id = "${azurerm_network_security_group.dcosprivate.id}"
  address_prefix            = "10.32.0.0/11"
}

resource "azurerm_network_security_group" "dcosprivate" {
  name                = "dcos-agent-private-nsg"
  location            = "${azurerm_resource_group.dcos.location}"
  resource_group_name = "${azurerm_resource_group.dcos.name}"
}

resource "azurerm_network_security_group" "dcospublic" {
  name                = "dcos-agent-public-nsg"
  location            = "${azurerm_resource_group.dcos.location}"
  resource_group_name = "${azurerm_resource_group.dcos.name}"

  security_rule {
    name                       = "Allow_HTTP"
    description                = "Allow HTTP traffic from the Internet to Public Agents"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTPS"
    description                = "Allow HTTPS traffic from the Internet to Public Agents"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_8080"
    description                = "Allow 8080 traffic from the Internet to Public Agents"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_9090"
    description                = "Allow 9090 traffic from the Internet to Public Agents"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "9090"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "dcosmaster" {
  name                = "dcos-master-nsg"
  location            = "${azurerm_resource_group.dcos.location}"
  resource_group_name = "${azurerm_resource_group.dcos.name}"

  security_rule {
    name                       = "ssh"
    description                = "Allow SSH"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTP"
    description                = "Allow HTTP traffic from the Internet to Master"
    priority                   = 210
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTPS"
    description                = "Allow HTTPS traffic from the Internet to Master"
    priority                   = 220
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}