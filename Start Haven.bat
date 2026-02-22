@echo off
title Haven Server
color 0A
echo.
echo  ========================================
echo       HAVEN - Private Chat Server
echo  ========================================
echo.

:: ── Data directory (portable: .\data) ──────────────────────
set "HAVEN_DATA=%~dp0data"
if not exist "%HAVEN_DATA%" mkdir "%HAVEN_DATA%"

:: Kill any existing Haven server on the configured port
echo  [*] Checking for existing server...

:: ── Pre-read PORT from project .env so we kill the right process ──
set "HAVEN_PORT=3000"
if exist "%HAVEN_DATA%\.env" (
    for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%HAVEN_DATA%\.env") do if "%%A"=="PORT" set "HAVEN_PORT=%%B"
) else if exist "%~dp0.env" (
    for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%~dp0.env") do if "%%A"=="PORT" set "HAVEN_PORT=%%B"
)
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%HAVEN_PORT%" ^| findstr "LISTENING"') do (
    echo  [!] Killing existing process on port %HAVEN_PORT%
    taskkill /PID %%a /F >nul 2>&1
)

:: ── Network connectivity check ────────────────────────────
echo  [*] Checking network connectivity...
set "NETWORK_OK=0"
ping -n 1 -w 3000 1.1.1.1 >nul 2>&1
if %ERRORLEVEL% EQU 0 set "NETWORK_OK=1"
if "%NETWORK_OK%"=="0" (
    ping -n 1 -w 3000 8.8.8.8 >nul 2>&1
    if %ERRORLEVEL% EQU 0 set "NETWORK_OK=1"
)
if "%NETWORK_OK%"=="1" (
    echo  [OK] Internet connection available
) else (
    color 0E
    echo  [!] WARNING: No internet connection detected.
    echo      Haven will work on your local network only.
    echo      Remote access will not be available.
    color 0A
)

:: ── Detect LAN IP ─────────────────────────────────────────
set "LAN_IP=YOUR_LOCAL_IP"
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4" 2^>nul') do (
    set "LAN_IP=%%a"
)
set "LAN_IP=%LAN_IP: =%"

:: ── Detect public IP (if online) ──────────────────────────
set "PUBLIC_IP=YOUR_PUBLIC_IP"
if "%NETWORK_OK%"=="1" (
    for /f "tokens=*" %%a in ('powershell -NoProfile -Command "(Invoke-WebRequest -Uri 'https://api.ipify.org' -UseBasicParsing -TimeoutSec 5).Content" 2^>nul') do set "PUBLIC_IP=%%a"
    if "%PUBLIC_IP%"=="YOUR_PUBLIC_IP" (
        echo  [!] Could not detect public IP
    ) else (
        echo  [OK] Public IP: %PUBLIC_IP%
    )
)

:: ── Port availability check ────────────────────────────────
echo  [*] Checking port %HAVEN_PORT% availability...
netstat -ano | findstr ":%HAVEN_PORT%" | findstr "LISTENING" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo  [!] WARNING: Port %HAVEN_PORT% is still in use by another process.
    echo      Haven may fail to start. Check for conflicting services.
) else (
    echo  [OK] Port %HAVEN_PORT% is available
)
echo.

:: Check Node.js is installed
where node >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :NODE_OK

color 0E
echo.
echo  [!] Node.js is not installed or not in PATH.
echo.
echo  You have two options:
echo.
echo    1) Press Y below to install it automatically (downloads ~30 MB)
echo.
echo    2) Or download it manually from https://nodejs.org
echo.
set /p "AUTOINSTALL=  Would you like to install Node.js automatically now? [Y/N]: "
if /i "%AUTOINSTALL%" NEQ "Y" goto :NODE_SKIP

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-node.ps1"
if %ERRORLEVEL% NEQ 0 (
    color 0C
    echo.
    echo  [ERROR] Automatic install failed. Please install manually from https://nodejs.org
    echo.
    pause
    exit /b 1
)
echo.
echo  [OK] Node.js installed! Close this window and double-click Start Haven again.
echo      Node.js needs a fresh terminal to be recognized.
echo.
pause
exit /b 0

:NODE_SKIP
echo.
echo  [*] No problem. Install Node.js from https://nodejs.org and try again.
echo.
pause
exit /b 1

