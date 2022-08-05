set "params=%*" && cd /d "%CD%" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/C cd ""%CD%"" && %~s0 %params%", "", "runas", 1 >>"%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )
@ECHO OFF
TITLE Close [TCP_139、445]、[UDP_137、138](Administrator)

GOTO MAIN

:MAIN
CLS
ECHO.
ECHO ==============================================================
ECHO 			    Choose Function
ECHO ==============================================================
ECHO.
ECHO --------------------------------------------------------------
ECHO [1] Management RDP(Remote Desktop Services) Services
ECHO [2] Management RPC(Remote Procedure Call) Services
ECHO [3] Management NetBios(NetBIOS over TCP/IP) Services
ECHO [4] Management SMB(Server Message Block)[NetBios] UDP 137、138 Port
ECHO [5] Management SMB(Server Message Block) TCP 139[NetBios]、445 Port
ECHO [6] Management SMBv1、SMBv2、SMBv3
ECHO [7] Check TCP/UDP Port State
ECHO --------------------------------------------------------------
ECHO.
CHOICE /C 7654321 /N /M "Choose Function[1~7]: "
IF ERRORLEVEL 7 (
	GOTO RDP_Service_Ask
)ELSE IF ERRORLEVEL 6 (
	GOTO RPC_Info
)ELSE IF ERRORLEVEL 5 (
	GOTO NetBIOS_Service_Info
)ELSE IF ERRORLEVEL 4 (
	GOTO SMB_UDP_Ask
)ELSE IF ERRORLEVEL 3 (
	GOTO SMB_TCP_Ask
)ELSE IF ERRORLEVEL 2 (
	GOTO SMB_Service_Ask
)ELSE (
	GOTO Check_TCP_UDP
)


::REM =====================================================================================================================
::REM =========================================================RDP=========================================================
::REM =====================================================================================================================

:RDP_Service_Ask
CLS
ECHO.
ECHO =======================================================
ECHO.
CHOICE /C 4321 /N /M "[1]Change RDP port [2]Close RDP services [3]Open RDP services [4]Back Menu: "
IF ERRORLEVEL 4 (
	GOTO RDP_Info
)ELSE IF ERRORLEVEL 3 (
	GOTO Close-RDP_Service-REG-A
)ELSE IF ERRORLEVEL 2 (
	GOTO Open-RDP_Service-REG-A
)ELSE IF ERRORLEVEL 1 (
	GOTO MAIN
)

::REM ====================================Change_RDP_Port====================================

:RDP_Info
CLS
ECHO.
ECHO =======================================================
ECHO.
CALL :RDP_Port
ECHO.
CHOICE /C ENY /N /M "Do you Want to Change RDP Port?( [Y]Change [N]Back [E]Exit ): "
IF ERRORLEVEL 3 (
	GOTO Change-RDP_Port-Ask
)ELSE IF ERRORLEVEL 2 (
	GOTO RDP_Service_Ask
)ELSE IF ERRORLEVEL 1 (
	GOTO Exit
)

:Change-RDP_Port-Ask
CLS
ECHO.
ECHO =======================================================
ECHO.
CALL :RDP_Port
ECHO.
SET "RDP-Port="
SET /P RDP-Port="Please Input New Port(1001~254535)(Press Enter use Port 3389)[B/b:Back]: "
IF NOT DEFINED RDP-Port (
	SET RDP-Port=3389
)ELSE IF /I "%RDP-Port%" EQU "B" (
	GOTO RDP_Info
)
CALL :Check_Port_Scope %RDP-Port% REM Check port of inputs is correct
IF "%Scope%"=="False" (
	ECHO.
	PAUSE
	GOTO Change-RDP_Port-Ask
)
GOTO Change-RDP_Port

:Change-RDP_Port
ECHO --------------------------------------------
ECHO Change port...
ECHO.
Powershell -command Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "PortNumber" -Value %RDP-Port%
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Change fail! )ELSE (ECHO. && ECHO Change success! )
ECHO.
GOTO RDP_TCP

:RDP_TCP
ECHO --------------------------------------------
ECHO [1/2]Setting firewall rule[TCP]...
ECHO.
CALL :Check_Rule RDPPORTLatest-TCP-In
IF %ERRORLEVEL% NEQ 0 (
	ECHO. && ECHO Confirmed not create rule，Creating...  && ECHO.
)ELSE (
	ECHO. && ECHO Rule already exists, updating...
	Powershell -command Remove-NetFirewallRule -DisplayName "RDPPORTLatest-TCP-In"
	ECHO.
)
Powershell -command New-NetFirewallRule -DisplayName 'RDPPORTLatest-TCP-In' -Profile 'Public' -Direction Inbound -Action Allow -Protocol TCP -LocalPort %RDP-Port%
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Set fail! )ELSE (ECHO. && ECHO Set success! )
ECHO.

