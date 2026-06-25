#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Script Setup VPS - Chay 1 lenh duy nhat tren VPS
.DESCRIPTION
    Tu dong cai dat Script Server tren VPS
    Bao gom: tao thu muc, download script, khoi dong server
.EXAMPLE
    irm https://raw.githubusercontent.com/thanhan92-f1/Windows-Genuine-License-Tool/main/setup-vps.ps1 | iex
#>

param(
    [int]$Port = 8888,
    [string]$InstallDir = "C:\PhoTueScripts"
)

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "   VPS SETUP - Pho Tue SoftWare Solutions JSC" -ForegroundColor White
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host ""

# Buoc 1: Tao thu muc
Write-Host "  [1/4] Tao thu muc cai dat..." -ForegroundColor Yellow
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    New-Item -ItemType Directory -Path "$InstallDir\scripts" -Force | Out-Null
    Write-Host "        [OK] Da tao: $InstallDir" -ForegroundColor Green
} else {
    Write-Host "        [OK] Thu muc da ton tai" -ForegroundColor Green
}

# Buoc 2: Download Cleanup Script
Write-Host "  [2/4] Download Cleanup Script..." -ForegroundColor Yellow
$scriptContent = @'
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Tool go bo License Windows lau & chuan hoa he thong
.DESCRIPTION
    Quet va xoa cac cong cu crack KMS, AutoKMS, KMSpico...
    Phuc vu phong may Cyber Game, PC ca nhan, doanh nghiep.
.AUTHOR
    Pho Tue SoftWare Solutions JSC
.VERSION
    1.0
.NOTES
    Chay voi quyen Administrator
#>

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "`n  [LOI] Ban can chay voi quyen Administrator!" -ForegroundColor Red
    Write-Host "  Mo PowerShell Admin va chay lai.`n" -ForegroundColor Yellow
    pause
    return
}

$LogFile = Join-Path $env:TEMP "Windows_Cleanup_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$HostsBackup = "$HostsPath.backup_$(Get-Date -Format 'yyyyMMdd')"

$KMSDirectories = @(
    "$env:ProgramFiles\KMSpico"
    "${env:ProgramFiles(x86)}\KMSpico"
    "$env:ProgramData\KMSAutoS"
    "$env:ProgramData\KMSAuto"
    "$env:SystemRoot\KMS-R@1n"
    "$env:ProgramFiles\KMSAuto"
    "$env:ProgramFiles\KMSAuto Net"
    "$env:ProgramFiles\KMS_VL_ALL"
    "$env:ProgramData\Microsoft\KMS"
)

$KMSFiles = @(
    "$env:SystemRoot\System32\SppExtComObjHook.dll"
    "$env:SystemRoot\System32\skc.dll"
    "$env:SystemRoot\System32\KMS-R@1n.dll"
    "$env:SystemRoot\SysWOW64\SppExtComObjHook.dll"
)

$KMSTasks = @(
    "AutoKMS"
    "KMSAuto"
    "KMSAutoNet"
    "SvcRestartTask"
    "KMSpico"
    "KMS-R@1n"
    "KMS Activation"
    "Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTask"
)

