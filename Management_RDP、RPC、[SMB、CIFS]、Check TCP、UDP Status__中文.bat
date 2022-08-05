set "params=%*" && cd /d "%CD%" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/C cd ""%CD%"" && %~s0 %params%", "", "runas", 1 >>"%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )
@ECHO OFF
TITLE Close [TCP_139、445]、[UDP_137、138](Administrator)

GOTO MAIN

:MAIN
CLS
ECHO.
ECHO ==============================================================
ECHO                            選擇功能
ECHO ==============================================================
ECHO.
ECHO --------------------------------------------------------------
ECHO [1] 管理RDP(Remote Desktop Services)服務
ECHO [2] 管理RPC(Remote Procedure Call)服務
ECHO [3] 管理NetBios(NetBIOS over TCP/IP)服務
ECHO [4] 管理SMB(Server Message Block)[NetBios] UDP_137、138 Port
ECHO [5] 管理SMB(Server Message Block) TCP_139[NetBios]、445 Port
ECHO [6] 管理SMBv1、SMBv2、SMBv3
ECHO [7] 查看TCP/UDP連接埠狀態
ECHO --------------------------------------------------------------
ECHO.
CHOICE /C 7654321 /N /M "選擇功能[1~7]: "
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
CHOICE /C 4321 /N /M "[1]更改RDP連接埠 [2]關閉RDP服務 [3]開啟RDP服務 [4]返回主選單: "
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
CHOICE /C ENY /N /M "是否更改連接埠( [Y]更改 [N]返回 [E]離開 ): "
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
SET /P RDP-Port="請輸入新的連接埠(1001~254535)(按下Enter使用默認埠3389)[B/b:返回]: "
IF NOT DEFINED RDP-Port (
	SET RDP-Port=3389
)ELSE IF /I "%RDP-Port%" EQU "B" (
	GOTO RDP_Info
)
CALL :Check_Port_Scope %RDP-Port% REM 確認連接埠輸入是否正確
IF "%Scope%"=="False" (
	ECHO.
	PAUSE
	GOTO Change-RDP_Port-Ask
)
ECHO.
GOTO Change-RDP_Port

:Change-RDP_Port
ECHO --------------------------------------------
ECHO 更改連接埠中...
ECHO.
Powershell -command Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "PortNumber" -Value %RDP-Port%
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 更改失敗! )ELSE (ECHO. && ECHO 更改成功! )
ECHO.
GOTO RDP_TCP

:RDP_TCP
ECHO --------------------------------------------
ECHO [1/2]設置防火牆規則中[TCP]...
ECHO.
CALL :Check_Rule RDPPORTLatest-TCP-In
IF %ERRORLEVEL% NEQ 0 (
	ECHO. && ECHO 確認未建立規則，建立中...
)ELSE (
	ECHO. && ECHO 已建立規則，更新中... && ECHO.
	Powershell -command Remove-NetFirewallRule -DisplayName "RDPPORTLatest-TCP-In"
)
ECHO.
Powershell -command New-NetFirewallRule -DisplayName 'RDPPORTLatest-TCP-In' -Profile 'Public' -Direction Inbound -Action Allow -Protocol TCP -LocalPort %RDP-Port%
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗! )ELSE (ECHO. && ECHO 設置成功! )
ECHO.
GOTO RDP_UDP

:RDP_UDP
ECHO --------------------------------------------
ECHO [2/2]設置防火牆規則中[UDP]...
ECHO.
CALL :Check_Rule RDPPORTLatest-UDP-In
IF %ERRORLEVEL% NEQ 0 (
	ECHO. && ECHO 確認未建立規則，建立中...
)ELSE (
	ECHO. && ECHO 已建立規則，更新中... && ECHO.
	Powershell -command Remove-NetFirewallRule -DisplayName "RDPPORTLatest-UDP-In"
)
ECHO.
Powershell -command New-NetFirewallRule -DisplayName 'RDPPORTLatest-UDP-In' -Profile 'Public' -Direction Inbound -Action Allow -Protocol UDP -LocalPort %RDP-Port%
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗! )ELSE (ECHO. && ECHO 設置成功! )
ECHO.
GOTO Show_RDP_Port

