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
    Su dung: irm https://YOUR-DOMAIN.COM/Windows_License_Cleanup.ps1 | iex
#>

# Kiem tra quyen Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "`n  [LOI] Ban can chay voi quyen Administrator!" -ForegroundColor Red
    Write-Host "  Chuot phai vao PowerShell chon 'Run as administrator'" -ForegroundColor Yellow
    Write-Host "  Hoac su dung lenh: irm ... | iex trong PowerShell Admin`n" -ForegroundColor Yellow
    pause
    return
}

# ============================================================
#  BIEN CAU HINH
# ============================================================
$LogFile = Join-Path $env:TEMP "Windows_Cleanup_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$HostsBackup = "$HostsPath.backup_$(Get-Date -Format 'yyyyMMdd')"

# Danh sach thu muc KMS
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

# Danh sach file KMS
$KMSFiles = @(
    "$env:SystemRoot\System32\SppExtComObjHook.dll"
    "$env:SystemRoot\System32\skc.dll"
    "$env:SystemRoot\System32\KMS-R@1n.dll"
    "$env:SystemRoot\SysWOW64\SppExtComObjHook.dll"
)

# Danh sach Scheduled Tasks
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

# Danh sach Registry Keys
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

# ============================================================
#  HAM HO TRO
# ============================================================
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "  $('=' * 60)" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor White
    Write-Host "  $('=' * 60)" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Step, [string]$Message, [string]$Status = "INFO")
    $color = switch ($Status) {
        "OK"    { "Green" }
        "WARN"  { "Yellow" }
        "ERROR" { "Red" }
        "DEL"   { "Magenta" }
        default { "White" }
    }
    Write-Host "  [$Step] $Message" -ForegroundColor $color
    Write-Log "$Step - $Message"
}

function Run-Slmgr {
    param([string]$Arguments, [string]$Description)
    Write-Step "RUN" "$Description..."
    try {
        $process = Start-Process -FilePath "cscript.exe" -ArgumentList "//NoLogo", "$env:SystemRoot\System32\slmgr.vbs", $Arguments -Wait -PassThru -WindowStyle Hidden
        if ($process.ExitCode -eq 0) {
            Write-Step "OK" "$Description - Thanh cong" "OK"
        } else {
            Write-Step "!" "$Description - Co the da duoc thuc hien truoc do" "WARN"
        }
    } catch {
        Write-Step "!" "$Description - Loi: $_" "ERROR"
    }
}

# ============================================================
#  CAC CHUC NANG CHINH
# ============================================================

function Remove-ProductKey {
    Run-Slmgr -Arguments "/upk" -Description "Go Product Key hien tai"
}

function Remove-KeyFromRegistry {
    Run-Slmgr -Arguments "/cpky" -Description "Xoa key khoi Registry"
}

function Remove-KMSInfo {
    Run-Slmgr -Arguments "/ckms" -Description "Xoa thong tin KMS server gia"
}

function Reset-LicenseStatus {
    Run-Slmgr -Arguments "/rearm" -Description "Reset trang thai License ve mac dinh"
}

function Remove-KMSFiles {
    Write-Step "SCAN" "Quet va xoa file/thu muc KMS..."
    $count = 0

    foreach ($dir in $KMSDirectories) {
        if (Test-Path $dir) {
            try {
                Remove-Item -Path $dir -Recurse -Force -ErrorAction Stop
                Write-Step "X" "Da xoa thu muc: $dir" "DEL"
                $count++
            } catch {
                Write-Step "!" "Khong the xoa: $dir - $_" "ERROR"
            }
        }
    }

    foreach ($file in $KMSFiles) {
        if (Test-Path $file) {
            try {
                # Lay quyen so huu va xoa
                takeown /f $file 2>$null | Out-Null
                icacls $file /grant administrators:F 2>$null | Out-Null
                Remove-Item -Path $file -Force -ErrorAction Stop
                Write-Step "X" "Da xoa file: $file" "DEL"
                $count++
            } catch {
                Write-Step "!" "Khong the xoa: $file - $_" "ERROR"
            }
        }
    }

    # Quet them cac file KMS trong System32
    $kmsPattern = @("KMS*.dll", "kms*.dll", "*KMS*.exe", "*kms*.exe")
    foreach ($pattern in $kmsPattern) {
        Get-ChildItem -Path "$env:SystemRoot\System32" -Filter $pattern -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-Item -Path $_.FullName -Force -ErrorAction Stop
                Write-Step "X" "Da xoa file: $($_.FullName)" "DEL"
                $count++
            } catch {
                Write-Step "!" "Khong the xoa: $($_.FullName)" "ERROR"
            }
        }
    }

    if ($count -eq 0) {
        Write-Step "OK" "Khong tim thay file/thu muc KMS nao" "OK"
    } else {
        Write-Step "DONE" "Da xoa tong cong $count muc" "OK"
    }
}

