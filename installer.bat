@echo off
setlocal EnableExtensions EnableDelayedExpansion
title BestFreeSoftwareCo Macro Installer

set "COMPANY=BestFreeSoftwareCo"
set "BOOT_LOGFILE=%TEMP%\BestFreeSoftwareCoInstaller.log"
set "LOGFILE=%BOOT_LOGFILE%"
set "WORKDIR=%TEMP%\BestFreeSoftwareCoInstaller_%RANDOM%%RANDOM%"
set "GITHUB_OWNER=BestFreeSoftwareCo"
set "INSTALLER_VERSION=mainv1"
set "UPDATE_OWNER=BestFreeSoftwareCo"
set "UPDATE_REPO=Main-Macro-Installer"
set "PYTHON_URL=https://www.python.org/ftp/python/3.12.3/python-3.12.3-amd64.exe"
set "AUTOIT_URL=https://www.autoitscript.com/cgi-bin/getfile.pl?autoit3/autoit-v3-setup.exe"

call :AdminCheck
if errorlevel 1 exit /b 1

call :Init
if errorlevel 1 goto Fatal

call :SelfUpdateCheck
if errorlevel 2 goto End

call :Header

call :DepsMenu
if errorlevel 1 goto Fatal

call :MacroMenu
if errorlevel 1 goto Fatal

call :LocationMenu
if errorlevel 1 goto Fatal

call :InstallMacro
if errorlevel 1 goto Fatal

call :Completion
goto End

:Fatal
call :PreserveLogForFailure
call :Log "ERROR: Installer terminated due to an unexpected error."
echo.
echo ========================================
echo  Installation Failed
echo ========================================
echo.
echo Please check the log for details:
echo %LOGFILE%
echo.
call :CleanupPartial
call :Cleanup
pause
exit /b 1

:End
call :Cleanup
exit /b 0

:AdminCheck
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); if ($p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }" >nul 2>&1
if %errorlevel%==0 exit /b 0
cls
echo ========================================
echo  Administrator Permissions Required
echo ========================================
echo This installer must be run as Administrator.
echo.
echo How to fix this:
echo 1. Close this window
echo 2. Right-click installer.bat
echo 3. Click "Run as administrator"
echo 4. Press "Yes" when prompted
echo.
echo Tip: Hold SHIFT, right-click for more options.
echo.
pause
exit /b 1

:Init
if not exist "%WORKDIR%" mkdir "%WORKDIR%" >nul 2>&1
if errorlevel 1 exit /b 1
> "%LOGFILE%" echo [%date% %time%] %COMPANY% Installer started
set "DEP_PY_INSTALLED=0"
set "DEP_AUTOIT_INSTALLED=0"
set "DEP_SUMMARY=None"
set "INSTALLED_ITEMS=0"
set "INSTALL_ROOT="
set "TARGET_DIR="
set "MACRO_NAME="
set "MACRO_REPO="
set "DL_TAG="
set "LAST_RELEASE_TAG="
exit /b 0

:Header
cls
echo ========================================
echo        BestFreeSoftwareCo Installer
echo ========================================
echo Visit https://bestfreesoftwareco.github.io/ for news, guides, and updates.
echo.
exit /b 0

:DepsMenu
cls
call :Header
echo Installing both dependencies ensures all macros run properly.
echo.
echo Recommended Dependencies:
echo [1] Install Python 3.12 (Recommended)
echo [2] Install AutoIt Latest Version (Recommended)
echo [3] Skip Dependencies
echo [4] Install Both (Python + AutoIt) (Recommended)
echo.
:DepsPrompt
set "DEPINPUT="
set "DEP_PY=0"
set "DEP_AUTOIT=0"
set "DEP_SKIP=0"
set /p "DEPINPUT=Type numbers to install (comma-separated, e.g. 1,2): "
set "DEPINPUT=%DEPINPUT:,= %"
if "%DEPINPUT%"=="" goto DepsPrompt
for %%A in (%DEPINPUT%) do (
  if "%%A"=="1" set "DEP_PY=1"
  if "%%A"=="2" set "DEP_AUTOIT=1"
  if "%%A"=="3" set "DEP_SKIP=1"
  if "%%A"=="4" (
    set "DEP_PY=1"
    set "DEP_AUTOIT=1"
  )
)
if %DEP_SKIP%==1 (
  call :Log "Dependencies skipped by user."
  set "DEP_SUMMARY=None"
  exit /b 0
)
if %DEP_PY%==0 if %DEP_AUTOIT%==0 if %DEP_SKIP%==0 (
  echo.
  echo Invalid input. Please try again.
  echo.
  goto DepsPrompt
)

if %DEP_PY%==1 (
  call :InstallPython
  if errorlevel 1 (
    call :DepInstallFailed "Python 3.12"
    if errorlevel 1 exit /b 1
  )
)

if %DEP_AUTOIT%==1 (
  call :InstallAutoIt
  if errorlevel 1 (
    call :DepInstallFailed "AutoIt"
    if errorlevel 1 exit /b 1
  )
)

