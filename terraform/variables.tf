variable "resource_base_name" {}

variable "resource_suffix" {}

variable "dcos_download_url" {}

variable "private_key_path" {}

variable "public_key_path" {}

variable "vm_user" {}

variable "location" {}

variable "owner" {}

variable "expiration" {}

variable "image" {
  type = "map"

  default = {
    publisher = "CoreOS"
    offer     = "CoreOS"
    sku       = "Stable"
    version   = "latest"
  }
}

/* Masters */
variable "master_count" {}

variable "master_port" {
  default = {
    "1" = 2200
    "2" = 2201
    "3" = 2202
    "4" = 2203
    "5" = 2204
    "6" = 2205
    "7" = 2206
    "8" = 2207
    "9" = 2208
    "10" = 2209
  }
}

/* Agents */

variable "publicAgentFQDN" {}

/* Bootstrap */
variable "bootstrap_size" {
  default = "Standard_A2"
}

variable "bootstrap_private_ip_address_index" {
  default = "8"
}

variable "master_size" {
  default = "Standard_D2_V2"
}

variable "master_private_ip_address_index" {
  default = "10"
}

variable "masterFQDN" {
  default = "mastervip"
}

variable "agent_private_count" {
  default = 10
}

variable "agent_size" {
  default = "Standard_D2_V2"
}

variable "agent_private_ip_address_index" {
  default = "15"
}

/* Public Agents */
variable "agent_public_count" {
  default = 2
}

variable "agent_public_size" {
  default = "Standard_D2_V2"
}

variable "agent_public_private_ip_address_index" {
  default = "200"
}
