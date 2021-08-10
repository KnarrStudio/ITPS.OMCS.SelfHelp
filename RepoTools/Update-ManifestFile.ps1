#!/usr/bin/env powershell
#requires -Version 2.0 -Modules Microsoft.PowerShell.Utility

Write-Host -Object 'ITPS.OMCS.Tools.psd1'


$ModulePath = '{0}\{1}.psd1' -f $((Get-Item -Path (Get-Location).Path).Parent.FullName), $((Get-Item -Path (Get-Location).Path).Parent.Name)

$Major = 2     # Changes that cause the code to operate differently or large rewrites
$minor = 1    # When an individual module or function is added
$Patch = 1     # Small updates to a function or module.  Note: This goes to zero when minor is updated
$Manifest = 13  # For each manifest module update

$SplatSettings = @{
  Path              = $ModulePath
  RootModule        = '.\loader.psm1'
  Guid              = "$(New-Guid)"
  Author            = 'Erik'
  CompanyName       = 'Knarr Studio'
  ModuleVersion     = '{0}.{1}.{2}.{3}' -f $Major, $minor, $Patch, $Manifest
  Description       = 'Tools that can be used without admin rights'
  PowerShellVersion = '3.0'
  FunctionsToExport = @('Convert-IPAddresstoBinary', 'Move-Cursor', 'Test-AuthentationServer', 'Test-TheInternet')
  CmdletsToExport   = '*'
  RequiredModules   = 'NetTCPIP'
}


$updateSplat = @{
  Path                       = $ModulePath
  ReleaseNotes               = 'Moved ISE Add On module to the ITPS.OMCS.Tools.  Updated manefest file maker.  Prepped to merge all of the branches.'
  ProjectUri                 = 'https://github.com/KnarrStudio/ITPS.OMCS.SelfHelp'
  ExternalModuleDependencies = @('NetTCPIP')
}

#Create New Manifest File
New-ModuleManifest @SplatSettings 

#Update Manifest File
Update-ModuleManifest @updateSplat