set "DEP_SUMMARY="
if %DEP_PY_INSTALLED%==1 set "DEP_SUMMARY=Python 3.12"
if %DEP_AUTOIT_INSTALLED%==1 (
  if not "%DEP_SUMMARY%"=="" (
    set "DEP_SUMMARY=%DEP_SUMMARY%, AutoIt"
  ) else (
    set "DEP_SUMMARY=AutoIt"
  )
)
if not defined DEP_SUMMARY set "DEP_SUMMARY=None"

call :Log "Dependency summary: %DEP_SUMMARY%"
exit /b 0

:DepInstallFailed
set "DEPFAIL_NAME=%~1"
call :Log "ERROR: Dependency install failed for %DEPFAIL_NAME%."
echo.
echo ----------------------------------------
echo Dependency installation failed: %DEPFAIL_NAME%
echo.
echo Continue anyway? (Y/N)
set /p "CONTDEP=> "
if /i "%CONTDEP%"=="Y" exit /b 0
exit /b 1

:InstallPython
call :Log "Python install requested."
py -3.12 -V >nul 2>&1
if %errorlevel%==0 (
  call :Log "Python 3.12 already present."
  set "DEP_PY_INSTALLED=1"
  exit /b 0
)

call :CheckInternet
if errorlevel 1 exit /b 1

set "PYFILE=%WORKDIR%\python-3.12.3-amd64.exe"
call :Log "Downloading Python from %PYTHON_URL%"
call :DownloadFile "%PYTHON_URL%" "%PYFILE%" "Python"
if errorlevel 1 exit /b 1

call :Log "Running Python installer."
"%PYFILE%" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 >> "%LOGFILE%" 2>&1
if errorlevel 1 exit /b 1

set "DEP_PY_INSTALLED=1"
call :Log "Python install completed."
exit /b 0

:InstallAutoIt
call :Log "AutoIt install requested."
if exist "%ProgramFiles(x86)%\AutoIt3\AutoIt3.exe" (
  call :Log "AutoIt already present (%ProgramFiles(x86)%\AutoIt3)."
  set "DEP_AUTOIT_INSTALLED=1"
  exit /b 0
)
if exist "%ProgramFiles%\AutoIt3\AutoIt3.exe" (
  call :Log "AutoIt already present (%ProgramFiles%\AutoIt3)."
  set "DEP_AUTOIT_INSTALLED=1"
  exit /b 0
)

call :CheckInternet
if errorlevel 1 exit /b 1

set "AIFILE=%WORKDIR%\autoit-v3-setup.exe"
call :Log "Downloading AutoIt from %AUTOIT_URL%"
call :DownloadFile "%AUTOIT_URL%" "%AIFILE%" "AutoIt"
if errorlevel 1 exit /b 1

call :Log "Running AutoIt installer (silent)."
"%AIFILE%" /S >> "%LOGFILE%" 2>&1
if errorlevel 1 exit /b 1

set "DEP_AUTOIT_INSTALLED=1"
call :Log "AutoIt install completed."
exit /b 0

:MacroMenu
:MacroMenuStart
cls
call :Header
echo What would you like to install?
echo.
echo [1] Rivals AFK Macro                (Released)
echo [2] Adopt Me Task Macro             (Released)
echo [3] Macro Creator                   (Released)
echo [4] Forge Auto Mine Macro           (Released)
echo [5] Grow A Garden Auto Buy          (Unreleased - Check Discord)
echo [6] Plants Vs Brainrots Auto Buy    (Unreleased - Check Discord)
echo [7] 99 Nights Auto Eat              (Unreleased - Check Discord)
echo [8] Auto Clicker                    (Unreleased - Check Discord)
echo [9] Blade Ball Playtime Macro       (Unreleased - Check Discord)
echo.
set /p "MACROSEL=Type the number of what you would like to install: "
for /f "tokens=* delims= " %%A in ("%MACROSEL%") do set "MACROSEL=%%A"

if "%MACROSEL%"=="1" (
  set "MACRO_NAME=Rivals AFK Macro"
  set "MACRO_REPO=Rivals-Afk-Macro"
  exit /b 0
)
if "%MACROSEL%"=="2" (
  set "MACRO_NAME=Adopt Me Task Macro"
  set "MACRO_REPO=Adopt-Me-Task-Macro"
  exit /b 0
)
if "%MACROSEL%"=="3" (
  set "MACRO_NAME=Macro Creator"
  set "MACRO_REPO=Macro-Creator"
  exit /b 0
)
if "%MACROSEL%"=="4" (
  set "MACRO_NAME=Forge Auto Mine Macro"
  set "MACRO_REPO=Forge-Macro---Auto-Mine-v1-"
  exit /b 0
)

if "%MACROSEL%"=="5" goto UnreleasedMacro
if "%MACROSEL%"=="6" goto UnreleasedMacro
if "%MACROSEL%"=="7" goto UnreleasedMacro
if "%MACROSEL%"=="8" goto UnreleasedMacro
if "%MACROSEL%"=="9" goto UnreleasedMacro

echo.
echo Invalid input. Please try again.
pause
goto MacroMenuStart

