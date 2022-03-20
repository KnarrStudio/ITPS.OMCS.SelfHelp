
function Get-OuComputerBelongsTo
{
  <#
      .SYNOPSIS
      Returns the computer name and the OU name the computer belongs to
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $false, Position = 0)]
    [System.String]
    $ComputerName = $env:computername
  )
  
  $Filter = "(&(objectCategory=Computer)(Name=$ComputerName))"
  
  $DirectorySearcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
  $DirectorySearcher.Filter = $Filter
  $SearcherPath = $DirectorySearcher.FindOne()
  $DistinguishedName = $SearcherPath.GetDirectoryEntry().DistinguishedName
  
  $OUName = ($DistinguishedName.Split(','))[1]
  $OUMainName = $OUName.SubString($OUName.IndexOf('=')+1)
  
  $OutputObj = New-Object -TypeName PSObject -Property @{
    'ComputerName' = $ComputerName
    'BelongsToOU' = $OUMainName
  }
  $OutputObj
}





