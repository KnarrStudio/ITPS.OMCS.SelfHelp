#!/usr/bin/env powershell
#requires -Version 2.0 -Modules Microsoft.PowerShell.Utility

<#
After Running (This is now done automatically):
Change
    # External dependent modules of this module
    ExternalModuleDependencies = 'NetTCPIP'
to this:

    # External dependent modules of this module
    ExternalModuleDependencies = @('NetTCPIP')
#>
param(
$ModuleName = 'ITPS.OMCS.SelfHelp',
$Major = 3,     # Changes that cause the code to operate differently or large rewrites
$minor = 1,   # When an individual module or function is added
$Patch = 4,     # Small updates to a function or module.  Note: This goes to zero when minor is updated
$Manifest = 16,  # For each manifest module update

$PSGallery = 'NasPSGallery',
$ReleaseNotes = 'Big rewrite. Fixed the error handling. Tests for active nic.  Captures all of the NIC information and stores it, instead of just capturing the few bits that were being used.  '
)

function Write-Yellow ($Comment){

    Write-Host -Object $Comment -ForegroundColor Yellow
    }

Write-Yellow -Comment ('Updating the manifest module for {0}' -f $ModuleName)


Write-Yellow -Comment 'Finding the local Github path'

if(Test-Path -Path $env:USERPROFILE\Documents\GitHub)
{
  $GitHubLocation = "$env:USERPROFILE\Documents\GitHub\"
}
elseif(Test-Path -Path D:/GitHub/KnarrStudio)
{
  $GitHubLocation = 'd:/GitHub/KnarrStudio'
}

Write-Yellow -Comment 'Setting location to RepoTools'
Set-Location -Path $GitHubLocation
Set-Location ".\$ModuleName\RepoTools"
$ManifestFilePath = '{0}\{1}.psd1' -f $((Get-Item -Path (Get-Location).Path).Parent.FullName), $((Get-Item -Path (Get-Location).Path).Parent.Name)

$ManifestSplat = @{
  Path              = $ManifestFilePath
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

$UpdateSplat = @{
  Path                       = $ManifestFilePath
  ReleaseNotes               = $ReleaseNotes
  ProjectUri                 = "https://github.com/KnarrStudio/$ModuleName"
  ExternalModuleDependencies = @("NetTCPIP")
}

$PublishSplat = @{
  Name       = ('{0}\{1}' -f $GitHubLocation, $ModuleName)
  Repository = $PSGallery
}

$InstallSplat = @{
  Name         = $ModuleName
  Repository   = $PSGallery
  Scope        = 'CurrentUser'
  AllowClobber = $true
  Force        = $true
}


Write-Yellow -Comment 'Setting location to Github directory'
Set-Location -Path $GitHubLocation


Write-Yellow -Comment 'Create New Manifest File'
New-ModuleManifest @ManifestSplat 

Write-Yellow -Comment 'Update Manifest File'
Update-ModuleManifest @UpdateSplat
(Get-Content $ManifestFilePath).Replace("ExternalModuleDependencies = 'NetTCPIP'","ExternalModuleDependencies = @('NetTCPIP')") | Out-File $ManifestFilePath -Force


Write-Yellow -Comment 'Publish Module'
#Publish-Module @PublishSplat

Write-Yellow -Comment 'Install Module'
#Install-Module @InstallSplat





