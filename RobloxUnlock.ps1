# Roblox Multi-Instance Unlocker (requires Administrator privileges)
# On first run, this script automatically downloads handle64.exe from Microsoft Sysinternals.

# ---- Auto-elevate to Administrator ----
$current = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Administrator privileges required. Requesting UAC elevation..." -ForegroundColor Yellow
    Start-Process -FilePath "powershell.exe" `
                  -ArgumentList @("-NoProfile","-File","`"$PSCommandPath`"") `
                  -Verb RunAs
    exit
}

# ---- Ensure handle64.exe is available (auto-download if missing) ----
$toolDir = Join-Path $PSScriptRoot "handle_tool"
$handleExe = Join-Path $toolDir "handle64.exe"

if (-not (Test-Path $handleExe)) {
    Write-Host ""
    Write-Host "First run detected. Downloading handle64.exe from Microsoft Sysinternals..." -ForegroundColor Cyan
    Write-Host "Source: https://download.sysinternals.com/files/Handle.zip" -ForegroundColor DarkGray

    if (-not (Test-Path $toolDir)) { New-Item -ItemType Directory -Path $toolDir | Out-Null }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $zipPath = Join-Path $toolDir "Handle.zip"
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Handle.zip" `
                          -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
        Expand-Archive -Path $zipPath -DestinationPath $toolDir -Force -ErrorAction Stop
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        # Accept Sysinternals EULA on first run
        & $handleExe -accepteula -nobanner 2>&1 | Out-Null
        Write-Host "[OK] Download complete." -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Download failed: $_" -ForegroundColor Red
        Write-Host "Please manually download https://download.sysinternals.com/files/Handle.zip" -ForegroundColor Yellow
        Write-Host "Extract handle64.exe to $toolDir" -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    Roblox Multi-Instance Unlocker (Admin)" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# ---- Scan for processes holding ROBLOX_singletonEvent ----
Write-Host "[1/3] Scanning processes holding ROBLOX_singletonEvent..." -ForegroundColor Cyan
$out = & $handleExe -accepteula -nobanner -a "ROBLOX_singletonEvent" 2>&1 | Out-String

$matches = [regex]::Matches($out, '(\S+\.exe)\s+pid:\s+(\d+)\s+type:\s+\S+\s+([0-9A-Fa-f]+):')
if ($matches.Count -eq 0) {
    Write-Host "[!] No process is holding the event." -ForegroundColor Yellow
    Write-Host "    Please launch Roblox first, then run this script." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 0
}

Write-Host "    Found $($matches.Count) handle(s):" -ForegroundColor Green
foreach ($m in $matches) {
    Write-Host ("      $($m.Groups[1].Value) PID $($m.Groups[2].Value) handle 0x$($m.Groups[3].Value)") -ForegroundColor White
}

# ---- Close each handle ----
Write-Host ""
Write-Host "[2/3] Closing handles..." -ForegroundColor Cyan
$ok = 0; $fail = 0
foreach ($m in $matches) {
    $name = $m.Groups[1].Value
    $procId = $m.Groups[2].Value
    $hid = $m.Groups[3].Value
    $r = & $handleExe -accepteula -nobanner -c $hid -p $procId -y 2>&1 | Out-String
    if ($r -match "closed" -and $r -notmatch "Error") {
        Write-Host "    [OK] $name PID $procId handle 0x$hid" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "    [FAIL] $name PID $procId handle 0x$hid" -ForegroundColor Red
        Write-Host "         $($r.Trim())" -ForegroundColor DarkRed
        $fail++
    }
}

# ---- Verify ----
Write-Host ""
Write-Host "[3/3] Verifying..." -ForegroundColor Cyan
try {
    $h = [System.Threading.EventWaitHandle]::OpenExisting("ROBLOX_singletonEvent")
    Write-Host "    [WARN] Event still exists. Some handles may not have been closed, or Roblox has recreated it." -ForegroundColor Yellow
    $h.Close(); $h.Dispose()
} catch {
    Write-Host "    [SUCCESS] Event has been fully released!" -ForegroundColor Green
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Done. Succeeded: $ok, Failed: $fail." -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "You can now launch a second Roblox client (use a different account to log in)." -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