$KMSRegistryKeys = @(
    @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform\KMSActivation"; Name = $null }
    @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name = "KMSAuto" }
    @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name = "KMSpico" }
    @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name = "AutoKMS" }
    @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name = "KMSAuto" }
    @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name = "KMSpico" }
    @{ Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"; Name = "KMSAuto" }
    @{ Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"; Name = "KMSpico" }
)

function Write-Log { param([string]$Message); "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8 }
function Write-Header { param([string]$Title); Write-Host ""; Write-Host "  $([string]::new([char]0x2550, 60))" -ForegroundColor Cyan; Write-Host "  $Title" -ForegroundColor White; Write-Host "  $([string]::new([char]0x2550, 60))" -ForegroundColor Cyan; Write-Host "" }
function Write-Step { param([string]$Step,[string]$Message,[string]$Status="INFO"); $c=@{"OK"="Green";"WARN"="Yellow";"ERROR"="Red";"DEL"="Magenta"}[$Status]; if(!$c){$c="White"}; Write-Host "  [$Step] $Message" -ForegroundColor $c; Write-Log "$Step - $Message" }

function Run-Slmgr { param([string]$Arguments,[string]$Description); Write-Step "RUN" "$Description..."; try { $p=Start-Process cscript.exe -ArgumentList "//NoLogo","$env:SystemRoot\System32\slmgr.vbs",$Arguments -Wait -PassThru -WindowStyle Hidden; if($p.ExitCode-eq 0){Write-Step "OK" "$Description - Thanh cong" "OK"}else{Write-Step "!" "Co the da duoc thuc hien truoc do" "WARN"} } catch { Write-Step "!" "Loi: $_" "ERROR" } }

function Remove-ProductKey { Run-Slmgr "/upk" "Go Product Key hien tai" }
function Remove-KeyFromRegistry { Run-Slmgr "/cpky" "Xoa key khoi Registry" }
function Remove-KMSInfo { Run-Slmgr "/ckms" "Xoa thong tin KMS server gia" }
function Reset-LicenseStatus { Run-Slmgr "/rearm" "Reset trang thai License ve mac dinh" }

function Remove-KMSFiles {
    Write-Step "SCAN" "Quet va xoa file/thu muc KMS..."
    $count = 0
    foreach ($dir in $KMSDirectories) {
        if (Test-Path $dir) {
            try { Remove-Item -Path $dir -Recurse -Force -EA Stop; Write-Step "X" "Da xoa: $dir" "DEL"; $count++ } catch { Write-Step "!" "Khong the xoa: $dir" "ERROR" }
        }
    }
    foreach ($file in $KMSFiles) {
        if (Test-Path $file) {
            try { takeown /f $file 2>$null | Out-Null; icacls $file /grant administrators:F 2>$null | Out-Null; Remove-Item $file -Force -EA Stop; Write-Step "X" "Da xoa: $file" "DEL"; $count++ } catch { Write-Step "!" "Khong the xoa: $file" "ERROR" }
        }
    }
    foreach ($pattern in @("KMS*.dll","kms*.dll","*KMS*.exe","*kms*.exe")) {
        Get-ChildItem "$env:SystemRoot\System32" -Filter $pattern -EA SilentlyContinue | ForEach-Object {
            try { Remove-Item $_.FullName -Force -EA Stop; Write-Step "X" "Da xoa: $($_.FullName)" "DEL"; $count++ } catch {}
        }
    }
    if ($count -eq 0) { Write-Step "OK" "Khong tim thay file KMS nao" "OK" } else { Write-Step "DONE" "Da xoa $count muc" "OK" }
}

function Remove-KMSScheduledTasks {
    Write-Step "SCAN" "Quet va xoa Scheduled Tasks KMS..."
    $count = 0
    foreach ($task in $KMSTasks) {
        try { if (Get-ScheduledTask -TaskName $task -EA SilentlyContinue) { Unregister-ScheduledTask $task -Confirm:$false -EA Stop; Write-Step "X" "Da xoa task: $task" "DEL"; $count++ } } catch {}
    }
    Get-ScheduledTask | Where-Object { $_.TaskName -match "KMS|kms|AutoKMS|KMSpico" } | ForEach-Object {
        try { Unregister-ScheduledTask $_.TaskName -Confirm:$false -EA Stop; Write-Step "X" "Da xoa task: $($_.TaskName)" "DEL"; $count++ } catch {}
    }
    if ($count -eq 0) { Write-Step "OK" "Khong tim thay task KMS nao" "OK" } else { Write-Step "DONE" "Da xoa $count tasks" "OK" }
}

function Remove-KMSRegistry {
    Write-Step "SCAN" "Quet va xoa Registry keys KMS..."
    $count = 0
    foreach ($entry in $KMSRegistryKeys) {
        try {
            if ($entry.Name) { if (Get-ItemProperty $entry.Path -Name $entry.Name -EA SilentlyContinue) { Remove-ItemProperty $entry.Path -Name $entry.Name -Force -EA Stop; Write-Step "X" "Da xoa: $($entry.Path) -> $($entry.Name)" "DEL"; $count++ } }
            else { if (Test-Path $entry.Path) { Remove-Item $entry.Path -Recurse -Force -EA Stop; Write-Step "X" "Da xoa: $($entry.Path)" "DEL"; $count++ } }
        } catch {}
    }
    if ($count -eq 0) { Write-Step "OK" "Khong tim thay registry KMS nao" "OK" } else { Write-Step "DONE" "Da xoa $count entries" "OK" }
}

function Repair-HostsFile {
    Write-Step "SCAN" "Kiem tra file Hosts..."
    if (-not (Test-Path $HostsPath)) { Write-Step "!" "Khong tim thay file hosts" "ERROR"; return }
    Copy-Item $HostsPath $HostsBackup -Force -EA SilentlyContinue
    $content = Get-Content $HostsPath
    $patterns = @("activation\.microsoft\.com","validation\.sls\.microsoft\.com","kms","crack","kmspico","kmsauto")
    $cleaned = $content | Where-Object { $line=$_; $keep=$true; foreach($p in $patterns){if($line-match $p){$keep=$false;break}}; $keep }
    $removed = ($content|Measure-Object).Count - ($cleaned|Measure-Object).Count
    if ($removed -gt 0) { $cleaned | Set-Content $HostsPath -Force -Encoding ASCII; Write-Step "OK" "Da xoa $removed dong block Microsoft" "OK" } else { Write-Step "OK" "File hosts sach" "OK" }
}

function Restore-Services {
    Write-Step "SCAN" "Khoi phuc dich vu he thong..."
    try { Set-Service wuauserv -StartupType Automatic -EA SilentlyContinue; Start-Service wuauserv -EA SilentlyContinue; Write-Step "OK" "Windows Update OK" "OK" } catch { Write-Step "!" "Khong the khoi phuc WU" "WARN" }
    try { Restart-Service sppsvc -Force -EA SilentlyContinue; Write-Step "OK" "Software Protection OK" "OK" } catch { Write-Step "!" "Khong the khoi phuc SP" "WARN" }
}

function Show-LicenseStatus {
    Write-Header "TRANG THAI LICENSE HIEN TAI"
    & cscript //NoLogo "$env:SystemRoot\System32\slmgr.vbs" /dlv; Write-Host ""
    & cscript //NoLogo "$env:SystemRoot\System32\slmgr.vbs" /xpr; Write-Host ""
}

function Invoke-FullCleanup {
    Write-Header "BAT DAU QUY TRINH CHUAN HOA HE THONG"
    Write-Log "=== BAT DAU CHUAN HOA ==="
    Write-Host "  Nhat ky: $LogFile" -ForegroundColor DarkGray; Write-Host ""
    Write-Step "1/8" "Go Product Key..."; Remove-ProductKey; Write-Host ""
    Write-Step "2/8" "Xoa key Registry..."; Remove-KeyFromRegistry; Write-Host ""
    Write-Step "3/8" "Xoa KMS server..."; Remove-KMSInfo; Write-Host ""
    Write-Step "4/8" "Reset License..."; Reset-LicenseStatus; Write-Host ""
    Write-Step "5/8" "Xoa file KMS..."; Remove-KMSFiles; Write-Host ""
    Write-Step "6/8" "Xoa Tasks KMS..."; Remove-KMSScheduledTasks; Write-Host ""
    Write-Step "7/8" "Sua Hosts..."; Repair-HostsFile; Write-Host ""
    Write-Step "8/8" "Khoi phuc dich vu..."; Restore-Services; Write-Host ""
    Write-Step "EXTRA" "Xoa Registry KMS..."; Remove-KMSRegistry; Write-Host ""
    Write-Log "=== HOAN TAT ==="
    Write-Host "  $([string]::new([char]0x2550, 60))" -ForegroundColor Green
    Write-Host "  HOAN TAT QUY TRINH CHUAN HOA!" -ForegroundColor Green
    Write-Host "  $([string]::new([char]0x2550, 60))" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [!] Khoi dong lai may de cap nhat hoan toan." -ForegroundColor Yellow
    Write-Host "  [!] Nhap key ban quyen chinh hang sau khi khoi dong." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Nhat ky: $LogFile" -ForegroundColor DarkGray
    Write-Host ""
    $r = Read-Host "  Khoi dong lai bay gio? (Y/N)"
    if ($r -eq 'Y' -or $r -eq 'y') { shutdown /r /t 10 /c "Chuan hoa he thong" }
}

$continue = $true
while ($continue) {
    Clear-Host
    Write-Host ""
    Write-Host "  $([string]::new([char]0x2550, 63))" -ForegroundColor Green
    Write-Host "     TOOL GO BO LICENSE WINDOWS LAU & CHUAN HOA HE THONG" -ForegroundColor White
    Write-Host "         Pho Tue SoftWare Solutions JSC - v1.0" -ForegroundColor DarkGray
    Write-Host "  $([string]::new([char]0x2550, 63))" -ForegroundColor Green
    Write-Host ""
    Write-Host "     [1] Go bo License lau & don dep he thong (TOAN BO)" -ForegroundColor White
    Write-Host "     [2] Chi go Product Key hien tai" -ForegroundColor White
    Write-Host "     [3] Chi xoa key khoi Registry" -ForegroundColor White
    Write-Host "     [4] Chi xoa thong tin KMS" -ForegroundColor White
    Write-Host "     [5] Don dep file & thu muc KMS rac" -ForegroundColor White
    Write-Host "     [6] Don dep Scheduled Tasks lien quan KMS" -ForegroundColor White
    Write-Host "     [7] Sua file Hosts (xoa block Microsoft)" -ForegroundColor White
    Write-Host "     [8] Kiem tra trang thai License hien tai" -ForegroundColor White
    Write-Host "     [9] Thoat" -ForegroundColor Red
    Write-Host ""
    Write-Host "  $([string]::new([char]0x2550, 63))" -ForegroundColor Green
    Write-Host ""
    $choice = Read-Host "  Chon chuc nang [1-9]"
    switch ($choice) {
        "1" { Invoke-FullCleanup }
        "2" { Write-Header "GO PRODUCT KEY"; Remove-ProductKey }
        "3" { Write-Header "XOA KEY REGISTRY"; Remove-KeyFromRegistry }
        "4" { Write-Header "XOA KMS"; Remove-KMSInfo; Reset-LicenseStatus }
        "5" { Write-Header "XOA FILE KMS"; Remove-KMSFiles }
        "6" { Write-Header "XOA TASKS KMS"; Remove-KMSScheduledTasks }
        "7" { Write-Header "SUA HOSTS"; Repair-HostsFile }
        "8" { Show-LicenseStatus }
        "9" { $continue = $false }
        default { Write-Host "  [!] Lua chon khong hop le." -ForegroundColor Red; Start-Sleep 1 }
    }
    if ($continue) { Write-Host ""; pause }
}

Write-Host ""
Write-Host "  $([string]::new([char]0x2550, 60))" -ForegroundColor Cyan
Write-Host "   Cam on ban da su dung Tool!" -ForegroundColor White
Write-Host "   Pho Tue SoftWare Solutions JSC" -ForegroundColor DarkGray
Write-Host "   Hotline: 0865.920.041" -ForegroundColor DarkGray
Write-Host "  $([string]::new([char]0x2550, 60))" -ForegroundColor Cyan
Write-Host ""
'@

$scriptContent | Out-File -FilePath "$InstallDir\scripts\Windows_License_Cleanup.ps1" -Encoding UTF8
Write-Host "        [OK] Da tao Cleanup Script" -ForegroundColor Green

# Buoc 3: Tao Server Script
Write-Host "  [3/4] Tao Script Server..." -ForegroundColor Yellow

$serverContent = @'
param([int]$Port = 8888, [string]$ScriptDir = "$PSScriptRoot\scripts")
if (-not (Test-Path $ScriptDir)) { New-Item -ItemType Directory -Path $ScriptDir -Force | Out-Null }
try { New-NetFirewallRule -DisplayName "PS-Script-Server-$Port" -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow -EA SilentlyContinue | Out-Null } catch {}
try { $publicIP = (Invoke-RestMethod "https://api.ipify.org" -TimeoutSec 5) } catch { $publicIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne '127.0.0.1' } | Select-Object -First 1).IPAddress }
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://+:$Port/")
$listener.Start()
Write-Host ""
Write-Host "  $([string]::new([char]0x2550, 60))" -ForegroundColor Cyan
Write-Host "  VPS SCRIPT SERVER - Pho Tue SoftWare Solutions JSC" -ForegroundColor White
Write-Host "  $([string]::new([char]0x2550, 60))" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Server dang chay tren port: $Port" -ForegroundColor Green
Write-Host ""
Write-Host "  Client su dung lenh:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  irm https://irm-genuine-license-windows.hitechcloud.vn | iex" -ForegroundColor White
    Write-Host "  (hoac: irm http://${publicIP}:${Port} | iex)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Nhan Ctrl+C de tat server" -ForegroundColor DarkGray
