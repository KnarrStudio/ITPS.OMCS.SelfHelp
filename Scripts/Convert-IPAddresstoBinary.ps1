﻿param
  (
    [Parameter(Mandatory,HelpMessage='v4 IP Address as "192.168.10.25"')]
    [String]$dottedDecimal
  )
$dottedDecimal.split('.') | ForEach-Object{$binary=$binary + $([convert]::toString($_,2).padleft(8,'0'))}
return $binary
