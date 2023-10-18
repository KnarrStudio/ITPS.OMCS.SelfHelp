﻿Function Get-InstalledSoftware
{
  <#
      .SYNOPSIS
      "Get-InstalledSoftware" collects all the software listed in the Uninstall registry.

      .DESCRIPTION
      Add a more complete description of what the function does.

      .PARAMETER SortList
      Allows you to sort by Name, Installed Date or Version Number.  'InstallDate' or 'DisplayName' or 'DisplayVersion'

      .PARAMETER SoftwareName
      This wil provide the installed date, version, and name of the software in the "value".  You can use part of a name or two words, but they must be in quotes.  Mozil or "Mozilla Firefox"

      .PARAMETER File
      Future Use:  Will be used to send to a file instead of the screen. 

      .EXAMPLE
      Get-InstalledSoftware -SortList DisplayName

      InstallDate  DisplayVersion   DisplayName 
      -----------  --------------   -----------
      20150128     6.1.1600.0       Windows MultiPoint Server Log Collector 
      02/06/2007   3.1              Windows Driver Package - Silicon Labs Software (DSI_SiUSBXp_3_1) USB  (02/06/2007 3.1) 
      07/25/2013   10.30.0.288      Windows Driver Package - Lenovo (WUDFRd) LenovoVhid  (07/25/2013 10.30.0.288)


      .EXAMPLE
      Get-InstalledSoftware -SoftwareName 'Mozilla Firefox',Green,vlc 

      Installdate  DisplayVersion  DisplayName                     
      -----------  --------------  -----------                     
      69.0            Mozilla Firefox 69.0 (x64 en-US)
      20170112     1.2.9.112       Greenshot 1.2.9.112             
      2.1.5           VLC media player  

      .NOTES
      Place additional notes here.

      .LINK
      https://github.com/KnarrStudio/ITPS.OMCS.Tools


      .OUTPUTS
      To the screen until the File parameter is working

  #>

  [cmdletbinding(DefaultParameterSetName = 'SortList',SupportsPaging = $true)]
  Param(
    
    [Parameter(Mandatory = $true,HelpMessage = 'At least part of the software name to test', Position = 0,ParameterSetName = 'SoftwareName')]
    [String[]]$SoftwareName,
    [Parameter(ParameterSetName = 'SortList')]
    [Parameter(ParameterSetName = 'SoftwareName')]
    [ValidateSet('DateInstalled', 'DisplayName','DisplayVersion')] 
    [String]$SortList = 'DateInstalled'
    
  )
  
  Begin { 
    $SoftwareOutput = @()
    $InstalledSoftware = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*)
  }
  
  Process {
    Try 
    {
      if($SoftwareName -eq $null) 
      {
        $SoftwareOutput = $InstalledSoftware |
        #Sort-Object -Descending -Property $SortList |
        Select-Object -Property @{
          Name = 'DateInstalled'
          Exp  = {
            $_.InstallDate
          }
        }, @{
          Name = 'Version'
          Exp  = {
            $_.DisplayVersion
          }
        }, DisplayName #, UninstallString 
      }
      Else 
      {
        foreach($Item in $SoftwareName)
        {
          $SoftwareOutput += $InstalledSoftware |
          Where-Object -Property DisplayName -Match -Value $SoftwareName|
          Select-Object -Property @{
            Name = 'DateInstalled'
            Exp  = {
              $_.InstallDate
            }
          }, @{
            Name = 'Version'
            Exp  = {
              $_.DisplayVersion
            }
          }, DisplayName #, UninstallString 
        }
      }
    }
    Catch 
    {
      # get error record
      [Management.Automation.ErrorRecord]$e = $_

      # retrieve information about runtime error
      $info = New-Object -TypeName PSObject -Property @{
        Exception = $e.Exception.Message
        Reason    = $e.CategoryInfo.Reason
        Target    = $e.CategoryInfo.TargetName
        Script    = $e.InvocationInfo.ScriptName
        Line      = $e.InvocationInfo.ScriptLineNumber
        Column    = $e.InvocationInfo.OffsetInLine
      }
      
      # output information. Post-process collected info, and log info (optional)
      $info
    }
  }
  
  End{ 
    Switch ($SortList){
      'DisplayName' 
      {
        $SoftwareOutput |
        Sort-Object -Property 'displayname'
      }
      'DisplayVersion' 
      {
        $SoftwareOutput |
        Sort-Object -Property 'Version'
      }
      'UninstallString'
      {

      }
      'DateInstalled'  
      {
        $SoftwareOutput |
        Sort-Object -Property 'DateInstalled' 
      } 
      default  
      {
        $SoftwareOutput |
        Sort-Object -Property 'DateInstalled'
      } #'InstallDate'
      
    }
  }
}


