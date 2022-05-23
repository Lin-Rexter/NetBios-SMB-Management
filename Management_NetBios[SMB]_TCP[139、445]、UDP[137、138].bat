set "params=%*" && cd /d "%CD%" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/C cd ""%CD%"" && %~s0 %params%", "", "runas", 1 >>"%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )
@ECHO OFF
TITLE Close [TCP_139、445]、[UDP_137、138](Administrator)

GOTO MAIN

:MAIN
CLS
ECHO.
ECHO ==============================================================
ECHO                           選擇功能
ECHO ==============================================================
ECHO.
ECHO --------------------------------------------------------------
ECHO [1] 更改RDP埠 (Change RDP Port)
ECHO [2] 管理NetBIOS[SMB] TCP 139、445 (Management NetBIOS[SMB] TCP 139、445)
ECHO [3] 管理NetBIOS UDP 137、138 (Management NetBIOS[SMB] UDP 137、138)
ECHO [4] 查看TCP、UDP連接埠 (Check TCP、UDP Port)
ECHO --------------------------------------------------------------
ECHO.
CHOICE /C 4321 /N /M "選擇功能(Choose Function)[1~4]: "
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
powershell -command '目前RDP的連接埠(Current RDP Port):'+("Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "PortNumber" | Select-Object -ExpandProperty PortNumber")
ECHO.
CHOICE /C NYE /N /M "是否更改連接埠(按下E離開;按下N返回主選單)/Do you Want to Change Port(Press E to Exit; N to Home): "
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
SET /P RDP-Port="請輸入要將連接埠更改為(按下Enter使用默認埠3389): "
IF "%RDP-Port%" EQU "" set rdp_port=3389
ECHO.

ECHO.
powershell -command Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "PortNumber" -Value %RDP-Port%
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗! )ELSE (ECHO. && ECHO 設置成功! )
ECHO.
ECHO 設置防火牆規則中...
powershell -command New-NetFirewallRule -DisplayName 'RDPPORTLatest-TCP-In' -Profile 'Public' -Direction Inbound -Action Allow -Protocol TCP -LocalPort %RDP-Port%
ECHO.
powershell -command New-NetFirewallRule -DisplayName 'RDPPORTLatest-UDP-In' -Profile 'Public' -Direction Inbound -Action Allow -Protocol UDP -LocalPort %RDP-Port%
ECHO.
Net stop Termservice
ECHO.
Net start Termservice
ECHO.
ECHO 更改完畢!
ECHO.
powershell -command '目前RDP的連接埠:'+("Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "PortNumber" | Select-Object -ExpandProperty PortNumber")
GOTO Exit

::REM ==================================================Close NetBIOS(SMB)=================================================

:NetBIOS_SMB
CLS
ECHO.
ECHO =======================================================
ECHO.
ECHO ---------------------------------------
ECHO 目前SMB(139)的連接埠狀態:
ECHO.
ECHO  協定    本機位址               外部位址               狀態            PID
netstat -ano | findstr LISTEN | findstr 139
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 未有連接狀態!)
ECHO.

ECHO ---------------------------------------
ECHO 目前SMB(445)的連接埠狀態:
ECHO.
ECHO  協定    本機位址               外部位址               狀態            PID
netstat -ano | findstr LISTEN | findstr 445
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 未有連接狀態! && GOTO Switch_SMB)

:Switch_SMB
ECHO.
ECHO =======================================================
ECHO.
CHOICE /C 321 /N /M "[1]關閉SMB連接埠 [2]開啟SMB連接埠 [3]返回主選單: "
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
ECHO 關閉NetBios功能中...
powershell -command $base = 'HKLM:SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces' ; $interfaces = Get-ChildItem $base ^| Select -ExpandProperty PSChildName ; foreach($interface in $interfaces) {Set-ItemProperty -Path "$base\$interface" -Name "NetbiosOptions" -Value 2}
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 關閉失敗!)ELSE (ECHO. && ECHO 關閉成功)

::REM ========================================Close Port_139======================================

ECHO.
ECHO ---------------------------------------
ECHO --------------【Port 139】---------------
ECHO ---------------------------------------
CALL :Is_Exist_139_Entries_RA REM 檢查註冊表Restrictanonymous項目是否存在
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO 設置註冊表限制匿名存取中...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "restrictanonymous" -Value "2"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
)