:Show_RDP_Port
ECHO --------------------------------------------
Powershell -command '更改後的RDP連接埠:'+("Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "PortNumber" | Select-Object -ExpandProperty PortNumber")
ECHO.
PAUSE
GOTO RDP_Info

::REM ====================================Close-RDP_Service==================================

:Close-RDP_Service-REG-A
ECHO --------------------------------------------
ECHO 修改註冊值fDenyTSConnections[SYSTEM]，關閉遠端服務中...
ECHO.
CALL :Is_Exist_fDenyTS_Entries REM 檢查註冊表fDenyTSConnections項目是否存在
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO 關閉遠端服務協定中...
	ECHO.
	powershell -command Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value "1"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
)
ECHO.
GOTO Close-RDP_Firewall

:Close-RDP_Service-REG-B
ECHO --------------------------------------------
ECHO 修改註冊值fDenyTSConnections[SOFTWARE]，關閉遠端服務中...
ECHO.
CALL :Is_Exist_fDenyTS_Entries-B
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO 關閉遠端服務協定中...
	ECHO.
	powershell -command Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name "fDenyTSConnections" -Value "1"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
)
ECHO.
GOTO Close-RDP_Firewall

:Close-RDP_Firewall
ECHO --------------------------------------------
ECHO 關閉遠端服務通過防火牆...
netsh advfirewall firewall set rule group="Remote Desktop" new enable=No
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	ECHO 非英文語系，使用繁體中文語系
	ECHO.
	netsh advfirewall firewall set rule group="遠端桌面" new enable=No
)
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	ECHO 關閉失敗，可能為名稱錯誤!
)ELSE (
	ECHO.
	ECHO 設置成功!
	ECHO.
)
ECHO.
GOTO Close-RDP_Service

:Close-RDP_Service
ECHO --------------------------------------------
ECHO [1/12]關閉遠端服務中[Termservice]...
ECHO.
Sc stop Termservice
CALL :Result_Service_Close_A
ECHO.
ECHO --------------------------------------------
ECHO [2/12]設置停用中...
ECHO.
Sc config Termservice start=disabled
CALL :Result_Service_Close_B
ECHO.
ECHO --------------------------------------------
ECHO [3/12]關閉遠端服務中[SessionEnv]...
ECHO.
sc stop SessionEnv
CALL :Result_Service_Close_A
ECHO.
ECHO --------------------------------------------
ECHO [4/12]設置停用中...
ECHO.
sc config SessionEnv start=disabled
CALL :Result_Service_Close_B
ECHO.
ECHO --------------------------------------------
ECHO [5/12]關閉遠端服務中[UmRdpService]...
ECHO.
sc stop UmRdpService
CALL :Result_Service_Close_A
ECHO.
ECHO --------------------------------------------
ECHO [6/12]設置停用中...
ECHO.
sc config UmRdpService start=disabled
CALL :Result_Service_Close_B
ECHO.
ECHO --------------------------------------------
ECHO [7/12]關閉遠端服務中[RemoteRegistry]...
ECHO.
sc stop RemoteRegistry
CALL :Result_Service_Close_A
ECHO.
ECHO --------------------------------------------
ECHO [8/12]設置停用中...
ECHO.
sc config RemoteRegistry start=disabled
CALL :Result_Service_Close_B
ECHO.
ECHO --------------------------------------------
ECHO [9/12]關閉遠端服務中[RasMan]...
ECHO.
sc stop RasMan
CALL :Result_Service_Close_A
ECHO.
ECHO --------------------------------------------
ECHO [10/12]設置停用中...
ECHO.
sc config RasMan start=disabled
CALL :Result_Service_Close_B
ECHO.
ECHO --------------------------------------------
ECHO [11/12]關閉遠端服務中[RasAuto]...
ECHO.
sc stop RasAuto
CALL :Result_Service_Close_A
ECHO.
ECHO --------------------------------------------
ECHO [12/12]設置停用中...
ECHO.
sc config RasAuto start=disabled
CALL :Result_Service_Close_B
ECHO.
PAUSE
GOTO RDP_Service_Ask

::REM ====================================Open-RDP_Service===================================

