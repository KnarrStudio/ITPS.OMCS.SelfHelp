#!/usr/bin/env powershell
#requires -Version 2.0 -Modules Microsoft.PowerShell.Utility
$ModulePath = 'D:\GitHub\KnarrStudio\ITPS-SelfHelp\ITPS-SelfHelp.psd1'

$SplatSettings = @{
  Path              = $ModulePath
  RootModule        = '.\loader.psm1'
  Guid              = "$(New-Guid)"
  Author            = 'Erik'
  CompanyName       = 'KnarrStudio'
  ModuleVersion     = '2.0.1.10'
  Description       = 'Tools that can be used without admin rights'
  PowerShellVersion = '3.0'
  FunctionsToExport = @('Convert-IPAddresstoBinary','Move-Cursor','Test-AuthentationServer','Test-TheInternet')
  CmdletsToExport   = '*'
  RequiredModules   = @('NetTCPIP')

}


$updateSplat = @{
  Path = $ModulePath
    ReleaseNotes      = 'Converted to Module and Updated the manifest'
  ProjectUri   = 'https://github.com/KnarrStudio/ITPS.OMCS.SelfHelp'
  ExternalModuleDependencies = @('NetTCPIP')
}

#Create New Manifest File
New-ModuleManifest @SplatSettings 

#Update Manifest File
Update-ModuleManifest @updateSplat


