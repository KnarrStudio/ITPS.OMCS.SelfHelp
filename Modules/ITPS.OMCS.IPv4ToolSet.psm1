
function Add-IntToAddress
{
  <#
      .SYNOPSIS
      Add an integer to an IP Address and get the new IP Address.

      .DESCRIPTION
      Add an integer to an IP Address and get the new IP Address.

      .PARAMETER IPv4Address
      The IP Address to add an integer to.

      .PARAMETER Integer
      An integer to add to the IP Address. Can be a positive or negative number.

      .EXAMPLE
      Add-IntToIPv4Address -IPv4Address 10.10.0.252 -Integer 10

      10.10.1.6

      Description
      -----------
      This command will add 10 to the IP Address 10.10.0.1 and return the new IP Address.

      .EXAMPLE
      Add-IntToIPv4Address -IPv4Address 192.168.1.28 -Integer -100

      192.168.0.184

      Description
      -----------
      This command will subtract 100 from the IP Address 192.168.1.28 and return the new IP Address.
  #>
  param(
    [Parameter(Mandatory = $true)]
    [String]$IPv4Address
    ,
    [Parameter(Mandatory = $true)]
    [int64]$Integer
  )
  try
  {
    $ipInt = ConvertIPv4ToInt -IPv4Address $IPv4Address `
      -ErrorAction Stop
    $ipInt += $Integer

    return (ConvertIntToIPv4 -Integer $ipInt)
  }
  catch
  {
    Write-Error -Exception $_.Exception `
      -Category $_.CategoryInfo.Category
  }
}

function Convert-AddressToBinaryString
{
  <#
      .SYNOPSIS
      Converts an IPv4 Address to Binary String

      .PARAMETER IPAddress
      The IP Address to convert to a binary string representation

      .EXAMPLE
      Convert-IPv4AddressToBinaryString -IPAddress 10.130.1.52
  #>
  Param(
    [IPAddress]$IPAddress = '0.0.0.0'
  )
  $addressBytes = $IPAddress.GetAddressBytes()

  $strBuilder = New-Object -TypeName Text.StringBuilder
  foreach ($byte in $addressBytes)
  {
    $8bitString = [Convert]::ToString($byte, 2).PadLeft(8, '0')
    $null = $strBuilder.Append($8bitString)
  }
  return $strBuilder.ToString()
}

function Convert-CIDRToNetMask
{
  <#
      .SYNOPSIS
      Converts a CIDR to a netmask

      .EXAMPLE
      Convert-CIDRToNetMask -PrefixLength 26

      Returns: 255.255.255.192/26

      .NOTES
      To convert back use "Convert-NetMaskToCIDR"
  #>
  [CmdletBinding()]
  [Alias('ToMask')]
  param(
    [ValidateRange(0, 32)]
    [int16]$PrefixLength = 0
  )
  $bitString = ('1' * $PrefixLength).PadRight(32, '0')
  $strBuilder = New-Object -TypeName Text.StringBuilder

  for ($i = 0; $i -lt 32; $i += 8)
  {
    $8bitString = $bitString.Substring($i, 8)
    $null = $strBuilder.Append(('{0}.' -f [Convert]::ToInt32($8bitString, 2)))
  }

  return $strBuilder.ToString().TrimEnd('.')
}