:Open-RDP_Service-REG-A
ECHO --------------------------------------------
ECHO 修改註冊值fDenyTSConnections[SYSTEM]，開啟遠端服務中...
CALL :Is_Exist_fDenyTS_Entries REM 檢查註冊表fDenyTSConnections項目是否存在
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO 啟用遠端服務協定中...
	ECHO.
	powershell -command Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value "0"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
)
ECHO.
GOTO Open-RDP_Firewall

:Open-RDP_Service-REG-B
ECHO --------------------------------------------
ECHO 修改註冊值fDenyTSConnections[SOFTWARE]，開啟遠端服務中...
CALL :Is_Exist_fDenyTS_Entries-B
IF %ERRORLEVEL% NEQ 0 (
	SET ERRORLEVEL=
)ELSE (
	ECHO.
	ECHO 啟用遠端服務協定中...
	ECHO.
	powershell -command Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name "fDenyTSConnections" -Value "0"
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
)
ECHO.
GOTO Open-RDP_Firewall

:Open-RDP_Firewall
ECHO --------------------------------------------
ECHO 開啟遠端服務通過防火牆...
Netsh advfirewall firewall set rule group="remote desktop" new enable=Yes
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	ECHO 非英文語系，使用繁體中文語系
	ECHO.
	netsh advfirewall firewall set rule group="遠端桌面" new enable=Yes
)
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	ECHO 開啟失敗，可能為名稱錯誤!
)ELSE (
	ECHO.
	ECHO 設置成功!
	ECHO.
)
ECHO.
GOTO Open-RDP_Service

:Open-RDP_Service
ECHO --------------------------------------------
ECHO [1/12]將遠端服務設置手動中[Termservice]...
ECHO.
Sc config Termservice start=demand
CALL :Result_Service_Active_B
ECHO.
ECHO --------------------------------------------
ECHO [2/12]啟用遠端服務中...
ECHO.
Sc start Termservice
CALL :Result_Service_Active_A
ECHO.
ECHO --------------------------------------------
ECHO [3/12]將遠端服務設置手動中[SessionEnv]...
ECHO.
sc config SessionEnv start=demand
CALL :Result_Service_Active_B
ECHO.
ECHO --------------------------------------------
ECHO [4/12]啟用遠端服務中...
ECHO.
sc start SessionEnv
CALL :Result_Service_Active_A
ECHO.
ECHO --------------------------------------------
ECHO [5/12]將遠端服務設置手動中[UmRdpService]...
ECHO.
sc config UmRdpService start=demand
CALL :Result_Service_Active_B
ECHO.
ECHO --------------------------------------------
ECHO [6/12]啟用遠端服務中...
ECHO.
sc start UmRdpService
CALL :Result_Service_Active_A
ECHO.
ECHO --------------------------------------------
ECHO [7/12]將遠端服務設置手動中[RemoteRegistry]...
ECHO.
sc config RemoteRegistry start=demand
CALL :Result_Service_Active_B
ECHO.
ECHO --------------------------------------------
ECHO [8/12]啟用遠端服務中...
ECHO.
sc start RemoteRegistry
CALL :Result_Service_Active_A
ECHO.
ECHO --------------------------------------------
ECHO [9/12]將遠端服務設置手動中[RasMan]...
ECHO.
sc config RasMan start=demand
CALL :Result_Service_Active_B
ECHO.
ECHO --------------------------------------------
ECHO [10/12]啟用遠端服務中...
ECHO.
sc start RasMan
CALL :Result_Service_Active_A
ECHO.
ECHO --------------------------------------------
ECHO [11/12]將遠端服務設置手動中[RasAuto]...
ECHO.
sc config RasAuto start=demand
CALL :Result_Service_Active_B
ECHO.
ECHO --------------------------------------------
ECHO [12/12]啟用遠端服務中...
ECHO.
sc start RasAuto
CALL :Result_Service_Active_A
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
ECHO 目前RPC(135)的連接埠狀態:
ECHO.
ECHO  協定    本機位址               外部位址               狀態            PID
CALL :Check_Port 135
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 未有連接狀態!)
ECHO.
GOTO RPC_Ask

