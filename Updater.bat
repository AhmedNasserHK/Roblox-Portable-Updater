@echo off
:: UPDATER-BATCH-API 1
::
:: Roblox Portable Updater - update script.
:: Downloaded by RobloxPortableUpdater.exe right before it applies an update
:: (from the MainSource branch of AhmedNasserHK/Roblox-Portable-Updater).
::
:: Keep this file ASCII-only. If you ever change what the tool passes in,
:: bump the API number above (older tools will then fall back to their embedded batch).
::
:: Arguments (each one quoted by the tool):
::   %1  full path of RobloxPortableUpdater.exe
::   %2  update archive (Update.rar)
::   %3  7z.exe to use
::   %4  archive password
::   %5  1 = the archive contains RobloxPortableUpdater.exe itself, 0 = it does not
::   %6  folder to extract into (the tool folder)
::   %7  log file to delete at the end (Update.log)
::   %8  7-Zip folder name (display only)

setlocal EnableExtensions
title Roblox Portable Updater
color 0B
cls

set "SELF_EXE=%~1"
set "ARCHIVE=%~2"
set "SEVENZIP=%~3"
set "PASSWORD=%~4"
set "SELF_IN_ARCHIVE=%~5"
set "EXTRACT_DIR=%~6"
set "LOG_FILE=%~7"
set "SZ_FOLDER=%~8"
set "THIS_BAT=%~f0"
set "SELF_BAK=%~1.old"

if not defined SELF_EXE goto :badargs
if not defined ARCHIVE goto :badargs
if not defined SEVENZIP goto :badargs
if not defined EXTRACT_DIR goto :badargs

echo ========================================
echo    Roblox Portable Updater
echo ========================================
echo.
echo [%DATE% %TIME%] Starting update...
echo.
echo Using 7-Zip from: %SZ_FOLDER%
echo.

echo [1/4] Waiting for program to close...
ping 127.0.0.1 -n 4 > nul

cd /d "%EXTRACT_DIR%"
if errorlevel 1 goto :badargs

:: If the update contains the updater itself, move the old exe out of the way
:: (it can only be moved after the program has fully closed), so 7-Zip can extract the new one.
if not "%SELF_IN_ARCHIVE%"=="1" goto :extract

echo Preparing to replace the updater itself...
if exist "%SELF_BAK%" del /f /q "%SELF_BAK%"
set /a TRIES=0

:selfmove
move /y "%SELF_EXE%" "%SELF_BAK%" >nul 2>&1
if not exist "%SELF_EXE%" goto :extract
set /a TRIES+=1
if %TRIES% GEQ 20 (
    echo.
    echo [ERROR] Could not replace the running program. Please close it and try again.
    pause
    exit /b 1
)
ping 127.0.0.1 -n 2 > nul
goto :selfmove

:extract
echo [2/4] Extracting files...
echo.
"%SEVENZIP%" x "%ARCHIVE%" "-p%PASSWORD%" -o"%EXTRACT_DIR%" -y -aos
if not errorlevel 1 goto :extracted

echo.
echo [WARNING] Extraction failed, retrying...
ping 127.0.0.1 -n 3 > nul
"%SEVENZIP%" x "%ARCHIVE%" "-p%PASSWORD%" -o"%EXTRACT_DIR%" -y -aos
if not errorlevel 1 goto :extracted

:: Extraction failed - put the old exe back so the tool is not lost
if "%SELF_IN_ARCHIVE%"=="1" move /y "%SELF_BAK%" "%SELF_EXE%" >nul 2>&1
echo.
echo [ERROR] All extraction attempts failed!
echo.
echo Please extract manually:
echo   1. Open file: %ARCHIVE%
echo   2. Use password: %PASSWORD%
echo   3. Extract to: %EXTRACT_DIR%
echo.
pause
exit /b 1

:extracted
echo.
echo [3/4] Update completed successfully!
echo.

:: If the update shipped the new updater as RobloxPortableUpdater.exe_NEW,
:: replace the old exe with it (retrying until the old one is no longer locked).
set "SELF_NEW=%SELF_EXE%_NEW"
if not exist "%SELF_NEW%" goto :restart

echo Replacing the updater with the new version...
set /a TRIES=0

:swapself
move /y "%SELF_NEW%" "%SELF_EXE%" >nul 2>&1
if not exist "%SELF_NEW%" goto :restart
set /a TRIES+=1
if %TRIES% GEQ 20 (
    echo.
    echo [ERROR] Could not replace RobloxPortableUpdater.exe with the new version.
    echo The new file was left as: %SELF_NEW%
    echo Close the program and rename it manually.
    pause
    exit /b 1
)
ping 127.0.0.1 -n 2 > nul
goto :swapself

:restart
echo [4/4] Restarting application...
start "" "%SELF_EXE%"

echo Cleaning up temporary files...
if exist "%SELF_BAK%" del /f /q "%SELF_BAK%"
del /f /q "%ARCHIVE%"
if defined LOG_FILE del /f /q "%LOG_FILE%"

echo.
echo ========================================
echo    Update completed successfully!
echo    The application will start in a moment...
echo ========================================
timeout /t 3 /nobreak >nul

:: Stop the script and delete it (a batch file cannot simply delete itself while running)
(goto) 2>nul & del /f /q "%THIS_BAT%"

:badargs
echo [ERROR] The updater script was started with missing or invalid arguments.
pause
exit /b 1
