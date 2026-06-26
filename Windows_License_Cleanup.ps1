#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Tool go bo License Windows lau & chuan hoa he thong
.DESCRIPTION
    Quet va xoa cac cong cu crack KMS, AutoKMS, KMSpico...
    Phuc vu phong may Cyber Game, PC ca nhan, doanh nghiep.
.AUTHOR
    Pho Tue SoftWare And Technology Solutions Joint Stock Company

.VERSION
    1.0
.NOTES
    Chay voi quyen Administrator
    Su dung: irm https://irm-genuine-license-windows.hitechcloud.vn | iex
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
function Activate-NewLicense {
    Write-Header "NHAP & KICH HOAT KEY BAN QUYEN MOI"

    # Nhap key
    Write-Host "  Nhap Product Key (dang: XXXXX-XXXXX-XXXXX-XXXXX-XXXXX)" -ForegroundColor Cyan
    Write-Host "  Hoac nhan Enter de bo qua" -ForegroundColor DarkGray
    Write-Host ""
    $newKey = Read-Host "  Product Key"

    if ([string]::IsNullOrWhiteSpace($newKey)) {
        Write-Host "  [!] Khong co key nao duoc nhap." -ForegroundColor Yellow
        return
    }

    # Kiem tra dinh dang key (co gach ngang hoac khong)
    $cleanKey = $newKey.Trim() -replace '\s+', ''

    Write-Host ""
    Write-Step "1/3" "Dang nhap Product Key moi..."
    try {
        $process = Start-Process -FilePath "cscript.exe" -ArgumentList "//NoLogo", "$env:SystemRoot\System32\slmgr.vbs", "/ipk", $cleanKey -Wait -PassThru -WindowStyle Hidden
        if ($process.ExitCode -eq 0) {
            Write-Step "OK" "Nhap Product Key thanh cong!" "OK"
        } else {
            Write-Step "!" "Key khong hop le hoac loi." "ERROR"
            Write-Host ""
            Write-Host "  Kiem tra lai key va thu lai." -ForegroundColor Yellow
            return
        }
    } catch {
        Write-Step "!" "Loi khi nhap key: $_" "ERROR"
        return
    }

    Write-Host ""
    Write-Step "2/3" "Dang kich hoat Windows voi Microsoft..."
    try {
        $process = Start-Process -FilePath "cscript.exe" -ArgumentList "//NoLogo", "$env:SystemRoot\System32\slmgr.vbs", "/ato" -Wait -PassThru -WindowStyle Hidden
        if ($process.ExitCode -eq 0) {
            Write-Step "OK" "Kich hoat thanh cong!" "OK"
        } else {
            Write-Step "!" "Kich hoat that bai. Hay kiem tra ket noi mang va key." "WARN"
        }
    } catch {
        Write-Step "!" "Loi khi kich hoat: $_" "ERROR"
    }

    Write-Host ""
    Write-Step "3/3" "Kiem tra trang thai sau kich hoat..."
    Write-Host ""
    & cscript //NoLogo "$env:SystemRoot\System32\slmgr.vbs" /xpr
    Write-Host ""
    Write-Host "  Nhat ky: $LogFile" -ForegroundColor DarkGray
}

# ============================================================
#  CHUC NANG NANG CAP HOME -> PRO
# ============================================================

