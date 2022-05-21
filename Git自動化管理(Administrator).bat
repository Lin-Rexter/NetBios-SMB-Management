set "params=%*" && cd /d "%CD%" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/C cd ""%CD%"" && %~s0 %params%", "", "runas", 1 >>"%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )
@ECHO OFF
TITLE Git自動化管理工具(Administrator)

:MAIN
CLS
net.exe session 1>NUL 2>NUL && (
    echo ========================已執行管理員權限========================
) || (
    echo ========================未執行管理員權限========================
)

ECHO.
ECHO 目前的執行路徑: "%CD%"

ECHO.
ECHO ==============================================================
ECHO                         選擇Git功能
ECHO ==============================================================
ECHO.
ECHO --------------------------------------------------------------
ECHO [1] 查看Git管控狀態資訊
ECHO [2] 建立Git管控本地端及遠端儲存庫(Repository)
ECHO [3] 切換Git帳號
ECHO [4] Git推送
ECHO [5] 設置SSH-Key(設置金鑰)
ECHO [6] 設置SSH代理(用於管理多個私鑰)
ECHO [7] 測試SSH連接
ECHO [8] 更新Git
ECHO --------------------------------------------------------------
ECHO.
CHOICE /C 7654321 /N /M "選擇Git功能[1~7]: "
IF ERRORLEVEL 7 (
 GOTO Info
)ELSE IF ERRORLEVEL 6 (
 GOTO Create_File_Ask
)ELSE IF ERRORLEVEL 5 (
 GOTO Global-Info
)ELSE IF ERRORLEVEL 4 (
 GOTO rm
)ELSE IF ERRORLEVEL 3 (
 GOTO Show-Key
)ELSE IF ERRORLEVEL 2 (
 GOTO SSH-Agent
)ELSE IF ERRORLEVEL 1 (
 GOTO SSH-Test
)

::REM ===============================查看Git管控狀態資訊================================

:Info
ECHO.
ECHO ====================================================================
ECHO 1.Git版本
Git version
ECHO.
ECHO ------------------------------------------------------------------
ECHO 2.檢視目前工作目錄狀況
Git status
IF %ERRORLEVEL% NEQ 0 (ECHO 錯誤: 目前目錄不存在Git儲存庫)
ECHO.
ECHO ------------------------------------------------------------------
ECHO 3.檢視本地與遠程所有分支
Git branch -a
IF %ERRORLEVEL% NEQ 0 (ECHO 錯誤: 目前目錄不存在Git儲存庫)
ECHO.
ECHO ------------------------------------------------------------------
ECHO 4.檢視提交的歷史記錄
Git log
IF %ERRORLEVEL% NEQ 0 (ECHO 錯誤: 目前目錄不存在Git儲存庫)
GOTO EXIT
::REM ================================建立Git管控儲存庫=================================

:Create_File_Ask
ECHO.
ECHO ====================================================================
ECHO [0/8] ---建立本地儲存庫資料夾---
CHOICE /C YN /N /M "是否建立本地資料夾?(Y/N):"
IF ERRORLEVEL 2 (
 GOTO Upload
)ELSE IF ERRORLEVEL 1 (  
 GOTO Create_File
)

:Create_File
ECHO.
ECHO ====================================================================
ECHO [0/8] ---建立本地儲存庫資料夾---
SET /p "File_Name=請輸入資料夾名稱(Ex: Github_Test):"
mkdir "%File_Name%"
IF %ERRORLEVEL% NEQ 0 (ECHO 資料夾創建失敗! GOTO Create_Filed)ELSE ( GOTO Create_Success)


:Create_File
ECHO.
ECHO 資料夾創建失敗!
GOTO Create_File_Ask


:Create_Success
ECHO.
CD %File_Name%
ECHO 已移動到資料夾下
ECHO 目前的執行路徑: %CD%
GOTO Upload


:Upload
ECHO.
ECHO ====================================================================
ECHO [1/8] ---建立 Markdown 說明文件---
SET /p "Commit=請輸入說明文件的標題(Ex: Practicing):"
ECHO # %Commit% > README.md
IF %ERRORLEVEL% NEQ 0 (ECHO 檔案創建失敗! && GOTO Upload)ELSE (GOTO Init)