function Convert-NetMaskToCIDR
{
  <#
      .SYNOPSIS
      Converts a netmask to a CIDR

      .EXAMPLE
      Convert-NetMaskToCIDR -SubnetMask 255.255.255.192

      Returns: 26

      .NOTES
      To convert back use "Convert-CIDRToNetMask"
  #>
  [CmdletBinding()]
  [Alias('ToCIDR')]
  param(
    [String]$SubnetMask = '255.255.255.0'
  )
  $byteRegex = '^(0|128|192|224|240|248|252|254|255)$'
  $invalidMaskMsg = ('Invalid SubnetMask specified [{0}]' -f $SubnetMask)
  try
  {
    $netMaskIP = [IPAddress]$SubnetMask
    $addressBytes = $netMaskIP.GetAddressBytes()

    $strBuilder = New-Object -TypeName Text.StringBuilder

    $lastByte = 255
    foreach ($byte in $addressBytes)
    {
      # Validate byte matches net mask value
      if ($byte -notmatch $byteRegex)
      {
        Write-Error -Message $invalidMaskMsg `
          -Category InvalidArgument `
          -ErrorAction Stop
      }
      elseif ($lastByte -ne 255 -and $byte -gt 0)
      {
        Write-Error -Message $invalidMaskMsg `
          -Category InvalidArgument `
          -ErrorAction Stop
      }

      $null = $strBuilder.Append([Convert]::ToString($byte, 2))
      $lastByte = $byte
    }

    return ($strBuilder.ToString().TrimEnd('0')).Length
  }
  catch
  {
    Write-Error -Exception $_.Exception `
      -Category $_.CategoryInfo.Category
  }
}

function Get-SubnetFromHostCount
{
  <#
      .SYNOPSIS
      Returns the CIDR number for a host count that will support the number of hosts you entered.
  #>
  [Alias('Get-CidrFromHostCount')]
  param(
    [Parameter(
        Mandatory = $true,
        ValueFromPipeline = $true,
    HelpMessage = 'Integer between 1 - 4294967293')]
    [ValidateScript({
          if(($_ -gt 0) -and ($_ -lt 4294967294))
          {
            $true
          }
          Else
          {
            Throw 'Input file needs to be an integer between 1 - 4294967293'
          }
    })]
    [UInt32]$HostCount
  )
  begin
  {
    $MyInvocation.Line
    If ($MyInvocation.Line -match 'Get-CidrFromHostCount') 
    {
      Write-Warning -Message 'The "Get-CidrFromHostCount" is depreciated.  Use: Get-Ipv4SbubnetFromHostCount'
    }
  }
  process
  {
    #Calculate available host addresses
    $i = $maxHosts = 0
    do
    {
      $i++
      $maxHosts = ([math]::Pow(2, $i) - 2)
      $prefix = 32 - $i
    }
    until ($maxHosts -ge $HostCount)
    $Subnet = Convert-CIDRToNetMask -PrefixLength $prefix
    $Binary = Convert-IPv4AddressToBinaryString -IPAddress $Subnet
    $NetworkSize = [PSCustomObject]@{
      PrefixLength = $prefix
      Subnet       = $Subnet
      Binary       = $Binary
    }

    return $NetworkSize
  }
}

function Get-Subnet
{
  <#
      .SYNOPSIS
      Get information about an IPv4 subnet based on an IP Address and a subnet mask or prefix length

      .DESCRIPTION
      Get information about an IPv4 subnet based on an IP Address and a subnet mask or prefix length

      .PARAMETER IPAddress
      The IP Address to use for determining subnet information.

      .PARAMETER PrefixLength
      The prefix length of the subnet.

      .PARAMETER SubnetMask
      The subnet mask of the subnet.

      .EXAMPLE
      Get-IPv4Subnet -IPAddress 192.168.34.76 -SubnetMask 255.255.128.0

      CidrID       : 192.168.0.0/17
      NetworkID    : 192.168.0.0
      SubnetMask   : 255.255.128.0
      PrefixLength : 17
      HostCount    : 32766
      FirstHostIP  : 192.168.0.1
      LastHostIP   : 192.168.127.254
      Broadcast    : 192.168.127.255

      Description
      -----------
      This command will get the subnet information about the IPAddress 192.168.34.76, with the subnet mask of 255.255.128.0

      .EXAMPLE
      Get-IPv4Subnet -IPAddress 10.3.40.54 -PrefixLength 25

      CidrID       : 10.3.40.0/25
      NetworkID    : 10.3.40.0
      SubnetMask   : 255.255.255.128
      PrefixLength : 25
      HostCount    : 126
      FirstHostIP  : 10.3.40.1
      LastHostIP   : 10.3.40.126
      Broadcast    : 10.3.40.127

      Description
      -----------
      This command will get the subnet information about the IPAddress 10.3.40.54, with the subnet prefix length of 25.
      Prefix length specifies the number of bits in the IP address that are to be used as the subnet mask.

  #>
  [CmdletBinding(DefaultParameterSetName = 'PrefixLength')]
  param(
    [Parameter(
      Mandatory = $true,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true,
      ValueFromRemainingArguments = $false,
      HelpMessage = 'IP Address in the form of XXX.XXX.XXX.XXX',
      Position = 0
    )]
    [IPAddress]$IPAddress
    ,
    [Parameter(
      Position = 1,
      ParameterSetName = 'PrefixLength',
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true
    )]
    [Int16]$PrefixLength = 24
    ,
    [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'SubnetMask')]
    [IPAddress]$SubnetMask
    ,
    [Parameter(
      Mandatory = $true,
      Position = 1,
      ParameterSetName = 'Hosts',
      HelpMessage = 'Number of hosts in need of IP Addresses'
    )]
    [Int64]$HostCount
  )
  begin
  {
  }
  process
  {
    try
    {
      if ($PSCmdlet.ParameterSetName -eq 'SubnetMask')
      {
        $PrefixLength = Convert-NetMaskToCIDR -SubnetMask $SubnetMask `
          -ErrorAction Stop
      }
      else
      {
        $SubnetMask = Convert-CIDRToNetMask -PrefixLength $PrefixLength `
          -ErrorAction Stop
      }
      if ($PSCmdlet.ParameterSetName -eq 'Hosts')
      {
        $PrefixLength = (Get-CidrFromHostCount -HostCount $HostCount).PrefixLength
        $SubnetMask = Convert-CIDRToNetMask -PrefixLength $PrefixLength `
          -ErrorAction Stop
      }
      $maxHosts = [math]::Pow(2, (32 - $PrefixLength)) - 2

      $netMaskInt = ConvertIPv4ToInt -IPv4Address $SubnetMask
      $ipInt = ConvertIPv4ToInt -IPv4Address $IPAddress

      $networkID = ConvertIntToIPv4 -Integer ($netMaskInt -band $ipInt)

      $broadcast = Add-IntToIPv4Address -IPv4Address $networkID `
        -Integer ($maxHosts + 1)

      $firstIP = Add-IntToIPv4Address -IPv4Address $networkID -Integer 1
      $lastIP = Add-IntToIPv4Address -IPv4Address $broadcast -Integer (-1)

      if ($PrefixLength -eq 32)
      {
        $broadcast = $networkID
        $firstIP = $null
        $lastIP = $null
        $maxHosts = 0
      }

      $outputObject = New-Object -TypeName PSObject

      $memberParam = @{
        InputObject = $outputObject
        MemberType  = 'NoteProperty'
        Force       = $true
      }
      Add-Member @memberParam -Name CidrID -Value ('{0}/{1}' -f $networkID, $PrefixLength)
      Add-Member @memberParam -Name NetworkID -Value $networkID
      Add-Member @memberParam -Name SubnetMask -Value $SubnetMask
      Add-Member @memberParam -Name PrefixLength -Value $PrefixLength
      Add-Member @memberParam -Name HostCount -Value $maxHosts
      Add-Member @memberParam -Name FirstHostIP -Value $firstIP
      Add-Member @memberParam -Name LastHostIP -Value $lastIP
      Add-Member @memberParam -Name Broadcast -Value $broadcast

      Write-Output -InputObject $outputObject
    }
    catch
    {
      Write-Error -Exception $_.Exception `
        -Category $_.CategoryInfo.Category
    }
  }
  end
  {
  }
}

