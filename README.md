### Management RDP or RPC or SMB/CIFS port or Check TCP/UDP port state of connection using batch script.
________________________________________________________________________________________________________________________________

### 介紹:
**1.** 更換RDP遠端連接埠。</br>
**2.** 關閉或開啟RPC 連接埠。</br>
**3.** 關閉或開啟NetBios。</br>
**4.** 關閉或開啟SMB/CIFS 連接埠 137、138(UDP)和139、445(TCP)。</br>
**5.** 關閉或開啟SMBv1、SMBv2、SMBv3。</br>
**6.** 檢查任一TCP/UDP連接埠狀態。
</br>

### Introduction:
**1.** Change RDP port.</br>
**2.** Close or Open RPC port.</br>
**3.** Close or Open NetBios.</br>
**3.** Close or Open SMB/CIFS port 137、138(UDP) and 139、445(TCP).</br>
**4.** Close or Open SMBv1、SMBv2、SMBv3.</br>
**5.** Check specifying TCP/UDP port ststus.
</br>
</br>

## 免責聲明(DISCLAIMER)
- ***本產品處於實驗狀態，對於任何因使用本產品而導致或涉及的產品損失、損害或損害之故，概不承擔法律責任及賠償義務。***
- ***This product is in experimental condition, and no liability or compensation will be accepted for any loss, damage or injury to the product caused by or related to the use of this product.***

</br>
________________________________________________________________________________________________________________________________