function Check-WindowsEdition {
    Write-Header "KIEM TRA PHIEN BAN WINDOWS HIEN TAI"

    Write-Step "SCAN" "Dang quet he thong..."
    Write-Host ""

    # Phien ban hien tai
    Write-Host "  ── Phien ban hien tai ──────────────────────────────────" -ForegroundColor Cyan
    & DISM /Online /Get-CurrentEdition 2>&1 | ForEach-Object {
        if ($_ -match "Current Edition\s*:\s*(.+)") {
            $edition = $Matches[1].Trim()
            Write-Host "  Phien ban: " -NoNewline
            $color = switch -Wildcard ($edition) {
                "*Professional*" { "Green" }
                "*Enterprise*"   { "Green" }
                "*Education*"    { "Green" }
                "*Core*"         { "Yellow" }
                default          { "White" }
            }
            Write-Host $edition -ForegroundColor $color
            Write-Log "Phien ban hien tai: $edition"
        }
    }
    Write-Host ""

    # Cac phien ban co the nang cap
    Write-Host "  ── Co the nang cap len ─────────────────────────────────" -ForegroundColor Cyan
    & DISM /Online /Get-TargetEditions 2>&1 | ForEach-Object {
        if ($_ -match "Target Edition\s*:\s*(.+)") {
            Write-Host "    -> $($Matches[1].Trim())" -ForegroundColor Green
        }
    }
    Write-Host ""

    # OEM Key trong BIOS
    Write-Host "  ── OEM Key (BIOS/UEFI) ────────────────────────────────" -ForegroundColor Cyan
    try {
        $oemKey = (Get-CimInstance -ClassName SoftwareLicensingService -ErrorAction SilentlyContinue).OA3xOriginalProductKey
        if ($oemKey) {
            Write-Host "  OEM Key: $oemKey" -ForegroundColor Green
        } else {
            Write-Host "  Khong tim thay OEM Key trong BIOS/UEFI" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "  Khong the doc OEM Key" -ForegroundColor DarkGray
    }
    Write-Host ""

    # Trang thai kich hoat
    Write-Host "  ── Trang thai kich hoat ────────────────────────────────" -ForegroundColor Cyan
    & cscript //NoLogo "$env:SystemRoot\System32\slmgr.vbs" /xpr 2>&1 | ForEach-Object {
        if ($_ -match ".+") { Write-Host "  $_" }
    }
    Write-Host ""

    # Key channel
    Write-Host "  ── Thong tin Key ───────────────────────────────────────" -ForegroundColor Cyan
    & cscript //NoLogo "$env:SystemRoot\System32\slmgr.vbs" /dli 2>&1 | ForEach-Object {
        if ($_ -match "Product Key Channel|Partial Product Key|License Status|Description") {
            Write-Host "  $_"
        }
    }
    Write-Host ""
}

function Fix-SystemErrors {
    Write-Header "SUA LOI HE THONG (DISM + SFC)"

    Write-Host "  Quy trinh nay se:" -ForegroundColor Cyan
    Write-Host "    1. Sua kho thanh phan he thong (DISM /RestoreHealth)" -ForegroundColor White
    Write-Host "    2. Kiem tra tinh toan ven file he thong (sfc /scannow)" -ForegroundColor White
    Write-Host "    3. Xoa bo nho dem Windows Update" -ForegroundColor White
    Write-Host ""
    Write-Host "  [!] Co the mat 10-30 phut. Vui long khong tat may." -ForegroundColor Yellow
    Write-Host ""

    $confirm = Read-Host "  Bat dau sua loi? (Y/N)"
    if ($confirm -ne 'Y' -and $confirm -ne 'y') { return }

    # Buoc 1: DISM RestoreHealth
    Write-Host ""
    Write-Step "1/4" "Dang sua kho thanh phan he thong (DISM)..."
    Write-Host "  [!] Dang chay, vui long doi..." -ForegroundColor Yellow
    & DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Step "OK" "DISM - Sua loi thanh cong" "OK"
    } else {
        Write-Step "!" "DISM - Co loi. Hay thu chay lai sau khoi dong." "WARN"
    }

    # Buoc 2: SFC
    Write-Host ""
    Write-Step "2/4" "Dang kiem tra tinh toan ven file he thong (sfc)..."
    Write-Host "  [!] Dang chay, vui long doi..." -ForegroundColor Yellow
    & sfc /scannow 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Step "OK" "SFC - Kiem tra thanh cong" "OK"
    } else {
        Write-Step "!" "SFC - Tim thay loi. Hay khoi dong lai va chay lai." "WARN"
    }

    # Buoc 3: Xoa bo nho dem Windows Update
    Write-Host ""
    Write-Step "3/4" "Dang xoa bo nho dem Windows Update..."

    $services = @("wuauserv", "bits", "cryptsvc", "msiserver")
    foreach ($svc in $services) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    }
    Write-Step "OK" "Da dung cac dich vu" "OK"

    $sdPath = "$env:SystemRoot\SoftwareDistribution"
    $crPath = "$env:SystemRoot\System32\catroot2"
    $sdOld = "$env:SystemRoot\SoftwareDistribution.old"
    $crOld = "$env:SystemRoot\System32\catroot2.old"

    if (Test-Path $sdPath) {
        Remove-Item -Path $sdOld -Recurse -Force -ErrorAction SilentlyContinue
        Rename-Item -Path $sdPath -NewName "SoftwareDistribution.old" -Force -ErrorAction SilentlyContinue
        Write-Step "OK" "Da doi ten SoftwareDistribution" "OK"
    }
    if (Test-Path $crPath) {
        Remove-Item -Path $crOld -Recurse -Force -ErrorAction SilentlyContinue
        Rename-Item -Path $crPath -NewName "catroot2.old" -Force -ErrorAction SilentlyContinue
        Write-Step "OK" "Da doi ten catroot2" "OK"
    }

    foreach ($svc in $services) {
        Start-Service -Name $svc -ErrorAction SilentlyContinue
    }
    Write-Step "OK" "Da khoi dong lai cac dich vu" "OK"

    # Buoc 4
    Write-Host ""
    Write-Step "4/4" "Kiem tra lai phien ban..."
    Write-Host ""
    & DISM /Online /Get-CurrentEdition 2>&1 | ForEach-Object {
        if ($_ -match "Current Edition\s*:\s*(.+)") {
            Write-Host "  Phien ban: $($Matches[1].Trim())" -ForegroundColor Cyan
        }
    }
    Write-Host ""

    Write-Host "  $('=' * 60)" -ForegroundColor Green
    Write-Host "  HOAN TAT SUA LOI HE THONG!" -ForegroundColor Green
    Write-Host "  $('=' * 60)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [!] Khoi dong lai may tinh truoc khi nang cap." -ForegroundColor Yellow
    Write-Host ""

    $reboot = Read-Host "  Khoi dong lai bay gio? (Y/N)"
    if ($reboot -eq 'Y' -or $reboot -eq 'y') {
        shutdown /r /t 10 /c "Khoi dong lai sau khi sua loi he thong"
    }
}

