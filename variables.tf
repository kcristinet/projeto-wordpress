variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "username"{
  description = "user name"
  type = string
}

variable "ssh_public_key" {
  description = "SSH Public Key for the VM administrator"
  type        = string
}

variable "vm_size" {
  description = "The size of the Virtual Machine"
  default     = "Standard_B1s"
}

