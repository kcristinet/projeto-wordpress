# Configuração do provedor
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.16.0"
    }
  }
}

#Autentica o usuario azure
provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}


#Criação do grupo de recursos
resource "azurerm_resource_group" "wordpress" {
  name = "rg-wordpress"
  location = "eastus2"
}

#Criação da rede virtual
resource "azurerm_virtual_network" "wordpress" {
  name = "vnet-wordpress"
  resource_group_name = azurerm_resource_group.wordpress.name
  location = azurerm_resource_group.wordpress.location
  address_space = ["10.0.0.0/16"]
}

#Criação da subnet
resource "azurerm_subnet" "wordpress" {
  name = "subnet-wordpress"
  resource_group_name = azurerm_resource_group.wordpress.name
  virtual_network_name = azurerm_virtual_network.wordpress.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "wordpress" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.wordpress.name
  location            = azurerm_resource_group.wordpress.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

#Criação do plano de serviço do MySQL
resource "azurerm_mssql_server" "wordpress" {
  name                         = "sqlserver-wordpress"
  resource_group_name          = azurerm_resource_group.wordpress.name
  location                     = azurerm_resource_group.wordpress.location
  version                      = "12.0"
  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_login_password
}

#Criação do database MySQL
resource "azurerm_mssql_database" "wordpress" {
  name         = "db-wordpress"
  server_id    = azurerm_mssql_server.wordpress.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "S0"
  enclave_type = "VBS"
  
  # prevent the possibility of accidental data loss
  lifecycle {
    prevent_destroy = true
  }
}

#Criação da interface de rede
resource "azurerm_network_interface" "wordpress" {
  name = "nic-wordpress"
  resource_group_name = azurerm_resource_group.wordpress.name
  location = azurerm_resource_group.wordpress.location

   ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.wordpress.id
    private_ip_address_allocation = "Dynamic"
}
}

#Criação da máquina virtual
resource "azurerm_virtual_machine" "wordpress" {
  name                  = "vm-wordpress"
  location              = azurerm_resource_group.wordpress.location
  resource_group_name   = azurerm_resource_group.wordpress.name
  network_interface_ids = [azurerm_network_interface.wordpress.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

#Criação do disco
resource "azurerm_managed_disk" "wordpress" {
  name = "disk-wordpress"
  resource_group_name = azurerm_resource_group.wordpress.name
  location = azurerm_resource_group.wordpress.location
  storage_account_type = "Standard_LRS"
  create_option = "Empty"
  disk_size_gb = 32
}