function Get-SubnetCheatSheet
{
  <#
      .SYNOPSIS
      Creates a little cheatsheet for subnets.

      .DESCRIPTION
      Creates and send a cheatsheet for subnets to the console or send it to a file such as a CSV for opening in a spreadsheet.
      The default is formated for the console.  

      .PARAMETER Raw
      Use this parameter to output an object for more manipulation

      .EXAMPLE
      Get-SubnetCheatSheet  

      .EXAMPLE
      Get-SubnetCheatSheet -Raw | Where-Object {($_.CIDR -gt 15) -and ($_.CIDR -lt 22)} | Select-Object CIDR,Netmask
      
      .EXAMPLE
      Get-SubnetCheatSheet -Raw | Export-Csv .\SubnetSheet.csv -NoTypeInformation
      Sends the data to a csv file

      .EXAMPLE
      Get-SubnetCheatSheet -Raw | Where-Object {$_.NetMask -like '255.255.*.0' }
      Selects only one class of subnets

      .Example
      Get-SubnetCheatSheet | Out-Printer -Name (Get-Printer | Out-GridView -PassThru).Name 
  #>
  [CmdletBinding()]
  [Alias('SubnetList','ListSubnets')]
  param(
    [Switch]$Raw
  )
  Begin{
    $OutputFormatting = '{0,4} | {1,13:#,#} | {2,13:#,#} | {3,-15}  '

    $CheatSheet = @()
  }
  Process{
    for($CIDR = 32;$CIDR -gt 0;$CIDR--)
    {
      $netmask = Convert-CIDRToNetMask -PrefixLength $CIDR
      $Addresses = [math]::Pow(2,32-$CIDR)
      $HostCount = (&{
          if($Addresses -le 2)
          {
            '0'
          }
          else
          {
            $Addresses -2
          }
      })
  
      $hash = [PsCustomObject]@{
        CIDR      = $CIDR
        NetMask   = $netmask
        HostCount = $HostCount
        Addresses = $Addresses
      }
      $CheatSheet += $hash
    }
  }
  End{
    if(-not $Raw)
    {
      $OutputFormatting  -f 'CIDR', 'Host Count', 'Addresses', 'NetMask'
      '='*55
      foreach($item in $CheatSheet)
      {
        $OutputFormatting -f $item.CIDR, $item.HostCount, $item.Addresses, $item.NetMask
      }
    }
    Else
    {
      $CheatSheet
    }
  }
}