Write-Host "  $([string]::new([char]0x2550, 60))" -ForegroundColor Cyan
Write-Host ""
while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $file = $request.Url.LocalPath.TrimStart('/')
        $mainScript = Get-ChildItem $ScriptDir -Filter "*.ps1" -EA SilentlyContinue | Select-Object -First 1
        if ($file -eq "" -or $file -eq "index") {
            if ($mainScript) {
                $content = Get-Content $mainScript.FullName -Raw -Encoding UTF8
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
                $response.ContentType = "text/plain; charset=utf-8"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                Write-Host "  [$(Get-Date -Format 'HH:mm:ss')] -> Phuc vu: $($mainScript.Name)" -ForegroundColor Green
            } else {
                $buffer = [System.Text.Encoding]::UTF8.GetBytes("# Khong tim thay script")
                $response.StatusCode = 404
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
        } else {
            $filePath = Join-Path $ScriptDir $file
            if (Test-Path $filePath) {
                $content = Get-Content $filePath -Raw -Encoding UTF8
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
                $response.ContentType = "text/plain; charset=utf-8"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                Write-Host "  [$(Get-Date -Format 'HH:mm:ss')] -> $file" -ForegroundColor Green
            } else {
                $buffer = [System.Text.Encoding]::UTF8.GetBytes("# 404 Not Found")
                $response.StatusCode = 404
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                Write-Host "  [$(Get-Date -Format 'HH:mm:ss')] -> 404: $file" -ForegroundColor Red
            }
        }
        $response.OutputStream.Close()
    } catch { if ($listener.IsListening) { Write-Host "  [!] Error: $_" -ForegroundColor Red } }
}
'@

