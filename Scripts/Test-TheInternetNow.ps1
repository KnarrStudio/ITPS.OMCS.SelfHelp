#PSScriptInfo
<#
    .VERSION 3.2.1
    .GUID 7e8e1c7b-4e2b-4c8e-9e2e-123456789abc
    .AUTHOR Erik
    .COMPANYNAME KnarrStudio
    .COPYRIGHT 2021-2024 KnarrStudio
    .TAGS network, diagnostics, ping, report, dns
    .LICENSEURI 
    .PROJECTURI https://github.com/KnarrStudio/ITPS.OMCS.SelfHelp/blob/master/README.md
    .ICONURI 
    .EXTERNALMODULEDEPENDENCIES Microsoft.PowerShell.Utility, NetTCPIP
    .REQUIREDSCRIPTS 
    .EXTERNALSCRIPTDEPENDENCIES 
    .RELEASENOTES
    - Improved DNS resolution output and error handling
    - Added multi-source external IP detection
    - Enhanced comments and comment-based help
#>

<#
    .SYNOPSIS
    Tests and reports on key points of your internet/network connection.

    .DESCRIPTION
    This script gathers information about your network adapters, pings key addresses (loopback, gateway, DNS, DHCP, external IP), and reports your public IP if your local IP is private. It also tests DNS resolution for your hostname and local IP using your configured DNS servers. Results are output to the console and a timestamped text file.

    .EXAMPLE
    Test-TheInternetNow

    .LINK
    https://github.com/KnarrStudio/ITPS.OMCS.SelfHelp/blob/master/README.md
#>

#requires -Version 5.1 -Modules Microsoft.PowerShell.Utility, NetTCPIP

