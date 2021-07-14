﻿
# .Add("Title of Menu",{Scriptblock},"HotKeys 'Ctrl+Alt+B'")

# Create the Menu Object
$MenuObject = $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add('Self Help',$null,$null) 


# Create the Submenu Object
$MenuObject.Submenus.Add('Test the Internet',{
    C:\Users\erika\Documents\GitHub\ITPS-SelfHelp\Scripts\Test-TheInternet.ps1
},'Ctrl+Alt+T')   
$MenuObject.Submenus.Add('Compare File Hash',{
    . C:\Users\erika\Documents\GitHub\ITPS-SelfHelp\Scripts\Compare-FileHash.ps1
},'Ctrl+Alt+F')
$MenuObject.Submenus.Add('Test Authentication Server',{
    C:\Users\erika\Documents\GitHub\ITPS-SelfHelp\Scripts\Test-AuthentationServer.ps1
},'Ctrl+Alt+A')
$MenuObject.Submenus.Add('Ping IP Range',{
    . C:\Users\erika\Documents\GitHub\AssetManagentapp\Ping-IpRange.ps1
},'Ctrl+Alt+P')




########################################
# Clear the Add-ons menu
#$psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Clear()

# Create an AddOns menu with an accessor.
# Note the use of "_"  as opposed to the "&" for mapping to the fast key letter for the menu item.
#$menuAdded = $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add('_Process', {Get-Process}, 'Alt+P')

# Add a nested menu.
#$parentAdded = $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add('Parent', $null, $null)
#$parentAdded.SubMenus.Add('_Dir', {dir}, 'Alt+D')

# Show the Add-ons menu on the current PowerShell tab.
#$psISE.CurrentPowerShellTab.AddOnsMenu