function Get-SystemUpTime
{
  <#PSScriptInfo

      .VERSION 2.0

      .GUID 404420d4-428f-4f43-833b-ecc511f8318c

      .AUTHOR Erik

      .COMPANYNAME KnarrStudio

      .COPYRIGHT

      .TAGS

      .LICENSEURI

      .PROJECTURI https://knarrstudio.github.io/ITPS.OMCS.Tools/

      .ICONURI

      .EXTERNALMODULEDEPENDENCIES 

      .REQUIREDSCRIPTS

      .EXTERNALSCRIPTDEPENDENCIES

      .RELEASENOTES


      .PRIVATEDATA

  #>
  <# 
      .SYNOPSIS
      Returns the last boot time and uptime in hours for one or many computers
    
      .DESCRIPTION 
      Returns system uptime
    
      .PARAMETER ComputerName
      One or Many Computers
    
      .PARAMETER ShowOfflineComputers
      Returns a list of the computers that did not respond.
    
      .EXAMPLE
      Get-UpTime -ComputerName Value -ShowOfflineComputers
      Returns the last boot time and uptime in hours of the list of computers in "value" and lists the computers that did not respond
    
      .OUTPUTS
      ComputerName LastBoot           TotalHours       
      ------------ --------           ----------       
      localhost    10/9/2019 00:09:28 407.57           
      tester       Unable to Connect  Error Shown Below
    
      Errors for Computers not able to connect.
      tester Error: The RPC server is unavailable. (Exception from HRESULT: 0x800706BA)
  #>
  
  [cmdletbinding(DefaultParameterSetName = 'DisplayOnly')]
  Param (
    [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName,Position = 0)]
    [Alias('hostname')]
    [string[]]$ComputerName = $env:COMPUTERNAME,
    [Parameter (ParameterSetName = 'DisplayOnly')]
    [Switch]$ShowOfflineComputers
  )
  
  BEGIN {
    $ErroredComputers = @()
    $Obj = @()
    $Properties = [PSCustomObject]@{
      ComputerName = ''
      LastBoot     = ''
      TotalHours   = ''
    }
  }
  
  PROCESS {
    Foreach ($Computer in $ComputerName) 
    {
      Try 
      {
        $OS = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer -ErrorAction Stop
        $UpTime = (Get-Date) - $OS.ConvertToDateTime($OS.LastBootUpTime)
        
        $Properties.ComputerName = $Computer
        $Properties.LastBoot     = $OS.ConvertToDateTime($OS.LastBootUpTime)
        $Properties.TotalHours   = ( '{0:n2}' -f $UpTime.TotalHours)
        $Obj += $Properties
      }
      catch 
      {
        if ($ShowOfflineComputers) 
        {
          $ErrorMessage = ('{0} Error: {1}' -f $Computer, $_.Exception.Message)
          $ErroredComputers += $ErrorMessage
          
          $Properties.ComputerName = $Computer
          $Properties.LastBoot     = 'Unable to Connect'
          $Properties.TotalHours   = 'Error Shown Below'
          $Obj += $Properties
        }
      }
    }
  }
  
  END {
    if ($ShowOfflineComputers) 
    {
      Write-Output -InputObject ''
      Write-Output -InputObject 'Errors for Computers not able to connect.'
      Write-Output -InputObject $ErroredComputers
    }
    else
    {
      $Obj
    }
  }
}