ECHO.
ECHO 關閉TCP/IP NetBIOS Helper服務中...
ECHO.
sc stop lmhosts
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO 服務已經關閉!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO 服務已經關閉，因為服務已設置停用中!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO 關閉服務成功!
)ELSE (
	ECHO.
	ECHO 無法關閉服務!
)

ECHO.
ECHO 將TCP/IP NetBIOS Helper服務設置手動中...
ECHO.
sc config lmhosts start=demand
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
ECHO.

ECHO 關閉NetBios服務中...
ECHO.
sc stop netbios
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO 服務已經關閉!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO 服務已經關閉，因為服務已設置停用中!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO 關閉服務成功!
)ELSE (
	ECHO.
	ECHO 無法關閉服務!
)

ECHO.
ECHO 將NetBios服務類型設置停用中...
ECHO.
sc config netbios start=disabled
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
ECHO.

CALL :Is_Exist_139_Entries_ShareServer REM 檢查註冊表AutoShareServer項目是否存在
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO 設置註冊表停止系統磁碟分享中...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareServer" -Value "0"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
)

CALL :Is_Exist_139_Entries_ShareWks REM 檢查註冊表AutoShareWks項目是否存在
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO 設置註冊表停止系統資料夾分享中...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareWks" -Value "0"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
)

ECHO 設置防火牆阻擋139輸入規則中...
ECHO.
powershell -command New-NetFirewallRule -DisplayName "Block_TCP-139" -Direction Inbound -LocalPort 139 -Protocol TCP -Action Block
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall add rule name="Block_TCP-139" dir=in protocol=tcp localport=139 action=block
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall set portopening protocol=tcp port=139 mode=disable name="Block_TCP-139"
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗! )ELSE (ECHO. && ECHO 設置成功! )
	)ELSE (
		ECHO. && ECHO 設置成功! 
	)
)ELSE (
	ECHO. && ECHO 設置成功! 
)

::REM ========================================Close Port_445======================================

ECHO.
ECHO ---------------------------------------
ECHO --------------【Port 445】---------------
ECHO ---------------------------------------
CALL :Is_Exist_445_Entries_SMBD REM 檢查註冊表SMBDeviceEnabled項目是否存在
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO 關閉註冊表項目SMBDeviceEnabled值中...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "SMBDeviceEnabled" -Value "0"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 關閉失敗! && ECHO.)ELSE (ECHO. && ECHO 關閉成功! && ECHO.)
)

CALL :Is_Exist_445_Entries_TB REM 檢查註冊表TransportBindName項目是否存在
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO 清空註冊表項目TransportBindName值中...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "TransportBindName" -Value "$null"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 清空失敗! && ECHO.)ELSE (ECHO. && ECHO 清空成功! && ECHO.)
)

ECHO 關閉lanmanserver服務中...
ECHO.
sc stop lanmanserver
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO 服務已經關閉!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO 服務已經關閉，因為服務已設置停用中!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO 關閉服務成功!
)ELSE (
	ECHO.
	ECHO 無法關閉服務!
)

ECHO.
ECHO 將lanmanserver服務設置停用中...
ECHO.
sc config lanmanserver start=disabled
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 無法關閉服務!)ELSE (ECHO. && ECHO 關閉服務成功!)

ECHO.
ECHO 設置防火牆阻擋445輸入規則中...
ECHO.
powershell -command New-NetFirewallRule -DisplayName "Block_TCP-445" -Direction Inbound -LocalPort 445 -Protocol TCP -Action Block
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall add rule name="Block_TCP-445" dir=in protocol=tcp localport=445 action=block
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall set portopening protocol=tcp port=445 mode=disable name="Block_TCP-445"
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
	)ELSE (
		ECHO. && ECHO 設置成功! 
	)
)ELSE (
	ECHO. && ECHO 設置成功! 
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
ECHO 開啟NetBios功能中...
powershell -command $base = 'HKLM:SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces' ; $interfaces = Get-ChildItem $base ^| Select -ExpandProperty PSChildName ; foreach($interface in $interfaces) {Set-ItemProperty -Path "$base\$interface" -Name "NetbiosOptions" -Value 0}
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 開啟失敗!)ELSE (ECHO. && ECHO 開啟成功)

::REM ========================================Open Port_139=======================================

