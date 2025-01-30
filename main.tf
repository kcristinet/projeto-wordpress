# Cria o resource group
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "random"
}

# Cria a virtual network
resource "azurerm_virtual_network" "projeto_network" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Cria a subnet
resource "azurerm_subnet" "projeto_subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.projeto_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Cria network interface
resource "azurerm_network_interface" "projeto_nic" {
  name                = "myNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.projeto_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.projeto_public_ip.id
  }
}

# Cria Network Security Group e regra
resource "azurerm_network_security_group" "projeto_nsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

 security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "web"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"

  }
}

# Cria public IPs
resource "azurerm_public_ip" "projeto_public_ip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Conecta security group para network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.projeto_nic.id
  network_security_group_id = azurerm_network_security_group.projeto_nsg.id
}

# Gera texto randomico para uma única storage account
resource "random_id" "random_id" {
  keepers = {
    # Gera um novo ID para o novo resource group
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Cria virtual machine
resource "azurerm_linux_virtual_machine" "projeto_vm" {
  name                  = "myVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.projeto_nic.id]
  size                  = "Standard_B1s"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "hostname"
  admin_username = var.username

  admin_ssh_key {
    username   = var.username
    public_key = var.ssh_public_key

  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}

# Cria storage account para boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Inicia script para instalação do WordPress na máquina virtual
resource "azurerm_virtual_machine_extension" "vm_extension" {
  name                 = "install-wordpress"
  virtual_machine_id   = azurerm_linux_virtual_machine.projeto_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
 {
  "fileUris": ["https://raw.githubusercontent.com/KarinPortfolio/wordpress/main/azuredeploy.sh"],
  "commandToExecute": "sh azuredeploy.sh"
 }
SETTINGS
}