:UnreleasedMacro
echo.
echo This macro is not released yet. Please check the official Discord for updates.
echo.
pause
goto MacroMenuStart

:LocationMenu
:LocationMenuStart
cls
call :Header
echo Where would you like to install it?
echo.
echo [1] Desktop
echo [2] Downloads
echo [3] Documents
echo [4] Custom Path
echo.
set /p "LOCSEL=Type the number of the install location: "
for /f "tokens=* delims= " %%A in ("%LOCSEL%") do set "LOCSEL=%%A"

set "BASE_DIR="
if "%LOCSEL%"=="1" set "BASE_DIR=%USERPROFILE%\Desktop"
if "%LOCSEL%"=="2" set "BASE_DIR=%USERPROFILE%\Downloads"
if "%LOCSEL%"=="3" set "BASE_DIR=%USERPROFILE%\Documents"
if "%LOCSEL%"=="4" (
  echo.
  set /p "BASE_DIR=Enter full custom path: "
)

for /f "tokens=* delims= " %%A in ("%BASE_DIR%") do set "BASE_DIR=%%A"

set "BASE_DIR=%BASE_DIR:"=%"

if not defined BASE_DIR (
  echo.
  echo Invalid input. Please try again.
  pause
  goto LocationMenuStart
)

set "BASE_DIR_N=%BASE_DIR%"
if "%BASE_DIR_N:~-1%"=="\" set "BASE_DIR_N=%BASE_DIR_N:~0,-1%"

set "BASE_LAST="
for %%I in ("%BASE_DIR_N%") do set "BASE_LAST=%%~nxI"

if /i "%BASE_LAST%"=="%COMPANY%" (
  set "INSTALL_ROOT=%BASE_DIR_N%"
) else (
  set "INSTALL_ROOT=%BASE_DIR_N%\%COMPANY%"
)

set "TARGET_DIR=%INSTALL_ROOT%\%MACRO_NAME%"

if not defined MACRO_NAME (
  call :Log "ERROR: Macro name not set when computing target directory."
  echo.
  echo Internal error: macro selection missing.
  pause
  exit /b 1
)

if /i "%TARGET_DIR%"=="%INSTALL_ROOT%" (
  call :Log "ERROR: Safety check failed (TARGET_DIR equals INSTALL_ROOT)."
  echo.
  echo Safety check failed for install path.
  pause
  exit /b 1
)

call :Log "Selected install directory: %TARGET_DIR%"

call :Log "Install root directory: %INSTALL_ROOT%"

if exist "%INSTALL_ROOT%\" (
  rem ok
) else (
  mkdir "%INSTALL_ROOT%" >nul 2>&1
)

if not exist "%INSTALL_ROOT%\" (
  call :Log "ERROR: Unable to create install root folder."
  echo.
  echo Unable to create the install root folder.
  pause
  exit /b 1
)

if exist "%TARGET_DIR%" (
  echo The folder already exists:
  echo %TARGET_DIR%
  echo.
  choice /C YN /N /M "Overwrite it? (Y = Yes, N = No)"
  if errorlevel 2 goto LocationMenuStart
  rmdir /s /q "%TARGET_DIR%" >nul 2>&1
)

mkdir "%TARGET_DIR%" >nul 2>&1
if errorlevel 1 (
  call :Log "ERROR: Unable to create install folder."
  echo.
  echo Unable to create the install folder.
  pause
  exit /b 1
)

call :CheckWriteAccess "%TARGET_DIR%"
if errorlevel 1 (
  call :Log "ERROR: No write access to install folder."
  echo.
  echo No write permission at the selected location.
  pause
  exit /b 1
)

call :SwitchLogToTarget

exit /b 0

:InstallMacro
call :Progress 10 "Preparing installer"
call :CheckInternet
if errorlevel 1 (
  call :Log "ERROR: No internet connection."
  echo.
  echo Internet connection required.
  pause
  exit /b 1
)

call :Progress 25 "Creating folders"
mkdir "%WORKDIR%\download" >nul 2>&1
mkdir "%WORKDIR%\extract" >nul 2>&1

if not exist "%TARGET_DIR%\" (
  mkdir "%TARGET_DIR%" >nul 2>&1
)

if not exist "%TARGET_DIR%\" (
  call :Log "ERROR: Target directory missing after setup: %TARGET_DIR%"
  echo.
  echo Unable to prepare the install folder:
  echo %TARGET_DIR%
  pause
  exit /b 1
)

set "INSTALL_MARKER=%TARGET_DIR%\.__installing"
> "%INSTALL_MARKER%" echo Installing... 2>> "%LOGFILE%"

call :Progress 50 "Downloading from GitHub"
set "PKGFILE=%WORKDIR%\download\%MACRO_REPO%.zip"
call :DownloadLatestRelease "%GITHUB_OWNER%" "%MACRO_REPO%" "%PKGFILE%"
if errorlevel 1 (
  call :Log "ERROR: GitHub download failed."
  echo.
  echo Download failed. Please check your internet connection and try again.
  pause
  exit /b 1
)