function Test-TheInternetNow 
{
  <#
      .SYNOPSIS
      Tests or "pings" the key points of your internet connection and generates a report.

      .DESCRIPTION
      Gathers NIC/network info, pings key addresses, checks external IP, and tests DNS resolution for hostname and local IP. Results are written to a timestamped report file and the console.

      .EXAMPLE
      Test-TheInternetNow

      .LINK
      https://github.com/KnarrStudio/ITPS.OMCS.SelfHelp/blob/master/README.md
  #>
  param(
    [Parameter(Position = 0)]
    [string]$OutputPath = "$env:TEMP"
  )

  # Set up variables and report file
  $NICinfoMsg = 'Not Available'
  $TextColorWarning = 'Yellow'
  $userName = $env:USERNAME
  $DateStamp = Get-Date -Format yyMMddTHHmmss
  $NetworkReportName = ('{0}-{1}.txt' -f $userName, $DateStamp)
  $NetworkReportFullName = Join-Path -Path $OutputPath -ChildPath $NetworkReportName
  $null = New-Item -Path $NetworkReportFullName -ItemType File -Force
  $Delimeter = ':'
  $Formatting = '{0,-33}{1,-2}{2,-24}'

  # Initialize NIC info object
  $NICinfo = [PSCustomObject]@{
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

  #region Helper Functions

  function Test-DnsResolution 
  {
    <#
        .SYNOPSIS
        Tests DNS resolution for the local host and local IP using configured DNS servers.

        .DESCRIPTION
        For each DNS server, attempts to resolve the local hostname to IPv4 and the local IP to a hostname (PTR). Results are written to the report and console.
    #>
    param(
      [Parameter(Mandatory)][string]$HostName,
      [Parameter(Mandatory)][string]$LocalIp,
      [Parameter(Mandatory)][string[]]$DnsServers,
      [Parameter(Mandatory)][string]$OutputFile,
      [Parameter(Mandatory)][string]$Delimeter,
      [Parameter(Mandatory)][string]$Formatting
    )

    $DnsTestHeader = "`n---------- DNS Resolution Tests ----------`n"
    Add-Content -Path $OutputFile -Value $DnsTestHeader

    foreach ($dns in $DnsServers) 
    {
      # Hostname to IPv4
      try 
      {
        $hostResult = Resolve-DnsName -Server $dns -Name $HostName -ErrorAction Stop
        $ipv4s = $hostResult |
        Where-Object -FilterScript {
          $_.QueryType -eq 'A' 
        } |
        Select-Object -ExpandProperty IPAddress
        if ($ipv4s) 
        {
          $line = $Formatting -f ('DNS ({0}) resolves' -f $dns), $Delimeter, ('{0} to {1}' -f $HostName, ($ipv4s -join ', '))
        }
        else 
        {
          $line = $Formatting -f ('DNS ({0}) resolves' -f $dns), $Delimeter, ('{0} (no IPv4 found)' -f $HostName)
        }
      }
      catch 
      {
        $line = $Formatting -f ('DNS ({0}) resolves' -f $dns), $Delimeter, ('{0} Failed' -f $HostName)
      }
      Write-Host $line
      $line | Tee-Object -FilePath $OutputFile -Append

      # IPv4 to Hostname (reverse lookup)
      try 
      {
        $ipResult = Resolve-DnsName -Server $dns -Name $LocalIp -ErrorAction Stop
        $nameHost = $ipResult |
        Where-Object -FilterScript {
          $_.NameHost 
        } |
        Select-Object -ExpandProperty NameHost -First 1
        if ($nameHost) 
        {
          $line = $Formatting -f ('DNS ({0}) PTR' -f $dns), $Delimeter, ('{0} to {1}' -f $LocalIp, $nameHost)
        }
        else 
        {
          $line = $Formatting -f ('DNS ({0}) PTR' -f $dns), $Delimeter, ('{0} (no PTR found)' -f $LocalIp)
        }
      }
      catch 
      {
        $line = $Formatting -f ('DNS ({0}) PTR' -f $dns), $Delimeter, ('{0} Failed' -f $LocalIp)
      }
      Write-Host $line
      $line | Tee-Object -FilePath $OutputFile -Append
    }
  }

  function Get-PhysicalNICInformation 
  {
    <#
        .SYNOPSIS
        Gets information about all physical NICs that are up.

        .DESCRIPTION
        Returns a hashtable of NIC names to NIC info objects, including configuration and statistics.
    #>
    $adapters = Get-NetAdapter -Physical | Where-Object -Property Status -EQ -Value 'Up'
    $info = @{}
    foreach ($adapter in $adapters) 
    {
      $ifindex = $adapter.ifIndex
      $config = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object -Property InterfaceIndex -EQ -Value $ifindex
      $info[$adapter.Name] = [PSCustomObject]@{
        Name                 = $adapter.Name
        AdminStatus          = $adapter.AdminStatus
        LinkSpeed            = $adapter.LinkSpeed
        InterfaceDescription = $adapter.InterfaceDescription
        MediaConnectionState = $adapter.MediaConnectionState
        Statistics           = $(try 
          {
            Get-NetAdapterStatistics -Name $adapter.Name 
          }
          catch 
          {
            $null 
          }
        )
        Config               = $config
      }
    }
    return $info
  }

  function Select-NetworkAdapter 
  {
    <#
        .SYNOPSIS
        Selects the first connected NIC, or the first available if none are connected.

        .DESCRIPTION
        Returns the name of the preferred NIC for testing.
    #>
    param([Parameter(Mandatory)][object]$NICinfo)
    foreach ($key in $NICinfo.Keys) 
    {
      $nic = $NICinfo[$key]
      if ($nic.AdminStatus -eq 'Up' -and $nic.MediaConnectionState -eq 'Connected') 
      {
        return $key
      }
    }
    # fallback: just return the first one
    return $NICinfo.Keys | Select-Object -First 1
  }

  function Test-NetworkConnection 
  {
    <#
        .SYNOPSIS
        Pings a list of targets and writes results to file.

        .DESCRIPTION
        For each target, pings and logs the result with the test name and IP.
    #>
    param(
      [Parameter(Mandatory)][string]$TestName,
      [Parameter(Mandatory)][string[]]$TargetNameIp,
      [Parameter(Mandatory)][string]$OutputFile
    )
    Add-Content -Value (('Testing: {0}' -f $TestName)) -Path $OutputFile

    foreach ($Target in $TargetNameIp) 
    {
      $TestResults = 'Unknown'
      try 
      {
        $PingSucceeded = (Test-NetConnection -ComputerName $Target).PingSucceeded
        $TestResults = if ($PingSucceeded) 
        {
          'Passed' 
        }
        else 
        {
          'Failed' 
        }
      }
      catch 
      {
        $TestResults = 'Invalid IPAddress'
      }
      $line = $Formatting -f ('{0} ({1})' -f $TestName, $Target), $Delimeter, $TestResults
      if ($OutputFile) 
      {
        $line | Tee-Object -FilePath $OutputFile -Append
      }
      else 
      {
        Write-Output -InputObject $line
      }
    }
  }

  function Write-Info 
  {
    <#
        .SYNOPSIS
        Writes formatted info to file and console.

        .DESCRIPTION
        Formats and outputs a line to both the console and the report file.
    #>
    param(
      [Parameter(Mandatory)][string]$Title,
      [Parameter(Mandatory)][object]$Value,
      [Parameter(Mandatory)][string]$FilePath,
      [Parameter(Mandatory)][string]$Delimeter
    )
    $line = $Formatting -f $Title, $Delimeter, $Value
    $line | Tee-Object -FilePath $FilePath -Append
  }

  function Is-PrivateIp 
  {
    <#
        .SYNOPSIS
        Checks if an IP address is private (RFC1918).
    #>
    param([Parameter(Mandatory)][string]$Ip)
    return ($Ip -match '^10\.' -or
      $Ip -match '^192\.168\.' -or
    $Ip -match '^172\.(1[6-9]|2[0-9]|3[0-1])\.')
  }

  function Get-WebFacingIPAddress 
  {
    <#
        .SYNOPSIS
        Returns the public facing IP address, or the local IP if already public.

        .DESCRIPTION
        Tries multiple external services to determine the public IP address.
    #>
    param([Parameter(Mandatory)][string]$LocalIp)
    $ExtIpAddressRegEx = '(\d{1,3}\.){3}\d{1,3}'
$ExtIpCatchMsg = 'Not Available'
    $ErrorActionPreference = 'Stop'
    # If local IP is public, just return it
    if ($LocalIp -and -not (Is-PrivateIp -Ip $LocalIp)) 
    {
      return $LocalIp
    }
    # Otherwise, try to get external IP from multiple sources
    $ExternalIp = $ExtIpCatchMsg

    # 1. checkip.dyndns.org
    try 
    {
      $HtmlData = (Invoke-RestMethod -Uri 'http://checkip.dyndns.org/').html.body
      $ExternalIp = [string]$HtmlData.Split(':')[1].trim()
      if ($ExternalIp -match $ExtIpAddressRegEx) 
      {
        return $ExternalIp 
      }
    }
    catch 
    {
      # get error record
      [Management.Automation.ErrorRecord]$e = $_

      # retrieve information about runtime error
      $info = [PSCustomObject]@{
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

    # 2. ipify.org
    if ($ExternalIp -eq $ExtIpCatchMsg) 
    {
      try 
      {
        $HtmlData = (Invoke-WebRequest -Uri 'https://api.ipify.org?format=json').Content
        $ExternalIp = [String](($HtmlData | ConvertFrom-Json).ip)
        if ($ExternalIp -match $ExtIpAddressRegEx) 
        {
          return $ExternalIp 
        }
      }
      catch 
      {
        # get error record
        [Management.Automation.ErrorRecord]$e = $_

        # retrieve information about runtime error
        $info = [PSCustomObject]@{
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

    # 3. ipchicken.com
    if ($ExternalIp -eq $ExtIpCatchMsg) 
    {
      try 
      {
        $HtmlData = Invoke-WebRequest -Uri 'https://www.ipchicken.com/' -UseBasicParsing
        $ipMatch = $HtmlData.Content -match 'Current IP Address:.*?(\d{1,3}(?:\.\d{1,3}){3})'
        if ($ipMatch) 
        {
          $ExternalIp = $Matches[1]
          if ($ExternalIp -match $ExtIpAddressRegEx) 
          {
            return $ExternalIp 
          }
        }
      }
      catch 
      {
        # get error record
        [Management.Automation.ErrorRecord]$e = $_

        # retrieve information about runtime error
        $info = [PSCustomObject]@{
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

    # 4. ifconfig.me (recommended, simple plain text)
    if ($ExternalIp -eq $ExtIpCatchMsg) 
    {
      try 
      {
        $ExternalIp = Invoke-RestMethod -Uri 'https://ifconfig.me/ip'
        if ($ExternalIp -match $ExtIpAddressRegEx) 
        {
          return $ExternalIp 
        }
      }
      catch 
      {
        # get error record
        [Management.Automation.ErrorRecord]$e = $_

        # retrieve information about runtime error
        $info = [PSCustomObject]@{
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

    return $ExternalIp
  }

  #endregion

  # Main script logic

  try 
  {
    Write-Host 'Gathering the information on your NICs' -ForegroundColor $TextColorWarning
    $PhysicalNICs = Get-PhysicalNICInformation
    if (-not $PhysicalNICs.Keys.Count) 
    {
      Write-Error -Message 'No physical network adapters found. Exiting script.'
      return
    }
    $ActiveNicName = Select-NetworkAdapter -NICinfo $PhysicalNICs
    if (-not $ActiveNicName) 
    {
      Write-Error -Message 'No active network adapter found. Exiting script.'
      return
    }

    $activeNic = $PhysicalNICs[$ActiveNicName]
    if (-not $activeNic -or -not $activeNic.Config) 
    {
      Write-Error -Message 'Could not retrieve configuration for the active NIC. Exiting script.'
      return
    }

    # Populate NICinfo object with details from the active NIC
    if ($activeNic.Config.DNSHostName)          
    {
      $NICinfo.DNSHostName          = $activeNic.Config.DNSHostName 
    }
    if ($activeNic.Config.IPAddress[0])         
    {
      $NICinfo.IPAddress            = $activeNic.Config.IPAddress[0] 
    }
    if ($activeNic.Config.DefaultIPGateway)     
    {
      $NICinfo.DefaultIPGateway     = $activeNic.Config.DefaultIPGateway[0] 
    }
    if ($activeNic.Config.DNSServerSearchOrder) 
    {
      $NICinfo.DNSServerSearchOrder = $activeNic.Config.DNSServerSearchOrder 
    }
    if ($activeNic.Config.IPSubnet[0])          
    {
      $NICinfo.IPSubnet             = $activeNic.Config.IPSubnet[0] 
    }
    if ($activeNic.Config.Description)          
    {
      $NICinfo.Description          = $activeNic.Config.Description 
    }
    if ($activeNic.Config.MACAddress)           
    {
      $NICinfo.MACAddress           = $activeNic.Config.MACAddress 
    }
    if ($activeNic.Config.DHCPEnabled)          
    {
      $NICinfo.DHCPServer           = $activeNic.Config.DHCPServer 
    }
    else                                        
    {
      $NICinfo.DHCPServer           = 'False' 
    }

    # Output NIC info
    Write-Info -Title 'HostName'           -Value $NICinfo.DNSHostName          -FilePath $NetworkReportFullName -Delimeter $Delimeter
    Write-Info -Title 'Local IPAddress'    -Value $NICinfo.IPAddress            -FilePath $NetworkReportFullName -Delimeter $Delimeter
    Write-Info -Title 'Default Gateway'    -Value $NICinfo.DefaultIPGateway     -FilePath $NetworkReportFullName -Delimeter $Delimeter
    Write-Info -Title 'DNS Server(s)'      -Value ($NICinfo.DNSServerSearchOrder -join ', ') -FilePath $NetworkReportFullName -Delimeter $Delimeter
    Write-Info -Title 'DHCP Server'        -Value $NICinfo.DHCPServer           -FilePath $NetworkReportFullName -Delimeter $Delimeter
    Write-Info -Title 'IP Subnet'          -Value $NICinfo.IPSubnet             -FilePath $NetworkReportFullName -Delimeter $Delimeter
    Write-Info -Title 'Description of NIC' -Value $NICinfo.Description          -FilePath $NetworkReportFullName -Delimeter $Delimeter
    Write-Info -Title 'MAC Address'        -Value $NICinfo.MACAddress           -FilePath $NetworkReportFullName -Delimeter $Delimeter

    Write-Host 'Finding the Web facing IP Address' -ForegroundColor $TextColorWarning
    $NICinfo.ExternalIp = Get-WebFacingIPAddress -LocalIp $NICinfo.IPAddress
    if (-not $NICinfo.ExternalIp -or $NICinfo.ExternalIp -eq 'Not Available') 
    {
      Write-Warning -Message 'Could not determine external IP address.'
    }
    Write-Info -Title 'External IP' -Value $NICinfo.ExternalIp -FilePath $NetworkReportFullName -Delimeter $Delimeter

    Write-Host 'Checking for an Authentication Server' -ForegroundColor $TextColorWarning
    $domainCheck = $null
    try 
    {
      $domainCheck = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()
    }
    catch 
    {
      $domainCheck = $null
    }
    if ($domainCheck) 
    {
      Write-Info -Title 'Authentication Server' -Value $env:LOGONSERVER -FilePath $NetworkReportFullName -Delimeter $Delimeter
    }
    else 
    {
      Write-Info -Title 'Authentication Server' -Value $NICinfoMsg -FilePath $NetworkReportFullName -Delimeter $Delimeter
    }

    # Print a clear section header to both console and file
    $testHeader = "`n---------- Testing Network Connectivity ----------`n"
    Write-Host $testHeader -ForegroundColor Cyan
    Add-Content -Path $NetworkReportFullName -Value $testHeader

    # Run network tests with error checking
    try 
    {
      Test-NetworkConnection -TestName 'Loopback'         -TargetNameIp '127.0.0.1'              -OutputFile $NetworkReportFullName
      Test-NetworkConnection -TestName 'Local IPAddress'  -TargetNameIp $NICinfo.IPAddress       -OutputFile $NetworkReportFullName
      Test-NetworkConnection -TestName 'Default Gateway'  -TargetNameIp $NICinfo.DefaultIPGateway-OutputFile $NetworkReportFullName
      Test-NetworkConnection -TestName 'DNS Server'       -TargetNameIp $NICinfo.DNSServerSearchOrder -OutputFile $NetworkReportFullName
      if ($NICinfo.DHCPServer -ne 'False' -and $NICinfo.DHCPServer) 
      {
        Test-NetworkConnection -TestName 'DHCP Server' -TargetNameIp $NICinfo.DHCPServer -OutputFile $NetworkReportFullName
      }
      if ($NICinfo.ExternalIp -and $NICinfo.ExternalIp -ne 'Not Available') 
      {
        Test-NetworkConnection -TestName 'External Ip' -TargetNameIp $NICinfo.ExternalIp -OutputFile $NetworkReportFullName
      }
         
      # call the DNS resolution section:
      $DnsTestHeader = "`n---------- DNS Resolution Tests ----------`n"
      Write-Host $DnsTestHeader -ForegroundColor Cyan

      $TestDnsResolutionParams = @{
        HostName   = $NICinfo.DNSHostName
        LocalIp    = $NICinfo.IPAddress
        DnsServers = $NICinfo.DNSServerSearchOrder
        OutputFile = $NetworkReportFullName
        Delimeter  = $Delimeter
        Formatting = $Formatting
      }
      Test-DnsResolution @TestDnsResolutionParams
    }
    catch 
    {
      Write-Warning -Message ('An error occurred during network connection tests: {0}' -f $_)
    }

    Write-Output -InputObject ('{1}Find the report: {0}' -f $NetworkReportFullName, "`n")
  }
  catch 
  {
    Write-Error -Message ('A fatal error occurred: {0}' -f $_)
  }
}

# Run the function
Test-TheInternetNow