:Init
ECHO.
ECHO ====================================================================
ECHO [2/8] ---倉庫初始化，建立本地數據庫，進行版本控制---
ECHO 將進行倉庫初始化，按任意鍵繼續
PAUSE...
Git init
IF %ERRORLEVEL% NEQ 0 (ECHO 倉庫初始化失敗! && GOTO Init)ELSE (GOTO MD)


:Add-Ask
ECHO.
ECHO ====================================================================
ECHO [3/8] ---將檔案加至暫存區---
CHOICE /C 12 /N /M "[1]所有檔案 [2]目錄下及子目錄所有檔案(1,2):"
IF ERRORLEVEL 2 (
 GOTO Add-Current_Directory
)ELSE IF ERRORLEVEL 1 (  
 GOTO Add-All
)


:Add-All
ECHO.
ECHO ====================================================================
ECHO [3/8] ---將所有檔案加至暫存區---
Git add -all
IF %ERRORLEVEL% NEQ 0 (ECHO 檔案加入失敗! && GOTO Add-Ask)ELSE (GOTO Commit)


:Add-Current_Directory
ECHO.
ECHO ====================================================================
ECHO [3/8] ---將目錄下及子目錄所有檔案加至暫存區---
Git add .
IF %ERRORLEVEL% NEQ 0 (ECHO 檔案加入失敗! && GOTO Add-Ask)ELSE (GOTO Commit)


:Commit
ECHO.
ECHO ====================================================================
ECHO [4/8] ---提交說明---
SET /p "Commit=請輸入要提交的說明內容:"
Git commit -m "%Commit%"
IF %ERRORLEVEL% NEQ 0 (ECHO 提交內容失敗! && GOTO Commit)ELSE (GOTO Branch-ASK)


:Branch-ASK
ECHO.
ECHO ====================================================================
ECHO [5/8] ---新增分支---
CHOICE /C YN /N /M "是否新增分支?(Y/N):"
IF ERRORLEVEL 2 (
 GOTO Remote
)ELSE IF ERRORLEVEL 1 (
 GOTO Branch
)


:Branch
ECHO.
ECHO ====================================================================
ECHO [6/8] ---新增分支---
SET /p "Branch_Name=請輸入分支名稱(可使用main):"
Git branch -M "%Branch_Name%"
IF %ERRORLEVEL% NEQ 0 (ECHO 新增分支失敗! && GOTO Branch)ELSE (GOTO Remote)


:Remote
ECHO.
ECHO ====================================================================
ECHO [7/8] ---新增一個遠端數據庫的節點---
SET /p "Remote_name=請輸入數據庫簡稱(Ex: origin):"
SET /p "Remote_Url=請輸入遠端數據庫位置(Ex: https://github.com/user/repo.git):"
Git remote add %Remote_name% %Remote_Url%
IF %ERRORLEVEL% NEQ 0 (ECHO 新增遠程數據庫節點失敗! && GOTO Remote)ELSE (ECHO. && ECHO 遠端數據庫列表: && git remove -v && GOTO Push)


:Push
ECHO.
ECHO ====================================================================
ECHO [8/8] ---將檔案推送至遠端數據庫---
SET /p "Push_Remote_name=請輸入遠端數據庫簡稱(Ex: origin):"
SET /p "Push_Branch_name=請輸入遠端數據庫分支名稱(Ex: main):"
Git push -u %Push_Remote_name% %Push_Branch_name%
IF %ERRORLEVEL% NEQ 0 (ECHO 推送至遠端數據庫失敗! && GOTO Remote)ELSE (ECHO. && ECHO 遠端數據庫列表: && git remove -v && GOTO Push)
GOTO END

:END
ECHO 本地儲存庫與遠端已成功建立關係
PAUSE...

::REM ====================================切換Git帳號====================================

:Global-Info
ECHO.
ECHO ===========================查看全局設定資訊==============================
ECHO.
git config --list --show-origin
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 無法查看全局設定資訊! && pause && GOTO Global-Info)ELSE (GOTO Switch_Account-unset-user.name)

