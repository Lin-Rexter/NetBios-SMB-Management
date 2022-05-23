set "params=%*" && cd /d "%CD%" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/C cd ""%CD%"" && %~s0 %params%", "", "runas", 1 >>"%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )
@ECHO OFF
TITLE Close [TCP_139¡B445]¡B[UDP_137¡B138](Administrator)

GOTO MAIN

:MAIN
CLS
ECHO.
ECHO ==============================================================
ECHO                         Choose Function
ECHO ==============================================================
ECHO.
ECHO --------------------------------------------------------------
ECHO [1] Change RDP Port
ECHO [2] Management NetBIOS[SMB] TCP 139¡B445
ECHO [3] Management NetBIOS[SMB] UDP 137¡B138
ECHO [4] Check TCP¡BUDP Port
ECHO --------------------------------------------------------------
ECHO.
CHOICE /C 4321 /N /M "Choose Function[1~4]: "
IF ERRORLEVEL 4 (
	GOTO RDP_Info
)ELSE IF ERRORLEVEL 3 (
	GOTO NetBIOS_SMB
)ELSE IF ERRORLEVEL 2 (
	GOTO NetBIOS_UDP
)ELSE (
	GOTO Check_TCP_UDP
)

::REM =========================================================RDP=========================================================

:RDP_Info
CLS
ECHO.
ECHO =======================================================
ECHO.
powershell -command 'Current RDP Port:'+("Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "PortNumber" | Select-Object -ExpandProperty PortNumber")
ECHO.
CHOICE /C NYE /N /M "Do you Want to Change RDP Port?( [E]Exit [N]Back Menu ): "
IF ERRORLEVEL 3 (
	GOTO Exit
)ELSE IF ERRORLEVEL 2 (
	GOTO Change-RDP_Port
)ELSE IF ERRORLEVEL 1 (
	GOTO MAIN
)

:Change-RDP_Port
CLS
ECHO.
ECHO =======================================================
ECHO.
SET /P RDP-Port="Please Input New Port(Press Enter use Port 3389): "
IF "%RDP-Port%" EQU "" set rdp_port=3389
ECHO.

ECHO.
powershell -command Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "PortNumber" -Value %RDP-Port%
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Change Success! )ELSE (ECHO. && ECHO Change Fail! )
ECHO.
ECHO Setting Firewall Rule...
powershell -command New-NetFirewallRule -DisplayName 'RDPPORTLatest-TCP-In' -Profile 'Public' -Direction Inbound -Action Allow -Protocol TCP -LocalPort %RDP-Port%
ECHO.
powershell -command New-NetFirewallRule -DisplayName 'RDPPORTLatest-UDP-In' -Profile 'Public' -Direction Inbound -Action Allow -Protocol UDP -LocalPort %RDP-Port%
ECHO.
Net stop Termservice
ECHO.
Net start Termservice
ECHO.
ECHO Change Finish!
ECHO.
powershell -command 'Current RDP Port:'+("Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "PortNumber" | Select-Object -ExpandProperty PortNumber")
GOTO Exit

::REM ==================================================Close NetBIOS(SMB)=================================================

:NetBIOS_SMB
CLS
ECHO.
ECHO =======================================================
ECHO.
ECHO ---------------------------------------
ECHO Current SMB(139) Port State:
ECHO.
ECHO  Proto   Local address        Foreign address      State           PID
netstat -ano | findstr LISTEN | findstr 139
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO No Connection!)
ECHO.

ECHO ---------------------------------------
ECHO Current SMB(445) Port State:
ECHO.
ECHO  Proto   Local address        Foreign address      State           PID
netstat -ano | findstr LISTEN | findstr 445
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
ECHO ---------------¡iNetBios¡j---------------
ECHO ---------------------------------------
ECHO Close NetBios...
powershell -command $base = 'HKLM:SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces' ; $interfaces = Get-ChildItem $base ^| Select -ExpandProperty PSChildName ; foreach($interface in $interfaces) {Set-ItemProperty -Path "$base\$interface" -Name "NetbiosOptions" -Value 2}
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Close Fail!)ELSE (ECHO. && ECHO Close Success!)

::REM ========================================Close Port_139======================================

ECHO.
ECHO ---------------------------------------
ECHO --------------¡iPort 139¡j---------------
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

ECHO Setting Firewall Rule[Block Inbound Port 139]...
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

::REM ========================================Close Port_445======================================

ECHO.
ECHO ---------------------------------------
ECHO --------------¡iPort 445¡j---------------
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
ECHO ---------------¡iNetBios¡j---------------
ECHO ---------------------------------------
ECHO Open NetBios...
powershell -command $base = 'HKLM:SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces' ; $interfaces = Get-ChildItem $base ^| Select -ExpandProperty PSChildName ; foreach($interface in $interfaces) {Set-ItemProperty -Path "$base\$interface" -Name "NetbiosOptions" -Value 0}
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Open Fail!)ELSE (ECHO. && ECHO Open Success!)

::REM ========================================Open Port_139=======================================

