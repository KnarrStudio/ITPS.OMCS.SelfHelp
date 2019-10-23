#Requires -Module NetAdapter, NetTCPIP 


begin{
  function Get-MyGateway
  {
    param
    (
      [Object]
      [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'Data to filter')]
      $InputObject
    )
    process
    {
      if ($InputObject.DestinationPrefix -eq '0.0.0.0/0')
      {
        $InputObject
      }
    }
  }

  Function Get-MyNicStatus 
  {
    Get-NetAdapter | ForEach-Object -Process {
      Write-Host ('{0} adapter status is: ' -f $_.name) -NoNewline
      if($_.status -ne 'Up')
      {
        Write-Host $_.status -ForegroundColor Red
      }
      Else
      {
        Write-Host $_.status -ForegroundColor Green
        #Get-NetAdapterStatistics -Name $_.Name
      }
    }
  }

  Get-MyNicStatus #For Testing
  function Test-MyGateway 
  {
    for($i = 0; $i -lt $MyNetAdapter.Length; $i++)
    {
      $NicName = $MyNetAdapter[$i].Name
      
      if(($MyNetAdapter[$i].mediaconnectionstate) -eq 'Connected')
      {
        $GatewayPresent = Test-Connection -ComputerName $MyGateway.NextHop -Count 1 -BufferSize 1000 -Quiet
            
        Write-Host ('NIC "{0}" can connect to the Gateway {1}: ' -f $NicName, ($MyGateway.NextHop)) -NoNewline -ForegroundColor cyan
         
        if ($GatewayPresent -eq $true)
        {
          Write-Host $GatewayPresent -ForegroundColor Green
        }
        else
        {
          Write-Host $GatewayPresent -ForegroundColor Red
        }
      }
    }
  }

  function Get-MyActiveIpAddress 
  {
    <#
        .SYNOPSIS
        Internal to script Get's ip information from most active NIC.
    #>

    [CmdletBinding()]
    Param()
  
    Begin{

      $testBytes = $null
    }
  
    Process{
      Try
      {            
        $AllNetworkAdaptors = Get-NetAdapter | Where-Object -Property Status -EQ -Value Up 
        if($AllNetworkAdaptors.count -ge 1)
        {
          foreach($CurrentAdaptor in $AllNetworkAdaptors)
          {
            $CurrentAdaptorStats = Get-NetAdapterStatistics -Name $CurrentAdaptor
            if($CurrentAdaptorStats.ReceivedBytes -gt $testBytes)
            {
              $testBytes = $CurrentAdaptorStats.ReceivedBytes
              $MostActiveAddapter = $CurrentAdaptor
            }
          }
        }
        $MostActiveAddapter = $AllNetworkAdaptors
        ($MostActiveAddapter | Get-NetIPAddress -AddressFamily IPv4).ipaddress
      }
    
      Catch
      {

      }
    }
  
    End{

    }
  }

  #$MyGateway = Get-NetRoute | Get-MyGateway
  #$MyNetAdapter = Get-NetAdapter
  $OutputFileName = "c:\temp\SelfHelp-$(get-date -Format mmss).txt"
}

process{
  Clear-Host
  Start-Transcript -Path $OutputFileName
  Get-MyNicStatus
  Write-Host ('The IP Address: {0}' -f (Get-MyActiveIpAddress))
  Test-MyGateway
  Stop-Transcript
  Start-Process notepad.exe $OutputFileName
}

end{}