function Upgrade-HomeToPro {
    Write-Header "NANG CAP WINDOWS HOME -> PRO"

    Write-Step "SCAN" "Kiem tra phien ban hien tai..."
    $currentEdition = ""
    & DISM /Online /Get-CurrentEdition 2>&1 | ForEach-Object {
        if ($_ -match "Current Edition\s*:\s*(.+)") {
            $currentEdition = $Matches[1].Trim()
        }
    }
    Write-Host "  Phien ban: $currentEdition" -ForegroundColor Cyan
    Write-Host ""

    if ($currentEdition -match "Professional|Enterprise|Education") {
        Write-Host "  [!] May tinh da o phien ban cao hon Home." -ForegroundColor Yellow
        Write-Host "  Neu muon kich hoat, chon option [9] Nhap & kich hoat key." -ForegroundColor Cyan
        return
    }

    $canUpgrade = $false
    & DISM /Online /Get-TargetEditions 2>&1 | ForEach-Object {
        if ($_ -match "Professional") { $canUpgrade = $true }
    }

    if (-not $canUpgrade) {
        Write-Host "  [!] Phien ban hien tai khong ho tro nang cap len Pro." -ForegroundColor Red
        return
    }

    Write-Host "  Chon phuong thuc nang cap:" -ForegroundColor White
    Write-Host ""
    Write-Host "    [1] Nang cap bang generic key (khong kich hoat)" -ForegroundColor White
    Write-Host "       -> Dung de chuyen edition, sau do nhap key Pro de kich hoat" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    [2] Nang cap va kich hoat truc tiep bang key Pro" -ForegroundColor Green
    Write-Host "       -> Nhap key Pro hop le, nang cap va kich hoat ngay" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    [3] Nang cap bang DISM + key Pro" -ForegroundColor Yellow
    Write-Host "       -> Su dung DISM khi slmgr bi loi (0xC004F069, 0x8007371B)" -ForegroundColor DarkGray
    Write-Host ""

    $method = Read-Host "  Chon [1-3]"

    switch ($method) {
        "1" { Upgrade-WithGenericKey }
        "2" { Upgrade-WithProKey }
        "3" { Upgrade-WithDISM }
        default { Write-Host "  [!] Lua chon khong hop le." -ForegroundColor Red }
    }
}

