# Roblox 多開解鎖器（需要系統管理員權限）
# 首次執行會自動從 Microsoft Sysinternals 下載 handle64.exe

# ---- 自動提升至系統管理員 ----
$current = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "需要系統管理員權限，正在請求 UAC..." -ForegroundColor Yellow
    Start-Process -FilePath "powershell.exe" `
                  -ArgumentList @("-NoProfile","-File","`"$PSCommandPath`"") `
                  -Verb RunAs
    exit
}

# ---- 確保 handle64.exe 就緒（不存在則自動下載）----
$toolDir = Join-Path $PSScriptRoot "handle_tool"
$handleExe = Join-Path $toolDir "handle64.exe"

if (-not (Test-Path $handleExe)) {
    Write-Host ""
    Write-Host "首次執行，正在從 Microsoft Sysinternals 下載 handle64.exe..." -ForegroundColor Cyan
    Write-Host "來源：https://download.sysinternals.com/files/Handle.zip" -ForegroundColor DarkGray

    if (-not (Test-Path $toolDir)) { New-Item -ItemType Directory -Path $toolDir | Out-Null }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $zipPath = Join-Path $toolDir "Handle.zip"
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Handle.zip" `
                          -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
        Expand-Archive -Path $zipPath -DestinationPath $toolDir -Force -ErrorAction Stop
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        # 接受 EULA
        & $handleExe -accepteula -nobanner 2>&1 | Out-Null
        Write-Host "[OK] 下載完成。" -ForegroundColor Green
    } catch {
        Write-Host "[錯誤] 下載失敗：$_" -ForegroundColor Red
        Write-Host "請手動下載 https://download.sysinternals.com/files/Handle.zip" -ForegroundColor Yellow
        Write-Host "解壓後將 handle64.exe 放到 $toolDir" -ForegroundColor Yellow
        Read-Host "按 Enter 鍵結束"
        exit 1
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    Roblox 多開解鎖器 (Administrator)" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# ---- 掃描所有持有 ROBLOX_singletonEvent 的處理程序 ----
Write-Host "[1/3] 掃描持有 ROBLOX_singletonEvent 的處理程序..." -ForegroundColor Cyan
$out = & $handleExe -accepteula -nobanner -a "ROBLOX_singletonEvent" 2>&1 | Out-String

$matches = [regex]::Matches($out, '(\S+\.exe)\s+pid:\s+(\d+)\s+type:\s+\S+\s+([0-9A-Fa-f]+):')
if ($matches.Count -eq 0) {
    Write-Host "[!] 找不到任何處理程序佔用該事件。" -ForegroundColor Yellow
    Write-Host "    請先啟動 Roblox，再執行本程式。" -ForegroundColor Yellow
    Read-Host "按 Enter 鍵結束"
    exit 0
}

Write-Host "    找到 $($matches.Count) 個控制代碼：" -ForegroundColor Green
foreach ($m in $matches) {
    Write-Host ("      $($m.Groups[1].Value) PID $($m.Groups[2].Value) 控制代碼 0x$($m.Groups[3].Value)") -ForegroundColor White
}

# ---- 逐個關閉 ----
Write-Host ""
Write-Host "[2/3] 關閉控制代碼..." -ForegroundColor Cyan
$ok = 0; $fail = 0
foreach ($m in $matches) {
    $name = $m.Groups[1].Value
    $procId = $m.Groups[2].Value
    $hid = $m.Groups[3].Value
    $r = & $handleExe -accepteula -nobanner -c $hid -p $procId -y 2>&1 | Out-String
    if ($r -match "closed" -and $r -notmatch "Error") {
        Write-Host "    [OK] $name PID $procId 控制代碼 0x$hid" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "    [失敗] $name PID $procId 控制代碼 0x$hid" -ForegroundColor Red
        Write-Host "         $($r.Trim())" -ForegroundColor DarkRed
        $fail++
    }
}

# ---- 驗證 ----
Write-Host ""
Write-Host "[3/3] 驗證..." -ForegroundColor Cyan
try {
    $h = [System.Threading.EventWaitHandle]::OpenExisting("ROBLOX_singletonEvent")
    Write-Host "    [警告] 事件仍然存在 — 可能尚未關閉全部控制代碼，或 Roblox 已重新建立。" -ForegroundColor Yellow
    $h.Close(); $h.Dispose()
} catch {
    Write-Host "    [成功] 事件已徹底釋放！" -ForegroundColor Green
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "完成。成功 $ok 個，失敗 $fail 個。" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "現在可以啟動第二個 Roblox（請用不同帳號登入）。" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "按 Enter 鍵結束"
