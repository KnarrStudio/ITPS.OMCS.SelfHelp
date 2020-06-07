#requires -Version 3.0 -Modules Microsoft.PowerShell.Utility, NetTCPIP

BEGIN{
  function Test-NetworkConnection
  {
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
      ForEach($Target in $TargetNameIp) 
      { 
        Write-Host -Object ('Testing {0}:' -f $TestName) -ForegroundColor Yellow
        Write-Verbose -Message $Target 
      
        $PingSucceeded = (Test-NetConnection -ComputerName $Target ).PingSucceeded
        if($PingSucceeded -eq $true){$TestResults = 'Passed'}elseif($PingSucceeded -eq $false){$TestResults = "Failed"}
        Write-Output -InputObject ($Formatting -f $Target, $Delimeter, $TestResults)
        ($Formatting -f $TestName, $Delimeter, $TestResults) | Out-File -FilePath $NetworkReportFullName -Append
      }
    }
    Catch
    {
      Write-Output -InputObject ('{0} Failed' -f $TestName)
    }
  }
  function Get-WebFacingIPAddress
  {
    param
    (
      [Parameter(Position = 0)]
      [string]$URL = 'http://checkip.dyndns.org/'
    )
  
    $Delimeter = ':'
    $Formatting = '{0,-23}{1,-2}{2,-24}'
  
    $HtmlData = (Invoke-RestMethod -Uri $URL).html.body
    $HtmlString = [string]$HtmlData.Replace(" ","")
    $ExternalIp = ($HtmlString.Split(':'))[1]
    $NICinfo.ExternalIp = $ExternalIp
    
    Write-Verbose -Message ('This is the IP address you are presenting to the internet')
    Write-Output -InputObject ($Formatting -f 'External IP', $Delimeter, $ExternalIp)
  }
  
  function Get-NICinformation
  {
    param
    (
      [Parameter(Position = 0)]
      [String]
      $Workstation = 'LocalHost'
    )
    
    $AllNetworkAdaptors = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $Workstation -ErrorAction Stop | Select-Object -Property * -ExcludeProperty IPX*, WINS*
    #$AllNetworkAdaptors = Get-NetAdapter | select -Property * | Where-Object {(($_.Status -EQ 'Up' ) -and ($_.ComponentID -match 'PCI'))} 
  
    foreach($NIC in $AllNetworkAdaptors)
    {
      if($NIC.index -eq 1) 
      {
        $NICinfo.DNSHostName          = $NIC.DNSHostName
        $NICinfo.IPAddress            = $NIC.IPAddress[0]
        $NICinfo.DefaultIPGateway     = $NIC.DefaultIPGateway[0]
        $NICinfo.DNSServerSearchOrder = $NIC.DNSServerSearchOrder
        $NICinfo.IPSubnet             = $NIC.IPSubnet[0]
        $NICinfo.Description          = $NIC.Description
        $NICinfo.MACAddress           = $NIC.MACAddress

        if($NIC.DHCPEnabled) 
        {
          $NICinfo.DHCPServer           = $NIC.DHCPServer
        }
        Else
        {
          $NICinfo.DHCPServer           = 'False'
        }
      }
    }
  }

  $userName = $env:USERNAME
  $DateStamp = Get-Date -Format yyMMddTHHmmss

  $NetworkReportPath = "$env:HOMEDRIVE\temp"
  $NetworkReportName = ('{0}-{1}.txt' -f $userName, $DateStamp)
  $NetworkReportFullName = ('{0}\{1}' -f $NetworkReportPath, $NetworkReportName)
  New-Item -Path $NetworkReportFullName -ItemType File
  
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

  Write-Host -Object ("Gathering the information on your NIC's") -ForegroundColor Yellow
  Get-NICinformation
  Write-Output -InputObject ($Formatting -f 'DNSHostName', $Delimeter, $NICinfo.DNSHostName)
  Write-Output -InputObject ($Formatting -f 'IPAddress', $Delimeter, $NICinfo.IPAddress)
  Write-Output -InputObject ($Formatting -f 'DefaultIPGateway', $Delimeter, $NICinfo.DefaultIPGateway)
  Write-Output -InputObject ($Formatting -f 'DNSServerSearchOrder', $Delimeter, $(([string]$NICinfo.DNSServerSearchOrder).Replace(' ', ', ')))
  Write-Output -InputObject ($Formatting -f 'DHCPEnabled', $Delimeter, $NICinfo.DHCPServer)
  Write-Output -InputObject ($Formatting -f 'IPSubnet', $Delimeter, $NICinfo.IPSubnet)
  Write-Output -InputObject ($Formatting -f 'Description of NIC', $Delimeter, $NICinfo.Description)
  Write-Output -InputObject ($Formatting -f 'MACAddress', $Delimeter, $NICinfo.MACAddress)
  
  Write-Host -Object ('Finding the Web facing IP Address') -ForegroundColor Yellow
  Get-WebFacingIPAddress

  
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

  $NICinfo | Out-File -FilePath $NetworkReportFullName -Append
  #Get-Content -Path $NetworkReportFullName
  Write-Output -InputObject ('Find the report: {0}' -f $NetworkReportFullName)
  
}