call :Progress 70 "Extracting archive"
call :ExtractZip "%PKGFILE%" "%WORKDIR%\extract"
if errorlevel 1 (
  call :Log "ERROR: Extract failed."
  echo.
  echo Installation failed while extracting files.
  pause
  exit /b 1
)

call :VerifyExtractedSource "%EXTRACT_SRC%"
if errorlevel 1 (
  call :Log "ERROR: Extracted source appears empty."
  echo.
  echo Installation failed: the downloaded package extracted but contained no files.
  echo Please try again or check your antivirus/quarantine settings.
  pause
  exit /b 1
)

call :Progress 80 "Copying files"
call :CopyToTarget "%EXTRACT_SRC%" "%TARGET_DIR%"
if errorlevel 1 (
  call :Log "ERROR: Copy failed."
  echo.
  echo Installation failed while copying files.
  pause
  exit /b 1
)

call :Progress 90 "Verifying installation"
call :VerifyInstall "%TARGET_DIR%"
if errorlevel 1 (
  call :Log "ERROR: Installation verification failed (target folder empty)."
  echo.
  echo Installation verification failed. The install folder appears to be empty:
  echo %TARGET_DIR%
  echo.
  pause
  exit /b 1
)

call :Progress 100 "Finalizing installation"
if defined INSTALL_MARKER if exist "%INSTALL_MARKER%" del /f /q "%INSTALL_MARKER%" >nul 2>> "%LOGFILE%"
if defined LAST_RELEASE_TAG (
  > "%TARGET_DIR%\.installed_version" echo %LAST_RELEASE_TAG% 2>> "%LOGFILE%"
) else (
  > "%TARGET_DIR%\.installed_version" echo unknown 2>> "%LOGFILE%"
)
call :Log "Macro installed successfully: %MACRO_NAME%"
exit /b 0

:Completion
cls
call :Header
echo ========================================
echo  Installation Complete
echo ========================================
echo.
echo Installed: %MACRO_NAME%
echo Dependencies Installed: %DEP_SUMMARY%
echo Location: %TARGET_DIR%
echo Installed Items: %INSTALLED_ITEMS%
echo.
echo Visit https://bestfreesoftwareco.github.io/ for the latest tutorials and support.
call :PostInstallUpdateCheck
echo Thank you for using BestFreeSoftwareCo software!
echo.
echo Launch now? (Y/N)
set /p "LAUNCH=> "
if /i "%LAUNCH%"=="Y" (
  start "" "%TARGET_DIR%"
)
exit /b 0

:CleanupPartial
call :PreserveLogForFailure
if defined INSTALL_MARKER (
  if not exist "%INSTALL_MARKER%" exit /b 0
)
if defined TARGET_DIR (
  if exist "%TARGET_DIR%" (
    rmdir /s /q "%TARGET_DIR%" >nul 2>&1
  )
)
exit /b 0

:Cleanup
if exist "%WORKDIR%" (
  rmdir /s /q "%WORKDIR%" >nul 2>&1
)
exit /b 0

:Log
set "MSG=%~1"
>> "%LOGFILE%" echo [%date% %time%] !MSG!
exit /b 0

:Progress
set "PCT=%~1"
set "PMSG=%~2"
set "BAR_WIDTH=30"
set /a FILLED=(PCT*BAR_WIDTH)/100
set "BAR="
for /L %%I in (1,1,%BAR_WIDTH%) do (
  if %%I LEQ !FILLED! (
    set "BAR=!BAR!=="
  ) else (
    set "BAR=!BAR!-"
  )
)
echo [!BAR!] !PCT!%% !PMSG!
>> "%LOGFILE%" echo [%date% %time%] [!PCT!%%] !PMSG!
exit /b 0

:CheckInternet
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try { $null=Invoke-WebRequest -UseBasicParsing -Method Head -Uri 'https://github.com'; exit 0 } catch { exit 1 }" >nul 2>&1
if errorlevel 1 exit /b 1
exit /b 0

:CheckWriteAccess
set "WPATH=%~1"
set "WTEST=%WPATH%\__write_test.tmp"
> "%WTEST%" echo. 2>> "%LOGFILE%"
if errorlevel 1 (
  call :Log "Write test failed at: %WPATH%"
  exit /b 1
)
del /f /q "%WTEST%" >nul 2>> "%LOGFILE%"
exit /b 0