:Switch_Account-unset-user.name
ECHO.
ECHO ========================清除user.name全局設定===========================
ECHO.
git config --global --unset user.name
IF %ERRORLEVEL% NEQ 0 (
	IF %ERRORLEVEL% NEQ 5 (
		ECHO. && ECHO 無法清除User.Name全局設定! && pause && GOTO Switch_Account-unset-user.name
	)ELSE (
		ECHO 成功清除User.Name全局設定! && GOTO Switch_Account-unset-user.email
	)
)ELSE (
	ECHO 成功清除User.Name全局設定! && GOTO Switch_Account-unset-user.email
)

:Switch_Account-unset-user.email
ECHO.
ECHO ========================清除user.name全局設定===========================
ECHO.
git config --global --unset user.email
IF %ERRORLEVEL% NEQ 0 (
	IF %ERRORLEVEL% NEQ 5 (
		ECHO. && ECHO 無法清除User.email全局設定! && pause && GOTO Switch_Account-unset-user.email
	)ELSE (
		ECHO 成功清除User.Name全局設定! && GOTO Switch_Account-Email
	)
)ELSE (
	ECHO 成功清除User.Name全局設定! && GOTO Switch_Account-Email
)

:Switch_Account-Email
ECHO.
ECHO ==========================切換Git帳號[Email]===========================
ECHO.
SET /P Email="[1/2] 請輸入要切換的Github或GitLab帳號Email: "
git config --global user.email "%Email%"
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 請輸入正確帳號Email && pause && GOTO Switch_Account-Email)ELSE (ECHO. && ECHO 切換完畢! && GOTO Switch_Account-Name)

:Switch_Account-Name
ECHO.
ECHO ==========================切換Git帳號[Name]===========================
ECHO.
SET /P Name="[2/2] 請輸入要切換的Github或GitLab帳號名稱: "
git config --global user.name "%Name%"
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 請輸入正確帳號名稱 && pause && GOTO Switch_Account-Name)ELSE (ECHO. && ECHO 切換完畢! && GOTO Switch_Account-Info)

:Switch_Account-Info
ECHO.
ECHO =======================查看更改後的全局設定資訊==========================
ECHO.
git config --list --show-origin
IF %ERRORLEVEL% NEQ 0 (ECHO. && ECHO 無法查看更改後的全局設定資訊! && pause && GOTO Global-Info)ELSE (GOTO EXIT)

::REM =====================================Git推送=======================================

:rm
ECHO.
ECHO ---------清除緩存(解放被鎖定的檔案)---------
ECHO.
TIMEOUT /NOBREAK /T 1 1>nul 2>nul
git rm -r --cached .

:add
ECHO.
ECHO --------------檔案提交到暫存區--------------
ECHO.
git add .

:commit
ECHO.
ECHO -----------------提交訊息-------------------
ECHO.
set /p message="請輸入提交訊息(可按下Enter使用預設 Upgrade):"
ECHO.
git commit -m "%message%"
if %errorlevel% NEQ 0 (git commit -m Upgrade)

:push
ECHO.
ECHO -------------檔案推送到遠端倉庫-------------	
ECHO.
set /p message="請輸入遠端倉庫分支名稱(可按下Enter使用預設 main):"
ECHO.
git push -u origin "%message%"
if %errorlevel% NEQ 0 (git push -u origin main)

::REM ================================SSH-Key(設置金鑰)================================

:SSH-Key-Show-KeyFile
SET Git_Bash="C:\Program Files\Git\bin\bash.exe" --login -i -c
SET Git_Bash2="C:\Program Files\Git\bin\sh.exe" --login -i -c
ECHO.
ECHO ==============================================================
ECHO                       現有SSH金鑰檔案
ECHO ==============================================================
ECHO.
%Git_Bash% "ls -al ~/.ssh"
REM ECHO ls -al ~/.ssh | %Git_Bash% //只適用於單輸出
GOTO SET-Email

:SET-Email
ECHO.
ECHO ==============================================================
ECHO                      SSH金鑰生成資料設定
ECHO ==============================================================
ECHO.
SET /P email="[1/2] 請輸入Github或者GitLab的Email: "
IF %ERRORLEVEL% NEQ 0 (CLS && ECHO 請輸入正確email && GOTO SSH-Key-Show-KeyFile)

