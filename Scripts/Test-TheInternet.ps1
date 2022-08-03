#requires -Version 3.0 -Modules Microsoft.PowerShell.Utility, NetTCPIP
function Test-TheInternet
{
  <#PSScriptInfo

      .VERSION 3.1.2

      .GUID ace3cc09-e726-4f25-9617-ea3d1f52aaba

      .AUTHOR Erik

      .COMPANYNAME KnarrStudio

      .COPYRIGHT 2021 KnarrStudio

      .TAGS 

      .LICENSEURI 

      .PROJECTURI https://github.com/KnarrStudio/ITPS.OMCS.SelfHelp/blob/master/README.md

      .ICONURI 

      .EXTERNALMODULEDEPENDENCIES 

      .REQUIREDSCRIPTS 

      .EXTERNALSCRIPTDEPENDENCIES 

      .RELEASENOTES
      Provides an output on the console and the in a txt file:
      DNSHostName
      IPAddress
      DefaultIPGateway
      DNSServerSearchOrder
      DHCPEnabled
      IPSubnet
      Description of NIC
      MACAddress

  #>

  <#
      .SYNOPSIS
      Tests or "pings" the key points of your internet connection
      .DESCRIPTION
      This came about after trying to walk people through the standard. IPCONFIG and PING the gateway. The script finds different information about the network, network card and network path. Then "pings" those IP Addresses. It provides an output on the console and the in a txt file shown below.
      .EXAMPLE
      Test-TheInternet

      Output:
        Gathering the information on your NICs
        Displaying information on the active NIC
        DNSHostName            : Lenovo-Server
        IPAddress              : 192.168.0.100
        DefaultIPGateway       : 192.168.0.1
        DNSServerSearchOrder   : 9.9.9.9, 192.168.1.3
        DHCPEnabled            : 192.168.0.1
        IPSubnet               : 255.255.255.0
        Description of NIC     : Realtek PCIeController
        MACAddress             : 54:E1:AD:B0:0d:0d
        Finding the Web facing IP Address
        External IP            : 18.117.109.252
        Checking for an Authentication Server
        Authentication Server  : Not Available
        
                     : ---------- Testing ---------- :
        Testing Loopback connection:
        127.0.0.1              : Passed
        Testing IPAddress:
        192.168.0.100          : Passed
        Testing DefaultIPGateway:
        192.168.0.1            : Passed
        Testing DNSServerSearchOrder:
        9.9.9.9                : Passed
        Testing DNSServerSearchOrder: WARNING: Ping to 192.168.1.3 failed with status: DestinationHostUnreachable
        192.168.1.3            : Failed
        Testing DHCPServer:
        192.168.0.1            : Passed
        Testing ExternalIp:
        18.117.109.252          : Failed
        Find the report: C:\temp\Username-200721T070003.txt

      .LINK
      https://github.com/KnarrStudio/ITPS.OMCS.SelfHelp/blob/master/README.md

  #>

  param
  (
    [Parameter(Position = 0)]
    [string]$OutputPath = "$env:TEMP"
  )

  BEGIN{
    $NICinfoMsg = 'Not Available'
    $TextColorWarning = 'Yellow'
    
    $userName = $env:USERNAME
    $DateStamp = Get-Date -Format yyMMddTHHmmss
    $NetworkReportName = ('{0}-{1}.txt' -f $userName, $DateStamp)
    $NetworkReportFullName = ('{0}\{1}' -f $OutputPath, $NetworkReportName)
    $Null = New-Item -Path $NetworkReportFullName -ItemType File
    #$TempFile = New-TemporaryFile 
    $Delimeter = ':'
    $Formatting = '{0,-23}{1,-2}{2,-24}'
    $Script:NICinfo = [Ordered]@{
      DNSHostName          = $NICinfoMsg
      IPAddress            = $NICinfoMsg
      DefaultIPGateway     = $NICinfoMsg
      DNSServerSearchOrder = $NICinfoMsg
      DHCPServer           = $NICinfoMsg
      IPSubnet             = $NICinfoMsg
      Description          = $NICinfoMsg
      MACAddress           = $NICinfoMsg
      ExternalIp           = $NICinfoMsg
    }

    function Script:Get-PhysicalNICInformation
    {
      <#
          .SYNOPSIS
          Captures information about the NICs from different sources and stores it in $NICinfo
      #>
      [CmdletBinding()]
      param
      (
        [Parameter(Mandatory = $false, 
        Position = 0)]
        [Switch]$Physical
      )

      [hashtable]$AdapterInfo = @{}
   
      Write-Verbose -Message "Create '`$NICinfo' hashtable" 
  
      $PhysicalAdapters = Get-NetAdapter -Physical | Select-Object -Property *
      Write-Verbose -Message 'Get physical NICs'
  
      foreach($PhysAdptr in $PhysicalAdapters)
      {
        $AdptrName = $PhysAdptr.Name
        Write-Verbose -Message ('NIC name: {0}' -f $AdptrName)
    
        $AdapterInfo.$AdptrName = @{}
        Write-Verbose -Message ("Create '`$NICInfo.{0}' hash table" -f $AdptrName)
    
        $AdapterInfo.$AdptrName.Name = $AdptrName
        $AdapterInfo.$AdptrName.AdminStatus = $PhysAdptr.AdminStatus
        $AdapterInfo.$AdptrName.LinkSpeed = $PhysAdptr.LinkSpeed
        $AdapterInfo.$AdptrName.InterfaceDescription = $PhysAdptr.InterfaceDescription
        $AdapterInfo.$AdptrName.MediaConnectionState = $PhysAdptr.MediaConnectionState 

        if($PhysAdptr.AdminStatus -eq 'Up')
        {
          try
          {
            $AdapterInfo.$AdptrName.Statistics = (Get-NetAdapterStatistics -Name $AdptrName)
          }
          catch
          {
            $AdapterInfo.$AdptrName.Statistics = 'N/A'
          }
        }

        Write-Verbose -Message ('NIC Name: {0}' -f $AdptrName)
        $ifindex = (Get-NetAdapter -Name $AdptrName).ifIndex
        Write-Verbose -Message ('Interface Index: {0}' -f $ifindex)
        $AdapterInfo.$AdptrName.Config = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration |
        Where-Object -Property interfaceindex -EQ -Value $ifindex |
        Select-Object -Property *
      }
  
      <#  foreach($NicName in $PhysicalAdapters.Name)
          {
          Write-Verbose -Message ('NIC Name: {0}' -f $NicName) -Verbose
          $ifindex = (Get-NetAdapter -Name $NicName).ifIndex
          Write-Verbose -Message ('Interface Index: {0}' -f $ifindex) -Verbose
          $NICinfo.$NicName.Config = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration |
          Where-Object -Property interfaceindex -EQ -Value $ifindex |
          Select-Object -Property *

      }#>


      Return $AdapterInfo
    } #End: Get-PhysicalNICInformation

    function Script:Select-NetworkAdapter
    {
      <#
          .SYNOPSIS
          Selects the main NIC to test against.
      #>

      param
      (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
        Position = 0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('InputData')]
        [Object]$NICinfo
      )
  

      $Script:NicState = @{}
      $NicState.ActiveNicName = @()
      $NicState.DisabledNicName = @()
  
    
      $Messages = @{
        Fix = 'Fix Action: Right click on the network adapter and select "Enable".'
      }

      foreach($key in $NICinfo.Keys)
      {
        if($VerbosePreference -eq 'Continue')
        {
          Write-Output -InputObject ('{0} - {1}/{2}' -f $key, $NICinfo.$key.AdminStatus, $NICinfo.$key.MediaConnectionState)
          #Write-Host -Object ('{0} is Up' -f $CurrentNIC.Name) 
        }

        Switch ($NICinfo.$key.AdminStatus){
          Up 
          {
            $SentStart = $NICinfo.$key.Statistics.SentBytes

            if($NICinfo.$key.MediaConnectionState -eq 'Connected')
            {
              if($SentStart -gt 0)
              {
                $NICinfo.$key.ActiveNIC               = $true
              }
            }
            elseif ($NICinfo.$key.MediaConnectionState -ne 'Connected')
            {
              if($SentStart -gt 0)
              {
                $NICinfo.$key.ActiveNIC               = $true
              } # if not connected
            }

            if($NICinfo.$key.ActiveNIC -eq $true)
            {
              $NicState.ActiveNicName += $NICinfo.$key.Name
            }
            # $ActiveNicName 
          }
      
          Down 
          {
            if($VerbosePreference -eq 'Continue')
            {
              Write-Output -InputObject ('{0} - {1}' -f $($key), $($NICinfo.$key.AdminStatus))
              ('{0}' -f $Messages.Fix) | Write-Output
            }
            $NicState.DisabledNicName += $NICinfo.$key.Name
        
            if($NicState.DisabledNicName.count -eq $NICinfo.$key.Count)
            {
              Write-Output -InputObject 'All Network devices are Disabled.  In the network settings right Click on the NIC and select Enable.'
              #$DisabledNicName
            }
          }

        } # End Switch
      } # End Foreach key
      Return $NicState
    } #End: Select-NetworkAdapter

    function Script:Test-NetworkConnection
    {
      <#
          .SYNOPSIS
          Ping function for use inside the script ping test
        
          .DESCRIPTION
          Uses Test-Netconnect to test an IP address while presenting the name 
        
          .PARAMETER TestName
          Name of the test that you want to present while testing.  Most often user friendly name.  i.e. Gateway, or DHCP server
        
          .PARAMETER TargetNameIp
          IP Address of the system that needs to be tested.
        
          .EXAMPLE
          Test-NetworkConnection -TestName 'My Gateway' -TargetNameIp 192.168.0.1 -NetworkReportFullName test.txt
          This will ping the 192.168.0.1 address and lable it 'My Gateway' and send the results to the file test.txt
        
      #>
      
      param
      (
        [Parameter(Position = 0)]
        [string]$TestName = 'Loopback connection',
        [Parameter(Position = 1)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$TargetNameIp = '127.0.0.1',
        [Parameter(Mandatory = $false)]
        [Alias('NetworkReportFullName')]
        [String]$OutputFile
      )
      $Delimeter = ':'
      $Formatting = '{0,-23}{1,-2}{2,-24}'

      Write-Verbose -Message $([String]$TargetNameIp)
      Write-Host -Object ('Testing {0}:' -f $TestName) -ForegroundColor Yellow
      Add-Content -Value ('Testing {0}:' -f $TestName) -Path $OutputFile
    
      ForEach($Target in $TargetNameIp) 
      { 
        try
        {
          Write-Verbose -Message ([IpAddress]$Target).IPAddressToString -ErrorAction Stop
          $PingSucceeded = (Test-NetConnection -ComputerName $Target).PingSucceeded
          if($PingSucceeded -eq $true)
          {
            $TestResults = 'Passed'
          }
          elseif($PingSucceeded -eq $false)
          {
            $TestResults = 'Failed'
          }
        }
        Catch
        {
          if(($Target -eq $Null) -or ($Target -eq ''))
          {
            $TestResults = 'Null or Blank IPAddress'
          }
          else
          {
            $TestResults = 'Invalid IPAddress'
          }
          Write-Verbose -Message ($Formatting -f $Target, $Delimeter, $TestResults) 
        }
        if($OutputFile)
        {
          Write-Info -Title $Target -Value $TestResults -FilePath $OutputFile
          #Tee-Object -InputObject ($Formatting -f $Target, $Delimeter, $TestResults) -FilePath $OutputFile -Append
        }
        else
        {
          Write-Output -InputObject ($Formatting -f $Target, $Delimeter, $TestResults)
        }
      }
    } #End: Test-NetworkConnection
    
    function Script:Get-WebFacingIPAddress
    {
  <#
      .SYNOPSIS
      Returns the public facing IP address.
        
      .DESCRIPTION
      Uses invoke-WebRequest and Invoke-RestMethod to return your web facing IP Address from one of the following sites:
      'http://checkip.dyndns.org/'
      'https://api.ipify.org'
     
      .EXAMPLE
      Get-WebFacingIPAddress

      Returns the $ExternalIp variable

      .NOTES
      Removed the parameters and added the websites directly to the code, because the simple call didn't work for every website.
 
  #>
  [CmdletBinding()]
  Param()
  $ExtIpCatchMsg = 'Not Available'
  $ErrorActionPreference = "Stop"
try
  {
    $HtmlData = (Invoke-RestMethod -Uri 'http://checkip.dyndns.org/').html.body
    $ExternalIp = [string]$HtmlData.Split(':')[1].trim()
  }
  catch
  {
    $ExternalIp = $ExtIpCatchMsg
  }
  if($ExternalIp -eq $ExtIpCatchMsg)
  {
    try
    {
      $HtmlData = (Invoke-WebRequest -Uri 'https://api.ipify.org?format=json').Content
      $ExternalIp = [String]($HtmlData | ConvertFrom-Json).IP
    }
    Catch
    {
      $ExternalIp = $ExtIpCatchMsg
    }
  }
  Write-Verbose -Message ('This is the IP address you are presenting to the internet')
    
  [String]$ExternalIp
  } #End: Get-WebFacingIPAddress

    function Script:Write-Info 
    {
      <#
          .SYNOPSIS
          Output function

          .INPUTS
          Filename, title of data and data

          .OUTPUTS
          Formatted input information to the screen and file
      #>

      [CmdletBinding()]
      param(
        [Parameter(Mandatory=$true)][string]$Title,
        [Parameter(Mandatory=$true)][Object]$Value,
        [Parameter(Mandatory=$true)][String]$FilePath
      )

      $Delimeter = ':'
      $Formatting = '{0,-23}{1,-2}{2,-24}'
    
      Tee-Object -InputObject ($Formatting -f $Title, $Delimeter, $Value) -FilePath $FilePath  -Append
    } #End: Write-Info 

  }

  PROCESS{
    Write-Host -Object ('Gathering the information on your NICs') -ForegroundColor $TextColorWarning
    
    $PhysicalNICs = Get-PhysicalNICInformation
    $ActiveNicName = [String](Select-NetworkAdapter -InputData $PhysicalNICs ).ActiveNicName
    
    if($PhysicalNICs.$ActiveNicName.Config.DNSHostName)
    {
      $NICinfo.DNSHostName          = $PhysicalNICs.$ActiveNicName.Config.DNSHostName
    }
    if($PhysicalNICs.$ActiveNicName.Config.IPAddress[0])
    {
      $NICinfo.IPAddress            = $PhysicalNICs.$ActiveNicName.Config.IPAddress[0]
    }
    if($PhysicalNICs.$ActiveNicName.Config.DefaultIPGateway)
    {
      $NICinfo.DefaultIPGateway     = $PhysicalNICs.$ActiveNicName.Config.DefaultIPGateway[0]
    }
    if($PhysicalNICs.$ActiveNicName.Config.DNSServerSearchOrder)
    {
      $NICinfo.DNSServerSearchOrder = $PhysicalNICs.$ActiveNicName.Config.DNSServerSearchOrder
    }
    if($PhysicalNICs.$ActiveNicName.Config.IPSubnet[0])
    {
      $NICinfo.IPSubnet             = $PhysicalNICs.$ActiveNicName.Config.IPSubnet[0]
    }
    if($PhysicalNICs.$ActiveNicName.Config.Description)
    {
      $NICinfo.Description          = $PhysicalNICs.$ActiveNicName.Config.Description
    }
    if($PhysicalNICs.$ActiveNicName.Config.MACAddress)
    {
      $NICinfo.MACAddress           = $PhysicalNICs.$ActiveNicName.Config.MACAddress
    }
    if($PhysicalNICs.$ActiveNicName.Config.DHCPEnabled) 
    {
      $NICinfo.DHCPServer         = $PhysicalNICs.$ActiveNicName.Config.DHCPServer
    }
    Else
    {
      $NICinfo.DHCPServer         = 'False'
    }


    Write-Host -Object ('Displaying information on the active NIC') -ForegroundColor $TextColorWarning
    Write-Info -Title 'DNSHostName' -Value $NICinfo.DNSHostName -FilePath $NetworkReportFullName
    Write-Info -Title 'IPAddress' -Value $NICinfo.IPAddress -FilePath $NetworkReportFullName 
    Write-Info -Title 'DefaultIPGateway' -Value $NICinfo.DefaultIPGateway -FilePath $NetworkReportFullName 
    Write-Info -Title 'DNSServerSearchOrder' -Value $(([string]$NICinfo.DNSServerSearchOrder).Replace(' ', ', ')) -FilePath $NetworkReportFullName 
    Write-Info -Title 'DHCPEnabled' -Value $NICinfo.DHCPServer -FilePath $NetworkReportFullName 
    Write-Info -Title 'IPSubnet' -Value $NICinfo.IPSubnet -FilePath $NetworkReportFullName
    Write-Info -Title 'Description of NIC' -Value $NICinfo.Description -FilePath $NetworkReportFullName 
    Write-Info -Title 'MACAddress' -Value $NICinfo.MACAddress -FilePath $NetworkReportFullName 
    
    Write-Host -Object ('Finding the Web facing IP Address') -ForegroundColor $TextColorWarning
    $NICinfo.ExternalIp = Get-WebFacingIPAddress
    Write-Info -Title 'External IP' -Value $NICinfo.ExternalIp -FilePath $NetworkReportFullName

    Write-Host -Object ('Checking for an Authentication Server') -ForegroundColor $TextColorWarning
    try
    {
      # Check if computer is connected to domain network
      [void]::([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain())
      Write-Info -Title 'Authentication Server' -Value $env:LOGONSERVER -FilePath $NetworkReportFullName
    }
    catch
    {
      #Write-Output -InputObject ($Formatting -f 'Authentication Server', $Delimeter, 'Not Available')
      Write-Info -Title 'Authentication Server'-Value $NICinfoMsg -FilePath $NetworkReportFullName
    }


    Write-Info -Title "`n`n" -value '---------- Testing ---------- :' -FilePath $NetworkReportFullName

    Test-NetworkConnection -NetworkReportFullName $NetworkReportFullName
    Test-NetworkConnection -TestName 'IPAddress' -TargetNameIp $NICinfo['IPAddress'] -NetworkReportFullName $NetworkReportFullName 
    Test-NetworkConnection -TestName 'DefaultIPGateway' -TargetNameIp $NICinfo['DefaultIPGateway'] -NetworkReportFullName $NetworkReportFullName 
    Test-NetworkConnection -TestName 'DNSServerSearchOrder' -TargetNameIp $($NICinfo.DNSServerSearchOrder) -NetworkReportFullName $NetworkReportFullName 
    if($NICinfo.DHCPServer -ne 'False')
    {
      Test-NetworkConnection -TestName 'DHCPServer' -TargetNameIp $NICinfo.DHCPServer -NetworkReportFullName $NetworkReportFullName
    }
    Test-NetworkConnection -TestName 'ExternalIp' -TargetNameIp $NICinfo['ExternalIp'] -NetworkReportFullName $NetworkReportFullName 
  }

  END{
    #$NICinfo | Out-File -FilePath $NetworkReportFullName -Append
    #Get-Content -Path $NetworkReportFullName
    Write-Output -InputObject ('Find the report: {0}' -f $NetworkReportFullName)
    ('Find this report: {0}' -f $NetworkReportFullName) |  Out-File -FilePath $NetworkReportFullName -Append
    Start-Process -FilePath notepad -ArgumentList $NetworkReportFullName
  } 
} #End: function Test-TheInternet
