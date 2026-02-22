@echo off
setlocal EnableDelayedExpansion
title Stop Haven
color 0C
echo.
echo  ========================================
echo       HAVEN - Stop Server
echo  ========================================
echo.

set "HAVEN_DATA=%APPDATA%\Haven"
set "HAVEN_PORT=3000"
if exist "%~dp0.env" for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%~dp0.env") do if "%%A"=="PORT" set "HAVEN_PORT=%%B"
if not exist "%~dp0.env" if exist "%HAVEN_DATA%\.env" for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%HAVEN_DATA%\.env") do if "%%A"=="PORT" set "HAVEN_PORT=%%B"

:: ── Try saved PID first (written by Start Haven.bat) ──────
set "FOUND=0"
if exist "%HAVEN_DATA%\haven.pid" (
    set /p SAVED_PID=<"%HAVEN_DATA%\haven.pid"
)
if defined SAVED_PID (
    :: Verify the saved PID is still a running process
    tasklist /FI "PID eq %SAVED_PID%" 2>nul | findstr "%SAVED_PID%" >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        call :KILL_PID %SAVED_PID%
    )
)

:: ── Fallback: scan the port if PID file was missing or stale ──
if "%FOUND%"=="0" (
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%HAVEN_PORT%" ^| findstr "LISTENING"') do call :KILL_PID %%a
)

if "%FOUND%"=="0" echo  [*] No Haven server found on port %HAVEN_PORT%

:: Clean up PID file
if exist "%HAVEN_DATA%\haven.pid" del "%HAVEN_DATA%\haven.pid" >nul 2>&1
goto :DONE

:KILL_PID
set "FOUND=1"
echo  [*] Stopping Haven server (PID %1)...
taskkill /PID %1 /F >nul 2>&1
if not errorlevel 1 echo  [OK] Server stopped  (PID %1)
if errorlevel 1 echo  [!] Failed to kill PID %1 -- try running as Administrator
goto :eof

:DONE
echo.
echo  ========================================
echo       Haven server stopped.
echo  ========================================
echo.
exit