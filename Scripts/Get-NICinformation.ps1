$NICinfo = @{}

function Script:Get-NICInformation
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

  [hashtable]$Script:NICinfo = @{}
   
  Write-Verbose -Message "Create '`$NICinfo' hashtable" 
  
  $PhysicalAdapters = Get-NetAdapter -Physical | Select-Object -Property *
  Write-Verbose -Message 'Get physical NICs'
  
  foreach($PhysAdptr in $PhysicalAdapters)
  {
    $AdptrName = $PhysAdptr.Name
    Write-Verbose -Message ('NIC name: {0}' -f $AdptrName)
    
    $NICinfo.$AdptrName = @{}
    Write-Verbose -Message ("Create '`$NICInfo.{0}' hash table" -f $AdptrName)
    
    $NICinfo.$AdptrName.Name = $AdptrName
    $NICinfo.$AdptrName.AdminStatus = $PhysAdptr.AdminStatus
    $NICinfo.$AdptrName.LinkSpeed = $PhysAdptr.LinkSpeed
    $NICinfo.$AdptrName.InterfaceDescription = $PhysAdptr.InterfaceDescription
    $NICinfo.$AdptrName.MediaConnectionState = $PhysAdptr.MediaConnectionState 
  }
  
  foreach($NicName in $PhysicalAdapters.Name)
  {
    Write-Verbose -Message ('NIC Name: {0}' -f $NicName) -Verbose
    $ifindex = (Get-NetAdapter -Name $NicName).ifIndex
    Write-Verbose -Message ('Interface Index: {0}' -f $ifindex) -Verbose
    $NICinfo.$NicName.Config = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration |
    Where-Object -Property interfaceindex -EQ -Value $ifindex |
    Select-Object -Property *
    $NICinfo.$NicName.Statistics = (Get-NetAdapterStatistics -Name $NicName)
    
    }

  Return $NICinfo
}

Get-NICInformation


foreach($NicNam in $NICinfo.Keys){
Write-Host -Object ('{0} - {1}/{2}' -f $NicNam,$NICinfo.$NicNam.AdminStatus,$NICinfo.$NicNam.MediaConnectionState)

if(($NICinfo.$NicNam.AdminStatus -eq 'Up') -and ($NICinfo.$NicNam.MediaConnectionState -eq 'Connected')){
#Write-Host -Object ('{0} - {1}/{2}' -f $n,$NICinfo.$n.AdminStatus,$NICinfo.$n.MediaConnectionState)
$ReceivedStart = $NICinfo.$NicNam.Statistics.ReceivedBytes
Start-Sleep 2
$ReceivedEnd = (Get-NetAdapterStatistics -Name $NicNam).ReceivedBytes
if($ReceivedStart -lt $ReceivedEnd){
}

}elseif(($NICinfo.$NicNam.AdminStatus -eq 'Up') -and ($NICinfo.$NicNam.MediaConnectionState -ne 'Connected')){
#Write-Host -Object ('{0} - {1}/{2}' -f $n,$NICinfo.$n.AdminStatus,$NICinfo.$n.MediaConnectionState)


}

}