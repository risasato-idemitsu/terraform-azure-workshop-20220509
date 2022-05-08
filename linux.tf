#### Linux VMの設定

## NICを作る
resource "azurerm_network_interface" "linux_nic" {
  name                = "${var.prefix}-linux-nic"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.prefix}ipconfig-linux"
    subnet_id                     = data.azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.linux_pip.id
  }
}

## NICにセキュリティグループを割り当て
resource "azurerm_network_interface_security_group_association" "linux_nic_sg_assoc" {
  network_interface_id      = azurerm_network_interface.linux_nic.id
  network_security_group_id = azurerm_network_security_group.generic_sg.id
}

## パブリックIPをつける
resource "azurerm_public_ip" "linux_pip" {
  name                = "${var.prefix}-linux-ip"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${var.prefix}-lin-test"
}

## VMを作る
resource "azurerm_linux_virtual_machine" "linux" {
  name                            = "${var.prefix}-lin"
  location                        = data.azurerm_resource_group.main.location
  resource_group_name             = data.azurerm_resource_group.main.name
  size                            = "Standard_F2"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false # 一般的にはtrueにしてpublic keyを指定すべき https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine#admin_ssh_key
  network_interface_ids           = [azurerm_network_interface.linux_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  depends_on = [azurerm_network_interface_security_group_association.linux_nic_sg_assoc]
}

resource "azurerm_virtual_machine_extension" "linux_custom_script" {
  name                 = "extension-linux2"
  virtual_machine_id   = azurerm_linux_virtual_machine.linux.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "touch /tmp/hello"
    }
SETTINGS
}

#### アウトプットの設定
output "linux_pip" {
  value = azurerm_public_ip.linux_pip.ip_address
}
