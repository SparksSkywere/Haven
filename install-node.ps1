# Downloads and installs Node.js 22 LTS (native modules have prebuilt binaries)

Clear-Host
Write-Host "[*] Fetching latest Node.js 22 LTS version..." -ForegroundColor Cyan

# Use Invoke-RestMethod with error handling to fetch the index, since Start-BitsTransfer can be unreliable on some systems and doesn't provide good error messages.
try {
    $index = Invoke-RestMethod 'https://nodejs.org/dist/index.json' -ErrorAction Stop
} catch {
    Write-Host "[ERROR] Could not reach nodejs.org. Check your internet connection." -ForegroundColor Red
    exit 1
}

# Find the latest 22.x LTS version. If not found, fall back to any LTS (in case 22.x was removed from the index).
$lts = $index | Where-Object { $_.lts -and $_.version -match '^v22\.' } | Select-Object -First 1
if (-not $lts) {
    $lts = $index | Where-Object { $_.lts } | Select-Object -First 1
}
if (-not $lts) {
    Write-Host "[ERROR] Could not determine LTS version." -ForegroundColor Red
    exit 1
}

# Download and install the MSI for the latest LTS version
$version = $lts.version
Write-Host "[*] Installing Node.js $version (LTS)" -ForegroundColor Cyan
$url = "https://nodejs.org/dist/$version/node-$version-x64.msi"
$msiPath = "$env:TEMP\node-$version-x64.msi"
Write-Host "[*] Downloading Node.js installer (this may take a minute)..." -ForegroundColor Cyan

# Use Invoke-WebRequest with error handling to download the MSI, since Start-BitsTransfer can be unreliable on some systems and doesn't provide good error messages.
try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $url -OutFile $msiPath -UseBasicParsing -ErrorAction Stop
    $ProgressPreference = 'Continue'
} catch {
    Write-Host "[ERROR] Download failed: $_" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $msiPath)) {
    Write-Host "[ERROR] Download failed - file not found." -ForegroundColor Red
    exit 1
}

# Get the file size in MB for display
$size = [math]::Round((Get-Item $msiPath).Length / 1MB, 1)
Write-Host "[OK] Downloaded ($size MB)" -ForegroundColor Green
Write-Host "[*] Installing Node.js (you may see a UAC prompt)..." -ForegroundColor Cyan

# Start the installer and wait for it to finish, with error handling. The /qb flag shows a basic progress bar without user interaction.
try {
    $process = Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qb" -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Host "[ERROR] Installer exited with code $($process.ExitCode)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[ERROR] Installation failed: $_" -ForegroundColor Red
    exit 1
}

# Verify installation by checking node.exe version and then exit
try {
    $nodeVersion = & node -v
    Write-Host "[OK] Node.js $nodeVersion installed successfully!" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Node.js installation verification failed: $_" -ForegroundColor Red
    exit 1
}
Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
exit 0