function Upgrade-WithGenericKey {
    Write-Host ""
    Write-Step "GENERIC" "Nang cap bang generic key Windows Pro..."
    Write-Host ""
    Write-Host "  Generic key: VK7JG-NPHTM-C97JM-9MPGT-3V66T" -ForegroundColor DarkGray
    Write-Host "  [!] Key nay chi dung de CHUYEN EDITION, khong kich hoat ban quyen." -ForegroundColor Yellow
    Write-Host ""

    $confirm = Read-Host "  Tiep tuc? (Y/N)"
    if ($confirm -ne 'Y' -and $confirm -ne 'y') { return }

    Write-Host ""
    Write-Step "1/2" "Nhap generic key de chuyen sang Pro..."
    & cscript //NoLogo "$env:SystemRoot\System32\slmgr.vbs" /ipk VK7JG-NPHTM-C97JM-9MPGT-3V66T 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Step "OK" "Da nhap generic key thanh cong" "OK"
    } else {
        Write-Step "!" "Loi khi nhap generic key" "ERROR"
        return
    }

    Write-Host ""
    Write-Step "2/2" "Kich hoat chuyen doi..."
    & cscript //NoLogo "$env:SystemRoot\System32\slmgr.vbs" /ato 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Step "OK" "Chuyen doi thanh cong!" "OK"
    } else {
        Write-Step "!" "Chuyen doi that bai. Hay thu dung DISM (option 3)." "WARN"
    }

    Write-Host ""
    Write-Host "  $('=' * 60)" -ForegroundColor Green
    Write-Host "  DA CHUYEN SANG WINDOWS PRO!" -ForegroundColor Green
    Write-Host "  $('=' * 60)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [!] Bay gio hay nhap key Pro CHINH HANG de kich hoat:" -ForegroundColor Yellow
    Write-Host "  Chon option [9] Nhap & kich hoat key ban quyen moi" -ForegroundColor Cyan
    Write-Host ""

    $reboot = Read-Host "  Khoi dong lai bay gio? (Y/N)"
    if ($reboot -eq 'Y' -or $reboot -eq 'y') {
        shutdown /r /t 10 /c "Khoi dong lai sau khi nang cap len Windows Pro"
    }
}

function Upgrade-WithProKey {
    Write-Host ""
    Write-Step "PRO" "Nang cap va kich hoat bang key Pro..."
    Write-Host ""

    $newKey = Read-Host "  Nhap Product Key Windows 11 Pro"
    if ([string]::IsNullOrWhiteSpace($newKey)) {
        Write-Host "  [!] Khong co key nao duoc nhap." -ForegroundColor Yellow
        return
    }

    $cleanKey = $newKey.Trim() -replace '\s+', ''
    Write-Host ""

    Write-Step "1/3" "Nhap Product Key Pro..."
    & cscript //NoLogo "$env:SystemRoot\System32\slmgr.vbs" /ipk $cleanKey 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Step "OK" "Nhap key thanh cong!" "OK"
    } else {
        Write-Step "!" "Loi nhap key. Thu dung DISM (option 3)." "ERROR"
        return
    }

    Write-Host ""
    Write-Step "2/3" "Kich hoat voi Microsoft..."
    & cscript //NoLogo "$env:SystemRoot\System32\slmgr.vbs" /ato 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Step "OK" "Kich hoat thanh cong!" "OK"
    } else {
        Write-Step "!" "Kich hoat that bai. Hay kiem tra key va ket noi mang." "WARN"
        Write-Host "  Neu gap loi 0xC004F069, hay chon option [3] DISM." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Step "3/3" "Kiem tra ket qua..."
    Write-Host ""
    & cscript //NoLogo "$env:SystemRoot\System32\slmgr.vbs" /xpr

    Write-Host ""
    $reboot = Read-Host "  Khoi dong lai bay gio? (Y/N)"
    if ($reboot -eq 'Y' -or $reboot -eq 'y') {
        shutdown /r /t 10 /c "Khoi dong lai sau khi nang cap len Windows Pro"
    }
}