:NODE_OK
for /f "tokens=1 delims=v." %%v in ('node -v 2^>nul') do set "NODE_MAJOR=%%v"
echo  [OK] Node.js found: & node -v

:: Warn if Node major version is too new (native modules won't have prebuilts)
if defined NODE_MAJOR (
    if %NODE_MAJOR% GEQ 24 (
        color 0E
        echo.
        echo  [!] WARNING: Node.js v%NODE_MAJOR% detected. Haven requires Node 18-22.
        echo      Native modules like better-sqlite3 may not have prebuilt
        echo      binaries yet, causing build failures.
        echo.
        echo      Please install Node.js 22 LTS from https://nodejs.org
        echo.
        pause
        exit /b 1
    )
)

:: Always install/update dependencies (fast when already up-to-date)
cd /d "%~dp0"
echo  [*] Checking dependencies...
call npm install --no-audit --no-fund 2>&1
if %ERRORLEVEL% NEQ 0 (
    color 0C
    echo.
    echo  [ERROR] npm install failed. Check the errors above.
    echo.
    pause
    exit /b 1
)
echo  [OK] Dependencies ready
echo.

:: ── Sync .env into data directory ─────────────────────────
:: Priority: project-dir .env -> existing data-dir .env -> .env.example
if exist "%~dp0.env" (
    echo  [*] Found .env in project directory -- copying to %HAVEN_DATA%
    copy /Y "%~dp0.env" "%HAVEN_DATA%\.env" >nul
    goto :ENV_DONE
)
if exist "%HAVEN_DATA%\.env" goto :ENV_DONE
if exist "%~dp0.env.example" (
    echo  [*] Creating .env in %HAVEN_DATA% from template...
    copy "%~dp0.env.example" "%HAVEN_DATA%\.env" >nul
)
echo  [!] IMPORTANT: Edit %HAVEN_DATA%\.env and change your settings before going live!
echo.
:ENV_DONE

:: ── Read PORT, HOST and FORCE_HTTP from .env ──────────────
set "HAVEN_PORT=3000"
set "HAVEN_HOST="
set "FORCE_HTTP="
if exist "%HAVEN_DATA%\.env" (
    for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%HAVEN_DATA%\.env") do (
        if "%%A"=="PORT" set "HAVEN_PORT=%%B"
        if "%%A"=="HOST" set "HAVEN_HOST=%%B"
        if "%%A"=="FORCE_HTTP" set "FORCE_HTTP=%%B"
    )
)
:: Determine the address to open in the browser / show in banners
:: 0.0.0.0 means "all interfaces" so localhost works; a specific IP must be used directly
set "HAVEN_ADDR=localhost"
if defined HAVEN_HOST (
    if not "%HAVEN_HOST%"=="0.0.0.0" (
        if not "%HAVEN_HOST%"=="" set "HAVEN_ADDR=%HAVEN_HOST%"
    )
)
echo  [OK] Using port %HAVEN_PORT%  (host: %HAVEN_ADDR%)

:: ── Generate self-signed SSL certs (skip if FORCE_HTTP or certs exist) ──
if /I "%FORCE_HTTP%"=="true" (
    echo  [*] FORCE_HTTP=true -- skipping SSL certificate generation
    echo.
    goto :SSL_DONE
)
if exist "%HAVEN_DATA%\certs\cert.pem" goto :SSL_DONE

echo  [*] Generating self-signed SSL certificate...
if not exist "%HAVEN_DATA%\certs" mkdir "%HAVEN_DATA%\certs"
where openssl >nul 2>&1
if errorlevel 1 (
    echo  [!] OpenSSL not found - skipping cert generation.
    echo      Haven will run in HTTP mode. See GUIDE.md for details.
    echo      To enable HTTPS, install OpenSSL or provide certs manually.
    echo.
    goto :SSL_DONE
)
openssl req -x509 -newkey rsa:2048 -keyout "%HAVEN_DATA%\certs\key.pem" -out "%HAVEN_DATA%\certs\cert.pem" -days 3650 -nodes -subj "/CN=Haven" 2>nul
if exist "%HAVEN_DATA%\certs\cert.pem" (
    echo  [OK] SSL certificate generated in %HAVEN_DATA%\certs
) else (
    echo  [!] SSL certificate generation failed.
    echo      Haven will run in HTTP mode. See GUIDE.md for details.
)
echo.

