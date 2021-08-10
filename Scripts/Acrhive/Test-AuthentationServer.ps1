#requires -Version 1.0

function Test-AuthentationServer
{
  <#
      .SYNOPSIS
      Checks to see if the local machine is part of a domain

      .DESCRIPTION
      Add a more complete description of what the function does.

      .EXAMPLE
      Test-AuthentationServer
      Looks for an Domain controller and displays it

  #>


  try
  {
    # Check if computer is connected to domain network
    [void]::([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain())
    Write-Output -InputObject ('Authentication Server: {0}' -f $env:LOGONSERVER)
  }
  catch
  {
    Write-Output -InputObject ('Authentication Server: Not Available') 
    Write-Output -InputObject ('Local Workstation: {0}' -f $env:COMPUTERNAME)
  }
}
Test-AuthentationServer