:SET-Email
ECHO.
ECHO ==============================================================
ECHO                      SSH金鑰生成資料設定
ECHO ==============================================================
ECHO.
SET /P Key-FileName="[2/2] 請輸入要生成的密鑰文件名稱: "
IF %ERRORLEVEL% NEQ 0 (CLS && ECHO 請輸入正確名稱 && GOTO SSH-Key-Show-KeyFile)ELSE (GOTO Choice_SSH-key)

:Choice_SSH-key
ECHO.
ECHO ==============================================================
ECHO                         SSH密鑰類型
ECHO ==============================================================
ECHO.
ECHO --------------------------------------------------------------
ECHO [1] ED25519(優先)
ECHO [2] RSA(其次)
ECHO --------------------------------------------------------------
ECHO.
CHOICE /C 21 /N /M "選擇加密類型[1,2]: "
IF ERRORLEVEL 2 (
 GOTO ED25519
)ELSE IF ERRORLEVEL 1 (
 GOTO RSA
)

:ED25519
ECHO.
ECHO ==============================================================
ECHO.
ECHO 選擇加密類型: ED25519
ECHO.
%Git_Bash% "ssh-keygen -t ed25519 -N '' -f id_ed25519_"%Key-FileName%" -C "%email%""
IF %ERRORLEVEL% NEQ 0 (GOTO FAIL-ED25519)ELSE (GOTO EXIT)

:RSA
ECHO.
ECHO ==============================================================
ECHO.
ECHO 選擇加密類型: RSA
ECHO.
%Git_Bash% "ssh-keygen -t rsa -b 4096 -C "%email%""
IF %ERRORLEVEL% NEQ 0 (GOTO FAIL-RSA)ELSE (GOTO EXIT)

:FAIL-ED25519
ECHO.
ECHO ==============================================================
ECHO.
ECHO ED25519加密失敗!
CHOICE /C NY /N /M "是否選擇RSA加密[Y,N]: "
IF ERRORLEVEL 2 (
 GOTO RSA
)ELSE IF ERRORLEVEL 1 (
 GOTO EXIT
)

:FAIL-RSA
ECHO.
ECHO ==============================================================
ECHO.
ECHO RSA加密失敗!
CHOICE /C NY /N /M "是否選擇ED25519加密[Y,N]: "
IF ERRORLEVEL 2 (
 GOTO ED25519
)ELSE IF ERRORLEVEL 1 (
 GOTO EXIT
)

::REM ====================================SSH-Agent====================================

:SSH-Agent-Show-SSHFile
ECHO.
ECHO ==============================================================
ECHO                        現有SSH金鑰檔案
ECHO ==============================================================
ECHO.
%Git_Bash% "ls -al ~/.ssh"
GOTO SSH-Agent

:SET-Email
ECHO.
ECHO ==============================================================
ECHO                      	   資料設定
ECHO ==============================================================
ECHO.
SET /P SSH-FileName="請輸入要的金鑰檔名: "
IF %ERRORLEVEL% NEQ 0 (CLS && ECHO 請輸入正確金鑰檔名 && GOTO SSH-Agent-Show-SSHFile && GOTO SSH-Agent)

:SSH-Agent
CLS
ECHO.
ECHO ====================啟動SSH代理並添加SSH私鑰=====================
ECHO.
%Git_Bash% "eval `ssh-agent -s`" || "ssh-add ~/.ssh/%SSH-FileName%"
IF %ERRORLEVEL% NEQ 0 (GOTO FAIL-SSH-Agent)

:FAIL-SSH-Agent
ECHO.
ECHO ==============================================================
ECHO.
ECHO 啟動SSH代理失敗或是SSH密鑰添加失敗
GOTO EXIT

::REM ====================================測試SSH連接====================================

:SSH-Test
ECHO.
ECHO ==========================測試SSH連接===========================
ECHO.
SET /P Host-Name="請輸入要連線的主機名稱(Ex: github.com or github-B11056051): "
ECHO.
ECHO 如果出現警告訊息，請鍵入Yes。
ECHO.
%Git_Bash% "ssh -T git@"%Host-Name%""
IF %ERRORLEVEL% NEQ 0 (GOTO FAIL-SSH-Test)ELSE (GOTO EXIT)

:FAIL-SSH-Test
ECHO.
ECHO ==============================================================
ECHO.
ECHO 測試SSH連接失敗，請確認主機名稱是否有誤或是未將公鑰新增到Github或是GitLab帳號上!
GOTO SSH-Agent-B