:RDP_UDP
ECHO --------------------------------------------
ECHO [2/2]Setting firewall rule[UDP]...
ECHO.
CALL :Check_Rule RDPPORTLatest-UDP-In
IF %ERRORLEVEL% NEQ 0 (
	ECHO. && ECHO Confirmed not create rule，Creating... && ECHO.
)ELSE (
	ECHO. && ECHO Rule already exists, updating... && ECHO.
	Powershell -command Remove-NetFirewallRule -DisplayName "RDPPORTLatest-UDP-In"
	ECHO.
)
Powershell -command New-NetFirewallRule -DisplayName 'RDPPORTLatest-UDP-In' -Profile 'Public' -Direction Inbound -Action Allow -Protocol UDP -LocalPort %RDP-Port%
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Set fail! )ELSE (ECHO. && ECHO Set success! )
ECHO.

:Show_RDP_Port
ECHO --------------------------------------------
Powershell -command 'RDP port:'+("Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "PortNumber" | Select-Object -ExpandProperty PortNumber")
ECHO.
PAUSE
GOTO RDP_Info

:Close-RDP_Service
ECHO --------------------------------------------
ECHO [1/2]Close RDP Services...
ECHO.
Sc stop Termservice
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO Service is Closed!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO Service is Closed!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO Close Service Success!
)ELSE (
	ECHO.
	ECHO Close Service Fail!
)
ECHO.
ECHO --------------------------------------------
ECHO [2/2]Disable RDP Services...
ECHO.
sc config Termservice start=disabled
IF %ERRORLEVEL% NEQ 0 (
	ECHO. && ECHO Can't disable RDP services!
)ELSE (
	ECHO. && ECHO Disable RDP Services successfully!
)
ECHO.
PAUSE
GOTO RDP_Service_Ask

:Open-RDP_Service
ECHO --------------------------------------------
ECHO [1/2]Enable RDP Services...
ECHO.
sc config Termservice start=demand
IF %ERRORLEVEL% NEQ 0 (
	ECHO. && ECHO Can't enable RDP services!
)ELSE (
	ECHO. && ECHO Enable RDP Services successfully!
)
ECHO.
ECHO --------------------------------------------
ECHO [2/2]Open RDP Services...
ECHO.
Sc start Termservice
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO Service is Opened!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO Service is Opened!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO Open Service Success!
)ELSE (
	ECHO.
	ECHO Open Service Fail!
)
ECHO.
PAUSE
GOTO RDP_Service_Ask


::REM =====================================================================================================================
::REM ========================================================RPC==========================================================
::REM =====================================================================================================================


:RPC_Info
CLS
ECHO.
ECHO =======================================================
ECHO.
ECHO ---------------------------------------
ECHO Current RPC(135) Port State:
ECHO.
ECHO  Proto   Local address        Foreign address            State          PID
CALL :Check_Port 135
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO No Connection!)
ECHO.
GOTO RPC_Ask

:RPC_Ask
ECHO.
CHOICE /C 321 /N /M "[1]Create block inbound firewall rule for RPC(135) [2]Clear rule [3]Back Menu: "
IF ERRORLEVEL 3 (
	CALL :RPC_Close
)ELSE IF ERRORLEVEL 2 (
	CALL :RPC_Open
)ELSE IF ERRORLEVEL 1 (
	GOTO MAIN
)
ECHO.
PAUSE
GOTO RPC_Info

:RPC_Close
CALL :Check_Rule Block_RPC-TCP-135-In
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Confirmed not create rule，Creating... && ECHO.)ELSE (ECHO. && ECHO Rule is exist! && ECHO. && PAUSE && GOTO RPC_Info)
powershell -command New-NetFirewallRule -DisplayName "Block_RPC-TCP-135-In" -Direction Inbound -LocalPort 135 -Action Block -Protocol TCP
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall add rule name="Block_RPC-TCP-135-In" dir=in protocol=tcp localport=135 action=block
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall set portopening protocol=tcp port=135 mode=disable name="Block_RPC-TCP-135-In"
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail! )ELSE (ECHO. && ECHO Setting Success! )
	)ELSE (
		ECHO. && ECHO Setting Success!
	)
)ELSE (
	ECHO. && ECHO Setting Success!
)
EXIT /B

:RPC_Open
CALL :Check_Rule Block_RPC-TCP-135-In
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Rule is not exist! && ECHO. && PAUSE && GOTO RPC_Info)
powershell -command Remove-NetFirewallRule -DisplayName "Block_RPC-TCP-135-In"
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall delete rule name="Block_RPC-TCP-135-In" dir=in
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall delete portopening protocol=tcp port=135
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Remove fail! )ELSE (ECHO. && ECHO Remove success! )
	)ELSE (
		ECHO. && ECHO Remove success!
	)
)ELSE (
	ECHO. && ECHO Remove success!
)
EXIT /B


::REM =====================================================================================================================
::REM ==================================================NetBIOS_Service====================================================
::REM =====================================================================================================================


:NetBIOS_Service_Info
CLS
ECHO.
ECHO =======================================================
ECHO.
CALL :Check_NetBios
ECHO.
GOTO NetBIOS_Service_Ask

:NetBIOS_Service_Ask
ECHO.
ECHO =======================================================
ECHO.
CHOICE /C 321 /N /M "[1]Set specific network adapter [2]Set all [3]Back Menu: "
IF ERRORLEVEL 3 (
	GOTO NetBIOS_Service_Specific_Ask
)ELSE IF ERRORLEVEL 2 (
	GOTO NetBIOS_Service_ALL_Ask
)ELSE IF ERRORLEVEL 1 (
	GOTO MAIN
)
ECHO.
PAUSE
GOTO RPC_Info

