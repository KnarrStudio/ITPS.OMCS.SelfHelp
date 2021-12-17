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
    [Object]$NICinfo
  )
  
  $Script:ActiveNicName = @()
  $Script:DisabledNicName = @()
    
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
          $ActiveNicName += $NICinfo.$key.Name
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
        $DisabledNicName += $NICinfo.$key.Name
        
        if($DisabledNicName.count -eq $NICinfo.$key.Count)
        {
          Write-Output -InputObject 'All Network devices are Disabled.  In the network settings right Click on the NIC and select Enable.'
          $DisabledNicName
        }
      }

    } # End Switch
  } # End Foreach key
}

Select-NetworkAdapter