function Remove-KMSScheduledTasks {
    Write-Step "SCAN" "Quet va xoa Scheduled Tasks lien quan KMS..."
    $count = 0

    foreach ($task in $KMSTasks) {
        try {
            $existingTask = Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
            if ($existingTask) {
                Unregister-ScheduledTask -TaskName $task -Confirm:$false -ErrorAction Stop
                Write-Step "X" "Da xoa task: $task" "DEL"
                $count++
            }
        } catch {
            Write-Step "!" "Khong the xoa task: $task - $_" "ERROR"
        }
    }

    # Quet them cac task chua tu khoa KMS
    try {
        Get-ScheduledTask | Where-Object { $_.TaskName -match "KMS|kms|AutoKMS|KMSpico" } | ForEach-Object {
            try {
                Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false -ErrorAction Stop
                Write-Step "X" "Da xoa task phu hop: $($_.TaskName)" "DEL"
                $count++
            } catch {
                Write-Step "!" "Khong the xoa: $($_.TaskName)" "ERROR"
            }
        }
    } catch { }

    if ($count -eq 0) {
        Write-Step "OK" "Khong tim thay Scheduled Tasks KMS nao" "OK"
    } else {
        Write-Step "DONE" "Da xoa tong cong $count tasks" "OK"
    }
}

function Remove-KMSRegistry {
    Write-Step "SCAN" "Quet va xoa Registry keys lien quan KMS..."
    $count = 0

    foreach ($entry in $KMSRegistryKeys) {
        try {
            if ($entry.Name) {
                if (Get-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue) {
                    Remove-ItemProperty -Path $entry.Path -Name $entry.Name -Force -ErrorAction Stop
                    Write-Step "X" "Da xoa registry: $($entry.Path) -> $($entry.Name)" "DEL"
                    $count++
                }
            } else {
                if (Test-Path $entry.Path) {
                    Remove-Item -Path $entry.Path -Recurse -Force -ErrorAction Stop
                    Write-Step "X" "Da xoa registry key: $($entry.Path)" "DEL"
                    $count++
                }
            }
        } catch {
            Write-Step "!" "Khong the xoa registry: $($entry.Path) - $_" "ERROR"
        }
    }

    if ($count -eq 0) {
        Write-Step "OK" "Khong tim thay Registry KMS nao" "OK"
    } else {
        Write-Step "DONE" "Da xoa tong cong $count registry entries" "OK"
    }
}

function Repair-HostsFile {
    Write-Step "SCAN" "Kiem tra va sua file Hosts..."

    if (-not (Test-Path $HostsPath)) {
        Write-Step "!" "Khong tim thay file hosts" "ERROR"
        return
    }

    # Sao luu
    try {
        Copy-Item -Path $HostsPath -Destination $HostsBackup -Force
        Write-Step "OK" "Da sao luu hosts tai: $HostsBackup" "OK"
    } catch {
        Write-Step "!" "Khong the sao luu file hosts" "WARN"
    }

    # Doc va loc
    $hostsContent = Get-Content -Path $HostsPath -ErrorAction SilentlyContinue
    $blockPatterns = @(
        "activation\.microsoft\.com"
        "validation\.sls\.microsoft\.com"
        "kms"
        "crack"
        "kmspico"
        "kmsauto"
    )

    $cleanedContent = $hostsContent | Where-Object {
        $line = $_
        $shouldKeep = $true
        foreach ($pattern in $blockPatterns) {
            if ($line -match $pattern) {
                $shouldKeep = $false
                break
            }
        }
        $shouldKeep
    }

    $removedCount = ($hostsContent | Measure-Object).Count - ($cleanedContent | Measure-Object).Count
    if ($removedCount -gt 0) {
        $cleanedContent | Set-Content -Path $HostsPath -Force -Encoding ASCII
        Write-Step "OK" "Da xoa $removedCount dong block Microsoft trong hosts" "OK"
    } else {
        Write-Step "OK" "File hosts sach, khong can xu ly" "OK"
    }
}

function Restore-Services {
    Write-Step "SCAN" "Khoi phuc dich vu he thong..."

    try {
        Set-Service -Name "wuauserv" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        Write-Step "OK" "Windows Update da duoc khoi phuc" "OK"
    } catch {
        Write-Step "!" "Khong the khoi phuc Windows Update" "WARN"
    }

    try {
        Restart-Service -Name "sppsvc" -Force -ErrorAction SilentlyContinue
        Write-Step "OK" "Software Protection da duoc khoi phuc" "OK"
    } catch {
        Write-Step "!" "Khong the khoi phuc Software Protection" "WARN"
    }
}

function Show-LicenseStatus {
    Write-Header "TRANG THAI LICENSE HIEN TAI"
    Write-Step "SCAN" "Dang kiem tra..."
    Write-Host ""

    # Hien thi thong tin chi tiet
    & cscript.exe //NoLogo "$env:SystemRoot\System32\slmgr.vbs" /dlv
    Write-Host ""
    Write-Host "  $('-' * 40)" -ForegroundColor DarkGray
    & cscript.exe //NoLogo "$env:SystemRoot\System32\slmgr.vbs" /xpr
    Write-Host ""
}

