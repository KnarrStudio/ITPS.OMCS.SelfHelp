function Script:Test-NetworkAdapter
{
  <#
      .SYNOPSIS
      Returns information about the local active NIC.
  #>

  param
  (
    [Parameter(Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
    Position = 0)]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [Alias('InputData')]
    [Object]$NetworkAdapterInfo
  )
  
  $Disabled  = @()
  <#  ------------------------------  Ment be moved to main script
      Dealing with the disabled status.
      A good first part since no testing will have to happen.
      It becomes even easier if all of the NICs are disable, because it can just be an output to say they are disabled.
  
      foreach($key in $NetworkAdapterInfo.Keys)
      {
      if($VerbosePreference -eq 'Continue')
      {
      Write-Output -InputObject ('{0} - {1}' -f $($key), $($NetworkAdapterInfo.$key.Status))
      }
      if($NetworkAdapterInfo.$key.Status -eq 'Disabled')
      {
      $Disabled  += $key
      }
      if($Disabled.count -eq $NetworkAdapterInfo.Count)
      {
      Write-Output -InputObject "All Network devices are Disabled.  In the network settings right Click on the NIC and select Enable."
      }
      }
  #>
  
  $NIC = $NetworkAdapterInfo
  Switch ($NIC.Status){
    Up 
    {
      Write-Host -Object "$($NIC.Name) is Up" 


      if($NIC.MediaConnectionState  -eq 'Connected')
      {
        $NICConnectionState = 'Connected'
        $NICDNSHostName          = $NIC.Config.DNSHostName
        $NICIPAddress            = $NIC.Config.IPAddress[0]
        $NICDefaultIPGateway     = $NIC.Config.DefaultIPGateway[0]
        $NICDNSServerSearchOrder = $NIC.Config.DNSServerSearchOrder
        $NICIPSubnet             = $NIC.Config.IPSubnet[0]
        $NICDescription          = $NIC.Config.Description
        $NICMACAddress           = $NIC.Config.MACAddress
          
        if($NIC.DHCPEnabled) 
        {
          $NICDHCPServer         = $NIC.DHCPServer
        }
        Else
        {
          $NICDHCPServer         = 'False'
        }
      } # if connected
      else
      {
        $NIC.ConnectionState = 'Not Connected'
      } # if not connected
    }
      
    Disabled 
    {
      Write-Output -InputObject "$($NIC.Name) is Disabled.  In the network settings right Click on the NIC and select Enable ."
    }
      
    Disconnected 
    {
      Write-Host -Object "$($NIC.Name) is Disconnected"
    }

    Default 
    {
      Write-Host -Object 'Default'
    }

  } # End Switch


  $NICConnectionState 
  $NICDNSHostName         
  $NICIPAddress           
  $NICDefaultIPGateway     
  $NICDNSServerSearchOrder 
  $NICIPSubnet             
  $NICDescription         
  $NICMACAddress  
}


Test-NetworkAdapter -NetworkAdapterInfo $($NICinfo.Ethernet) -Verbose