:NetBIOS_Service_Specific_Ask
CLS
ECHO.
ECHO =======================================================
ECHO.
CALL :Check_NetBios
ECHO.
ECHO -------------------------------------------------------
SET "Network_Adapter_Name="
SET /P Network_Adapter_Name="Please input network adapter index number[B/b:Back]: "
IF NOT DEFINED Network_Adapter_Name (
	ECHO.
	ECHO Please input index number!
	ECHO.
	PAUSE
	GOTO NetBIOS_Service_Specific_Ask
)ELSE IF /I "%Network_Adapter_Name%" EQU "B" (
	GOTO NetBIOS_Service_Ask
)
ECHO.
CALL :Check_NetBios_Correct %Network_Adapter_Name% REM Check the existence of the index number
IF NOT DEFINED Ans (
	ECHO.
	ECHO Index number does not exists，please enter again!
	ECHO.
	PAUSE
	GOTO NetBIOS_Service_Specific_Ask
)ELSE (
	GOTO NetBIOS_Service_on-off_Ask
)

:NetBIOS_Service_on-off_Ask
CLS
ECHO.
ECHO =======================================================
ECHO.
CALL :Check_NetBios
ECHO.
ECHO.
ECHO.
Powershell -command 'Specified Network Adapter: '+("wmic nicconfig get Caption,index | find ' %Network_Adapter_Name% '")
ECHO.
ECHO -------------------------------------------------------
CHOICE /C B210 /N /M "Please input the TcpipNetbiosOptions Value [0,1,2][B/b:Back]: "
IF ERRORLEVEL 4 (
	CALL :NetBIOS_Service_Specific_SET 0
)ELSE IF ERRORLEVEL 3 (
	CALL :NetBIOS_Service_Specific_SET 1
)ELSE IF ERRORLEVEL 2 (
	CALL :NetBIOS_Service_Specific_SET 2
)ELSE (
	GOTO NetBIOS_Service_Specific_Ask
)
ECHO.
PAUSE
GOTO NetBIOS_Service_Info

:NetBIOS_Service_ALL_Ask
CLS
ECHO.
ECHO =======================================================
ECHO.
CALL :Check_NetBios
ECHO.
CHOICE /C B210 /N /M "Please input the TcpipNetbiosOptions Value[0,1,2][B/b:Back]: "
IF ERRORLEVEL 4 (
	CALL :NetBIOS_Service_ALL_SET 0
)ELSE IF ERRORLEVEL 3 (
	CALL :NetBIOS_Service_ALL_SET 1
)ELSE IF ERRORLEVEL 2 (
	CALL :NetBIOS_Service_ALL_SET 2
)ELSE (
	GOTO NetBIOS_Service_Info
)
ECHO.
PAUSE
GOTO NetBIOS_Service_Info

:NetBIOS_Service_Specific_SET
ECHO.
ECHO Setting...
ECHO.
WMIC nicconfig where index=%Network_Adapter_Name% call SetTcpipNetbios %~1
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Set Failed!)ELSE (ECHO. && ECHO Set Success!)
EXIT /B

:NetBIOS_Service_ALL_SET
ECHO.
ECHO Setting...
ECHO.
powershell -command $base = 'HKLM:SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces' ; $interfaces = Get-ChildItem $base ^| Select -ExpandProperty PSChildName ; foreach($interface in $interfaces) {Set-ItemProperty -Path "$base\$interface" -Name "NetbiosOptions" -Value "%~1"}
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Set Failed!)ELSE (ECHO. && ECHO Set Success!)
EXIT /B


::REM ==================================================Close NetBIOS(SMB)=================================================


:NetBIOS_SMB
CLS
ECHO.
ECHO =======================================================
ECHO.
ECHO ---------------------------------------
ECHO Current SMB(139) Port State:
ECHO.
ECHO  Proto   Local address        Foreign address            State          PID
CALL :Check_Port 139
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO No Connection!)
ECHO.

ECHO ---------------------------------------
ECHO Current SMB(445) Port State:
ECHO.
ECHO  Proto   Local address        Foreign address            State          PID
CALL :Check_Port 445
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO No Connection! && GOTO Switch_SMB)

:Switch_SMB
ECHO.
ECHO =======================================================
ECHO.
CHOICE /C 321 /N /M "[1]Close SMB Port [2]Open SMB Port [3]Back Menu: "
IF ERRORLEVEL 3 (
	GOTO Close_SMB
)ELSE IF ERRORLEVEL 2 (
	GOTO Open_SMB
)ELSE (
	GOTO MAIN
)

:Close_SMB
ECHO.
ECHO =======================================================
ECHO.

::REM ========================================Close NetBIOS=======================================

ECHO ---------------------------------------
ECHO ---------------【NetBios】---------------
ECHO ---------------------------------------
ECHO Close NetBios...
powershell -command $base = 'HKLM:SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces' ; $interfaces = Get-ChildItem $base ^| Select -ExpandProperty PSChildName ; foreach($interface in $interfaces) {Set-ItemProperty -Path "$base\$interface" -Name "NetbiosOptions" -Value 2}
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Close Fail!)ELSE (ECHO. && ECHO Close Success!)

::REM ========================================Close Port_139======================================

