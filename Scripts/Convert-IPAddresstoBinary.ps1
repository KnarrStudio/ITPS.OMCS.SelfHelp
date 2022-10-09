function Convert-IPv4AddresstoBinary
{
  <#
      .SYNOPSIS
      Converts an IP v4 Address to a binary string 

      .DESCRIPTION
      IPv4 Addresses are 32 bit addresses written in four bytes (Octets) separated by dots like 192.168.2.1.
      This function converts each of those Octets to binary, then concatinates those into a 32 bit string without the dots. 
 
      .EXAMPLE
      Convert-IPAddresstoBinary -IPAddress 4.3.2.1
      
      Returns:
      00000100000000110000001000000001

      .INPUTS
      v4 IpAddress

      .OUTPUTS
      String
  #>

  param
  (
    [Parameter(Mandatory,HelpMessage = 'v4 IP Address as "192.168.10.25"')]
    [ipaddress]$IPAddress
  )
  $addressBytes = $IPAddress.GetAddressBytes()

  $addressBytes | ForEach-Object -Process {
    $binary = $binary + $([convert]::toString($_,2).padleft(8,'0'))
  }
  return $binary
}