:DownloadLatestRelease
set "D_OWNER=%~1"
set "D_REPO=%~2"
set "D_OUT=%~3"
call :Log "Resolving latest GitHub release for %D_OWNER%/%D_REPO%"
set "DL_URL="
set "DL_TAG="
set "LAST_RELEASE_TAG="
for /f "usebackq tokens=1,2 delims=	" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $owner='%D_OWNER%'; $repo='%D_REPO%'; $headers=@{'User-Agent'='BestFreeSoftwareCoInstaller'}; $url=$null; $tag=$null; $defaultBranch='main'; try { $ri=Invoke-RestMethod -Headers $headers -Uri ('https://api.github.com/repos/'+$owner+'/'+$repo); if($ri -and $ri.default_branch){ $defaultBranch=$ri.default_branch } } catch { } try { $r=Invoke-RestMethod -Headers $headers -Uri ('https://api.github.com/repos/'+$owner+'/'+$repo+'/releases/latest'); if($r){ $tag=$r.tag_name }; if($r -and $r.assets){ foreach($a in $r.assets){ if($a.name -match '\.zip$'){ $url=$a.browser_download_url; break } } } if(-not $url -and $r -and $r.zipball_url){ $url=$r.zipball_url } } catch { $url=$null; $tag=$null } if(-not $url){ $url='https://github.com/'+$owner+'/'+$repo+'/archive/refs/heads/'+$defaultBranch+'.zip'; $tag=('branch:'+ $defaultBranch) } if(-not $tag){ $tag='unknown' } Write-Output ($url + ([char]9) + $tag)"`) do (
  set "DL_URL=%%A"
  set "DL_TAG=%%B"
)
if not defined DL_URL exit /b 1
if not defined DL_TAG set "DL_TAG=unknown"
set "LAST_RELEASE_TAG=%DL_TAG%"
call :Log "Download URL: %DL_URL%"
call :Log "Resolved version tag: %LAST_RELEASE_TAG%"
call :DownloadFile "%DL_URL%" "%D_OUT%" "GitHub Package"
if errorlevel 1 exit /b 1
if not exist "%D_OUT%" exit /b 1
exit /b 0

:ExtractZip
set "E_ZIP=%~1"
set "E_EXTRACT=%~2"
call :Log "Extracting archive."
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { param($zip,$extract) $ErrorActionPreference='Stop'; if(Test-Path -LiteralPath $extract){ Remove-Item -LiteralPath $extract -Recurse -Force }; $null=New-Item -ItemType Directory -Path $extract -Force; Expand-Archive -LiteralPath $zip -DestinationPath $extract -Force; $items=Get-ChildItem -LiteralPath $extract -Force; if($items.Count -eq 1 -and $items[0].PSIsContainer){ Write-Output $items[0].FullName } else { Write-Output $extract } }" "%E_ZIP%" "%E_EXTRACT%" > "%WORKDIR%\extract_src.txt" 2>> "%LOGFILE%"
if errorlevel 1 exit /b 1
set "EXTRACT_SRC="
if not exist "%WORKDIR%\extract_src.txt" exit /b 1
set /p "EXTRACT_SRC="<"%WORKDIR%\extract_src.txt"
if not defined EXTRACT_SRC exit /b 1
exit /b 0

:CopyToTarget
set "C_SRC=%~1"
set "C_DEST=%~2"
call :Log "Copying files to destination."
if not exist "%C_SRC%" exit /b 1
robocopy "%C_SRC%" "%C_DEST%" /E /R:1 /W:1 /TEE /LOG+:"%LOGFILE%"
set "RC=%errorlevel%"
call :Log "Robocopy exit code: !RC!"
if !RC! GEQ 8 exit /b 1
exit /b 0