function Invoke-FullCleanup {
    Write-Header "BAT DAU QUY TRINH CHUAN HOA HE THONG TOAN DIEN"
    Write-Log "=== BAT DAU CHUAN HOA HE THONG ==="

    Write-Host "  Nhat ky luu tai: $LogFile" -ForegroundColor DarkGray
    Write-Host ""

    # Buoc 1
    Write-Step "1/8" "Go Product Key hien tai..."
    Remove-ProductKey
    Write-Host ""

    # Buoc 2
    Write-Step "2/8" "Xoa key khoi Registry..."
    Remove-KeyFromRegistry
    Write-Host ""

    # Buoc 3
    Write-Step "3/8" "Xoa thong tin KMS server gia..."
    Remove-KMSInfo
    Write-Host ""

    # Buoc 4
    Write-Step "4/8" "Reset trang thai License..."
    Reset-LicenseStatus
    Write-Host ""

    # Buoc 5
    Write-Step "5/8" "Don dep file va thu muc KMS rac..."
    Remove-KMSFiles
    Write-Host ""

    # Buoc 6
    Write-Step "6/8" "Don dep Scheduled Tasks KMS..."
    Remove-KMSScheduledTasks
    Write-Host ""

    # Buoc 7
    Write-Step "7/8" "Sua file Hosts..."
    Repair-HostsFile
    Write-Host ""

    # Buoc 8
    Write-Step "8/8" "Khoi phuc dich vu he thong..."
    Restore-Services
    Write-Host ""

    # Dọn dẹp Registry
    Write-Step "EXTRA" "Don dep Registry keys lien quan KMS..."
    Remove-KMSRegistry
    Write-Host ""

    Write-Log "=== HOAN TAT CHUAN HOA HE THONG ==="

    Write-Host "  $('=' * 60)" -ForegroundColor Green
    Write-Host "  HOAN TAT QUY TRINH CHUAN HOA HE THONG!" -ForegroundColor Green
    Write-Host "  $('=' * 60)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [!] BAN NEN KHOI DONG LAI MAY TINH DE CAP NHAT HOAN TOAN." -ForegroundColor Yellow
    Write-Host "  [!] Sau do, nhap key ban quyen chinh hang de kich hoat Windows." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Nhat ky da duoc luu tai: $LogFile" -ForegroundColor DarkGray
    Write-Host ""

    $reboot = Read-Host "  Ban co muon khoi dong lai may bay gio? (Y/N)"
    if ($reboot -eq 'Y' -or $reboot -eq 'y') {
        Write-Host "  Dang khoi dong lai may tinh sau 10 giay..." -ForegroundColor Cyan
        shutdown /r /t 10 /c "Khoi dong lai de hoan tat chuan hoa he thong"
    } else {
        Write-Host "  [!] Hay khoi dong lai may tinh khi ban san sang." -ForegroundColor Yellow
    }
}

# ============================================================
#  MENU CHINH
# ============================================================
function Show-Menu {
    $continue = $true
    while ($continue) {
        Clear-Host
        Write-Host ""
        Write-Host "  $('=' * 63)" -ForegroundColor Green
        Write-Host "     TOOL GO BO LICENSE WINDOWS LAU & CHUAN HOA HE THONG" -ForegroundColor White
        Write-Host "         Pho Tue SoftWare Solutions JSC - v1.0" -ForegroundColor DarkGray
        Write-Host "  $([char]0x2550)$(('=' * 61).Substring(1))" -ForegroundColor Green
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
        Write-Host "  $('=' * 63)" -ForegroundColor Green
        Write-Host ""

        $choice = Read-Host "  Chon chuc nang [1-9]"

        switch ($choice) {
            "1" { Invoke-FullCleanup }
            "2" { Write-Header "GO PRODUCT KEY"; Remove-ProductKey }
            "3" { Write-Header "XOA KEY KHOI REGISTRY"; Remove-KeyFromRegistry }
            "4" { Write-Header "XOA THONG TIN KMS"; Remove-KMSInfo; Reset-LicenseStatus }
            "5" { Write-Header "DON DEP FILE KMS"; Remove-KMSFiles }
            "6" { Write-Header "DON DEP SCHEDULED TASKS"; Remove-KMSScheduledTasks }
            "7" { Write-Header "SUA FILE HOSTS"; Repair-HostsFile }
            "8" { Show-LicenseStatus }
            "9" { $continue = $false }
            default { Write-Host "  [!] Lua chon khong hop le." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }

        if ($continue) {
            Write-Host ""
            pause
        }
    }

    Write-Host ""
    Write-Host "  $('=' * 60)" -ForegroundColor Cyan
    Write-Host "   Cam on ban da su dung Tool!" -ForegroundColor White
    Write-Host "   Pho Tue SoftWare Solutions JSC" -ForegroundColor DarkGray
    Write-Host "   Hotline: 0865.920.041" -ForegroundColor DarkGray
    Write-Host "   Email: info@photuesoftware.com" -ForegroundColor DarkGray
    Write-Host "  $('=' * 60)" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================
#  BAT DAU
# ============================================================
Write-Host ""
Write-Host "  Dang tai Windows License Cleanup Tool..." -ForegroundColor Cyan
Write-Host "  Pho Tue SoftWare Solutions JSC" -ForegroundColor DarkGray
Write-Host ""

Show-Menu