function Upgrade-WithDISM {
    Write-Host ""
    Write-Step "DISM" "Nang cap bang DISM (khac phuc loi 0xC004F069 / 0x8007371B)..."
    Write-Host ""
    Write-Host "  Phuong thuc nay su dung DISM de nang cap edition." -ForegroundColor Cyan
    Write-Host "  Khac phuc cac loi lien quan den slmgr.vbs." -ForegroundColor Cyan
    Write-Host ""

    $newKey = Read-Host "  Nhap Product Key Windows 11 Pro"
    if ([string]::IsNullOrWhiteSpace($newKey)) {
        Write-Host "  [!] Khong co key nao duoc nhap." -ForegroundColor Yellow
        return
    }

    $cleanKey = $newKey.Trim() -replace '\s+', ''
    Write-Host ""

    Write-Step "1/2" "Sua loi he thong truoc khi nang cap..."
    Write-Host "  [!] Dang chay DISM RestoreHealth, vui long doi..." -ForegroundColor Yellow
    & DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-Null
    Write-Step "OK" "Da sua loi he thong" "OK"

    Write-Host ""
    Write-Step "2/2" "Nang cap bang DISM..."
    Write-Host "  [!] Dang nang cap, co the mat vai phut..." -ForegroundColor Yellow
    Write-Host ""

    $dismResult = & DISM /Online /Set-Edition:Professional /ProductKey:$cleanKey /AcceptEula 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "  $('=' * 60)" -ForegroundColor Green
        Write-Host "  NANG CAP THANH CONG!" -ForegroundColor Green
        Write-Host "  $('=' * 60)" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Step "!" "Nang cap that bai:" "ERROR"
        Write-Host ""
        $dismResult | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        Write-Host ""
        Write-Host "  Cach khac phuc:" -ForegroundColor Yellow
        Write-Host "    1. Chon option [10] Sua loi he thong (DISM + SFC)" -ForegroundColor White
        Write-Host "    2. Khoi dong lai may" -ForegroundColor White
        Write-Host "    3. Thu lai option nay" -ForegroundColor White
        return
    }

    $reboot = Read-Host "  Khoi dong lai bay gio? (Y/N)"
    if ($reboot -eq 'Y' -or $reboot -eq 'y') {
        shutdown /r /t 10 /c "Khoi dong lai sau khi nang cap len Windows Pro (DISM)"
    }
}

