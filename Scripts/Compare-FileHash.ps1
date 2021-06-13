#requires -Version 4.0
Function Compare-FileHash 
{
  <#
      .Synopsis
      Generates a file hash and compares against a known hash
      .Description
      Generates a file hash and compares against a known hash.
      .Parameter File
      Mandatory. File name to generate hash. Example file.txt
      .Parameter Hash
      Mandatory. Known hash. Example 186F55AC6F4D2B60F8TB6B5485080A345ABA6F82
      .Parameter Algorithm
      Mandatory. Algorithm to use when generating the hash. Example SHA1
      .Notes
      Version: 1.0
      History:
      .Example
      Compare-FileHash -fileName file.txt -Hash  186F5AC26F4E9B12F861485485080A30BABA6F82 -Algorithm SHA1
  #>

  Param(
    [Parameter(Mandatory,HelpMessage = 'The file that you are testing against.  Normally the file that you just downloaded.')]
    [string] $fileName
    ,
    [Parameter(Mandatory,HelpMessage = 'The original hash that you are expecting it to be the same.  Normally provided by website at download.')]
    [string] $originalhash
    ,
    [Parameter(Mandatory,HelpMessage = 'Enter "SHA256" as an example.  Or press "TAB".')]
    [ValidateSet('SHA1','SHA256','SHA384','SHA512','MD5')]
    [string] $algorithm
  )
 
  $fileHash = Get-FileHash -Algorithm $algorithm -Path $fileName |
  ForEach-Object -Process {
    $_.Hash
  } |
  Out-String
  Write-Output -InputObject ('File = {0}' -f $fileName)
  Write-Output -InputObject ('Algorithm = {0}' -f $algorithm)
  Write-Output -InputObject ('Original hash = {0}' -f $originalhash)
  Write-Output -InputObject ('Current hash = {0}' -f $fileHash)
    
  $fileHash = $fileHash.Trim()
  If ($fileHash -eq $originalhash) 
  {
    Write-Host -Object 'Matches' -ForegroundColor Green
  }
  else 
  {
    Write-Host -Object "Doesn't match" -ForegroundColor Red
  }
}

