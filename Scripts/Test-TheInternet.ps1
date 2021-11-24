#requires -Version 3.0 -Modules Microsoft.PowerShell.Utility, NetTCPIP
  function Test-TheInternet
{
  <#PSScriptInfo

      .VERSION 1.1.1

      .GUID 4df65b29-eafd-4ddc-863d-114a67f4532a

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
      Gathering the information on your NIC
      DNSHostName : Workstation Name
      IPAddress : 192.168.1.247
      DefaultIPGateway : 192.168.1.1
      DNSServerSearchOrder : 192.168.1.3, 9.9.9.9
      DHCPEnabled : 192.168.1.1
      IPSubnet : 255.255.255.0
      Description of NIC : Intel(R) Wireless-N
      MACAddress : 00:0B:01:C1:56:77
      Finding the Web facing IP Address External IP : 18.117.109.252
      Testing Loopback connection: 127.0.0.1 : Passed
      Testing IPAddress:
      192.168.1.247 : Passed
      Testing DefaultIPGateway: 192.168.1.1 : Passed
      Testing DNSServerSearchOrder: WARNING: Ping to 192.168.1.3 failed with status: DestinationHostUnreachable
      192.168.1.3 : Failed
      9.9.9.9 : Passed
      Testing DHCPServer: 192.168.1.1 : Passed
      Testing ExternalIp:
      18.117.109.252 : Passed
      Find the report: C:\temp\Username-200721T070003.txt

      .LINK
      https://github.com/KnarrStudio/ITPS.OMCS.SelfHelp/blob/master/README.md

  #>

  BEGIN{
    $TextColorWarning = 'Yellow'
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
          Test-NetworkConnection -TestName 'My Gateway' -TargetNameIp 192.168.0.1
          This will ping the 192.168.0.1 address and lable it 'My Gateway'
        
      #>
      
      
      param
      (
        [Parameter(Position = 0)]
        [string]$TestName = 'Loopback connection',
        [Parameter(Position = 1)]
        [string[]]$TargetNameIp = '127.0.0.1'
      )
      $Delimeter = ':'
      $Formatting = '{0,-23}{1,-2}{2,-24}'
      Write-Verbose -Message $([String]$TargetNameIp)
      try
      {
        Write-Host -Object ('Testing {0}:' -f $TestName) -ForegroundColor Yellow
        ForEach($Target in $TargetNameIp) 
        { 
          Write-Verbose -Message $Target 
          $PingSucceeded = (Test-NetConnection -ComputerName $Target).PingSucceeded
          if($PingSucceeded -eq $true)
          {
            $TestResults = 'Passed'
          }
          elseif($PingSucceeded -eq $false)
          {
            $TestResults = 'Failed'
          }
          Tee-Object -InputObject ($Formatting -f $Target, $Delimeter, $TestResults) -FilePath $NetworkReportFullName -Append
          Write-Verbose ($Formatting -f $TestName, $Delimeter, $TestResults) 
        }
      }
      Catch
      {
        Write-Output -InputObject ('{0} Failed' -f $TestName)
      }
    }
    function Script:Get-WebFacingIPAddress
    {
      <#
          .SYNOPSIS
          Returns the public facing IP address.
        
          .DESCRIPTION
          Add a more complete description of what the function does.
        
          .PARAMETER URL
          in this case it is 'http://checkip.dyndns.org/', but you can use anyone you want such as IPchicken.org
        
          .PARAMETER IpAddress
          The IP address of the local computer.  This is used to compare your address to the one returned.
        
          .EXAMPLE
          Get-WebFacingIPAddress -URL IPchicken.org -IpAddress 192.168.0.123
          Looks at the URL for the IP address that is being presented, then compares it against your local machine. 
        
      #>
      
      
      param
      (
        [Parameter(Position = 0)]
        [String]$URL = 'http://checkip.dyndns.org/',
        [Parameter(Mandatory,HelpMessage = 'Add Local active IPAddress. "ipconfig/ifconfig"',Position = 1)]
        [String]$IpAddress
      )
      $Delimeter = ':'
      $Formatting = '{0,-23}{1,-2}{2,-24}'
      $PrivateArray = @('192.', '10.', '127.')
      $PrivateIp = ($PrivateArray | ForEach-Object -Process {
          if($IpAddress.Contains($_))
          {
            $true
          }
      })
      Write-Verbose -Message ('Ip Address {0}' -f $IpAddress)
      if($PrivateIp)
      {
        $HtmlData = (Invoke-RestMethod -Uri $URL).html.body
        $HtmlString = [string]$HtmlData.Replace(' ','')
        $ExternalIp = ($HtmlString.Split(':'))[1]
      }
      else
      {
        $ExternalIp = $IpAddress
      }
      $NICinfo.ExternalIp = $ExternalIp
      Write-Verbose -Message ('This is the IP address you are presenting to the internet')
      Write-Output -InputObject ($Formatting -f 'External IP', $Delimeter, $ExternalIp)
    }
    function Script:Get-NICinformation
    {
      <#
          .SYNOPSIS
          Returns information about the local active NIC.
      #>
      
      
      param
      (
        [Parameter(Position = 0)]
        [String]
        $Workstation = $env:COMPUTERNAME
      )
      #$NicServiceName = (Get-NetAdapter -physical -| where status -eq 'up') 
      $NicServiceName = (Get-WmiObject -Class win32_networkadapter -Filter 'netconnectionstatus = 2' | Where-Object -FilterScript {
          $_.Description -notmatch 'virtual'  
      }).ServiceName  #select -Property *
      #    $AllNetworkAdaptors = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | where ServiceName -eq $NicServiceName | Select-Object -Property *  #IPEnabled=TRUE -ComputerName $Workstation -ErrorAction Stop | Select-Object -Property * -ExcludeProperty IPX*, WINS*
      $NIC = Get-WmiObject -Class Win32_NetworkAdapterConfiguration |
      Where-Object -Property ServiceName -EQ -Value $NicServiceName |
      Select-Object -Property *  #IPEnabled=TRUE -ComputerName $Workstation -ErrorAction Stop | Select-Object -Property * -ExcludeProperty IPX*, WINS*
      #$AllNetworkAdaptors = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $Workstation -ErrorAction Stop | Select-Object -Property * -ExcludeProperty IPX*, WINS*
      #$AllNetworkAdaptors = Get-NetAdapter | select -Property * | Where-Object {(($_.Status -EQ 'Up' ) -and ($_.ComponentID -match 'PCI'))} 
      #    foreach($NIC in $AllNetworkAdaptors)
      #   {
      #      if($NIC.ServiceName -eq $NicServiceName) 
      #      {
      $NICinfo.DNSHostName          = $NIC.DNSHostName
      $NICinfo.IPAddress            = $NIC.IPAddress[0]
      $NICinfo.DefaultIPGateway     = $NIC.DefaultIPGateway[0]
      $NICinfo.DNSServerSearchOrder = $NIC.DNSServerSearchOrder
      $NICinfo.IPSubnet             = $NIC.IPSubnet[0]
      $NICinfo.Description          = $NIC.Description
      $NICinfo.MACAddress           = $NIC.MACAddress
      if($NIC.DHCPEnabled) 
      {
        $NICinfo.DHCPServer         = $NIC.DHCPServer
      }
      Else
      {
        $NICinfo.DHCPServer         = 'False'
      }
      #      }
      #    }
    }
    
    $userName = $env:USERNAME
    $DateStamp = Get-Date -Format yyMMddTHHmmss
    $NetworkReportPath = "$env:TEMP"
    $NetworkReportName = ('{0}-{1}.txt' -f $userName, $DateStamp)
    $NetworkReportFullName = ('{0}\{1}' -f $NetworkReportPath, $NetworkReportName)
    $Null = New-Item -Path $NetworkReportFullName -ItemType File
    $TempFile = New-TemporaryFile 
    $Delimeter = ':'
    $Formatting = '{0,-23}{1,-2}{2,-24}'
    $Script:NICinfo = [Ordered]@{
      DNSHostName          = ''
      IPAddress            = ''
      DefaultIPGateway     = ''
      DNSServerSearchOrder = ''
      DHCPServer           = ''
      IPSubnet             = ''
      Description          = ''
      MACAddress           = ''
      ExternalIp           = ''
    }
  } 
  PROCESS{
    Write-Host -Object ("Gathering the information on your NIC's") -ForegroundColor $TextColorWarning
    Get-NICinformation
    Tee-Object -InputObject ($Formatting -f 'DNSHostName', $Delimeter, $NICinfo.DNSHostName) -FilePath $NetworkReportFullName -Append
    Tee-Object -InputObject ($Formatting -f 'IPAddress', $Delimeter, $NICinfo.IPAddress) -FilePath $NetworkReportFullName -Append
    Tee-Object -InputObject ($Formatting -f 'DefaultIPGateway', $Delimeter, $NICinfo.DefaultIPGateway) -FilePath $NetworkReportFullName -Append
    Tee-Object -InputObject ($Formatting -f 'DNSServerSearchOrder', $Delimeter, $(([string]$NICinfo.DNSServerSearchOrder).Replace(' ', ', '))) -FilePath $NetworkReportFullName -Append
    Tee-Object -InputObject ($Formatting -f 'DHCPEnabled', $Delimeter, $NICinfo.DHCPServer) -FilePath $NetworkReportFullName -Append
    Tee-Object -InputObject ($Formatting -f 'IPSubnet', $Delimeter, $NICinfo.IPSubnet) -FilePath $NetworkReportFullName -Append
    Tee-Object -InputObject ($Formatting -f 'Description of NIC', $Delimeter, $NICinfo.Description) -FilePath $NetworkReportFullName -Append
    Tee-Object -InputObject ($Formatting -f 'MACAddress', $Delimeter, $NICinfo.MACAddress) -FilePath $NetworkReportFullName -Append
    Write-Host -Object ('Checking for an Authentication Server') -ForegroundColor $TextColorWarning
    try
    {
      # Check if computer is connected to domain network
      [void]::([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain())
      Write-Output -InputObject ($Formatting -f 'Authentication Server', $Delimeter, $env:LOGONSERVER)
    }
    catch
    {
      Write-Output -InputObject ($Formatting -f 'Authentication Server', $Delimeter, 'Not Available')
    }
    Write-Host -Object ('Finding the Web facing IP Address') -ForegroundColor $TextColorWarning
    Get-WebFacingIPAddress -IpAddress $($NICinfo.IPAddress)
    Test-NetworkConnection
    Test-NetworkConnection -TestName 'IPAddress' -TargetNameIp $NICinfo['IPAddress'] 
    Test-NetworkConnection -TestName 'DefaultIPGateway' -TargetNameIp $NICinfo['DefaultIPGateway'] 
    Test-NetworkConnection -TestName 'DNSServerSearchOrder' -TargetNameIp $($NICinfo.DNSServerSearchOrder) 
    if($NICinfo.DHCPServer -ne 'False')
    {
      Test-NetworkConnection -TestName 'DHCPServer' -TargetNameIp $NICinfo.DHCPServer
    }
    Test-NetworkConnection -TestName 'ExternalIp' -TargetNameIp $NICinfo['ExternalIp'] 
  }
  END{
    #$NICinfo | Out-File -FilePath $NetworkReportFullName -Append
    #Get-Content -Path $NetworkReportFullName
    Write-Output -InputObject ('Find the report: {0}' -f $NetworkReportFullName)
    ('Find this report: {0}' -f $NetworkReportFullName) |  Out-File -FilePath $NetworkReportFullName -Append
    Start-Process -FilePath notepad -ArgumentList $NetworkReportFullName
  }
}