:VerifyExtractedSource
set "S_PATH=%~1"
set "S_COUNT=0"
for /f "usebackq tokens=* delims= " %%C in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "& { param($p) $ErrorActionPreference='SilentlyContinue'; $c=0; try { if(Test-Path -LiteralPath $p){ $c=(Get-ChildItem -LiteralPath $p -Force -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count } } catch { } [Console]::WriteLine($c) }" "%S_PATH%" 2^>^> "%LOGFILE%"`) do set "S_COUNT=%%C"
set "S_NONNUM="
for /f "delims=0123456789" %%D in ("%S_COUNT%") do set "S_NONNUM=1"
if defined S_NONNUM (
  call :Log "ERROR: Extracted source verification returned non-numeric count: %S_COUNT%"
  exit /b 1
)
if %S_COUNT% LSS 1 (
  call :Log "ERROR: Extracted source verification failed (no files detected)."
  exit /b 1
)
exit /b 0

:DownloadFile
set "DL_SRC=%~1"
set "DL_DST=%~2"
set "DL_NAME=%~3"
call :Log "Downloading: %DL_NAME%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { param($src,$dst,$name) $ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $headers=@{'User-Agent'='BestFreeSoftwareCoInstaller'}; $attempts=3; for($i=1;$i -le $attempts;$i++){ try { if(Test-Path -LiteralPath $dst){ Remove-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue } try { Import-Module BitsTransfer -ErrorAction Stop; $job=Start-BitsTransfer -Source $src -Destination $dst -Asynchronous -DisplayName $name; while($true){ $job=Get-BitsTransfer -Id $job.Id; if($job.JobState -in @('Transferred','Error','Cancelled')){ break }; $pct=0; if($job.BytesTotal -gt 0){ $pct=[int](100*$job.BytesTransferred/$job.BytesTotal) }; Write-Progress -Activity ('Downloading '+$name) -Status ($pct.ToString()+'%%') -PercentComplete $pct; Start-Sleep -Milliseconds 200 }; if($job.JobState -eq 'Transferred'){ Complete-BitsTransfer $job; Write-Progress -Activity ('Downloading '+$name) -Completed } else { try { Remove-BitsTransfer $job -Confirm:$false } catch { }; throw 'BITS download failed' } } catch { Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $src -OutFile $dst } if(-not (Test-Path -LiteralPath $dst)){ throw 'Download did not create file' }; $len=(Get-Item -LiteralPath $dst).Length; if($len -lt 1){ throw 'Downloaded file is empty (0 bytes)' }; exit 0 } catch { if($i -lt $attempts){ Start-Sleep -Seconds (2*$i); continue } else { throw } } } }" "%DL_SRC%" "%DL_DST%" "%DL_NAME%" >> "%LOGFILE%" 2>&1
if errorlevel 1 exit /b 1
exit /b 0

:SwitchLogToTarget
if not defined TARGET_DIR exit /b 0

set "TARGET_LOG=%TARGET_DIR%\%COMPANY%Installer.log"

if exist "%TARGET_LOG%" del /f /q "%TARGET_LOG%" >nul 2>&1

if exist "%LOGFILE%" (
  copy /y "%LOGFILE%" "%TARGET_LOG%" >nul 2>&1
) else (
  > "%TARGET_LOG%" echo.
)

set "LOGFILE=%TARGET_LOG%"
call :Log "Log file location: %LOGFILE%"
exit /b 0

:PreserveLogForFailure
if not defined BOOT_LOGFILE exit /b 0
if not defined TARGET_DIR exit /b 0

echo(%LOGFILE%| find /i "%TARGET_DIR%" >nul
if errorlevel 1 exit /b 0

if exist "%LOGFILE%" (
  copy /y "%LOGFILE%" "%BOOT_LOGFILE%" >nul 2>&1
  set "LOGFILE=%BOOT_LOGFILE%"
)
exit /b 0

:SelfUpdateCheck
set "SELF_PATH=%~f0"
set "SELF_DIR=%~dp0"
set "SELF_NAME=%~nx0"

set "UPD_DIR=%TEMP%\%COMPANY%Updater_%RANDOM%%RANDOM%"
set "UPD_RESULT=%UPD_DIR%\update_result.txt"
set "UPD_NEW=%UPD_DIR%\%SELF_NAME%.new"
set "UPD_ZIP=%UPD_DIR%\update.zip"
set "UPD_EXT=%UPD_DIR%\src"
set "UPD_SCRIPT=%UPD_DIR%\apply_update.bat"

mkdir "%UPD_DIR%" >nul 2>&1

call :Log "Checking for installer updates..."

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { param($owner,$repo,$localTag,$zipPath,$extractDir,$outBat) $ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $headers=@{'User-Agent'='BestFreeSoftwareCoInstaller'}; $api=('https://api.github.com/repos/'+$owner+'/'+$repo+'/releases/latest'); $r=Invoke-RestMethod -Headers $headers -Uri $api; $tag=$r.tag_name; if(-not $tag){ 'NOUPDATE'; exit 0 }; if($tag -eq $localTag){ 'NOUPDATE'; exit 0 }; $zipUrl=$r.zipball_url; if(-not $zipUrl){ 'ERROR'; exit 0 }; Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $zipUrl -OutFile $zipPath; if(Test-Path -LiteralPath $extractDir){ Remove-Item -LiteralPath $extractDir -Recurse -Force }; $null=New-Item -ItemType Directory -Path $extractDir -Force; Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force; $bat=Get-ChildItem -LiteralPath $extractDir -Recurse -Filter 'installer.bat' ^| Select-Object -First 1; if(-not $bat){ 'ERROR'; exit 0 }; Copy-Item -LiteralPath $bat.FullName -Destination $outBat -Force; ('UPDATE'+([char]9)+$tag) }" "%UPDATE_OWNER%" "%UPDATE_REPO%" "%INSTALLER_VERSION%" "%UPD_ZIP%" "%UPD_EXT%" "%UPD_NEW%" > "%UPD_RESULT%" 2>> "%LOGFILE%"

if not exist "%UPD_RESULT%" exit /b 0

set "UPD_STATUS="
set "UPD_TAG="
for /f "usebackq tokens=1,2 delims=	" %%A in ("%UPD_RESULT%") do (
  set "UPD_STATUS=%%A"
  set "UPD_TAG=%%B"
)

if /i not "!UPD_STATUS!"=="UPDATE" exit /b 0
if not exist "%UPD_NEW%" exit /b 0

echo.
echo Update available: !UPD_TAG! (current %INSTALLER_VERSION%)
choice /C YN /N /M "Install update now? (Y = Yes, N = No)"
if errorlevel 2 (
  call :Log "Update available: !UPD_TAG! (current %INSTALLER_VERSION%). User chose NO."
  exit /b 0
)

call :Log "Update available: !UPD_TAG! (current %INSTALLER_VERSION%). User chose YES. Applying update..."

> "%UPD_SCRIPT%" echo @echo off
>> "%UPD_SCRIPT%" echo setlocal EnableExtensions
>> "%UPD_SCRIPT%" echo ping 127.0.0.1 -n 3 ^>nul
>> "%UPD_SCRIPT%" echo copy /y "%UPD_NEW%" "%SELF_PATH%" ^>nul
>> "%UPD_SCRIPT%" echo start "" "%SELF_PATH%"
>> "%UPD_SCRIPT%" echo exit /b 0

start "" /min cmd /c ""%UPD_SCRIPT%""
exit /b 2

:VerifyInstall
set "V_PATH=%~1"
set "V_COUNT=0"
for /f "usebackq tokens=* delims= " %%C in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "& { param($p,$logPath,$company) $ErrorActionPreference='SilentlyContinue'; $c=0; try { if(Test-Path -LiteralPath $p){ $files=Get-ChildItem -LiteralPath $p -Force -Recurse -File -ErrorAction SilentlyContinue; foreach($i in $files){ $n=$i.Name; if($n -like '*Installer.log'){ continue }; if($n -ieq '.__installing'){ continue }; if($n -ieq '.installed_version'){ continue }; if($company -and ($n -ieq ($company+'Installer.log'))){ continue }; if($logPath -and ($i.FullName -ieq $logPath)){ continue }; $c++ } } } catch { } [Console]::WriteLine($c) }" "%V_PATH%" "%LOGFILE%" "%COMPANY%" 2^>^> "%LOGFILE%"`) do set "V_COUNT=%%C"