### What is NetBIOS(Network Ba​​sic Input/Output System):
```
It provides services related to the session layer of the OSI model allowing
applications on separate computers to communicate over a local area network.
As strictly an API, NetBIOS is not a networking protocol.
NetBIOS normally runs over TCP/IP via the NetBIOS over TCP/IP (NBT) protocol.
```
>[Reference article](https://superuser.com/questions/694469/difference-between-netbios-and-smb)</br>
>[Wiki](https://en.wikipedia.org/wiki/NetBIOS)

### What is SMB(Server Message Block):
```
SMB is a communication protocol used for sharing access to files, printers,
serial ports and other resources on a network,operates at the application layer,
but relies on lower network levels for transport and 
was originally designed to run on top of NetBIOS over TCP/IP (NBT)
using TCP port 139 and UDP ports 137 and 138,designed by Barry Feigenbaum at IBM in 1983.
Since Windows 2000,SMB runs directly over TCP/IP and uses port 445.
```
> [Reference article](https://www.techtarget.com/searchnetworking/definition/Server-Message-Block-Protocol)

### What is CIFS(Common Internet File System):
```
CIFS is an early dialect of the SMB(1.0) protocol and added more features,support direct connections over TCP port 445
without requiring NetBIOS as a transport(a largely experimental effort that required further refinement),
created by Microsoft in 1996.
CIFS was considered as a "chatty protocol" that was a huge bug and had network issues.
Microsoft has since given up on CIFS but has made SMB specifications publicly available.
CIFS is now considered obsolete, because most modern storage systems use SMBv2 or SMBv3.
```
> [Reference article](https://blog.fosketts.net/2012/02/16/cifs-smb/)

### CIFS vs SMB(v1) ?
```
The CIFS/SMBv1 is rarely used these days,most modern storage systems use SMBv2 or SMBv3.
```
> [Reference article](https://www.varonis.com/blog/cifs-vs-smb)

### SMB1.0 (1984):
```
SMB1.0 is a deprecated and insecure protocol,Microsoft has marked SMB1 as deprecated in June 2013.
Early the protocol were exploited during the WannaCry ransomware attack through a zero-day exploit called EternalBlue.
SMB1.0 has significant security vulnerabilities and strongly encourage you not to use it.
```
> [Reference article](https://techcommunity.microsoft.com/t5/storage-at-microsoft/stop-using-smb1/ba-p/425858)

### SMB2.0 (2006):
```
Microsoft introduced SMB2.0 protocol in 2006 with Windows Vista and Windows Server 2008.
SMB2.0 reduced chattiness to improve performance, enhanced scalability and resiliency, 
and added support for wide area network (WAN) acceleration.
```
> [Reference article](https://en.wikipedia.org/wiki/Server_Message_Block#SMB_2.0)

### SMB2.1 (2010):
```
SMB 2.1 was introduced with Windows Server 2008 R2 and Windows 7.
SMB 2.1 introduced minor performance enhancements with a new opportunistic locking mechanism.
```

### SMB3.0 (2012):
```
SMB3.0 is part of Windows 8 and Windows Server 2012.
SMB3.0 added several significant upgrades to improve availability, 
performance, backup, security and management.
SMB3.0 introduces several security enhancements, 
such as end-to-end encryption and a new AES based signing algorithm and
transparent failover mechanism and other functional.
```
> [Reference article 1](https://www.mosmb.com/why-smb-3-0/)</br>
> [Reference article 2](https://docs.microsoft.com/en-us/troubleshoot/windows-server/high-availability/smb-3-file-server-features)</br>
> [Reference article 3](https://docs.microsoft.com/en-us/windows-server/storage/file-server/file-server-smb-overview#features-added-in-smb-30-with-windows-server-2012-and-windows-8)

### SMB3.0.2 (2014):
```
SMB3.0.2 was introduced in Windows 8.1 and Windows Server 2012 R2.
SMB3.0.2 can be optionally disabled SMB1.0 to increase security.
```
> [Reference article 1](https://techgenix.com/improvements-smb-30-and-302-protocol-updates/)</br>
> [Reference article 2](https://docs.microsoft.com/en-us/windows-server/storage/file-server/file-server-smb-overview#features-added-in-smb-302-with-windows-server-2012-r2-and-windows-81)

### SMB3.1.1 (2015):
```
SMB 3.1.1 was introduced with Windows 10 and Windows Server 2016.
SMB 3.1.1 added pre-authentication integrity check using SHA-512 hash to 
prevent man-in-the-middle (MitM) attacks and contained various encryption improvements,
including AES-128-CCM or AES-128-GCM(new) and cluster dialect fencing, among other updates.
```
> [Reference article 1](https://www.vembu.com/blog/windows-server-2016-smb-3-1-1-features-hyper-v-enhancements/)</br>
> [Reference article 2](https://docs.microsoft.com/en-us/archive/blogs/openspecification/smb-3-1-1-pre-authentication-integrity-in-windows-10)</br>
> [Reference article 3](https://docs.microsoft.com/en-us/windows-server/storage/file-server/file-server-smb-overview#features-added-in-smb-311-with-windows-server-2016-and-windows-10-version-1607)</br>
> [AES-CCM vs AES-GCM](https://crypto.stackexchange.com/questions/6842/how-to-choose-between-aes-ccm-and-aes-gcm-for-storage-volume-encryption)

### SMB1.0 vs SMB2.0 vs SMB3.0:
> [Reference article](https://visualitynq.com/resources/articles/what-is-smb-what-it-decision-makers-need-to-know/)

### Other file sharing protocol:
- **Samba**
- **NFS**
- **SSHFS**
- **AFP**
- **iSCSI**
- **More...**

### What is 137,138,139,445 port:
```
137(UDP): Netbios-ns NETBIOS Name Service(NBNS)(WINS).
138(UDP): Netbios-dgm NETBIOS Datagram Service.
139(TCP): Netbios-ssn NETBIOS Session Service.
445(TCP): Microsoft-DS,modern SMB (especially v2/v3) runs only on TCP port 445.
```
> [Reference article](https://4sysops.com/archives/smb-port-number-ports-445-139-138-and-137-explained/)</br>
> [137 vs 138](https://superuser.com/questions/637696/what-is-netbios-does-windows-need-its-ports-137-and-138-open)</br>
> [TCP 445](https://superuser.com/questions/1587386/is-port-445-enough-for-smb)
</br>

### The ports used by various Windows services:
> [Reference article](https://docs.microsoft.com/en-us/troubleshoot/windows-server/networking/service-overview-and-network-port-requirements#ports-and-protocols)
________________________________________________________________________________________________________________________________

**Change RDP(Remote Desktop Services) Port**
> [Reference](https://docs.microsoft.com/zh-tw/windows-server/remote/remote-desktop-services/clients/change-listening-port)

</br>

**Close RPC(Remote Procedure Call):**
```
1. HKEY_LOCAL_MACHINE\Software\Microsoft\OLE > EnableDCOM -> Set N (Disabled DCOM)
2. HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RPC > DCOM Protocols -> Clear value "ncacn_ip_tcp"
3. HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\RpcEptMapper > Start -> Set value "4"(Disabled-4,Manual-3,Automatic-2)
4. HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\RpcSs > Start -> Set value "4"(Disabled-4,Manual-3,Automatic-2)
5. 
```
> [Disable RPC](http://www.keyfocus.net/kfsensor/help/AdminGuide/adm_RPC.php)</br>
> [How RPC Works](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2003/cc738291(v=ws.10)?redirectedfrom=MSDN#network-ports-used-by-rpc)</br>
> [Mitigating RPC and DCOM Vulnerabilities](https://docs.microsoft.com/en-us/previous-versions/tn-archive/dd632946(v=technet.10)?redirectedfrom=MSDN)</br>
> [If the RPC service is disabled](https://docs.microsoft.com/en-us/troubleshoot/windows-client/performance/disable-rpc-service-windows-process-not-work)</br>
> [If the DCOM is disabled](https://support.microsoft.com/en-us/topic/how-to-disable-dcom-support-in-windows-2bb8c280-9698-7f9c-bf67-2625a5873c7b)</br>
>> **Disabling RPC is not at all recommended,because many windows operating system procedures depend on the RPC service.**

</br>

**Close NetBios:**
> [Disable netbios(Disable NetBIOS over TCP/IP)](https://github.com/hvs-consulting/disable-netbios/blob/main/disable_netbios.ps1)

</br>

**Close [UDP]137、138 Port:**
```
1. 創建防火牆阻擋入站Port 137、138規則。
```

</br>

**Close [TCP]139 Port:**
```
1. 將註冊表HKLM:\SYSTEM\CurrentControlSet\Control\Lsa當中的restrictanonymous值改成2。
2. 關閉lmhosts服務，並設置成停用狀態。
3. 關閉netbios服務，並設置成停用狀態。
4. 將註冊表HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters當中的AutoShareServer值改成0。
5. 將註冊表HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters當中的AutoShareWks值改成0。
6. 創建防火牆阻擋入站Port 139規則。
```

</br>

**Close [TCP]445 Port:**
```
1. 將註冊表HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters當中的SMBDeviceEnabled值改成0。
2. 將註冊表HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters當中的TransportBindName值清空。
3. 關閉lanmanserver服務，並設置成停用狀態。
4. 創建防火牆阻擋入站Port 445規則。
```

</br>

**CLOSE SMBv1、SMBv2、SMBv3:**
> [Reference](https://docs.microsoft.com/en-us/windows-server/storage/file-server/troubleshoot/detect-enable-and-disable-smbv1-v2-v3)