:RPC_Ask
ECHO.
CHOICE /C 321 /N /M "[1]關閉RPC [2]開啟RPC [3]返回主選單: "
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
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 確認未建立規則，建立中... && ECHO.)ELSE (ECHO. && ECHO 已建立規則，無須建立! && ECHO. && PAUSE && GOTO RPC_Info)
powershell -command New-NetFirewallRule -DisplayName "Block_RPC-TCP-135-In" -Direction Inbound -LocalPort 135 -Action Block -Protocol TCP
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall add rule name="Block_RPC-TCP-135-In" dir=in protocol=tcp localport=135 action=block
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall set portopening protocol=tcp port=135 mode=disable name="Block_RPC-TCP-135-In"
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗! )ELSE (ECHO. && ECHO 設置成功! )
	)ELSE (
		ECHO. && ECHO 設置成功! 
	)
)ELSE (
	ECHO. && ECHO 設置成功! 
)
EXIT /B

:RPC_Open
CALL :Check_Rule Block_RPC-TCP-135-In
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 未建立規則，無須移除! && ECHO. && PAUSE && GOTO RPC_Info)
powershell -command Remove-NetFirewallRule -DisplayName "Block_RPC-TCP-135-In"
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	netsh advfirewall firewall delete rule name="Block_RPC-TCP-135-In" dir=in
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		netsh firewall delete portopening protocol=tcp port=135
		IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 移除失敗! )ELSE (ECHO. && ECHO 移除成功! )
	)ELSE (
		ECHO. && ECHO 移除成功!
	)
)ELSE (
	ECHO. && ECHO 移除成功!
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
CHOICE /C 321 /N /M "[1]設置指定介面卡 [2]設置全部介面卡 [3]返回主選單: "
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
SET /P Network_Adapter_Name="請輸入網路介面卡index號碼[B/b:返回]: "
IF NOT DEFINED Network_Adapter_Name (
	ECHO.
	ECHO 尚未輸入!
	ECHO.
	PAUSE
	GOTO NetBIOS_Service_Specific_Ask
)ELSE IF /I "%Network_Adapter_Name%" EQU "B" (
	GOTO NetBIOS_Service_Ask
)
ECHO.
CALL :Check_NetBios_Correct %Network_Adapter_Name% REM 檢查輸入的index號碼是否存在
IF NOT DEFINED Ans (
	ECHO.
	ECHO 輸入的值不存在，請重新輸入!
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
Powershell -command '指定的網路介面卡: '+("wmic nicconfig get Caption,index | find ' %Network_Adapter_Name% '")
ECHO.
ECHO -------------------------------------------------------
CHOICE /C B210 /N /M "請輸入TcpipNetbiosOptions選項[0,1,2][B/b:返回]: "
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
CHOICE /C B210 /N /M "請輸入TcpipNetbiosOptions選項[0,1,2][B/b:返回]: "
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
ECHO 設置中...
ECHO.
WMIC nicconfig where index=%Network_Adapter_Name% call SetTcpipNetbios %~1
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
EXIT /B

:NetBIOS_Service_ALL_SET
ECHO.
ECHO 設置中...
ECHO.
powershell -command $base = 'HKLM:SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces' ; $interfaces = Get-ChildItem $base ^| Select -ExpandProperty PSChildName ; foreach($interface in $interfaces) {Set-ItemProperty -Path "$base\$interface" -Name "NetbiosOptions" -Value "%~1"}
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
EXIT /B


::REM =====================================================================================================================
::REM =============================================Close SMB(NetBIOS)_139、445==============================================
::REM =====================================================================================================================


:NetBIOS_SMB
CLS
ECHO.
ECHO =======================================================
ECHO.
ECHO ---------------------------------------
ECHO 目前SMB(139)的連接埠狀態:
ECHO.
ECHO  協定    本機位址               外部位址               狀態            PID
CALL :Check_Port 139
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 未有連接狀態!)
ECHO.

ECHO ---------------------------------------
ECHO 目前SMB(445)的連接埠狀態:
ECHO.
ECHO  協定    本機位址               外部位址               狀態            PID
CALL :Check_Port 445
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 未有連接狀態! && GOTO Switch_SMB)