ECHO.
ECHO ---------------------------------------
ECHO --------------【Port 139】---------------
ECHO ---------------------------------------
CALL :Is_Exist_139_Entries_RA REM Check Reg Entries[Restrictanonymous] Exist
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO Setting Registry[Restrict anonymous access]...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "restrictanonymous" -Value "2"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail!)ELSE (ECHO. && ECHO Setting Success!)
)

ECHO.
ECHO [1/2]Close TCP/IP NetBIOS Helper Service...
ECHO.
sc stop lmhosts
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO Service is Closed!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO Service is Closed!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO Close Service Success! 
)ELSE (
	ECHO.
	ECHO Close Service Fail!
)

ECHO.
ECHO [2/2]Close TCP/IP NetBIOS Helper Service...
ECHO.
sc config lmhosts start=disabled
IF %ERRORLEVEL% NEQ 0 (
	ECHO. && ECHO Setting Fail!
)ELSE (
	ECHO. && ECHO Setting Success!
)
ECHO.

ECHO [1/2]Close NetBios Service...
ECHO.
sc stop netbios
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO Service is Closed!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO Service is Closed!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO Close Service Success! 
)ELSE (
	ECHO.
	ECHO Close Service Fail!
)

ECHO.
ECHO [2/2]Close NetBios Service...
ECHO.
sc config netbios start=disabled
IF %ERRORLEVEL% NEQ 0 (
	ECHO. && ECHO Close Fail!
)ELSE (
	ECHO. && ECHO Close Success!
)
ECHO.

CALL :Is_Exist_139_Entries_ShareServer REM Check Reg Entries[AutoShareServer] Exist
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO Disable System Disk Sharing...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareServer" -Value "0"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail!)ELSE (ECHO. && ECHO Setting Success!)
)

CALL :Is_Exist_139_Entries_ShareWks REM Check Reg Entries[AutoShareWks] Exist
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO Disable System Folder Sharing...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareWks" -Value "0"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail!)ELSE (ECHO. && ECHO Setting Success!)
)

ECHO.
ECHO Setting Firewall Rule[Block Inbound Port 139]...
ECHO.
CALL :Check_Rule Block_TCP-139
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Confirmed not create rule，Creating... && ECHO.)ELSE (ECHO. && ECHO Rule is exist! && ECHO. && PAUSE && GOTO Close_Port_445)
ECHO.
powershell -command New-NetFirewallRule -DisplayName "Block_TCP-139" -Direction Inbound -LocalPort 139 -Protocol TCP -Action Block
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall add rule name="Block_TCP-139" dir=in protocol=tcp localport=139 action=block
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall set portopening protocol=tcp port=139 mode=disable name="Block_TCP-139"
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail! )ELSE (ECHO. && ECHO Setting Success! )
	)ELSE (
		ECHO. && ECHO Setting Success!
	)
)ELSE (
	ECHO. && ECHO Setting Success!
)
GOTO Close_Port_445

::REM ========================================Close Port_445======================================

:Close_Port_445
ECHO.
ECHO ---------------------------------------
ECHO --------------【Port 445】---------------
ECHO ---------------------------------------
CALL :Is_Exist_445_Entries_SMBD REM Check Reg Entries[SMBDeviceEnabled] Exist
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO Disable Reg Entries SMBDeviceEnabled Value...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "SMBDeviceEnabled" -Value "0"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Disable Fail! && ECHO.)ELSE (ECHO. && ECHO Disable Success! && ECHO.)
)

CALL :Is_Exist_445_Entries_TB REM Check Reg Entries[TransportBindName] Exist
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO Clear Reg Entries TransportBindName Value...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "TransportBindName" -Value "$null"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Clear Fail! && ECHO.)ELSE (ECHO. && ECHO Clear Success! && ECHO.)
)

ECHO [1/2]Close lanmanserver Service...
ECHO.
sc stop lanmanserver
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO Service is Closed!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO Service is Closed!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO Close Service Success!
)ELSE (
	ECHO.
	ECHO Close Service Fail!
)

ECHO.
ECHO [2/2]Close lanmanserver Service...
ECHO.
sc config lanmanserver start=disabled
IF %ERRORLEVEL% NEQ 0 (
	ECHO. && ECHO Close Fail!
)ELSE (
	ECHO. && ECHO Close Success!
)

ECHO.
ECHO Setting Firewall Rule[Block Inbound Port 445]...
ECHO.
CALL :Check_Rule Block_TCP-445
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Confirmed not create rule，Creating... && ECHO.)ELSE (ECHO. && ECHO Rule is exist! && ECHO. && PAUSE && GOTO NetBIOS_SMB)
ECHO.
powershell -command New-NetFirewallRule -DisplayName "Block_TCP-445" -Direction Inbound -LocalPort 445 -Protocol TCP -Action Block
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall add rule name="Block_TCP-445" dir=in protocol=tcp localport=445 action=block
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall set portopening protocol=tcp port=445 mode=disable name="Block_TCP-445"
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail! )ELSE (ECHO. && ECHO Setting Success! )
	)ELSE (
		ECHO. && ECHO Setting Success!
	)
)ELSE (
	ECHO. && ECHO Setting Success!
)
ECHO.
PAUSE
GOTO MAIN