ECHO.
ECHO ---------------------------------------
ECHO --------------【Port 139】---------------
ECHO ---------------------------------------
CALL :Is_Exist_139_Entries_RA REM 檢查註冊表Restrictanonymous項目是否存在
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO 設置註冊表限制匿名存取中...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "restrictanonymous" -Value "0"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
)
ECHO.
ECHO 將TCP/IP NetBIOS Helper服務設置手動中...
ECHO.
sc config lmhosts start=demand
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)

ECHO.
ECHO 開啟TCP/IP NetBIOS Helper服務中...
ECHO.
sc start lmhosts
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO 服務已經開啟!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO 服務已經開啟，因為服務已設置手動中!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO 開啟服務成功!
)ELSE (
	ECHO.
	ECHO 無法開啟服務!
)

ECHO.
ECHO 將NetBios服務類型設置開啟中...
ECHO.
sc config netbios start=auto
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)

ECHO.
ECHO 開啟NetBios服務中...
ECHO.
sc start netbios
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO 服務已經開啟!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO 服務已經開啟，因為服務已設置開啟中!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO 開啟服務成功!
)ELSE (
	ECHO.
	ECHO 無法開啟服務!
)
ECHO.

CALL :Is_Exist_139_Entries_ShareServer REM 檢查註冊表AutoShareServer項目是否存在
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO 設置註冊表啟用系統磁碟分享中...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareServer" -Value "1"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
)

CALL :Is_Exist_139_Entries_ShareWks REM 檢查註冊表AutoShareWks項目是否存在
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO 設置註冊表啟用系統資料夾分享中...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareWks" -Value "1"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
)

ECHO 移除防火牆阻擋139輸入規則中...
ECHO.
powershell -command Remove-NetFirewallRule -DisplayName "Block_TCP-139"
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall delete rule name="Block_TCP-139" dir=in
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall delete portopening protocol=tcp port=139
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗! )ELSE (ECHO. && ECHO 設置成功! )
	)ELSE (
		ECHO. && ECHO 設置成功!
	)
)ELSE (
	ECHO. && ECHO 設置成功!
)

::REM ========================================Open Port_445=======================================

ECHO.
ECHO ---------------------------------------
ECHO --------------【Port 445】---------------
ECHO ---------------------------------------
CALL :Is_Exist_445_Entries_SMBD REM 檢查註冊表SMBDeviceEnabled項目是否存在
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO 開啟註冊表項目SMBDeviceEnabled值中...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "SMBDeviceEnabled" -Value "1"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 開啟失敗! && ECHO.)ELSE (ECHO. && ECHO 開啟成功! && ECHO.)
)

CALL :Is_Exist_445_Entries_TB REM 檢查註冊表TransportBindName項目是否存在
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO 設置註冊表項目TransportBindName值中...
	ECHO.
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "TransportBindName" -Value "\Device\"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗! && ECHO.)ELSE (ECHO. && ECHO 設置成功! && ECHO.)
)

ECHO.
ECHO 將lanmanserver服務設置啟用中...
ECHO.
sc config lanmanserver start=auto
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 無法開啟服務!)ELSE (ECHO. && ECHO 開啟服務成功!)

ECHO.
ECHO 開啟lanmanserver服務中...
ECHO.
sc start lanmanserver
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO 服務已經開啟!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO 服務已經開啟，因為服務已設置開啟中!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO 開啟服務成功!
)ELSE (
	ECHO.
	ECHO 無法開啟服務!
)

ECHO.
ECHO 移除防火牆阻擋445輸入規則中...
ECHO.
powershell -command Remove-NetFirewallRule -DisplayName "Block_TCP-445"
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall delete rule name=”Block_TCP-445” dir=in
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall delete portopening protocol=tcp port=445
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)	
	)ELSE (
		ECHO. && ECHO 設置成功! 
	)
)ELSE (
	ECHO. && ECHO 設置成功! 
)
ECHO.
PAUSE
GOTO MAIN

:Is_Exist_139_Entries_RA
ECHO 檢查註冊表RestrictAnonymous項目中...
powershell -command Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -name "restrictanonymous" ^| findstr restrictanonymous > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO Create_139_Entries_RA)ELSE (ECHO 確認存在RestrictAnonymous項目!)
EXIT /B

:Is_Exist_139_Entries_ShareServer
ECHO 檢查註冊表AutoShareServer項目中...
powershell -command Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -name "AutoShareServer" ^| findstr AutoShareServer > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO Create_139_Entries_ShareServer)ELSE (ECHO 確認存在AutoShareServer項目!)
EXIT /B

