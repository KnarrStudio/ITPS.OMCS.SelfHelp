if(($InputObject -eq $Null) -or ($InputObject -eq ''))
{
  $InputObject = 'None'
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
  
  $ConnectionStateCode = @{
    0 = 'Disconnected'
    1 = 'Connecting'
    2 = 'Connected'
    3 = 'Disconnecting'
    4 = 'Hardware not present'
    5 = 'Hardware disabled'
    6 = 'Hardware malfunction'
    7 = 'Media disconnected'
    8 = 'Authenticating'
    9 = 'Authentication succeeded'
    10 = 'Authentication failed'
    11 = 'Invalid address'
    12 = 'Credentials required'
  }
  
  $InterfaceType = @{ # Get-NetAdapter | Select -Property InterfaceType
    1 = 'Some other type of network interface'
    6 = 'Ethernet network interface'
    9 = 'Token ring network interface'
    23 = 'PPP network interface'
    24 = 'Software loopback network interface'
    37 = 'ATM network interface'
    71 = 'IEEE 802.11 wireless network interface'
    131 = 'Tunnel type encapsulation network interface'
    144 = 'IEEE 1394 (Firewire) high performance serial bus network interface'
  }
  
  $InfaceAdminStatus = @{
    1 = 'Up'
    2 = 'Down'
    3 = 'Testing'
  } 
  if($NicMAC -ne 'Not Connected')
  {
    #$NicServiceName = (Get-WmiObject -Class win32_networkadapter -Filter 'netconnectionstatus = 2' | Where-Object -FilterScript {
    # $_.Description -notmatch 'virtual'  
    #}).ServiceName  #select -Property *
    #    $AllNetworkAdaptors = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | where ServiceName -eq $NicServiceName | Select-Object -Property *  #IPEnabled=TRUE -ComputerName $Workstation -ErrorAction Stop | Select-Object -Property * -ExcludeProperty IPX*, WINS*
    <#$NIC = ((Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration) |
        Where-Object -Property MacAddress -EQ -Value $NicMAC |
        Select-Object -Property *)
    #>      
    $AllNIC = (Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration) | Where-Object -Property interfaceindex -EQ 10 | Select-Object -Property *
    
    foreach($NIC in $AllNIC){
      $NicMAC = ($NIC.MacAddress).replace('-',':')
    }
    
    #Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object -Property MacAddress $NicMAC | Select-Object -Property *  
    #IPEnabled=TRUE -ComputerName $Workstation -ErrorAction Stop | Select-Object -Property * -ExcludeProperty IPX*, WINS*
    #$AllNetworkAdaptors = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $Workstation -ErrorAction Stop | Select-Object -Property * -ExcludeProperty IPX*, WINS*
    #$AllNetworkAdaptors = Get-NetAdapter | select -Property * | Where-Object {(($_.Status -EQ 'Up' ) -and ($_.ComponentID -match 'PCI'))} 
    #    foreach($NIC in $AllNetworkAdaptors)
    #   {
    #      if($NIC.ServiceName -eq $NicServiceName) 
    #      {
    $Response = 'Not Found'
    try
    {
      $NICinfo.IPXAddress = $NIC.IPXAddress
    }
    catch
    {
      $NICinfo.IPXAddress = $Response
    }
      
    function Script:Set_NICinfo
    {
      param(
        [Parameter(Mandatory,Position = 1)][Object]$Value,
        [Parameter(Mandatory,Position = 0)][String]$Name
      )
      $Response = 'Not Found'
      Write-Verbose -Message ('Name: {0}' -f $Name)
      Write-Verbose -Message ('Value: {0}' -f $Value)
      Write-Verbose -Message ('NIC.Value: {0}' -f $Value)
          
      if($Value)
      {
        $NICinfo.$Name = $Value
      }
      else
      {
        $NICinfo.$Name = $Response
      }
    }


    $Null = Set_NicInfo -Name DNSHostName -Value DNSHostName -Verbose
    $Null = Set_NicInfo -Name IPAddress -Value $NIC.IPAddress[0] -Verbose
    $Null = Set_NicInfo -Name DefaultIPGateway -Value $NIC.DefaultIPGateway[0] -Verbose
    $NICinfo
    foreach($item in $NIC)
    {
      Write-Host -Object $item
    }
         
         
    #$NICinfo.DNSHostName          = $NIC.DNSHostName
    #$NICinfo.IPAddress            = $NIC.IPAddress[0]
    #$NICinfo.DefaultIPGateway     = $NIC.DefaultIPGateway[0]
    $NICinfo.DNSServerSearchOrder = $NIC.DNSServerSearchOrder
    $NICinfo.IPSubnet             = $NIC.IPSubnet[0]
    $NICinfo.Description          = $NIC.Description
    $NICinfo.MACAddress           = $NIC.MACAddress
    if($NIC.DHCPEnabled) 
    {
      Set_NicInfo -Name DHCPServer -Value $NIC.DHCPServer
    }
    Else
    {
      Set_NicInfo -Name DHCPServer -Value 'False'
    }
  }
  #    }
}