set "NONNUM="
for /f "delims=0123456789" %%D in ("%V_COUNT%") do set "NONNUM=1"
if defined NONNUM (
  call :Log "ERROR: Installation verification returned non-numeric count: %V_COUNT%"
  exit /b 1
)

set "INSTALLED_ITEMS=%V_COUNT%"
call :Log "Installed item count: %INSTALLED_ITEMS%"
if %INSTALLED_ITEMS% LSS 1 (
  call :Log "ERROR: Installation verification failed (no installed files detected after filtering)."
  exit /b 1
)
exit /b 0

:PostInstallUpdateCheck
if not defined INSTALL_ROOT exit /b 0

call :Log "Post-install update check started."
call :CheckInternet
if errorlevel 1 (
  call :Log "Post-install update check skipped (no internet connection)."
  echo.
  echo Skipping update check (no internet connection).
  echo.
  exit /b 0
)
echo.
echo Checking for updates to installed macros...

set "OUTDATED="
set "OUTDATED_COUNT=0"

call :CheckOneMacroUpdate "Rivals AFK Macro" "Rivals-Afk-Macro"
call :CheckOneMacroUpdate "Adopt Me Task Macro" "Adopt-Me-Task-Macro"
call :CheckOneMacroUpdate "Macro Creator" "Macro-Creator"

if %OUTDATED_COUNT% LEQ 0 (
  call :Log "No outdated installed macros detected."
  echo All installed macros are up to date.
  echo.
  exit /b 0
)

echo.
echo The following installed macros have updates available:
echo !OUTDATED!
echo.
choice /C YN /N /M "Update them now? (Y = Yes, N = No)"
if errorlevel 2 (
  call :Log "User chose not to update outdated macros."
  echo.
  exit /b 0
)

call :Log "User chose to update outdated macros."
set "ORIG_TARGET_DIR=%TARGET_DIR%"
set "ORIG_MACRO_NAME=%MACRO_NAME%"
set "ORIG_MACRO_REPO=%MACRO_REPO%"
call :UpdateOutdatedMacros
set "TARGET_DIR=%ORIG_TARGET_DIR%"
set "MACRO_NAME=%ORIG_MACRO_NAME%"
set "MACRO_REPO=%ORIG_MACRO_REPO%"
echo.
exit /b 0

:CheckOneMacroUpdate
set "CHK_NAME=%~1"
set "CHK_REPO=%~2"
set "CHK_DIR=%INSTALL_ROOT%\%CHK_NAME%"
if not exist "%CHK_DIR%" exit /b 0

set "CHK_VERFILE=%CHK_DIR%\.installed_version"
if not exist "%CHK_VERFILE%" exit /b 0

set "LOCAL_TAG="
set /p "LOCAL_TAG="<"%CHK_VERFILE%"
if not defined LOCAL_TAG set "LOCAL_TAG=unknown"
if /i "%LOCAL_TAG%"=="unknown" exit /b 0

set "LATEST_TAG="
for /f "usebackq tokens=* delims= " %%T in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $headers=@{'User-Agent'='BestFreeSoftwareCoInstaller'}; $tag=$null; for($i=1;$i -le 3;$i++){ try { $r=Invoke-RestMethod -Headers $headers -Uri ('https://api.github.com/repos/%GITHUB_OWNER%/%CHK_REPO%/releases/latest'); if($r -and $r.tag_name){ $tag=$r.tag_name; break } } catch { try { if($_.Exception -and $_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 403){ break } } catch { } Start-Sleep -Seconds (2*$i) } }; if($tag){ Write-Output $tag }" 2^>^> "%LOGFILE%"`) do set "LATEST_TAG=%%T"

if not defined LATEST_TAG (
  call :Log "Update check: unable to resolve latest tag for %CHK_NAME% (%CHK_REPO%). Possibly offline, rate limited, or no releases."
  exit /b 0
)