function Ping-Range
{
  <#
      .SYNOPSIS
      Tests a range of Ip addresses.

      .DESCRIPTION
      A simple function to test a range of Ip addresses and returns the results to the screen. It returns an object, so you can sort and filter.

      .PARAMETER FirstAddress
      First address to test.

      .PARAMETER LastAddress
      Last address to test.

      .EXAMPLE
      Ping-IpRange -FirstAddress 192.168.0.20 -LastAddress 192.168.0.25 | sort available

      Address      Available
      -------      ---------
      192.168.0.22     False
      192.168.0.23     False
      192.168.0.25     False
      192.168.0.20      True
      192.168.0.21      True
      192.168.0.24      True
    
      .EXAMPLE
      Ping-IpRangeNew -FirstAddress 192.168.0.20 -LastAddress 192.168.0.50 | Where Available -EQ $true

      Address      Available
      -------      ---------
      192.168.0.20      True
      192.168.0.21      True
      192.168.0.24      True
      192.168.0.43      True


      .OUTPUTS
      Object to console
  #>
  [CmdletBinding()]
  [Alias("pingr","Ping-IpRange")]
  Param(
    [Parameter(Mandatory,HelpMessage = 'Ip Address to start from',Position = 0)]
    [ipaddress]$FirstAddress,
    [Parameter(Mandatory,HelpMessage = 'Ip Address to stop at',Position = 1)]
    [ipaddress]$LastAddress
  )

  $Startip = ConvertIPv4ToInt -IPv4Address $FirstAddress.IPAddressToString
  $endip = ConvertIPv4ToInt -IPv4Address $LastAddress.IPAddressToString
  $PingRange = @()
    
  Try
  {
    $ProgressCount = $endip - $Startip
    $j = 0
    for($i = $Startip;$i -le $endip;$i++)
    {
      $ip = ConvertIntToIPv4 -Integer $i
      $Response = [PSCustomObject]@{
        Address   = $ip
        Available = (Test-Connection -ComputerName $ip -Count 1 -Quiet -TimeToLive 20)
      }

      Write-Progress -Activity ('Ping {0}' -f $ip) -PercentComplete ($j / $ProgressCount*100)
      $j++

      $PingRange += $Response
    }
  }
  Catch
  {
    Write-Error -Exception $_.Exception -Category $_.CategoryInfo.Category
  }
  $PingRange
}

function Find-MTUSize 
{
  <#
      .SYNOPSIS
      Returns the MTU size on your network

      .DESCRIPTION
      This automates the manual ping test, guess, subtract, test, guess, test again

      .PARAMETER IpToPing
      IP Address to test against. An example is your gateway

      .EXAMPLE
      Get-MTU -IpToPing 192.168.0.1
      Will ping the ip and return the MTU size

      .NOTES
      The program adds 28 to the final number to account for 20 bytes for the IP header and 8 bytes for the ICMP Echo Request header

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Get-MTU

      .INPUTS
      IP Address as an ipaddress

      .OUTPUTS
      MTU as an Object
  #>


  param(
    [Parameter(Mandatory = $true,HelpMessage = 'IP Address to test against. An example is your gateway')]
    [ipaddress]$IpToPing
  )
  Begin{
    [int]$Script:UpperBoundPacketSize = 9000 #Jumbo Frame 
    $DecrementBy = @(100, 50, 1)
    $IpAddress = $IpToPing.ToString()
    function Test-Size
    {
      <#
          .SYNOPSIS
          Test size of MTU with Ping.exe
      #>

      param
      (
        [Parameter(Mandatory = $true)]
        [String]$IpAddress,

        [Parameter(Mandatory = $true)]
        [int]$UpperBoundPacketSize,

        [Parameter(Mandatory = $true)]
        [int]$DecrementBy
      )
      $PingOut = $null
      $SearchString = '*fragmented*'
      $Script:UpperBoundPacketSize  += $DecrementBy+100
      do 
      {
        $Script:UpperBoundPacketSize -= $DecrementBy
        Write-Verbose -Message ('Testing packet size {0}' -f $Script:UpperBoundPacketSize)
        $PingOut = & "$env:windir\system32\ping.exe" $IpAddress -n 1 -l $Script:UpperBoundPacketSize -f
      }
      while ($PingOut[2] -like $SearchString)
    }
  }
  Process{
    $DecrementBy | ForEach-Object -Process {
      Test-Size -IpAddress $IpAddress -UpperBoundPacketSize $Script:UpperBoundPacketSize -DecrementBy $_
    }
  }
  End{
    $MTU = [int]$Script:UpperBoundPacketSize + 28 # Add 28 to this number to account for 20 bytes for the IP header and 8 bytes for the ICMP Echo Request header
    Remove-Variable -Name UpperBoundPacketSize -Scope Script # This just cleans up the variable since it was in the Global scope
    
    New-Object -TypeName PSObject -Property @{
      MTU = $MTU
  }}
}