:Switch_SMB
ECHO.
ECHO =======================================================
ECHO.
CHOICE /C 4321 /N /M "[1]關閉SMB(139) [2]關閉SMB(445) [3]關閉全部 [4]返回主選單: "
IF ERRORLEVEL 4 (
	GOTO Close_SMB
)ELSE IF ERRORLEVEL 3 (
	GOTO Open_SMB
)ELSE IF ERRORLEVEL 2 (
	GOTO Open_SMB
)ELSE (
	GOTO MAIN
)

:Close_SMB
ECHO.
ECHO =======================================================
ECHO.

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
ECHO [1/2]關閉TCP/IP NetBIOS Helper服務中...
ECHO.
sc stop lmhosts
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO 服務已經關閉!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO 服務已經關閉!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO 關閉服務成功!
)ELSE (
	ECHO.
	ECHO 無法關閉服務!
)

ECHO.
ECHO [2/2]將TCP/IP NetBIOS Helper服務設置禁用中...
ECHO.
sc config lmhosts start=disabled
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)
ECHO.

ECHO [1/2]關閉NetBios服務中...
ECHO.
sc stop netbios
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO 服務已經關閉!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO 服務已經關閉!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO 關閉服務成功!
)ELSE (
	ECHO.
	ECHO 無法關閉服務!
)

ECHO.
ECHO [2/2]將NetBios服務類型設置停用中...
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

ECHO.
ECHO 設置防火牆阻擋139輸入規則中...
ECHO.
CALL :Check_Rule Block_TCP-139
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 確認未建立規則，建立中... && ECHO.)ELSE (ECHO. && ECHO 已建立規則，無須建立! && ECHO. && PAUSE && GOTO Close_Port_445)
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
GOTO Close_Port_445

::REM ========================================Close Port_445======================================

:Close_Port_445
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

ECHO [1/2]關閉lanmanserver服務中...
ECHO.
sc stop lanmanserver
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO 服務已經關閉!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO 服務已經關閉!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO 關閉服務成功!
)ELSE (
	ECHO.
	ECHO 無法關閉服務!
)

ECHO.
ECHO [2/2]將lanmanserver服務設置停用中...
ECHO.
sc config lanmanserver start=disabled
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 無法關閉服務!)ELSE (ECHO. && ECHO 關閉服務成功!)

ECHO.
ECHO 設置防火牆阻擋445輸入規則中...
ECHO.
CALL :Check_Rule Block_TCP-445
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 確認未建立規則，建立中... && ECHO.)ELSE (ECHO. && ECHO 已建立規則，無須建立! && ECHO. && PAUSE && GOTO NetBIOS_SMB)
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
ECHO [1/2]將TCP/IP NetBIOS Helper服務設置手動中...
ECHO.
sc config lmhosts start=demand
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)

ECHO.
ECHO [2/2]開啟TCP/IP NetBIOS Helper服務中...
ECHO.
sc start lmhosts
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO 服務已經開啟!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO 服務已經開啟!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO 開啟服務成功!
)ELSE (
	ECHO.
	ECHO 無法開啟服務!
)

ECHO.
ECHO [1/2]將NetBios服務類型設置開啟中...
ECHO.
sc config netbios start=auto
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗!)ELSE (ECHO. && ECHO 設置成功!)

ECHO.
ECHO [2/2]開啟NetBios服務中...
ECHO.
sc start netbios
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO 服務已經開啟!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO 服務已經開啟!
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


ECHO.
ECHO 移除防火牆阻擋139輸入規則中...
ECHO.
CALL :Check_Rule Block_TCP-139
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 未建立規則，無須移除! && ECHO. && PAUSE && GOTO Open_Port_445)
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
GOTO Open_Port_445

::REM ========================================Open Port_445=======================================

:Open_Port_445
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
	powershell -command Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -Name "TransportBindName" -Value '"\Device"\'
	IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 設置失敗! && ECHO.)ELSE (ECHO. && ECHO 設置成功! && ECHO.)
)

ECHO.
ECHO [1/2]將lanmanserver服務設置啟用中...
ECHO.
sc config lanmanserver start=auto
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 無法開啟服務!)ELSE (ECHO. && ECHO 開啟服務成功!)