if /i not "%LOCAL_TAG%"=="%LATEST_TAG%" (
  set /a OUTDATED_COUNT+=1
  if not defined OUTDATED (
    set "OUTDATED=%CHK_NAME% (%LOCAL_TAG% -> %LATEST_TAG%)"
  ) else (
    set "OUTDATED=!OUTDATED!, %CHK_NAME% (%LOCAL_TAG% -> %LATEST_TAG%)"
  )
  call :Log "Update available for %CHK_NAME%: %LOCAL_TAG% -> %LATEST_TAG%"
)

exit /b 0

:UpdateOutdatedMacros
call :UpdateMacroIfOutdated "Rivals AFK Macro" "Rivals-Afk-Macro"
call :UpdateMacroIfOutdated "Adopt Me Task Macro" "Adopt-Me-Task-Macro"
call :UpdateMacroIfOutdated "Macro Creator" "Macro-Creator"
exit /b 0

:UpdateMacroIfOutdated
set "U_NAME=%~1"
set "U_REPO=%~2"
set "U_DIR=%INSTALL_ROOT%\%U_NAME%"
if not exist "%U_DIR%" exit /b 0
if not exist "%U_DIR%\.installed_version" exit /b 0

set "U_LOCAL="
set /p "U_LOCAL="<"%U_DIR%\.installed_version"
if not defined U_LOCAL exit /b 0
if /i "%U_LOCAL%"=="unknown" exit /b 0

set "U_LATEST="
for /f "usebackq tokens=* delims= " %%T in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $headers=@{'User-Agent'='BestFreeSoftwareCoInstaller'}; $tag=$null; for($i=1;$i -le 3;$i++){ try { $r=Invoke-RestMethod -Headers $headers -Uri ('https://api.github.com/repos/%GITHUB_OWNER%/%U_REPO%/releases/latest'); if($r -and $r.tag_name){ $tag=$r.tag_name; break } } catch { try { if($_.Exception -and $_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 403){ break } } catch { } Start-Sleep -Seconds (2*$i) } }; if($tag){ Write-Output $tag }" 2^>^> "%LOGFILE%"`) do set "U_LATEST=%%T"
if not defined U_LATEST exit /b 0

if /i "%U_LOCAL%"=="%U_LATEST%" exit /b 0

echo.
echo Updating %U_NAME%...
call :Log "Updating %U_NAME% in place."

call :InstallMacroDirect "%U_NAME%" "%U_REPO%" "%U_DIR%"
if errorlevel 1 (
  call :Log "ERROR: Update failed for %U_NAME%."
  echo Update failed for %U_NAME%. See log:
  echo %LOGFILE%
  echo.
  exit /b 0
)
echo Updated %U_NAME% successfully.
exit /b 0

:InstallMacroDirect
setlocal EnableExtensions EnableDelayedExpansion
set "M_NAME=%~1"
set "M_REPO=%~2"
set "M_TARGET=%~3"

if not defined M_TARGET ( endlocal & exit /b 1 )
if not defined M_REPO ( endlocal & exit /b 1 )

set "MACRO_NAME=%M_NAME%"
set "MACRO_REPO=%M_REPO%"
set "TARGET_DIR=%M_TARGET%"

call :Progress 10 "Preparing update"
call :CheckInternet
if errorlevel 1 ( endlocal & exit /b 1 )

mkdir "%WORKDIR%\download" >nul 2>&1
mkdir "%WORKDIR%\extract" >nul 2>&1

set "INSTALL_MARKER=%TARGET_DIR%\.__installing"
> "%INSTALL_MARKER%" echo Updating... 2>> "%LOGFILE%"

call :Progress 50 "Downloading from GitHub"
set "PKGFILE=%WORKDIR%\download\%MACRO_REPO%.zip"
call :DownloadLatestRelease "%GITHUB_OWNER%" "%MACRO_REPO%" "%PKGFILE%"
if errorlevel 1 ( endlocal & exit /b 1 )

call :Progress 70 "Extracting archive"
call :ExtractZip "%PKGFILE%" "%WORKDIR%\extract"
if errorlevel 1 ( endlocal & exit /b 1 )

call :VerifyExtractedSource "%EXTRACT_SRC%"
if errorlevel 1 ( endlocal & exit /b 1 )

call :Progress 80 "Copying files"
call :CopyToTarget "%EXTRACT_SRC%" "%TARGET_DIR%"
if errorlevel 1 ( endlocal & exit /b 1 )

call :Progress 90 "Verifying installation"
call :VerifyInstall "%TARGET_DIR%"
if errorlevel 1 ( endlocal & exit /b 1 )

call :Progress 100 "Finalizing update"
if defined INSTALL_MARKER if exist "%INSTALL_MARKER%" del /f /q "%INSTALL_MARKER%" >nul 2>> "%LOGFILE%"
if defined LAST_RELEASE_TAG (
  > "%TARGET_DIR%\.installed_version" echo !LAST_RELEASE_TAG! 2>> "%LOGFILE%"
) else (
  > "%TARGET_DIR%\.installed_version" echo unknown 2>> "%LOGFILE%"
)

endlocal & exit /b 0
