module "windowsservers" {
  source              = "Azure/compute/azurerm"
  resource_group_name = data.azurerm_resource_group.main.name
  is_windows_image    = true
  vm_hostname         = "${var.prefix}-vm"
  admin_password      = var.admin_password
  vm_os_publisher = "MicrosoftWindowsServer"
  vm_os_offer                   = "WindowsServer"
  vm_os_sku                     = "2019-Datacenter"
  vm_size                       = "Standard_DS2_V2"
  public_ip_dns       = ["${var.prefix}-vmips1","${var.prefix}-vmips2"]
  vnet_subnet_id      = data.azurerm_subnet.main.id
  nb_instances                  = 2
  nb_public_ip                  = 2
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true
}

resource "azurerm_virtual_machine_extension" "windows_custom_script_module" {
  count =  length(module.windowsservers.vm_ids)
  name                 = "extension-windows"
  virtual_machine_id   = module.windowsservers.vm_ids[count.index]
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute":"powershell -ExecutionPolicy Unrestricted -File Install-zabbix-agent.ps1",
        "fileUris": ["https://gist.githubusercontent.com/jacopen/c33657b2c582f1ff8f2c86792b94e5ec/raw/cbd761c8c562a93082f374307b4450b4eb9de6eb/Install-zabbix-agent.ps1"]
    }
SETTINGS
}

output "moduled" {
  value = module.windowsservers.vm_ids
}