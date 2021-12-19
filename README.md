## ITPS.OMCS.SelfHelp
Another Open Minded Common Sense (OMCS) Toolset.  These are meant to be for the normal user and run without admin credentials.   
Or **Self help for the normal user**. 

## Scripts
**Test-TheInternet.ps1** - This came about after trying to walk people through the standard troubleshooting steps of **_IPCONFIG_** and **_PINGing_** the gateway.  
**Convert-IPAddresstoBinary.ps1** - Although you can find online tools for this, it was fun.
**Move-Cursor.ps1** - Needed at some point and found online.  It is really here to build out this toolbox, but might not stay
**Test-AuthentationServer.ps1** - This is an overcomplicated version of ```$env:LOGONSERVER```. 

## Test-TheInternet
Gathers information about the network, network card and network path.  Then "pings" those IP Addresses.  I attempted to provide a little sense of order, so that it pings from the local machine outward. The script provides an output to the console and text file.
  
```
Gathering the information on your NIC
DNSHostName            : ComputerName
IPAddress              : 192.168.0.100
DefaultIPGateway       : 192.168.0.1
DNSServerSearchOrder   : 9.9.9.9, 192.168.0.3
DHCPEnabled            : 192.168.0.1
IPSubnet               : 255.255.255.0
Description of NIC     : Intel(R) Wireless-N  
MACAddress             : 54:E1:AD:B0:14:58
Finding the Web facing IP Address
External IP            : 18.168.220.50
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
192.168.0.3            : Passed
Testing DHCPServer:
192.168.0.1            : Passed
Testing ExternalIp:
18.168.220.50          : Passed               
Find the report: C:\temp\Username-200721T070003.txt  
```