ECHO.
ECHO [2/2]開啟lanmanserver服務中...
ECHO.
sc start lanmanserver
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO 服務已經開啟!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO 服務已經開啟!
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
CALL :Check_Rule Block_TCP-445
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 未建立規則，無須移除! && ECHO. && PAUSE && GOTO NetBIOS_SMB)
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

:RDP_Port
Powershell -command '目前RDP的連接埠:'+("Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "PortNumber" | Select-Object -ExpandProperty PortNumber")
EXIT /B

:Is_Exist_fDenyTS_Entries
ECHO 檢查註冊表fDenyTSConnections項目中...
powershell -command Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" ^| findstr fDenyTSConnections > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO Create_fDenyTS_Entries)ELSE (ECHO. && ECHO 確認存在fDenyTSConnections項目!)
EXIT /B

:Is_Exist_fDenyTS_Entries-B
ECHO 檢查註冊表fDenyTSConnections項目中...
powershell -command Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "fDenyTSConnections" ^| findstr fDenyTSConnections > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO Create_fDenyTS_Entries-B)ELSE (ECHO. && ECHO 確認存在fDenyTSConnections項目!)
EXIT /B

:Is_Exist_139_Entries_RA
ECHO 檢查註冊表RestrictAnonymous項目中...
powershell -command Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -name "restrictanonymous" ^| findstr restrictanonymous > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO Create_139_Entries_RA)ELSE (ECHO. && ECHO 確認存在RestrictAnonymous項目!)
EXIT /B

:Is_Exist_139_Entries_ShareServer
ECHO 檢查註冊表AutoShareServer項目中...
powershell -command Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -name "AutoShareServer" ^| findstr AutoShareServer > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO Create_139_Entries_ShareServer)ELSE (ECHO. && ECHO 確認存在AutoShareServer項目!)
EXIT /B

:Is_Exist_139_Entries_ShareWks
ECHO 檢查註冊表AutoShareWks項目中...
powershell -command Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -name "AutoShareWks" ^| findstr AutoShareWks > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO Create_139_Entries_ShareWks)ELSE (ECHO. && ECHO 確認存在AutoShareWks項目!)
EXIT /B

:Is_Exist_445_Entries_SMBD
ECHO 檢查註冊表SMBDeviceEnabled項目中...
powershell -command Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -name "SMBDeviceEnabled" ^| findstr SMBDeviceEnabled > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO Create_445_Entries_SMBD)ELSE (ECHO. && ECHO 確認存在SMBDeviceEnabled項目!)
EXIT /B

:Is_Exist_445_Entries_TB
ECHO 檢查註冊表TransportBindName項目中...
powershell -command Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -name "TransportBindName" ^| findstr TransportBindName > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO Create_445_Entries_TB)ELSE (ECHO. && ECHO 確認存在TransportBindName項目!)
EXIT /B

:Create_fDenyTS_Entries
ECHO.
ECHO 不存在fDenyTSConnections項目，創建中...
ECHO.
powershell -command New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -PropertyType "DWORD" -Value "1"
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 創建失敗，無法啟用遠端桌面連線協定! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO 創建成功!)
EXIT /B

:Create_fDenyTS_Entries-B
ECHO.
ECHO 不存在fDenyTSConnections項目，創建中...
ECHO.
powershell -command New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -name "fDenyTSConnections" -PropertyType "DWORD" -Value "1"
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 創建失敗，無法啟用遠端桌面連線協定! && SET ERRORLEVEL=1)ELSE (ECHO. && ECHO 創建成功!)
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

:Check_NetBios
ECHO 目前各網路介面卡的Netbios啟用狀態:
ECHO.
WMIC nicconfig get caption,index,TcpipNetbiosOptions
ECHO.
ECHO TcpipNetbiosOptions 選項說明:
ECHO.
ECHO 0 = 在DHCP伺服器上啟用NetBios設定
ECHO 1 = 啟用NetBios(NetBIOS over TCP/IP)
ECHO 2 = 禁用NetBios(NetBIOS over TCP/IP)
EXIT /B