::REM ==================================================Open NetBIOS(SMB)==================================================

:Open_SMB
ECHO.
ECHO =======================================================
ECHO.

::REM ========================================Open NetBIOS========================================

ECHO ---------------------------------------
ECHO ---------------【NetBios】---------------
ECHO ---------------------------------------
ECHO Open NetBios...
powershell -command $base = 'HKLM:SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces' ; $interfaces = Get-ChildItem $base ^| Select -ExpandProperty PSChildName ; foreach($interface in $interfaces) {Set-ItemProperty -Path "$base\$interface" -Name "NetbiosOptions" -Value 0}
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Open Fail!)ELSE (ECHO. && ECHO Open Success!)

::REM ========================================Open Port_139=======================================

ECHO.
ECHO ---------------------------------------
ECHO --------------【Port 139】---------------
ECHO ---------------------------------------
CALL :Is_Exist_139_Entries_RA REM Check Reg Entries[Restrictanonymous] Exist
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO Setting Registry[Restrict anonymous access]...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "restrictanonymous" -Value "0"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail!)ELSE (ECHO. && ECHO Setting Success!)
)
ECHO.
ECHO [1/2]Open TCP/IP NetBIOS Helper Service...
ECHO.
sc config lmhosts start=demand
IF %ERRORLEVEL% NEQ 0 (
	ECHO. && ECHO Setting Fail!
)ELSE (
	ECHO. && ECHO Setting Success!
)

ECHO.
ECHO [2/2]Open TCP/IP NetBIOS Helper Service...
ECHO.
sc start lmhosts
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO Service is Opened!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO Service is Opened!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO Open Service Success! 
)ELSE (
	ECHO.
	ECHO Open Service Fail!
)

ECHO.
ECHO [1/2]Open NetBios Service...
ECHO.
sc config netbios start=auto
IF %ERRORLEVEL% NEQ 0 (
	ECHO. && ECHO Open Fail!
)ELSE (
	ECHO. && ECHO Open Success!
)

ECHO.
ECHO [1/2]Open NetBios Service...
ECHO.
sc start netbios
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO Service is Opened!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO Service is Opened!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO Open Service Success! 
)ELSE (
	ECHO.
	ECHO Open Service Fail!
)

ECHO.

CALL :Is_Exist_139_Entries_ShareServer REM Check Reg Entries[AutoShareServer] Exist
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO Enable System Disk Sharing...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareServer" -Value "1"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail!)ELSE (ECHO. && ECHO Setting Success!)
)

CALL :Is_Exist_139_Entries_ShareWks REM Check Reg Entries[AutoShareWks] Exist
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO Enable System Folder Sharing...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareWks" -Value "1"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail!)ELSE (ECHO. && ECHO Setting Success!)
)

ECHO.
ECHO Remove Firewall Rule[Block Inbound Port 139]...
ECHO.
CALL :Check_Rule Block_TCP-139
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Rule is not exist! && ECHO. && PAUSE && GOTO Open_Port_445)
ECHO.
powershell -command Remove-NetFirewallRule -DisplayName "Block_TCP-139"
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall delete rule name="Block_TCP-139" dir=in
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall delete portopening protocol=tcp port=139
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail! )ELSE (ECHO. && ECHO Setting Success! )
	)ELSE (
		ECHO. && ECHO Setting Success!
	)
)ELSE (
	ECHO. && ECHO Setting Success!
)
GOTO Open_Port_445

::REM ========================================Open Port_445=======================================

:Open_Port_445
ECHO.
ECHO ---------------------------------------
ECHO --------------【Port 445】---------------
ECHO ---------------------------------------
CALL :Is_Exist_445_Entries_SMBD REM Check Reg Entries[SMBDeviceEnabled] Exist
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO Enable Reg Entries SMBDeviceEnabled Value...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "SMBDeviceEnabled" -Value "1"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail! && ECHO.)ELSE (ECHO. && ECHO Setting Success! && ECHO.)
)

CALL :Is_Exist_445_Entries_TB REM Check Reg Entries[TransportBindName] Exist
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO Setting Reg Entries TransportBindName Value...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "TransportBindName" -Value '"\Device"\'
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail! && ECHO.)ELSE (ECHO. && ECHO Setting Success! && ECHO.)
)

ECHO.
ECHO [1/2]Open lanmanserver Service...
ECHO.
sc config lanmanserver start=auto
IF %ERRORLEVEL% NEQ 0 (
	ECHO. && ECHO Open Fail!
)ELSE (
	ECHO. && ECHO Open Success!
)

ECHO.
ECHO [2/2]Open lanmanserver Service...
ECHO.
sc start lanmanserver
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO Service is Opened!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO Service is Opened!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO Open Service Success!
)ELSE (
	ECHO.
	ECHO Open Service Fail!
)

ECHO.
ECHO Remove Firewall Rule[Block Inbound Port 445]...
ECHO.
CALL :Check_Rule Block_TCP-445
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Rule is not exist! && ECHO. && PAUSE && GOTO NetBIOS_SMB)
ECHO.
powershell -command Remove-NetFirewallRule -DisplayName "Block_TCP-445"
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall delete rule name=”Block_TCP-445” dir=in
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall delete portopening protocol=tcp port=445
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail! )ELSE (ECHO. && ECHO Setting Success! )
	)ELSE (
		ECHO. && ECHO Setting Success!
	)
)ELSE (
	ECHO. && ECHO Setting Success!
)
ECHO.
PAUSE
GOTO MAIN