::REM ======================================安裝Git======================================

:Install-Git-Choose
CLS
ECHO.
ECHO ==============================================================
ECHO                         安裝Git選項
ECHO ==============================================================
ECHO.
ECHO --------------------------------------------------------------
ECHO [1] 進入官網下載
ECHO [2] 下載源文件(Github)
ECHO [3] 使用Winget工具(Windows)
ECHO [4] 使用Choco(Chocolatey)
ECHO --------------------------------------------------------------

:Install-Official
ECHO.
ECHO ===========================安裝Git============================
ECHO.
ECHO 開啟官網中...
Start "" "https://git-scm.com/download/win"
IF %ERRORLEVEL% NEQ 0(GOTO FAIL-Install-Official)ELSE (GOTO Update-Git-Finish)

:Install-Source
ECHO.
ECHO ========================安裝Git源文件==========================
ECHO.
ECHO 開啟網址中...
Start "" "https://github.com/git-for-windows/git/releases"
IF %ERRORLEVEL% NEQ 0(GOTO FAIL-Install-Official)ELSE (GOTO Update-Git-Finish)

:Install-Winget
Call :Confirm-Winget REM 檢查Winget是否安裝
ECHO.
ECHO =======================使用Winget安裝Git=======================
ECHO.
ECHO 安裝中...
ECHO.
Winget install --id Git.Git -e --source winget
IF %ERRORLEVEL% NEQ 0(GOTO FAIL-Install-Winget)ELSE (GOTO Update-Git-Finish)

:Install-Choco
Call :Confirm-Choco REM 檢查Chocolatey是否安裝
ECHO.
ECHO =======================使用Choco安裝Git========================
ECHO.
ECHO 安裝中...
ECHO.
Choco install git
IF %ERRORLEVEL% NEQ 0(GOTO FAIL-Install-Choco)ELSE (GOTO Update-Git-Finish)

:FAIL-Install-Official_AND_Source
ECHO.
ECHO ==============================================================
ECHO.
CHOICE /C NY /N /M "開啟失敗!網址可能已更改，是否回到選單使用其他方式下載[Y,N]? : "
IF ERRORLEVEL 2 (
 GOTO Install-Git-Choose
)ELSE IF ERRORLEVEL 1 (
 GOTO Finish-Back
)

:FAIL-Install-Winget
ECHO.
ECHO ==============================================================
ECHO.
CHOICE /C NY /N /M "安裝失敗! 是否回到選單使用其他方式下載[Y,N]? : "
IF ERRORLEVEL 2 (
 GOTO Install-Git-Choose
)ELSE IF ERRORLEVEL 1 (
 GOTO Finish-Back
)

:Install-Git-Finish
ECHO.
ECHO ==============================================================
ECHO.
CHOICE /C NY /N /M "安裝失敗! 是否回到選單使用其他方式下載[Y,N]? : "
IF ERRORLEVEL 2 (
 GOTO Install-Git-Choose
)ELSE IF ERRORLEVEL 1 (
 GOTO Finish-Back
)

:Install-Git-Finish
ECHO.
ECHO ==============================================================
ECHO. 
ECHO 安裝成功! 版本為:
Git version
ECHO 安裝位置:
Where.exe Git
GOTO Finish-Back

::REM ====================================安裝Winget=====================================

:Install-Winget
ECHO.
ECHO ==========================安裝Winget==========================
ECHO.
ECHO 安裝中...

::REM ======================================更新Git======================================

:Update-Git-Ask
CLS
Call :Confirm-Git REM 檢查Git是否安裝
ECHO.
ECHO ===========================更新Git============================
ECHO.
ECHO 目前的版本為:
Git version
ECHO 最新的版本為:
Winget search --id Git.Git -e --source winget
ECHO.
CHOICE /C NY /N /M "是否進行更新[Y,N]?: "
IF ERRORLEVEL 2 (
 GOTO Update-Git-Choose
)ELSE IF ERRORLEVEL 1 (
 GOTO Finish-Back
)