function Test-TheInternet
{
  <#PSScriptInfo

      .VERSION 3.1.2

      .GUID ace3cc09-e726-4f25-9617-ea3d1f52aaba

      .AUTHOR Erik

      .COMPANYNAME KnarrStudio

      .COPYRIGHT 2021 KnarrStudio

      .TAGS 

      .LICENSEURI 

      .PROJECTURI https://github.com/KnarrStudio/ITPS.OMCS.SelfHelp/blob/master/README.md

      .ICONURI 

      .EXTERNALMODULEDEPENDENCIES 

      .REQUIREDSCRIPTS 

      .EXTERNALSCRIPTDEPENDENCIES 

      .RELEASENOTES
      Provides an output on the console and the in a txt file:
      DNSHostName
      IPAddress
      DefaultIPGateway
      DNSServerSearchOrder
      DHCPEnabled
      IPSubnet
      Description of NIC
      MACAddress

  #>

  <#
      .SYNOPSIS
      Tests or "pings" the key points of your internet connection
      .DESCRIPTION
      This came about after trying to walk people through the standard. IPCONFIG and PING the gateway. The script finds different information about the network, network card and network path. Then "pings" those IP Addresses. It provides an output on the console and the in a txt file shown below.
      .EXAMPLE
      Test-TheInternet

      Output:
        Gathering the information on your NICs
        Displaying information on the active NIC
        DNSHostName            : Lenovo-Server
        IPAddress              : 192.168.0.100
        DefaultIPGateway       : 192.168.0.1
        DNSServerSearchOrder   : 9.9.9.9, 192.168.1.3
        DHCPEnabled            : 192.168.0.1
        IPSubnet               : 255.255.255.0
        Description of NIC     : Realtek PCIeController
        MACAddress             : 54:E1:AD:B0:0d:0d
        Finding the Web facing IP Address
        External IP            : 18.117.109.252
        Checking for an Authentication Server
        Authentication Server  : Not Available
        
                     : ---------- Testing ---------- :
        Testing Loopback connection:
        127.0.0.1              : Passed
        Testing IPAddress:
        192.168.0.100          : Passed
        Testing DefaultIPGateway:
        192.168.0.1            : Passed
        Testing DNSServerSearchOrder:
        9.9.9.9                : Passed
        Testing DNSServerSearchOrder: WARNING: Ping to 192.168.1.3 failed with status: DestinationHostUnreachable
        192.168.1.3            : Failed
        Testing DHCPServer:
        192.168.0.1            : Passed
        Testing ExternalIp:
        18.117.109.252          : Failed
        Find the report: C:\temp\Username-200721T070003.txt

      .LINK
      https://github.com/KnarrStudio/ITPS.OMCS.SelfHelp/blob/master/README.md

  #>

  param
  (
    [Parameter(Position = 0)]
    [string]$OutputPath = "$env:TEMP"
  )

  BEGIN{
    $NICinfoMsg = 'Not Available'
    $TextColorWarning = 'Yellow'
    
    $userName = $env:USERNAME
    $DateStamp = Get-Date -Format yyMMddTHHmmss
    $NetworkReportName = ('{0}-{1}.txt' -f $userName, $DateStamp)
    $NetworkReportFullName = ('{0}\{1}' -f $OutputPath, $NetworkReportName)
    $Null = New-Item -Path $NetworkReportFullName -ItemType File
    #$TempFile = New-TemporaryFile 
    $Delimeter = ':'
    $Formatting = '{0,-23}{1,-2}{2,-24}'
    $Script:NICinfo = [Ordered]@{
      DNSHostName          = $NICinfoMsg
      IPAddress            = $NICinfoMsg
      DefaultIPGateway     = $NICinfoMsg
      DNSServerSearchOrder = $NICinfoMsg
      DHCPServer           = $NICinfoMsg
      IPSubnet             = $NICinfoMsg
      Description          = $NICinfoMsg
      MACAddress           = $NICinfoMsg
      ExternalIp           = $NICinfoMsg
    }

    function Script:Get-PhysicalNICInformation
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

      [hashtable]$AdapterInfo = @{}
   
      Write-Verbose -Message "Create '`$NICinfo' hashtable" 
  
      $PhysicalAdapters = Get-NetAdapter -Physical | Select-Object -Property *
      Write-Verbose -Message 'Get physical NICs'
  
      foreach($PhysAdptr in $PhysicalAdapters)
      {
        $AdptrName = $PhysAdptr.Name
        Write-Verbose -Message ('NIC name: {0}' -f $AdptrName)
    
        $AdapterInfo.$AdptrName = @{}
        Write-Verbose -Message ("Create '`$NICInfo.{0}' hash table" -f $AdptrName)
    
        $AdapterInfo.$AdptrName.Name = $AdptrName
        $AdapterInfo.$AdptrName.AdminStatus = $PhysAdptr.AdminStatus
        $AdapterInfo.$AdptrName.LinkSpeed = $PhysAdptr.LinkSpeed
        $AdapterInfo.$AdptrName.InterfaceDescription = $PhysAdptr.InterfaceDescription
        $AdapterInfo.$AdptrName.MediaConnectionState = $PhysAdptr.MediaConnectionState 

        if($PhysAdptr.AdminStatus -eq 'Up')
        {
          try
          {
            $AdapterInfo.$AdptrName.Statistics = (Get-NetAdapterStatistics -Name $AdptrName)
          }
          catch
          {
            $AdapterInfo.$AdptrName.Statistics = 'N/A'
          }
        }

        Write-Verbose -Message ('NIC Name: {0}' -f $AdptrName)
        $ifindex = (Get-NetAdapter -Name $AdptrName).ifIndex
        Write-Verbose -Message ('Interface Index: {0}' -f $ifindex)
        $AdapterInfo.$AdptrName.Config = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration |
        Where-Object -Property interfaceindex -EQ -Value $ifindex |
        Select-Object -Property *
      }
  
      <#  foreach($NicName in $PhysicalAdapters.Name)
          {
          Write-Verbose -Message ('NIC Name: {0}' -f $NicName) -Verbose
          $ifindex = (Get-NetAdapter -Name $NicName).ifIndex
          Write-Verbose -Message ('Interface Index: {0}' -f $ifindex) -Verbose
          $NICinfo.$NicName.Config = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration |
          Where-Object -Property interfaceindex -EQ -Value $ifindex |
          Select-Object -Property *

      }#>


      Return $AdapterInfo
    } #End: Get-PhysicalNICInformation

    function Script:Select-NetworkAdapter
    {
      <#
          .SYNOPSIS
          Selects the main NIC to test against.
      #>

      param
      (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
        Position = 0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('InputData')]
        [Object]$NICinfo
      )
  

      $Script:NicState = @{}
      $NicState.ActiveNicName = @()
      $NicState.DisabledNicName = @()
  
    
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
              $NicState.ActiveNicName += $NICinfo.$key.Name
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
            $NicState.DisabledNicName += $NICinfo.$key.Name
        
            if($NicState.DisabledNicName.count -eq $NICinfo.$key.Count)
            {
              Write-Output -InputObject 'All Network devices are Disabled.  In the network settings right Click on the NIC and select Enable.'
              #$DisabledNicName
            }
          }

        } # End Switch
      } # End Foreach key
      Return $NicState
    } #End: Select-NetworkAdapter

    function Script:Test-NetworkConnection
    {
      <#
          .SYNOPSIS
          Ping function for use inside the script ping test
        
          .DESCRIPTION
          Uses Test-Netconnect to test an IP address while presenting the name 
        
          .PARAMETER TestName
          Name of the test that you want to present while testing.  Most often user friendly name.  i.e. Gateway, or DHCP server
        
          .PARAMETER TargetNameIp
          IP Address of the system that needs to be tested.
        
          .EXAMPLE
          Test-NetworkConnection -TestName 'My Gateway' -TargetNameIp 192.168.0.1 -NetworkReportFullName test.txt
          This will ping the 192.168.0.1 address and lable it 'My Gateway' and send the results to the file test.txt
        
      #>
      
      param
      (
        [Parameter(Position = 0)]
        [string]$TestName = 'Loopback connection',
        [Parameter(Position = 1)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$TargetNameIp = '127.0.0.1',
        [Parameter(Mandatory = $false)]
        [Alias('NetworkReportFullName')]
        [String]$OutputFile
      )
      $Delimeter = ':'
      $Formatting = '{0,-23}{1,-2}{2,-24}'

      Write-Verbose -Message $([String]$TargetNameIp)
      Write-Host -Object ('Testing {0}:' -f $TestName) -ForegroundColor Yellow
      Add-Content -Value ('Testing {0}:' -f $TestName) -Path $OutputFile
    
      ForEach($Target in $TargetNameIp) 
      { 
        try
        {
          Write-Verbose -Message ([IpAddress]$Target).IPAddressToString -ErrorAction Stop
          $PingSucceeded = (Test-NetConnection -ComputerName $Target).PingSucceeded
          if($PingSucceeded -eq $true)
          {
            $TestResults = 'Passed'
          }
          elseif($PingSucceeded -eq $false)
          {
            $TestResults = 'Failed'
          }
        }
        Catch
        {
          if(($Target -eq $Null) -or ($Target -eq ''))
          {
            $TestResults = 'Null or Blank IPAddress'
          }
          else
          {
            $TestResults = 'Invalid IPAddress'
          }
          Write-Verbose -Message ($Formatting -f $Target, $Delimeter, $TestResults) 
        }
        if($OutputFile)
        {
          Write-Info -Title $Target -Value $TestResults -FilePath $OutputFile
          #Tee-Object -InputObject ($Formatting -f $Target, $Delimeter, $TestResults) -FilePath $OutputFile -Append
        }
        else
        {
          Write-Output -InputObject ($Formatting -f $Target, $Delimeter, $TestResults)
        }
      }
    } #End: Test-NetworkConnection
    
    function Script:Get-WebFacingIPAddress
    {
  <#
      .SYNOPSIS
      Returns the public facing IP address.
        
      .DESCRIPTION
      Uses invoke-WebRequest and Invoke-RestMethod to return your web facing IP Address from one of the following sites:
      'http://checkip.dyndns.org/'
      'https://api.ipify.org'
     
      .EXAMPLE
      Get-WebFacingIPAddress

      Returns the $ExternalIp variable

      .NOTES
      Removed the parameters and added the websites directly to the code, because the simple call didn't work for every website.
 
  #>
  [CmdletBinding()]
  Param()
  $ExtIpCatchMsg = 'Not Available'
  $ErrorActionPreference = "Stop"
try
  {
    $HtmlData = (Invoke-RestMethod -Uri 'http://checkip.dyndns.org/').html.body
    $ExternalIp = [string]$HtmlData.Split(':')[1].trim()
  }
  catch
  {
    $ExternalIp = $ExtIpCatchMsg
  }
  if($ExternalIp -eq $ExtIpCatchMsg)
  {
    try
    {
      $HtmlData = (Invoke-WebRequest -Uri 'https://api.ipify.org?format=json').Content
      $ExternalIp = [String]($HtmlData | ConvertFrom-Json).IP
    }
    Catch
    {
      $ExternalIp = $ExtIpCatchMsg
    }
  }
  Write-Verbose -Message ('This is the IP address you are presenting to the internet')
    
  [String]$ExternalIp
  } #End: Get-WebFacingIPAddress

    function Script:Write-Info 
    {
      <#
          .SYNOPSIS
          Output function

          .INPUTS
          Filename, title of data and data

          .OUTPUTS
          Formatted input information to the screen and file
      #>

      [CmdletBinding()]
      param(
        [Parameter(Mandatory=$true)][string]$Title,
        [Parameter(Mandatory=$true)][Object]$Value,
        [Parameter(Mandatory=$true)][String]$FilePath
      )

      $Delimeter = ':'
      $Formatting = '{0,-23}{1,-2}{2,-24}'
    
      Tee-Object -InputObject ($Formatting -f $Title, $Delimeter, $Value) -FilePath $FilePath  -Append
    } #End: Write-Info 

  }

  PROCESS{
    Write-Host -Object ('Gathering the information on your NICs') -ForegroundColor $TextColorWarning
    
    $PhysicalNICs = Get-PhysicalNICInformation
    $ActiveNicName = [String](Select-NetworkAdapter -InputData $PhysicalNICs ).ActiveNicName
    
    if($PhysicalNICs.$ActiveNicName.Config.DNSHostName)
    {
      $NICinfo.DNSHostName          = $PhysicalNICs.$ActiveNicName.Config.DNSHostName
    }
    if($PhysicalNICs.$ActiveNicName.Config.IPAddress[0])
    {
      $NICinfo.IPAddress            = $PhysicalNICs.$ActiveNicName.Config.IPAddress[0]
    }
    if($PhysicalNICs.$ActiveNicName.Config.DefaultIPGateway)
    {
      $NICinfo.DefaultIPGateway     = $PhysicalNICs.$ActiveNicName.Config.DefaultIPGateway[0]
    }
    if($PhysicalNICs.$ActiveNicName.Config.DNSServerSearchOrder)
    {
      $NICinfo.DNSServerSearchOrder = $PhysicalNICs.$ActiveNicName.Config.DNSServerSearchOrder
    }
    if($PhysicalNICs.$ActiveNicName.Config.IPSubnet[0])
    {
      $NICinfo.IPSubnet             = $PhysicalNICs.$ActiveNicName.Config.IPSubnet[0]
    }
    if($PhysicalNICs.$ActiveNicName.Config.Description)
    {
      $NICinfo.Description          = $PhysicalNICs.$ActiveNicName.Config.Description
    }
    if($PhysicalNICs.$ActiveNicName.Config.MACAddress)
    {
      $NICinfo.MACAddress           = $PhysicalNICs.$ActiveNicName.Config.MACAddress
    }
    if($PhysicalNICs.$ActiveNicName.Config.DHCPEnabled) 
    {
      $NICinfo.DHCPServer         = $PhysicalNICs.$ActiveNicName.Config.DHCPServer
    }
    Else
    {
      $NICinfo.DHCPServer         = 'False'
    }


    Write-Host -Object ('Displaying information on the active NIC') -ForegroundColor $TextColorWarning
    Write-Info -Title 'DNSHostName' -Value $NICinfo.DNSHostName -FilePath $NetworkReportFullName
    Write-Info -Title 'IPAddress' -Value $NICinfo.IPAddress -FilePath $NetworkReportFullName 
    Write-Info -Title 'DefaultIPGateway' -Value $NICinfo.DefaultIPGateway -FilePath $NetworkReportFullName 
    Write-Info -Title 'DNSServerSearchOrder' -Value $(([string]$NICinfo.DNSServerSearchOrder).Replace(' ', ', ')) -FilePath $NetworkReportFullName 
    Write-Info -Title 'DHCPEnabled' -Value $NICinfo.DHCPServer -FilePath $NetworkReportFullName 
    Write-Info -Title 'IPSubnet' -Value $NICinfo.IPSubnet -FilePath $NetworkReportFullName
    Write-Info -Title 'Description of NIC' -Value $NICinfo.Description -FilePath $NetworkReportFullName 
    Write-Info -Title 'MACAddress' -Value $NICinfo.MACAddress -FilePath $NetworkReportFullName 
    
    Write-Host -Object ('Finding the Web facing IP Address') -ForegroundColor $TextColorWarning
    $NICinfo.ExternalIp = Get-WebFacingIPAddress
    Write-Info -Title 'External IP' -Value $NICinfo.ExternalIp -FilePath $NetworkReportFullName

    Write-Host -Object ('Checking for an Authentication Server') -ForegroundColor $TextColorWarning
    try
    {
      # Check if computer is connected to domain network
      [void]::([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain())
      Write-Info -Title 'Authentication Server' -Value $env:LOGONSERVER -FilePath $NetworkReportFullName
    }
    catch
    {
      #Write-Output -InputObject ($Formatting -f 'Authentication Server', $Delimeter, 'Not Available')
      Write-Info -Title 'Authentication Server'-Value $NICinfoMsg -FilePath $NetworkReportFullName
    }


    Write-Info -Title "`n`n" -value '---------- Testing ---------- :' -FilePath $NetworkReportFullName

    Test-NetworkConnection -NetworkReportFullName $NetworkReportFullName
    Test-NetworkConnection -TestName 'IPAddress' -TargetNameIp $NICinfo['IPAddress'] -NetworkReportFullName $NetworkReportFullName 
    Test-NetworkConnection -TestName 'DefaultIPGateway' -TargetNameIp $NICinfo['DefaultIPGateway'] -NetworkReportFullName $NetworkReportFullName 
    Test-NetworkConnection -TestName 'DNSServerSearchOrder' -TargetNameIp $($NICinfo.DNSServerSearchOrder) -NetworkReportFullName $NetworkReportFullName 
    if($NICinfo.DHCPServer -ne 'False')
    {
      Test-NetworkConnection -TestName 'DHCPServer' -TargetNameIp $NICinfo.DHCPServer -NetworkReportFullName $NetworkReportFullName
    }
    Test-NetworkConnection -TestName 'ExternalIp' -TargetNameIp $NICinfo['ExternalIp'] -NetworkReportFullName $NetworkReportFullName 
  }

  END{
    #$NICinfo | Out-File -FilePath $NetworkReportFullName -Append
    #Get-Content -Path $NetworkReportFullName
    Write-Output -InputObject ('Find the report: {0}' -f $NetworkReportFullName)
    ('Find this report: {0}' -f $NetworkReportFullName) |  Out-File -FilePath $NetworkReportFullName -Append
    Start-Process -FilePath notepad -ArgumentList $NetworkReportFullName
  } 
} #End: function Test-TheInternet