:RDP_Port
powershell -command 'Current RDP Port:'+("Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "PortNumber" | Select-Object -ExpandProperty PortNumber")
EXIT /B

:Is_Exist_139_Entries_RA
ECHO Check Reg Entries[Restrictanonymous] Exist...
powershell -command Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -name "restrictanonymous" ^| findstr restrictanonymous > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO Create_139_Entries_RA)ELSE (ECHO Confirm RestrictAnonymous is Exist!)
EXIT /B

:Is_Exist_139_Entries_ShareServer
ECHO Check Reg Entries[AutoShareServer] Exist...
powershell -command Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -name "AutoShareServer" ^| findstr AutoShareServer > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO Create_139_Entries_ShareServer)ELSE (ECHO Confirm AutoShareServer is Exist!)
EXIT /B

:Is_Exist_139_Entries_ShareWks
ECHO Check Reg Entries[AutoShareWks] Exist...
powershell -command Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -name "AutoShareWks" ^| findstr AutoShareWks > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO Create_139_Entries_ShareWks)ELSE (ECHO Confirm AutoShareWks is Exist!)
EXIT /B

:Is_Exist_445_Entries_SMBD
ECHO Check Reg Entries[SMBDeviceEnabled] Exist...
powershell -command Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -name "SMBDeviceEnabled" ^| findstr SMBDeviceEnabled > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO Create_445_Entries_SMBD)ELSE (ECHO Confirm SMBDeviceEnabled is Exist!)
EXIT /B

:Is_Exist_445_Entries_TB
ECHO Check Reg Entries[TransportBindName] Exist...
powershell -command Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -name "TransportBindName" ^| findstr TransportBindName > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO Create_445_Entries_TB)ELSE (ECHO Confirm TransportBindName is Exist!)
EXIT /B

:Create_139_Entries_RA
ECHO.
ECHO Reg Entries[Restrictanonymous] is not exist，Creating...
ECHO.
powershell -command New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "restrictanonymous" -PropertyType "DWORD" -Value "0"
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Create Fail，Can't Setting Entries[Restrictanonymous]! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO Create Success!)
EXIT /B

:Create_139_Entries_ShareServer
ECHO.
ECHO Reg Entries[AutoShareServer] is not exist，Creating...
ECHO.
powershell -command New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareServer" -PropertyType "DWORD" -Value "0"
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Create Fail，Can't Setting System Disk Share! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO Create Success!)
EXIT /B

:Create_139_Entries_ShareWks
ECHO.
ECHO Reg Entries[AutoShareWks] is not exist，Creating...
ECHO.
powershell -command New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareWks" -PropertyType "DWORD" -Value "0"
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Create Fail，Can't Setting System Folder Share! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO Create Success!)
EXIT /B

:Create_445_Entries_SMBD
ECHO.
ECHO Reg Entries[SMBDeviceEnabled] is not exist，Creating...
ECHO.
CALL :Check_OS
IF %OS_Type% == x64 (SET REG_WORD=QWORD)ELSE (SET REG_WORD=DWORD)
powershell -command New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "SMBDeviceEnabled" -PropertyType "%REG_WORD%" -Value "1"
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Create Fail，Can't Setting Entries[SMBDeviceEnabled]! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO Create Success!)
EXIT /B

:Create_445_Entries_TB
ECHO.
ECHO Reg Entries[TransportBindName] is not exist，Creating...
ECHO.
powershell -command New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "TransportBindName" -PropertyType "String" -Value "1" 
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Create Fail，Can't Setting Entries[TransportBindName]! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO Create Success!)
EXIT /B

:Check_NetBios
ECHO Current all network adapter's Netbios state:
ECHO.
WMIC nicconfig get caption,index,TcpipNetbiosOptions
ECHO.
ECHO TcpipNetbiosOptions option:
ECHO.
ECHO 0 = Use NetBIOS setting from the DHCP server
ECHO 1 = Enable NetBIOS over TCP/IP
ECHO 2 = Disable NetBIOS over TCP/IP
EXIT /B

:Check_NetBios_Correct
FOR /F %%i in ('wmic nicconfig get index') do if %%i==%~1 ( SET Ans=True && EXIT /B ) > nul 2>&1
EXIT /B

:Check_Port_Scope
SET "Scope="
IF 1%~1 NEQ +1%~1  (
	ECHO.
	ECHO Please input numeric!
	ECHO.
	SET Scope=False
	EXIT /B
)
IF %~1 LSS 1001 (
	ECHO.
	ECHO Port < 1001!
	ECHO.
	SET Scope=False
)ELSE IF %~1 GTR 254535 (
	ECHO.
	ECHO Port > 254535!
	ECHO.
	SET Scope=False
)
EXIT /B

:Check_OS
IF %PROCESSOR_ARCHITECTURE% == "AMD64" (
	SET OS_Type=x64
)ElSE (
	SET OS_Type=x86
)
EXIT /B

:Check_Rule
powershell -command Get-NetFirewallRule -DisplayName "%~1" > nul 2>&1
EXIT /B

