## ITPS.OMCS.SelfHelp
Self help for the normal user.  

## Scripts
**Test-TheInternet.ps1** - This came about after trying to walk people through the standard. **_IPCONFIG_** and **_PING_** the gateway.  Finds different information about the network, network card and network path.  Then "pings" those IP Addresses.  It provides an output on the console and the in a txt file shown below.
 
**Gathering the information on your NIC**  
DNSHostName            : Workstation Name          
IPAddress              : 192.168.1.247           
DefaultIPGateway       : 192.168.1.1             
DNSServerSearchOrder   : 192.168.1.3, 9.9.9.9    
DHCPEnabled            : 192.168.1.1             
IPSubnet               : 255.255.255.0           
Description of NIC     : Intel(R) Wireless-N  
MACAddress             : 00:0B:01:C1:56:77      
**Finding the Web facing IP Address** 
External IP            : 18.117.109.252            
**Testing Loopback connection:** 
127.0.0.1              : Passed                  
**Testing IPAddress:**  
192.168.1.247          : Passed                  
**Testing DefaultIPGateway:** 
192.168.1.1            : Passed                  
**Testing DNSServerSearchOrder:** 
_WARNING: Ping to 192.168.1.3 failed with status: DestinationHostUnreachable_  
192.168.1.3            : Failed                  
9.9.9.9                : Passed                  
**Testing DHCPServer:**
192.168.1.1            : Passed                  
**Testing ExternalIp:**  
18.117.109.252         : Passed                    
Find the report: C:\temp\Username-200721T070003.txt  