$serverContent | Out-File -FilePath "$InstallDir\Start-Server.ps1" -Encoding UTF8
Write-Host "        [OK] Da tao Script Server" -ForegroundColor Green

# Buoc 4: Mo firewall
Write-Host "  [4/4] Cau hinh firewall..." -ForegroundColor Yellow
try {
    New-NetFirewallRule -DisplayName "PhoTue-Script-Server" -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow -EA SilentlyContinue | Out-Null
    Write-Host "        [OK] Da mo port $Port" -ForegroundColor Green
} catch {
    Write-Host "        [!] Khong the mo port (co the da ton tai)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Green
Write-Host "   CAI DAT THANH CONG!" -ForegroundColor Green
Write-Host "  ============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  De khoi dong server, chay:" -ForegroundColor Yellow
Write-Host ""
Write-Host "    powershell -File $InstallDir\Start-Server.ps1" -ForegroundColor White
Write-Host ""
Write-Host "  Client chi can chay 1 lenh:" -ForegroundColor Yellow
Write-Host ""
Write-Host "    irm http://${publicIP}:${Port}/Windows_License_Cleanup.ps1 | iex" -ForegroundColor White
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Green
Write-Host ""

$start = Read-Host "  Ban co muon khoi dong server ngay bay gio? (Y/N)"
if ($start -eq 'Y' -or $start -eq 'y') {
    Write-Host ""
    Write-Host "  Dang khoi dong server..." -ForegroundColor Cyan
    & powershell -File "$InstallDir\Start-Server.ps1"
}