:Is_Exist_139_Entries_ShareWks
ECHO 檢查註冊表AutoShareWks項目中...
powershell -command Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -name "AutoShareWks" ^| findstr AutoShareWks > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO Create_139_Entries_ShareWks)ELSE (ECHO 確認存在AutoShareWks項目!)
EXIT /B

:Is_Exist_445_Entries_SMBD
ECHO 檢查註冊表SMBDeviceEnabled項目中...
powershell -command Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -name "SMBDeviceEnabled" ^| findstr SMBDeviceEnabled > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO Create_445_Entries_SMBD)ELSE (ECHO 確認存在SMBDeviceEnabled項目!)
EXIT /B

:Is_Exist_445_Entries_TB
ECHO 檢查註冊表TransportBindName項目中...
powershell -command Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -name "TransportBindName" ^| findstr TransportBindName > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO Create_445_Entries_TB)ELSE (ECHO 確認存在TransportBindName項目!)
EXIT /B

:Create_139_Entries_RA
ECHO.
ECHO 不存在Restrictanonymous項目，創建中...
ECHO.
powershell -command New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "restrictanonymous" -PropertyType "DWORD" -Value "0"
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 創建失敗，無法設置註冊表限制匿名存取! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO 創建成功!)
EXIT /B

:Create_139_Entries_ShareServer
ECHO.
ECHO 不存在AutoShareServer項目，創建中...
ECHO.
powershell -command New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareServer" -PropertyType "DWORD" -Value "0"
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 創建失敗，無法設置註冊表系統磁碟分享! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO 創建成功!)
EXIT /B

:Create_139_Entries_ShareWks
ECHO.
ECHO 不存在AutoShareWks項目，創建中...
ECHO.
powershell -command New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareWks" -PropertyType "DWORD" -Value "0"
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 創建失敗，無法設置註冊表系統資料夾分享! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO 創建成功!)
EXIT /B

:Create_445_Entries_SMBD
ECHO.
ECHO 不存在SMBDeviceEnabled項目，創建中...
ECHO.
CALL :Check_OS
IF %OS_Type% == x64 (SET REG_WORD=QWORD)ELSE (SET REG_WORD=DWORD)
powershell -command New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "SMBDeviceEnabled" -PropertyType "%REG_WORD%" -Value "1"
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 創建失敗，無法設置註冊表項目SMBDeviceEnabled值! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO 創建成功!)
EXIT /B

:Create_445_Entries_TB
ECHO.
ECHO 不存在TransportBindName項目，創建中...
ECHO.
powershell -command New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "TransportBindName" -PropertyType "String" -Value "1"
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 創建失敗，無法設置註冊表項目TransportBindName值! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO 創建成功!)
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
ECHO 目前SMB(137)的連接埠狀態:
ECHO.
ECHO  協定    本機位址               外部位址               狀態            PID
netstat -ano | findstr LISTEN | findstr 137
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 未有連接狀態!)
ECHO.

ECHO ---------------------------------------
ECHO 目前SMB(138)的連接埠狀態:
ECHO.
ECHO  協定    本機位址               外部位址               狀態            PID
netstat -ano | findstr LISTEN | findstr 138
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 未有連接狀態! && GOTO Switch_UDP)

:Switch_UDP
ECHO.
ECHO =======================================================
ECHO.
CHOICE /C 321 /N /M "[1]關閉UDP(137~8)連接埠 [2]開啟UDP(137~8)連接埠 [3]返回主選單: "
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
CALL :Is_Exist_Port_137 REM 檢查防火牆是否已有設置Port 137規則中
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	GOTO Close_NetBIOS_UDP_138
)
ECHO.
ECHO 設置防火牆阻擋137輸入規則中...
ECHO.
powershell -command New-NetFirewallRule -DisplayName "Block_UDP-137" -Direction Inbound -LocalPort 137 -Protocol UDP -Action Block
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall add rule name="Block_UDP-137" dir=in protocol=udp localport=137 action=block
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall set portopening protocol=udp port=137 mode=disable name="Block_UDP-137"
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
	)ELSE (
		ECHO. && ECHO 設置成功!
	)
)ELSE (
	ECHO. && ECHO 設置成功!
)