:Check_Port
netstat -ano | find "%~1 "
EXIT /B


::REM ==================================================Close NetBIOS(UDP)=================================================

:NetBIOS_UDP
CLS
ECHO.
ECHO =======================================================
ECHO.
ECHO ---------------------------------------
ECHO Current SMB(137) Port Connection State:
ECHO.
ECHO  Proto   Local address        Foreign address            State          PID
CALL :Check_Port 137
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO No Connection!)
ECHO.

ECHO ---------------------------------------
ECHO Current SMB(138) Port Connection State:
ECHO.
ECHO  Proto   Local address        Foreign address            State          PID
CALL :Check_Port 138
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO No Connection! && GOTO Switch_UDP)
:Switch_UDP
ECHO.
ECHO =======================================================
ECHO.
CHOICE /C 321 /N /M "[1]Close UDP(137~8) Port [2]Open UDP(137~8) Port [3]Back Menu: "
IF ERRORLEVEL 3 (
	GOTO Close_NetBIOS_UDP_137
)ELSE IF ERRORLEVEL 2 (
	GOTO Open_NetBIOS_UDP_137
)ELSE (
	GOTO MAIN
)

::REM ========================================Close Port_137_138===================================

:Close_NetBIOS_UDP_137
CLS
ECHO.
ECHO ---------------------------------------
ECHO --------------【Port 137】---------------
ECHO ---------------------------------------
CALL :Is_Exist_Port_137 REM Check Firewall Rule[Block Inbound Port 137] Exist
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	GOTO Close_NetBIOS_UDP_138
)
ECHO.
ECHO Setting Firewall Rule[Block Inbound Port 137]...
ECHO.
powershell -command New-NetFirewallRule -DisplayName "Block_UDP-137" -Direction Inbound -LocalPort 137 -Protocol UDP -Action Block
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall add rule name="Block_UDP-137" dir=in protocol=udp localport=137 action=block
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall set portopening protocol=udp port=137 mode=disable name="Block_UDP-137"
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail!)ELSE (ECHO. && ECHO Setting Success!)
	)ELSE (
		ECHO. && ECHO Setting Success!
	)
)ELSE (
	ECHO. && ECHO Setting Success!
)

:Close_NetBIOS_UDP_138
ECHO.
ECHO ---------------------------------------
ECHO --------------【Port 138】---------------
ECHO ---------------------------------------
CALL :Is_Exist_Port_138 REM Check Firewall Rule[Block Inbound Port 138] Exist
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	PAUSE
	GOTO NetBIOS_UDP
)
ECHO.
ECHO Setting Firewall Rule[Block Inbound Port 138]...
ECHO.
powershell -command New-NetFirewallRule -DisplayName "Block_UDP-138" -Direction Inbound -LocalPort 138 -Protocol UDP -Action Block
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall add rule name="Block_UDP-138" dir=in protocol=udp localport=138 action=block
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall set portopening protocol=udp port=138 mode=disable name="Block_UDP-138"
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail!)ELSE (ECHO. && ECHO Setting Success!)
	)ELSE (
		ECHO. && ECHO Setting Success!
	)
)ELSE (
	ECHO. && ECHO Setting Success!
)
ECHO.
PAUSE
GOTO NetBIOS_UDP

::REM ========================================Open Port_137_138====================================

:Open_NetBIOS_UDP_137
CLS
ECHO.
ECHO ---------------------------------------
ECHO --------------【Port 137】---------------
ECHO ---------------------------------------
CALL :Is_Exist_Port_137 REM Check Firewall Rule[Block Inbound Port 137] Exist
IF %ERRORLEVEL% NEQ 0 (
	GOTO Open_NetBIOS_UDP_138
)ELSE (
	SET ERRORLEVEL=
)
ECHO.
ECHO Remove Firewall Rule[Block Inbound Port 137]...
ECHO.
powershell -command Remove-NetFirewallRule -DisplayName "Block_UDP-137"
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall delete rule name=”Block_UDP-137” dir=in
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall delete portopening protocol=udp port=137
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail!)ELSE (ECHO. && ECHO Setting Success!)
	)ELSE (
		ECHO. && ECHO Setting Success!
	)
)ELSE (
	ECHO. && ECHO Setting Success!
)

:Open_NetBIOS_UDP_138
ECHO.
ECHO ---------------------------------------
ECHO --------------【Port 138】---------------
ECHO ---------------------------------------
CALL :Is_Exist_Port_138 REM Check Firewall Rule[Block Inbound Port 138] Exist
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	PAUSE
	GOTO NetBIOS_UDP
)ELSE (
	SET ERRORLEVEL=
)
ECHO.
ECHO Remove Firewall Rule[Block Inbound Port 138]...
ECHO.
powershell -command Remove-NetFirewallRule -DisplayName "Block_UDP-138"
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall delete rule name=”Block_UDP-138” dir=in
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall delete portopening protocol=udp port=138
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail!)ELSE (ECHO. && ECHO Setting Success!)
	)ELSE (
		ECHO. && ECHO Setting Success!
	)
)ELSE (
	ECHO. && ECHO Setting Success!
)
ECHO.
PAUSE
GOTO NetBIOS_UDP