function Invoke-FullUpgradeFlow {
    Write-Header "QUY TRINH NANG CAP TOAN DIEN"

    Write-Host "  Quy trinh nay se thuc hien:" -ForegroundColor Cyan
    Write-Host "    1. Kiem tra phien ban hien tai" -ForegroundColor White
    Write-Host "    2. Sua loi he thong (DISM + SFC)" -ForegroundColor White
    Write-Host "    3. Go bo license cu (neu co crack)" -ForegroundColor White
    Write-Host "    4. Nang cap Home -> Pro" -ForegroundColor White
    Write-Host "    5. Kich hoat bang key ban quyen" -ForegroundColor White
    Write-Host ""
    Write-Host "  [!] Mat khoang 30-60 phut. Khong tat may." -ForegroundColor Yellow
    Write-Host ""

    $confirm = Read-Host "  Bat dau quy trinh? (Y/N)"
    if ($confirm -ne 'Y' -and $confirm -ne 'y') { return }

    # Buoc 1: Kiem tra
    Write-Host ""
    Write-Step "1/5" "Kiem tra phien ban hien tai..."
    $currentEdition = ""
    & DISM /Online /Get-CurrentEdition 2>&1 | ForEach-Object {
        if ($_ -match "Current Edition\s*:\s*(.+)") {
            $currentEdition = $Matches[1].Trim()
        }
    }
    Write-Host "  Phien ban: $currentEdition" -ForegroundColor Cyan

    $needUpgrade = $currentEdition -notmatch "Professional|Enterprise|Education"

    # Buoc 2: Sua loi he thong
    Write-Host ""
    Write-Step "2/5" "Sua loi he thong (DISM + SFC)..."
    Write-Host "  [!] Dang chay DISM, vui long doi..." -ForegroundColor Yellow
    & DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-Null
    Write-Step "OK" "DISM hoan tat" "OK"
    Write-Host "  [!] Dang chay SFC, vui long doi..." -ForegroundColor Yellow
    & sfc /scannow 2>&1 | Out-Null
    Write-Step "OK" "SFC hoan tat" "OK"

    # Buoc 3: Go bo license cu
    Write-Host ""
    Write-Step "3/5" "Go bo license cu..."
    Remove-ProductKey
    Remove-KeyFromRegistry
    Remove-KMSInfo
    Reset-LicenseStatus

    # Buoc 4: Nang cap
    if ($needUpgrade) {
        Write-Host ""
        Write-Step "4/5" "Nang cap Home -> Pro bang generic key..."
        & cscript //NoLogo "$env:SystemRoot\System32\slmgr.vbs" /ipk VK7JG-NPHTM-C97JM-9MPGT-3V66T 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Step "OK" "Da nhap generic key" "OK"
        } else {
            Write-Step "!" "slmgr loi. Thu DISM..." "WARN"
            & DISM /Online /Set-Edition:Professional /ProductKey:VK7JG-NPHTM-C97JM-9MPGT-3V66T /AcceptEula 2>&1 | Out-Null
        }
    } else {
        Write-Host ""
        Write-Step "4/5" "May da la Pro - bo qua nang cap" "OK"
    }

    # Buoc 5: Nhap key
    Write-Host ""
    Write-Step "5/5" "Nhap key ban quyen de kich hoat..."
    Write-Host ""
    $newKey = Read-Host "  Nhap Product Key Pro (hoac Enter de bo qua)"

    if (-not [string]::IsNullOrWhiteSpace($newKey)) {
        $cleanKey = $newKey.Trim() -replace '\s+', ''
        & cscript //NoLogo "$env:SystemRoot\System32\slmgr.vbs" /ipk $cleanKey 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Step "OK" "Nhap key thanh cong" "OK"
            & cscript //NoLogo "$env:SystemRoot\System32\slmgr.vbs" /ato 2>&1 | Out-Null
        } else {
            Write-Step "!" "slmgr loi. Thu DISM..." "WARN"
            & DISM /Online /Set-Edition:Professional /ProductKey:$cleanKey /AcceptEula 2>&1 | Out-Null
        }
    } else {
        Write-Host "  [!] Ban chua nhap key. Hay nhap key sau khi khoi dong lai." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  $('=' * 60)" -ForegroundColor Green
    Write-Host "  HOAN TAT QUY TRINH NANG CAP!" -ForegroundColor Green
    Write-Host "  $('=' * 60)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [!] Khoi dong lai may de hoan tat." -ForegroundColor Yellow
    Write-Host ""

    $reboot = Read-Host "  Khoi dong lai bay gio? (Y/N)"
    if ($reboot -eq 'Y' -or $reboot -eq 'y') {
        shutdown /r /t 10 /c "Khoi dong lai sau quy trinh nang cap toan dien"
    }
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
        Write-Host "     [9] Nhap & kich hoat key ban quyen moi" -ForegroundColor Green
        Write-Host ""
        Write-Host "     --- NANG CAP WINDOWS HOME -> PRO ---" -ForegroundColor Yellow
        Write-Host "     [A] Kiem tra phien ban Windows hien tai" -ForegroundColor Cyan
        Write-Host "     [B] Sua loi he thong (DISM + SFC)" -ForegroundColor Cyan
        Write-Host "     [C] Nang cap Home -> Pro" -ForegroundColor Green
        Write-Host "     [D] Quy trinh nang cap toan dien" -ForegroundColor Green
        Write-Host ""
        Write-Host "     [0] Thoat" -ForegroundColor Red
        Write-Host ""
        Write-Host "  $('=' * 63)" -ForegroundColor Green
        Write-Host ""

        $choice = Read-Host "  Chon chuc nang [0-9]"

        switch ($choice) {
            "1" { Invoke-FullCleanup }
            "2" { Write-Header "GO PRODUCT KEY"; Remove-ProductKey }
            "3" { Write-Header "XOA KEY KHOI REGISTRY"; Remove-KeyFromRegistry }
            "4" { Write-Header "XOA THONG TIN KMS"; Remove-KMSInfo; Reset-LicenseStatus }
            "5" { Write-Header "DON DEP FILE KMS"; Remove-KMSFiles }
            "6" { Write-Header "DON DEP SCHEDULED TASKS"; Remove-KMSScheduledTasks }
            "7" { Write-Header "SUA FILE HOSTS"; Repair-HostsFile }
            "8" { Show-LicenseStatus }
            "9" { Activate-NewLicense }
            "a" { Check-WindowsEdition }
            "b" { Fix-SystemErrors }
            "c" { Upgrade-HomeToPro }
            "d" { Invoke-FullUpgradeFlow }
            "0" { $continue = $false }
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
    Write-Host "   HiTechCloud by Pho Tue SoftWare Solutions JSC" -ForegroundColor DarkGray
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