:Close_NetBIOS_UDP_138
ECHO.
ECHO ---------------------------------------
ECHO --------------【Port 138】---------------
ECHO ---------------------------------------
CALL :Is_Exist_Port_138 REM 檢查防火牆是否已有設置Port 138規則中
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	PAUSE
	GOTO MAIN
)
ECHO.
ECHO 設置防火牆阻擋138輸入規則中...
ECHO.
powershell -command New-NetFirewallRule -DisplayName "Block_UDP-138" -Direction Inbound -LocalPort 138 -Protocol UDP -Action Block
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall add rule name="Block_UDP-138" dir=in protocol=udp localport=138 action=block
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall set portopening protocol=udp port=138 mode=disable name="Block_UDP-138"
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
	)ELSE (
		ECHO. && ECHO 設置成功!
	)
)ELSE (
	ECHO. && ECHO 設置成功!
)
ECHO.
PAUSE
GOTO MAIN

::REM ========================================Open Port_137_138====================================

:Open_NetBIOS_UDP_137
CLS
ECHO.
ECHO ---------------------------------------
ECHO --------------【Port 137】---------------
ECHO ---------------------------------------
CALL :Is_Exist_Port_137 REM 檢查防火牆是否已有設置Port 137規則中
IF %ERRORLEVEL% NEQ 0 (
	GOTO Open_NetBIOS_UDP_138
)ELSE (
	SET ERRORLEVEL=
)
ECHO.
ECHO 移除防火牆阻擋137輸入規則中...
ECHO.
powershell -command Remove-NetFirewallRule -DisplayName "Block_UDP-137"
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall delete rule name=”Block_UDP-137” dir=in
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall delete portopening protocol=udp port=137
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
	)ELSE (
		ECHO. && ECHO 設置成功!
	)
)ELSE (
	ECHO. && ECHO 設置成功!
)

:Open_NetBIOS_UDP_138
ECHO.
ECHO ---------------------------------------
ECHO --------------【Port 138】---------------
ECHO ---------------------------------------
CALL :Is_Exist_Port_138 REM 檢查防火牆是否已有設置Port 138規則中
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	PAUSE
	GOTO MAIN
)ELSE (
	SET ERRORLEVEL=
)
ECHO.
ECHO 移除防火牆阻擋138輸入規則中...
ECHO.
powershell -command Remove-NetFirewallRule -DisplayName "Block_UDP-138"
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall delete rule name=”Block_UDP-138” dir=in
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall delete portopening protocol=udp port=138
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
	)ELSE (
		ECHO. && ECHO 設置成功!
	)
)ELSE (
	ECHO. && ECHO 設置成功!
)
ECHO.
PAUSE
GOTO MAIN

:Is_Exist_Port_137
ECHO 檢查防火牆是否已有設置137規則中...
powershell -command Get-NetFirewallRule -DisplayName "Block_UDP-137" > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 確認不存在規則! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO 確認已經存在規則!) 
EXIT /B

:Is_Exist_Port_138
ECHO 檢查防火牆是否已有設置138規則中...
powershell -command Get-NetFirewallRule -DisplayName "Block_UDP-138" > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 確認不存在規則! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO 確認已經存在規則!)
EXIT /B

::REM ==================================================Check_TCP_UDP_Port=================================================

:Check_TCP_UDP
CLS
ECHO.
ECHO =======================================================
ECHO.
SET /P Check-Port="請輸入要監看的連接埠(輸入Q返回主選單;輸入E離開;不輸入顯示所有連接埠): "
IF /I "%Check-Port%" EQU "Q" (
	GOTO MAIN
)ELSE IF /I "%Check-Port%" EQU "E" (
	GOTO Exit
)ELSE IF "%Check-Port%" EQU "" (
	SET RUN=^| findstr LISTEN
)ELSE (
	SET RUN=^| findstr LISTEN ^| findstr "%Check-Port%"
)
ECHO.
ECHO  協定    本機位址               外部位址               狀態            PID
netstat -ano %RUN%
IF %ERRORLEVEL% NEQ 0 (
	ECHO. && ECHO 目前沒有此連接埠 && ECHO. && PAUSE && GOTO Check_TCP_UDP
)ELSE (
	ECHO. && PAUSE && GOTO Check_TCP_UDP
)

::REM =========================================================EXIT========================================================

:Exit
ECHO.
ECHO.
PAUSE
EXIT

