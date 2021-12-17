function Script:Select-NetworkAdapter
{
  <#
      .SYNOPSIS
      Selects the main NIC to test against.
  #>

  param
  (
    [Parameter(Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        #SupportsShouldProcess=$true,
    Position = 0)]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [Alias('InputData')]
    [Object]$InputObject = $NICinfo
  )
  
  $Disabled  = @()
  $NicOutputData = @{}
    
  $Script:ActiveNIC = @{}

  $Messages = @{
  Fix = 'Fix Action: Right click on the network adapter and select "Enable".'
  }

  #$InputObject = $InputObject.Ethernet

  <#
      Dealing with the disabled status.
      A good first part since no testing will have to happen.
      It becomes even easier if all of the NICs are disable, because it can just be an output to say they are disabled.
  #>

  foreach($key in $InputObject.Keys)
  {
  $CurrentNIC = $InputObject.$key
    Switch ($CurrentNIC.AdminStatus){
      Up 
      {
        if($VerbosePreference -eq 'Continue')
        {
          Write-Output -InputObject ('{0} - {1}' -f $($key), $($CurrentNIC.AdminStatus))
          #Write-Host -Object ('{0} is Up' -f $CurrentNIC.Name) 
        }

        if($CurrentNIC.MediaConnectionState  -eq 'Connected')
        {
          $ActiveNIC.NICConnectionState      = $CurrentNIC.MediaConnectionState
          $ActiveNIC.NICDNSHostName          = $CurrentNIC.Config.DNSHostName
          $ActiveNIC.NICIPAddress            = $CurrentNIC.Config.IPAddress[0]
          $ActiveNIC.NICDefaultIPGateway     = $CurrentNIC.Config.DefaultIPGateway[0]
          $ActiveNIC.NICDNSServerSearchOrder = $CurrentNIC.Config.DNSServerSearchOrder
          $ActiveNIC.NICIPSubnet             = $CurrentNIC.Config.IPSubnet[0]
          $ActiveNIC.NICDescription          = $CurrentNIC.Config.Description
          $ActiveNIC.NICMACAddress           = $CurrentNIC.Config.MACAddress
          $ActiveNIC.ActiveNIC               = $true
          
          if($CurrentNIC.Config.DHCPEnabled) 
          {
            $ActiveNIC.NICDHCPServer         = $CurrentNIC.Config.DHCPServer
          }
          Else
          {
            $ActiveNIC.NICDHCPServer         = 'False'
          }
        } # if connected
        else
        {
          $CurrentNIC.ConnectionState = 'Not Connected'
          $ActiveNIC.ActiveNIC               = $false
        } # if not connected
      }
      
      Down 
      {
        if($VerbosePreference -eq 'Continue')
        {
          Write-Output -InputObject ('{0} - {1}' -f $($key), $($CurrentNIC.AdminStatus))
          ('{0}' -f $Messages.Fix) | Write-Output
        }
        $Disabled  += $key
        $NicOutputData.$key = @{
          'Name' = $key
        }
        $NicOutputData.$key.AdminStatus = $CurrentNIC.AdminStatus
        
        if($Disabled.count -eq $CurrentNIC.Count)
        {
          Write-Output -InputObject 'All Network devices are Disabled.  In the network settings right Click on the NIC and select Enable.'
          Return $NicOutputData
        }
      
        #Write-Output -InputObject ('{0} is Disabled.  In the network settings right Click on the NIC and select Enable .' -f $NIC.Name)
      }

    } # End Switch
  } # EndIf

<#  $ActiveNIC.NICConnectionState 
  $ActiveNIC.NICDNSHostName         
  $ActiveNIC.NICIPAddress           
  $ActiveNIC.NICDefaultIPGateway     
  $ActiveNIC.NICDNSServerSearchOrder 
  $ActiveNIC.NICIPSubnet             
  $ActiveNIC.NICDescription         
  $ActiveNIC.NICMACAddress  
  $ActiveNIC.NICDHCPServer #>
}


$t = (Select-NetworkAdapter -InputObject $NICinfo -Verbose)


      $CurrentNIC.Name                    = $NICinfo.$Key.Name
      $CurrentNIC.NICConnectionState      = $NICinfo.$Key.MediaConnectionState
      $CurrentNIC.NICDNSHostName          = $NICinfo.$Key.Config.DNSHostName
      $CurrentNIC.NICIPAddress            = $NICinfo.$Key.Config.IPAddress[0]
      $CurrentNIC.NICDefaultIPGateway     = $NICinfo.$Key.Config.DefaultIPGateway[0]
      $CurrentNIC.NICDNSServerSearchOrder = $NICinfo.$Key.Config.DNSServerSearchOrder
      $CurrentNIC.NICIPSubnet             = $NICinfo.$Key.Config.IPSubnet[0]
      $CurrentNIC.NICDescription          = $NICinfo.$Key.Config.Description
      $CurrentNIC.NICMACAddress           = $NICinfo.$Key.Config.MACAddress