ECHO.
ECHO ---------------------------------------
ECHO --------------¡iPort 139¡j---------------
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

ECHO Remove Firewall Rule[Block Inbound Port 139]...
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

::REM ========================================Open Port_445=======================================

ECHO.
ECHO ---------------------------------------
ECHO --------------¡iPort 445¡j---------------
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
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "TransportBindName" -Value "\Device\"
	IIF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Setting Fail! && ECHO.)ELSE (ECHO. && ECHO Setting Success! && ECHO.)
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
powershell -command Remove-NetFirewallRule -DisplayName "Block_TCP-445"
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall delete rule name=¡¨Block_TCP-445¡¨ dir=in
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
ECHO Reg Entries[Restrictanonymous] is not exist¡ACreating...
ECHO.
powershell -command New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "restrictanonymous" -PropertyType "DWORD" -Value "0"
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Create Fail¡ACan't Setting Entries[Restrictanonymous]! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO Create Success!)
EXIT /B

:Create_139_Entries_ShareServer
ECHO.
ECHO Reg Entries[AutoShareServer] is not exist¡ACreating...
ECHO.
powershell -command New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareServer" -PropertyType "DWORD" -Value "0"
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Create Fail¡ACan't Setting System Disk Share! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO Create Success!)
EXIT /B

:Create_139_Entries_ShareWks
ECHO.
ECHO Reg Entries[AutoShareWks] is not exist¡ACreating...
ECHO.
powershell -command New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareWks" -PropertyType "DWORD" -Value "0"
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Create Fail¡ACan't Setting System Folder Share! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO Create Success!)
EXIT /B

:Create_445_Entries_SMBD
ECHO.
ECHO Reg Entries[SMBDeviceEnabled] is not exist¡ACreating...
ECHO.
CALL :Check_OS
IF %OS_Type% == x64 (SET REG_WORD=QWORD)ELSE (SET REG_WORD=DWORD)
powershell -command New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "SMBDeviceEnabled" -PropertyType "%REG_WORD%" -Value "1"
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Create Fail¡ACan't Setting Entries[SMBDeviceEnabled]! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO Create Success!)
EXIT /B

:Create_445_Entries_TB
ECHO.
ECHO Reg Entries[TransportBindName] is not exist¡ACreating...
ECHO.
powershell -command New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "TransportBindName" -PropertyType "String" -Value "1" 
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO Create Fail¡ACan't Setting Entries[TransportBindName]! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO Create Success!)
EXIT /B

:Check_OS
IF %PROCESSOR_ARCHITECTURE% == "AMD64" (
	SET OS_Type=x64
)ElSE (
	SET OS_Type=x86
)
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
ECHO  Proto   Local address        Foreign address      State           PID
netstat -ano | findstr LISTEN | findstr 137
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO No Connection!)
ECHO.

ECHO ---------------------------------------
ECHO Current SMB(138) Port Connection State:
ECHO.
ECHO  Proto   Local address        Foreign address      State           PID
netstat -ano | findstr LISTEN | findstr 138
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
ECHO --------------¡iPort 137¡j---------------
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
ECHO --------------¡iPort 138¡j---------------
ECHO ---------------------------------------
CALL :Is_Exist_Port_138 REM Check Firewall Rule[Block Inbound Port 138] Exist
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	PAUSE
	GOTO MAIN
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
GOTO MAIN

::REM ========================================Open Port_137_138====================================

:Open_NetBIOS_UDP_137
CLS
ECHO.
ECHO ---------------------------------------
ECHO --------------¡iPort 137¡j---------------
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
	netsh advfirewall firewall delete rule name=¡¨Block_UDP-137¡¨ dir=in
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
ECHO --------------¡iPort 138¡j---------------
ECHO ---------------------------------------
CALL :Is_Exist_Port_138 REM Check Firewall Rule[Block Inbound Port 138] Exist
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	PAUSE
	GOTO MAIN
)ELSE (
	SET ERRORLEVEL=
)
ECHO.
ECHO Remove Firewall Rule[Block Inbound Port 138]...
ECHO.
powershell -command Remove-NetFirewallRule -DisplayName "Block_UDP-138"
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall delete rule name=¡¨Block_UDP-138¡¨ dir=in
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
GOTO MAIN

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
SET Check-Port=
SET /P Check-Port="Please input port to check( [Q]Back Menu [E]Exit [A]Check All Port ): "
IF "%Check-Port%"=="" (
	ECHO. && ECHO Please input Port! && ECHO. && PAUSE && GOTO Check_TCP_UDP
)
IF /I "%Check-Port%" EQU "Q" (
	GOTO MAIN
)ELSE IF /I "%Check-Port%" EQU "E" (
	GOTO Exit
)ELSE IF /I "%Check-Port%" EQU "A" (
	SET RUN=^| findstr LISTEN
)ELSE (
	SET RUN=^| findstr LISTEN ^| findstr %Check-Port%
)
ECHO.
ECHO  Proto   Local address        Foreign address      State           PID
netstat -ano %RUN%
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