:Update-Git-Choose
CLS
ECHO.
ECHO ==============================================================
ECHO                         更新Git選項
ECHO ==============================================================
ECHO.
ECHO --------------------------------------------------------------
ECHO [1] 使用Git內建指令更新
ECHO [2] 使用Winget工具(Windows)
ECHO [3] 使用Choco(Chocolatey)
ECHO --------------------------------------------------------------
CHOICE /C 321 /N /M "請選擇更新方式[1,2,3]: "
IF ERRORLEVEL 3 (
 GOTO Update-Git-Git
)ELSE IF ERRORLEVEL 2 (
 Call :Confirm-Winget REM 檢查Winget是否安裝
 GOTO Update-Git-Winget
)ELSE IF ERRORLEVEL 1 (
 Call :Confirm-Choco REM 檢查Chocolatey是否安裝
 GOTO Update-Git-Choco
)

:Update-Git-Git
ECHO.
ECHO =========================使用Git更新===========================
ECHO.
ECHO 更新中...
ECHO.
Git update-git-for-windows
IF %ERRORLEVEL% == 0(GOTO Update-Git-Finish)
ECHO.
ECHO.
Git update
IF %ERRORLEVEL% NEQ 0(GOTO FAIL-Update-Git-Back)ELSE (GOTO Update-Git-Finish)

:Update-Git-Winget
ECHO.
ECHO ========================使用Winget更新=========================
ECHO.
ECHO 更新中...
ECHO.
Winget upgrade --id Git.Git -e --source winget
IF %ERRORLEVEL% NEQ 0(GOTO FAIL-Update-Git-Back)ELSE (GOTO Update-Git-Finish)

:Update-Git-Choco
ECHO.
ECHO ========================使用Choco更新==========================
ECHO.
ECHO 更新中...
ECHO.
Choco upgrade git
IF %ERRORLEVEL% NEQ 0(GOTO FAIL-Update-Git-Back)ELSE (GOTO Update-Git-Finish)

:FAIL-Update-Git-Back
ECHO.
ECHO ==============================================================
ECHO.
CHOICE /C NY /N /M "安裝失敗! 是否回到選單使用其他方式下載[Y,N]? : "
IF ERRORLEVEL 2 (
 GOTO Update-Git-Choose
)ELSE IF ERRORLEVEL 1 (
 GOTO Finish-Back
)

:Update-Git-Finish
ECHO.
ECHO ==============================================================
ECHO. 
ECHO 更新成功! 版本為:
Git version
GOTO Finish-Back

::REM ===================================檢查是否安裝=====================================

:Confirm-Git
Git --help > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO FAIL-Confirm-Git)
EXIT /B

:Confirm-Winget
Winget -? > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO FAIL-Confirm-Winget)
EXIT /B

:Confirm-Choco
Choco help > nul 2>&1
IF %ERRORLEVEL% NEQ 0 (GOTO FAIL-Confirm-Choco)
EXIT /B

:FAIL-Confirm-Git
ECHO.
ECHO ==============================================================
ECHO.
CHOICE /C NY /N /M "未安裝Git，是否進行安裝程序? : "
IF ERRORLEVEL 2 (
 GOTO Install-Git
)ELSE IF ERRORLEVEL 1 (
 GOTO Finish-Back
)

:FAIL-Confirm-Winget
ECHO.
ECHO ==============================================================
ECHO.
CHOICE /C NY /N /M "未安裝Winget，是否進行安裝程序(Windows10 1709(組建 16299)以上才支援Winget)? : "
IF ERRORLEVEL 2 (
 GOTO Install-Winget
)ELSE IF ERRORLEVEL 1 (
 GOTO Finish-Back
)

:FAIL-Confirm-Choco
ECHO.
ECHO ==============================================================
ECHO.
CHOICE /C NY /N /M "未安裝Chocolatey，是否進行安裝程序? : "
IF ERRORLEVEL 2 (
 GOTO Install-Chocolatey
)ELSE IF ERRORLEVEL 1 (
 GOTO Finish-Back
)

::REM =====================================Finish========================================

:Finish-Back
ECHO.
ECHO ==============================================================
ECHO. 
CHOICE /C NY /N /M "是否回到主選單[Y,N]?: "
IF ERRORLEVEL 2 (
 GOTO MAIN
)ELSE IF ERRORLEVEL 1 (
 GOTO EXIT
)

:EXIT
ECHO.
ECHO.
PAUSE
EXIT