:Check_NetBios_Correct
FOR /F %%i in ('wmic nicconfig get index') do IF %%i==%~1 ( SET Ans=True && EXIT /B ) > nul 2>&1
EXIT /B

:Check_Port_Scope
SET "Scope="
IF 1%~1 NEQ +1%~1  (
	ECHO.
	ECHO 請輸入數字!
	ECHO.
	SET Scope=False
	EXIT /B
)
IF %~1 LSS 1001 (
	ECHO.
	ECHO 連接埠小於1001!
	ECHO.
	SET Scope=False
)ELSE IF %~1 GTR 254535 (
	ECHO.
	ECHO 連接埠超過254535!
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

:Result_Service_Close_A
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO 服務已經關閉!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO 服務已經關閉!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO 關閉服務成功!
)ELSE (
	ECHO.
	ECHO 無法關閉服務!
)
EXIT /B

:Result_Service_Active_A
IF %ERRORLEVEL% == 1062 (
	ECHO.
	ECHO 服務已經開啟!
)ELSE IF %ERRORLEVEL% == 1052 (
	ECHO.
	ECHO 服務已經開啟!
)ELSE IF %ERRORLEVEL% == 0 (
	ECHO.
	ECHO 開啟服務成功!
)ELSE (
	ECHO.
	ECHO 無法開啟服務!
)
EXIT /B

:Result_Service_Close_B
IF %ERRORLEVEL% NEQ 0 (
	ECHO. && ECHO 無法停用服務!
)ELSE (
	ECHO. && ECHO 停用服務成功!
)
EXIT /B

:Result_Service_Active_B
IF %ERRORLEVEL% NEQ 0 (
	ECHO. && ECHO 無法設置服務!
)ELSE (
	ECHO. && ECHO 設置成功!
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
CALL :Check_Port 137
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 未有連接狀態!)
ECHO.

ECHO ---------------------------------------
ECHO 目前SMB(138)的連接埠狀態:
ECHO.
ECHO  協定    本機位址               外部位址               狀態            PID
CALL :Check_Port 138
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
	GOTO NetBIOS_UDP
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
GOTO NetBIOS_UDP

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
	GOTO NetBIOS_UDP
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
GOTO NetBIOS_UDP

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
ECHO ==============================================================
ECHO.
SET "Port="
SET "Check-Port="
SET /P Check-Port="請輸入要監看的連接埠( [Q]返回主選單 [E]離開 [A]查看所有連接埠 ): "
IF "%Check-Port%"=="" (
	ECHO. && ECHO 輸入為空，請重新輸入! && ECHO. && PAUSE && GOTO Check_TCP_UDP
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
CHOICE /C 321 /N /M "請選擇協議( [1]TCP [2]UDP [3]ALL ): "
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
ECHO                           選擇連線狀態
ECHO ==============================================================
ECHO.
ECHO 注意:UDP協議，沒有連線狀態，請直接按K選項，否則將無輸出。
ECHO.
ECHO --------------------------------------------------------------
ECHO [A]  LISTEN: 		等待連線中，處於監聽狀態。
ECHO [B]  ESTABLISHED: 	已連線狀態。
ECHO [C]  CLOSING: 		已關閉狀態。
ECHO [D]  TIMED_WAIT: 	我方已主動關閉連線。
ECHO [E]  CLOSE_WAIT: 	對方已主動關閉連線，或網路異常而中斷。
ECHO [F]  FIN_WAIT_1: 
ECHO [G]  FIN_WAIT_2: 
ECHO [H]  LAST_ACK: 
ECHO [I]  SYN_SEND: 	請求連線狀態(Send first SYN)。
ECHO [J]  SYN_RECEIVED: 完成連線的初始狀態，並等待最後確認(Send SYN+ACK，but not receive last ACK)。
ECHO [K]  ALL_State:	顯示全部狀態。
ECHO --------------------------------------------------------------
ECHO.
SET "State="
SET "State_Type="
CHOICE /C KJIHGFEDCBA /N /M "選擇功能[A~K]: "
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
ECHO  協定    本機位址               外部位址               狀態            PID
ECHO.
SET "RUN=%Proto% %Port% %State%"
powershell -command netstat -ano %RUN%
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