:SSL_DONE

:: ── Ensure Windows Firewall allows Haven traffic ──────────
echo  [*] Checking firewall rules...
netsh advfirewall firewall show rule name="Haven Server" >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :FW_EXISTS

echo  [*] Adding firewall rule for port %HAVEN_PORT%...
netsh advfirewall firewall add rule name="Haven Server" dir=in action=allow protocol=TCP localport=%HAVEN_PORT% >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo  [OK] Firewall rule added for port %HAVEN_PORT%
) else (
    echo  [!] Could not add firewall rule -- need admin rights.
    echo      Run this .bat as Administrator, or manually allow port %HAVEN_PORT%.
)
goto :FW_DONE

:FW_EXISTS
netsh advfirewall firewall set rule name="Haven Server" new localport=%HAVEN_PORT% >nul 2>&1
echo  [OK] Firewall rule present for port %HAVEN_PORT%

:FW_DONE
echo.

echo  [*] Data directory: %HAVEN_DATA%
echo.

:: Detect protocol based on whether certs exist
set "HAVEN_PROTO=http"
if /I "%FORCE_HTTP%"=="true" goto :PROTO_DONE
if exist "%HAVEN_DATA%\certs\cert.pem" if exist "%HAVEN_DATA%\certs\key.pem" set "HAVEN_PROTO=https"
:PROTO_DONE

:: ── Launch server in background and capture PID ──────────
cd /d "%~dp0"
set "HAVEN_QUIET=1"
start /B node server.js

:: Wait for the server to begin listening so we can capture its PID
echo  [*] Waiting for server to start...
set RETRIES=0
:WAIT_LOOP
timeout /t 1 /nobreak >nul
set /a RETRIES+=1
netstat -ano | findstr ":%HAVEN_PORT%" | findstr "LISTENING" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    if %RETRIES% GEQ 15 (
        color 0C
        echo  [ERROR] Server failed to start after 15 seconds.
        echo  Check the output above for errors.
        pause
        exit /b 1
    )
    goto WAIT_LOOP
)

:: Capture PID of the node process listening on our port
set "NODE_PID="
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%HAVEN_PORT%" ^| findstr "LISTENING"') do set "NODE_PID=%%a"

:: Save PID to data directory so Stop Haven.bat can use it
if defined NODE_PID (
    echo %NODE_PID%>"%HAVEN_DATA%\haven.pid"
    echo  [OK] Server running  (PID %NODE_PID%)
) else (
    echo  [!] Server started but could not capture PID
)
echo.

:: Open browser
start %HAVEN_PROTO%://%HAVEN_ADDR%:%HAVEN_PORT%

if "%HAVEN_PROTO%"=="https" (
    echo  ========================================
    echo    Haven is LIVE on port %HAVEN_PORT% - HTTPS
    echo  ========================================
    echo.
    echo  Local:    https://%HAVEN_ADDR%:%HAVEN_PORT%
    echo  LAN:      https://%LAN_IP%:%HAVEN_PORT%
    echo  Remote:   https://%PUBLIC_IP%:%HAVEN_PORT%
    echo.
    echo  First time? Your browser will show a security
    echo  warning. Click "Advanced" then "Proceed" to continue.
) else (
    echo  ========================================
    echo    Haven is LIVE on port %HAVEN_PORT% - HTTP
    echo  ========================================
    echo.
    echo  Local:    http://%HAVEN_ADDR%:%HAVEN_PORT%
    echo  LAN:      http://%LAN_IP%:%HAVEN_PORT%
    echo  Remote:   http://%PUBLIC_IP%:%HAVEN_PORT%
    echo.
    echo  NOTE: Running without SSL. Voice chat and
    echo  remote connections work best with HTTPS.
    echo  See GUIDE.md for how to enable HTTPS.
)
echo.
echo  ----------------------------------------
echo   Run "Stop Haven.bat" to stop the server.
echo   Do NOT close this window directly.
echo  ----------------------------------------
echo.

:: Keep the window open -- closing it would orphan the background node process.
:: The user should always use Stop Haven.bat to shut down cleanly.
exit