:Is_Exist_Port_137
ECHO Check Firewall Rule[Block Inbound Port 137] Exist...
powershell -command Get-NetFirewallRule -DisplayName "Block_UDP-137" > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Confirm Rule is not Exist! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO Confirm Rule is Exist!) 
EXIT /B

:Is_Exist_Port_138
ECHO Check Firewall Rule[Block Inbound Port 138] Exist...
powershell -command Get-NetFirewallRule -DisplayName "Block_UDP-138" > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Confirm Rule is not Exist! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO Confirm Rule is Exist!)
EXIT /B

::REM ==================================================Check_TCP_UDP_Port=================================================

:Check_TCP_UDP
CLS
ECHO.
ECHO =======================================================
ECHO.
SET "Port="
SET "Check-Port="
SET /P Check-Port="Please input port to check( [Q]Back Menu [E]Exit [A]Check All Port ): "
IF "%Check-Port%"=="" (
	ECHO. && ECHO Please input Port! && ECHO. && PAUSE && GOTO Check_TCP_UDP
)
IF /I "%Check-Port%" EQU "Q" (
	GOTO MAIN
)ELSE IF /I "%Check-Port%" EQU "E" (
	GOTO Exit
)ELSE IF /I "%Check-Port%" EQU "A" (
	GOTO Check_TCP_UDP_Proto
)
SET "Port=^| find ':%Check-Port% '"
GOTO Check_TCP_UDP_Proto

:Check_TCP_UDP_Proto
ECHO.
ECHO ==============================================================
ECHO.
SET "Proto="
SET "Proto_Type="
CHOICE /C 321 /N /M "Pleast select the name of the protocol( [1]TCP [2]UDP [3]ALL ): "
IF ERRORLEVEL 3 (
	SET Proto_Type=TCP
)ELSE IF ERRORLEVEL 2 (
	SET Proto_Type=UDP
)ELSE (
	GOTO Check_TCP_UDP-State
)
SET "Proto=^| findstr %Proto_Type%"
GOTO Check_TCP_UDP-State


:Check_TCP_UDP-State
ECHO.
ECHO.
ECHO ==============================================================
ECHO                 Choose the state of connection                
ECHO ==============================================================
ECHO.
ECHO Warning: UDP protocol，no state of connection，Please press K.
ECHO.
ECHO --------------------------------------------------------------
ECHO [A]  LISTEN: 		The socket is listening for incoming connections.
ECHO [B]  ESTABLISHED:  The socket has an established connection.
ECHO [C]  CLOSING: 		The socket is not being used.
ECHO [D]  TIMED_WAIT: 	The socket is waiting after close to handle packets still in the network.
ECHO [E]  CLOSE_WAIT: 	The remote end has shut down, waiting for the socket to close.
ECHO [F]  FIN_WAIT_1: 	The socket is closed, and the connection is shutting down.
ECHO [G]  FIN_WAIT_2: 	Connection is closed, and the socket is waiting for a shutdown from the remote end.
ECHO [H]  LAST_ACK: 	The remote end has shutdown, and the socket is closed. Waiting for acknowledgement.
ECHO [I]  SYN_SEND: 	The socket is actively attempting to establish a connection.
ECHO [J]  SYN_RECEIVED: A connection request has been received from the network.
ECHO [K]  ALL_State: 	Show all state.
ECHO --------------------------------------------------------------
ECHO.
SET "State="
SET "State_Type="
CHOICE /C KJIHGFEDCBA /N /M "Choose Function[A~K]: "
IF ERRORLEVEL 11 (
	SET State_Type=LISTEN
)ELSE IF ERRORLEVEL 10 (
	SET State_Type=ESTABLISHED
)ELSE IF ERRORLEVEL 9 (
	SET State_Type=CLOSING
)ELSE IF ERRORLEVEL 8 (
	SET State_Type=TIMED_WAIT
)ELSE IF ERRORLEVEL 7 (
	SET State_Type=CLOSE_WAIT
)ELSE IF ERRORLEVEL 6 (
	SET State_Type=FIN_WAIT_1
)ELSE IF ERRORLEVEL 5 (
	SET State_Type=FIN_WAIT_2
)ELSE IF ERRORLEVEL 4 (
	SET State_Type=LAST_ACK
)ELSE IF ERRORLEVEL 3 (
	SET State_Type=SYN_SEND
)ELSE IF ERRORLEVEL 2 (
	SET State_Type=SYN_RECEIVED
)ELSE (
	GOTO Check_TCP_UDP-Run
)
SET "State=^| findstr %State_Type%"
GOTO Check_TCP_UDP-Run

:Check_TCP_UDP-Run
ECHO.
ECHO.
ECHO ==============================================================
ECHO.
ECHO  Proto   Local address        Foreign address            State          PID
ECHO.
SET "RUN=%Proto% %Port% %State%"
powershell -command netstat -ano %RUN%
IF %ERRORLEVEL% NEQ 0 (
	ECHO. && ECHO Current no this port! && ECHO. && PAUSE && GOTO Check_TCP_UDP
)ELSE (
	ECHO. && PAUSE && GOTO Check_TCP_UDP
)

::REM =========================================================EXIT========================================================

:Exit
ECHO.
ECHO.
PAUSE
EXIT