# Non-Published Functions referenced by other modules

function ConvertIPv4ToInt
{
  [CmdletBinding()]
  param(
    [String]$IPv4Address
  )
  try
  {
    $ipAddress = [IPAddress]::Parse($IPv4Address)

    $bytes = $IPAddress.GetAddressBytes()
    [Array]::Reverse($bytes)

    return [BitConverter]::ToUInt32($bytes, 0)
  }
  catch
  {
    Write-Error -Exception $_.Exception `
      -Category $_.CategoryInfo.Category
  }
}

function ConvertIntToIPv4
{
  [CmdletBinding()]
  param(
    [uint32]$Integer
  )
  try
  {
    $bytes = [BitConverter]::GetBytes($Integer)
    [Array]::Reverse($bytes)
    ([IPAddress]($bytes)).ToString()
  }
  catch
  {
    Write-Error -Exception $_.Exception `
      -Category $_.CategoryInfo.Category
  }
}



$AliasSplat = @{
  Alias = ('pingr', 'Ping-IpRange', 'SubnetList', 'ListSubnets', 'ToCIDR', 'ToMask', 'Get-CIDRFromHostCount')
}

$FunctionSplat = @{
  Function = ('Add-IntToAddress', 'Convert-CIDRToNetMask', 'Convert-AddressToBinaryString', 
    'Convert-NetMaskToCIDR', 'Get-SubnetFromHostCount', 'Get-Subnet', 'Ping-Range', 
  'Get-SubnetCheatSheet', 'Find-MtuSize', 'Test-TheInternet')
}


Export-ModuleMember @AliasSplat @FunctionSplat

# (Get-Module ITPS.OMCS.IPv4ToolSet).ExportedFunctions
# Import-Module .\ITPS.OMCS.IPv4ToolSet.psm1 -Prefix IPv4
