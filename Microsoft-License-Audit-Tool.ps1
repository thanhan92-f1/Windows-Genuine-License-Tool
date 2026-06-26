#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Microsoft Genuine License Audit & Recovery Tool v3.0
.DESCRIPTION
    Kiem tra toan bo san pham Microsoft (Windows, Office, Project, Visio,
    Visual Studio, SQL Server, Microsoft 365, Defender...), phat hien kich hoat
    khong hop le, go bo cau hinh KMS, nang cap edition, kich hoat bang giay phep
    hop le, va xuat bao cao chi tiet (HTML/JSON/TXT).
.AUTHOR
    Pho Tue SoftWare And Technology Solutions Joint Stock Company
    HiTechCloud - Microsoft Partner
.VERSION
    3.0
.NOTES
    Chay voi quyen Administrator
    Su dung: irm https://irm-genuine-license-windows.hitechcloud.vn | iex
#>

# ============================================================
#  KIEM TRA QUYEN ADMINISTRATOR
# ============================================================
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "`n  [LOI] Ban can chay voi quyen Administrator!" -ForegroundColor Red
    Write-Host "  Nhap chuot phai vao PowerShell chon 'Run as administrator'" -ForegroundColor Yellow
    pause; return
}

# ============================================================
#  BIEN TOAN CAU
# ============================================================
$Script:Version = "3.0"
$Script:LogFile = Join-Path $env:TEMP "MS_License_Audit_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$Script:ReportDir = Join-Path $env:TEMP "MS_License_Audit_Reports"
$Script:BackupDir = Join-Path $env:TEMP "MS_License_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$Script:HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$Script:HostsBackup = "$Script:HostsPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$Script:GenericProKey = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"
$Script:Slmgr = "$env:SystemRoot\System32\slmgr.vbs"

$Script:KMSDirectories = @(
    "$env:ProgramFiles\KMSpico", "${env:ProgramFiles(x86)}\KMSpico",
    "$env:ProgramData\KMSAutoS", "$env:ProgramData\KMSAuto",
    "$env:SystemRoot\KMS-R@1n", "$env:ProgramFiles\KMSAuto",
    "$env:ProgramFiles\KMSAuto Net", "$env:ProgramFiles\KMS_VL_ALL",
    "$env:ProgramData\Microsoft\KMS", "$env:ProgramFiles\HEU_KMS",
    "$env:ProgramData\HEU_KMS_Activator", "$env:ProgramFiles\KMS Tools",
    "$env:ProgramData\KMS Tools"
)
$Script:KMSFiles = @(
    "$env:SystemRoot\System32\SppExtComObjHook.dll",
    "$env:SystemRoot\System32\skc.dll",
    "$env:SystemRoot\System32\KMS-R@1n.dll",
    "$env:SystemRoot\SysWOW64\SppExtComObjHook.dll",
    "$env:SystemRoot\System32\ClipUp.exe.bak"
)
$Script:KMSTasks = @(
    "AutoKMS", "KMSAuto", "KMSAutoNet", "SvcRestartTask", "KMSpico",
    "KMS-R@1n", "KMS Activation", "MASHWID", "Online_KMS",
    "Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTask",
    "HEU_KMS", "KMS_Activation", "OfficeKMS", "WindowsKMS"
)
$Script:KMSRegistryKeys = @(
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform\KMSActivation"; Name=$null}
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name="KMSAuto"}
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name="KMSpico"}
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name="AutoKMS"}
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name="HEU_KMS"}
    @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name="KMSAuto"}
    @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name="KMSpico"}
    @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name="HEU_KMS"}
    @{Path="HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"; Name="KMSAuto"}
    @{Path="HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"; Name="KMSpico"}
    @{Path="HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"; Name="HEU_KMS"}
)
$Script:KMSSoftwareKeywords = @(
    "kms", "kmspico", "kmsauto", "autoKMS", "reloader", "microsoft toolkit",
    "hwid", "ohook", "heu_kms", "kms vl all", "ez-activator", "kms-r@1n",
    "microsoft_toolkit", "kmsnano", "kms server emulator", "windivert"
)
$Script:KMSServiceNames = @(
    "KMSEmulator", "KMSpico", "KMSAuto", "KMS-R@1n", "HEU_KMS",
    "SppExtComObjHook", "kms_service", "AutoKMS"
)

# Generic Keys cho chuyen edition
$Script:GenericKeys = @{
    "Core"              = "YTMG3-N6DKC-DKB77-7M9GH-8HVX7"
    "CoreN"             = "3KHY7-WNT83-DGQKR-F7HPR-844BM"
    "Professional"      = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"
    "ProfessionalN"     = "2B87N-8KFHP-DKV6R-Y2C8J-PKCKT"
    "Enterprise"        = "NPPR9-FWDCX-D2C8J-H872K-2YT43"
    "EnterpriseN"       = "DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4"
    "Education"         = "NW6C2-QMPVW-D7KKK-3GKT6-VCFB2"
    "EducationN"        = "2WH4N-8QGBV-H22JP-CT43Q-MDWWJ"
    "CoreSingleLanguage" = "7HNRX-D7KGG-3K4RQ-4WPJ4-YTDFH"
    "ServerStandard"    = "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY"
    "ServerDatacenter"  = "CB7KF-BWN84-R7R2Y-793K2-8XDDG"
}

# Bao cao tong hop
$Script:AuditReport = @{
    MachineName     = $env:COMPUTERNAME
    AuditDate       = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ToolVersion     = $Script:Version
    SystemInfo      = @{}
    Windows         = @{}
    Office          = @()
    Project         = @()
    Visio           = @()
    VisualStudio    = @()
    SQLServer       = @()
    Defender        = @{}
    Win11Ready      = @{}
    Issues          = @()
    CleanupResults  = @()
    ActivationResult = @{}
    HealthStatus    = @{}
    RiskLevel       = "Unknown"
}

# ============================================================
#  HAM HO TRO (UTILITY FUNCTIONS)
# ============================================================
function Write-Log {
    param([string]$Message)
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message" | Out-File $Script:LogFile -Append -Encoding UTF8
}

function Write-Header {
    param([string]$Title)
    $line = [string]::new([char]0x2550, 62)
    Write-Host ""
    Write-Host "  $line" -Fore Cyan
    Write-Host "  $Title" -Fore White
    Write-Host "  $line" -Fore Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Type, [string]$Message, [string]$Status="INFO")
    $colorMap = @{ OK="Green"; WARN="Yellow"; ERROR="Red"; DEL="Magenta"; INFO="White"; PASS="Green"; FAIL="Red"; SKIP="DarkGray" }
    $iconMap  = @{ OK="[+]"; WARN="[!]"; ERROR="[-]"; DEL="[x]"; INFO="[i]"; PASS="[OK]"; FAIL="[!!]"; SKIP="[~]" }
    $color = if($colorMap.ContainsKey($Status)){ $colorMap[$Status] } else { "White" }
    $icon  = if($iconMap.ContainsKey($Status)){ $iconMap[$Status] } else { "[i]" }
    Write-Host "  $icon $Message" -Fore $color
    Write-Log "$Status - $Message"
}

function Run-Slmgr {
    param([string]$Args, [string]$Description)
    Write-Step "INFO" "$Description..."
    try {
        $p = Start-Process cscript.exe -Arg "//NoLogo", $Script:Slmgr, $Args -Wait -PassThru -WindowStyle Hidden
        if ($p.ExitCode -eq 0) { Write-Step "OK" "$Description - OK" "OK" }
        else { Write-Step "WARN" "$Description - Co the da thuc hien" "WARN" }
    } catch { Write-Step "ERROR" "$Description - Loi: $_" "ERROR" }
}

function Read-UserChoice {
    param([string]$Prompt = "Chon", [string]$Default = "")
    $input = Read-Host "  $Prompt"
    if ([string]::IsNullOrWhiteSpace($input) -and $Default) { return $Default }
    return $input
}

function Confirm-Proceed {
    param([string]$Message = "Ban co muon tiep tuc?")
    Write-Host ""
    Write-Host "  $Message (Y/N)" -Fore Yellow
    $ch = Read-Host "  Chon"
    return ($ch -eq 'Y' -or $ch -eq 'y')
}

# ============================================================
#  PHASE 1: THU THAP THONG TIN HE THONG
# ============================================================
function Get-SystemInventory {
    Write-Header "PHASE 1: THU THAP THONG TIN HE THONG"
    $sys = @{}

    # --- Windows Version ---
    Write-Step "INFO" "Dang thu thap thong tin Windows..."
    $nt = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -EA SilentlyContinue
    $sys.ProductName    = $nt.ProductName
    $sys.DisplayVersion = $nt.DisplayVersion
    $sys.CurrentBuild   = $nt.CurrentBuild
    $sys.UBR            = $nt.UBR
    $sys.InstallDate    = if($nt.InstallDate){ $nt.InstallDate } else { "N/A" }

    Write-Host "  May tinh:      $env:COMPUTERNAME" -Fore White
    Write-Host "  San pham:      $($sys.ProductName)" -Fore White
    Write-Host "  Build:         $($sys.CurrentBuild).$($sys.UBR) ($($sys.DisplayVersion))" -Fore White

    # --- Edition ---
    Write-Step "INFO" "Dang kiem tra edition..."
    & DISM /Online /Get-CurrentEdition 2>&1 | ForEach-Object {
        if ($_ -match "Current Edition\s*:\s*(.+)") {
            $sys.CurrentEdition = $Matches[1].Trim()
            Write-Host "  Edition:       $($sys.CurrentEdition)" -Fore Cyan
        }
    }
    $sys.TargetEditions = @()
    & DISM /Online /Get-TargetEditions 2>&1 | ForEach-Object {
        if ($_ -match "Target Edition\s*:\s*(.+)") { $sys.TargetEditions += $Matches[1].Trim() }
    }
    if ($sys.TargetEditions.Count -gt 0) {
        Write-Host "  Nang cap duoc: $($sys.TargetEditions -join ', ')" -Fore Green
    }
    Write-Host ""

    # --- CPU ---
    Write-Step "INFO" "Dang kiem tra phan cung..."
    $cpu = Get-CimInstance Win32_Processor -EA SilentlyContinue | Select-Object -First 1
    if ($cpu) {
        $sys.CPU             = $cpu.Name
        $sys.CPUManufacturer = $cpu.Manufacturer
        $sys.CPUMaxClock     = $cpu.MaxClockSpeed
        $sys.CPUCores        = $cpu.NumberOfCores
        $sys.CPULogical      = $cpu.NumberOfLogicalProcessors
        Write-Host "  CPU:           $($sys.CPU)" -Fore White
        Write-Host "  CPU Cores:     $($sys.CPUCores) cores / $($sys.CPULogical) threads" -Fore White
    }

    # --- RAM ---
    $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue).TotalPhysicalMemory / 1GB, 1)
    $sys.RAM_GB = $ram
    Write-Host "  RAM:           $ram GB" -Fore White

    # --- Disk ---
    $disk = Get-Disk | Where-Object { $_.IsSystem -eq $true } | Select-Object -First 1
    if ($disk) {
        $sys.DiskSize_GB    = [math]::Round($disk.Size / 1GB, 0)
        $sys.PartitionStyle = $disk.PartitionStyle
        Write-Host "  Disk:          $($sys.DiskSize_GB) GB ($($sys.PartitionStyle))" -Fore White
    }
    # Free space
    $sysDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'" -EA SilentlyContinue
    if ($sysDrive) {
        $sys.FreeSpace_GB = [math]::Round($sysDrive.FreeSpace / 1GB, 1)
        Write-Host "  Free Space:    $($sys.FreeSpace_GB) GB" -Fore White
    }

    # --- BIOS ---
    $bios = Get-CimInstance Win32_BIOS -EA SilentlyContinue
    if ($bios) {
        $sys.BIOSVersion     = $bios.SMBIOSBIOSVersion
        $sys.BIOSManufacturer = $bios.Manufacturer
        $sys.BIOSSerial      = $bios.SerialNumber
        Write-Host "  BIOS:          $($sys.BIOSManufacturer) $($sys.BIOSVersion)" -Fore White
    }

    # --- Mainboard ---
    $mb = Get-CimInstance Win32_BaseBoard -EA SilentlyContinue
    if ($mb) {
        $sys.Motherboard = "$($mb.Manufacturer) $($mb.Product)"
        $sys.MBSerial    = $mb.SerialNumber
        Write-Host "  Mainboard:     $($sys.Motherboard)" -Fore White
    }

    # --- TPM ---
    try {
        $tpm = Get-Tpm -EA SilentlyContinue
        if ($tpm) {
            $sys.TPMPresent = $tpm.TpmPresent
            $sys.TPMReady   = $tpm.TpmReady
            $sys.TPMVersion = $tpm.SpecVersion
            Write-Host "  TPM:           Present=$($tpm.TpmPresent) Ready=$($tpm.TpmReady) Version=$($tpm.SpecVersion)" -Fore White
        }
    } catch {
        $sys.TPMPresent = $false
        $sys.TPMReady   = $false
        $sys.TPMVersion = "N/A"
    }

    # --- Secure Boot ---
    try { $sys.SecureBoot = Confirm-SecureBootUEFI -EA SilentlyContinue }
    catch { $sys.SecureBoot = $false }
    Write-Host "  Secure Boot:   $($sys.SecureBoot)" -Fore White

    # --- Boot Mode ---
    $fw = Get-ComputerInfo -Property BiosFirmwareType -EA SilentlyContinue
    if ($fw) {
        $sys.BootMode = $fw.BiosFirmwareType
        Write-Host "  Boot Mode:     $($sys.BootMode)" -Fore White
    }

    # --- Network ---
    $net = Get-NetIPAddress -AddressFamily IPv4 -EA SilentlyContinue | Where-Object { $_.IPAddress -ne "127.0.0.1" } | Select-Object -First 3
    if ($net) {
        $sys.IPAddresses = ($net.IPAddress -join ", ")
        Write-Host "  IP:            $($sys.IPAddresses)" -Fore White
    }

    # --- Windows Update Service ---
    $wu = Get-Service wuauserv -EA SilentlyContinue
    if ($wu) {
        $sys.WindowsUpdateStatus = $wu.Status.ToString()
        $sys.WindowsUpdateStart  = $wu.StartType.ToString()
    }

    Write-Host ""
    $Script:AuditReport.SystemInfo = $sys
    return $sys
}

# ============================================================
#  PHASE 2: KIEM TRA DIEU KIEN WINDOWS 11
# ============================================================
function Test-Windows11Compatibility {
    Write-Header "PHASE 2: KIEM TRA DIEU KIEN WINDOWS 11"
    $sys = $Script:AuditReport.SystemInfo
    $ready = @{ Pass = 0; Fail = 0; Details = @() }

    function Check-Item {
        param([string]$Name, [bool]$Passed, [string]$Detail)
        if ($Passed) {
            Write-Step "PASS" "$Name - $Detail" "PASS"
            $ready.Pass++
        } else {
            Write-Step "FAIL" "$Name - $Detail" "FAIL"
            $ready.Fail++
        }
        $ready.Details += @{ Item = $Name; Status = $(if($Passed){"PASS"}else{"FAIL"}); Detail = $Detail }
    }

    # Supported CPU list (partial - key families)
    $supportedCPU = $false
    $cpuName = $sys.CPU
    if ($cpuName) {
        # Intel: 8th gen+ (Coffee Lake, Whiskey Lake, Comet Lake, Ice Lake, Tiger Lake, Alder Lake, Raptor Lake, Meteor Lake)
        # AMD: Ryzen 2000+ (Zen+ architecture)
        if ($cpuName -match "i[3579]-[89]\d{3}|i[3579]-1[0-4]\d{3}|Xeon.*[EW]-2[2-9]\d{3}|Core.*Ultra|Ryzen [3579] [2-9]\d{3}|Ryzen.*[2-9]\d{3}|EPYC|Snapdragon") {
            $supportedCPU = $true
        }
        # Also check clock speed as heuristic
        if ($sys.CPUMaxClock -ge 1000 -and $sys.CPUCores -ge 2) {
            $supportedCPU = $true  # Conservative: allow if decent specs
        }
    }
    Check-Item "CPU ho tro" $supportedCPU $(if($cpuName){"$cpuName"}else{"Khong xac dinh"})

    $tpmOK = $sys.TPMPresent -eq $true -and ($sys.TPMVersion -match "^2\." -or $sys.TPMReady -eq $true)
    Check-Item "TPM 2.0" $tpmOK $(if($sys.TPMPresent){"Version: $($sys.TPMVersion)"}else{"Khong tim thay"})

    Check-Item "Secure Boot" ($sys.SecureBoot -eq $true) $(if($sys.SecureBoot){"Enabled"}else{"Disabled"})
    Check-Item "GPT Disk" ($sys.PartitionStyle -eq "GPT") "$($sys.PartitionStyle)"
    Check-Item "UEFI Boot" ($sys.BootMode -match "Uefi") "$($sys.BootMode)"
    Check-Item "RAM >= 4GB" ($sys.RAM_GB -ge 4) "$($sys.RAM_GB) GB"
    Check-Item "Storage >= 64GB" ($sys.DiskSize_GB -ge 64) "$($sys.DiskSize_GB) GB"

    Write-Host ""
    $total = $ready.Pass + $ready.Fail
    if ($ready.Fail -eq 0) {
        Write-Host "  -> May tinh DAT tat ca yeu cau Windows 11 ($ready.Pass/$total PASS)" -Fore Green
    } else {
        Write-Host "  -> CHUA DAT $ready.Fail / $total yeu cau" -Fore Red
        Write-Host "  -> Cac muc khong dat se hien thi trong bao cao" -Fore Yellow
    }
    $Script:AuditReport.Win11Ready = $ready
}

# ============================================================
#  PHASE 3: KIEM TRA BAN QUYEN - TAT CA SAN PHAM MICROSOFT
# ============================================================
function Get-LicenseAudit {
    Write-Header "PHASE 3: KIEM TRA BAN QUYEN MICROSOFT"

    # ──────────────────────────────────────────────────────────
    #  3.1 Windows License
    # ──────────────────────────────────────────────────────────
    Write-Step "INFO" "Dang kiem tra ban quyen Windows..."
    $winLic = @{
        Status = "Unknown"; Channel = "Unknown"; Description = ""
        PartialKey = ""; KMSMachine = ""; Licensed = $false
        OEMKey = ""; Expiration = ""; ActivationID = ""
        GracePeriod = ""; LicenseFamily = ""
    }

    $dli = & cscript //NoLogo $Script:Slmgr /dli 2>&1
    foreach ($l in $dli) {
        if ($l -match "License Status:\s*(.+)")      { $winLic.Status       = $Matches[1].Trim() }
        if ($l -match "Partial Product Key:\s*(.+)")  { $winLic.PartialKey   = $Matches[1].Trim() }
        if ($l -match "Product Key Channel:\s*(.+)")  { $winLic.Channel      = $Matches[1].Trim() }
        if ($l -match "Description:\s*(.+)")          { $winLic.Description  = $Matches[1].Trim() }
        if ($l -match "KMS Machine Name:\s*(.+)")     { $winLic.KMSMachine   = $Matches[1].Trim() }
        if ($l -match "Grace Period:\s*(.+)")         { $winLic.GracePeriod  = $Matches[1].Trim() }
        if ($l -match "License Family:\s*(.+)")       { $winLic.LicenseFamily = $Matches[1].Trim() }
    }
    $dlv = & cscript //NoLogo $Script:Slmgr /dlv 2>&1
    foreach ($l in $dlv) {
        if ($l -match "Activation ID:\s*([0-9a-fA-F-]+)") { $winLic.ActivationID = $Matches[1].Trim() }
    }
    $xpr = & cscript //NoLogo $Script:Slmgr /xpr 2>&1
    $winLic.Expiration = ($xpr | Where-Object { $_ -match "\S" } | Select-Object -Last 1)
    $winLic.Licensed   = ($winLic.Status -match "Licensed")

    # OEM Key tu BIOS
    try { $winLic.OEMKey = (Get-CimInstance -ClassName SoftwareLicensingService -EA SilentlyContinue).OA3xOriginalProductKey } catch {}

    # Phan loai
    $winLic.Classification = Get-LicenseClassification -Channel $winLic.Channel -KMSMachine $winLic.KMSMachine -Licensed $winLic.Licensed

    $sc = if ($winLic.Licensed) { "Green" } elseif ($winLic.Status -match "Notification") { "Yellow" } else { "Red" }
    Write-Host "  ── Windows License ─────────────────────────────────────" -Fore Cyan
    Write-Host "  Trang thai:    " -NoNewline; Write-Host $winLic.Status -Fore $sc
    Write-Host "  Channel:       $($winLic.Channel)" -Fore White
    Write-Host "  Mo ta:         $($winLic.Description)" -Fore White
    Write-Host "  Key 5 ky tu:     $($winLic.PartialKey)" -Fore White
    Write-Host "  Het han:       $($winLic.Expiration)" -Fore White
    Write-Host "  Phan loai:     " -NoNewline
    $clColor = switch ($winLic.Classification) { "HOP_LE" { "Green" } "CAN_XEM_XET" { "Yellow" } "CAN_XU_LY" { "Red" } default { "White" } }
    Write-Host $winLic.Classification -Fore $clColor
    if ($winLic.OEMKey)     { Write-Host "  OEM Key:       $($winLic.OEMKey)" -Fore Green }
    if ($winLic.KMSMachine) { Write-Host "  KMS Server:    $($winLic.KMSMachine)" -Fore Yellow }
    $Script:AuditReport.Windows = $winLic
    Write-Host ""

    # ──────────────────────────────────────────────────────────
    #  3.2 Office License (Click-to-Run & MSI)
    # ──────────────────────────────────────────────────────────
    Write-Step "INFO" "Dang kiem tra ban quyen Office..."
    $officeList = @()
    $osppPaths = @(
        "$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS",
        "$env:ProgramFiles\Microsoft Office\Office15\OSPP.VBS",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office15\OSPP.VBS",
        "$env:ProgramFiles\Microsoft Office\Office14\OSPP.VBS",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office14\OSPP.VBS"
    )

    # Tim tat ca OSPP.VBS
    $foundOSPP = $osppPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    # Cach thay: tim qua Registry va Click-to-Run
    $c2rPath = "$env:ProgramFiles\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
    $officeC2R = Test-Path $c2rPath

    if ($foundOSPP) {
        Write-Host "  -- Office (OSPP) --" -Fore Cyan
        $out = & cscript //NoLogo $foundOSPP /dstatus 2>&1
        $cur = @{}
        foreach ($l in $out) {
            if ($l -match "LICENSE NAME:\s*(.+)")       { $cur.LicenseName   = $Matches[1].Trim() }
            if ($l -match "LICENSE DESCRIPTION:\s*(.+)") { $cur.LicenseDesc  = $Matches[1].Trim() }
            if ($l -match "LICENSE STATUS:\s*(.+)")     { $cur.LicenseStatus = $Matches[1].Trim() }
            if ($l -match "REMAINING GRACE:\s*(.+)")    { $cur.Grace         = $Matches[1].Trim() }
            if ($l -match "Last 5 characters.*:\s*(.+)"){ $cur.PartialKey    = $Matches[1].Trim() }
            if ($l -match "KMS machine name:\s*(.+)")   { $cur.KMSMachine    = $Matches[1].Trim() }
            if ($l -match "KMS port:\s*(.+)")           { $cur.KMSPort       = $Matches[1].Trim() }
            if ($l -match "Activation Type:\s*(.+)")    { $cur.ActivationType = $Matches[1].Trim() }
            if ($l -match "---") {
                if ($cur.LicenseName) {
                    $cur.Classification = Get-LicenseClassification -Channel (Get-OfficeChannel $cur.LicenseName) -KMSMachine $cur.KMSMachine -Licensed ($cur.LicenseStatus -match "LICENSED")
                    $officeList += $cur.Clone()
                    $oc = if ($cur.LicenseStatus -match "LICENSED") { "Green" } else { "Yellow" }
                    Write-Host "  $($cur.LicenseName): " -NoNewline
                    Write-Host $cur.LicenseStatus -Fore $oc
                    if ($cur.KMSMachine) { Write-Host "    KMS: $($cur.KMSMachine)" -Fore Yellow }
                }
                $cur = @{}
            }
        }
        if ($cur.LicenseName) {
            $cur.Classification = Get-LicenseClassification -Channel (Get-OfficeChannel $cur.LicenseName) -KMSMachine $cur.KMSMachine -Licensed ($cur.LicenseStatus -match "LICENSED")
            $officeList += $cur.Clone()
            $oc = if ($cur.LicenseStatus -match "LICENSED") { "Green" } else { "Yellow" }
            Write-Host "  $($cur.LicenseName): " -NoNewline
            Write-Host $cur.LicenseStatus -Fore $oc
        }
    }

    # Tim Office qua Registry (neu OSPP khong co)
    if ($officeList.Count -eq 0) {
        $officeRegPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration",
            "HKLM:\SOFTWARE\Microsoft\Office\16.0\Common\InstallRoot",
            "HKLM:\SOFTWARE\Microsoft\Office\15.0\Common\InstallRoot"
        )
        foreach ($rp in $officeRegPaths) {
            if (Test-Path $rp) {
                $reg = Get-ItemProperty $rp -EA SilentlyContinue
                if ($reg.ProductReleaseIds) {
                    Write-Host "  Office Click-to-Run: $($reg.ProductReleaseIds)" -Fore Cyan
                }
            }
        }
    }

    if ($officeList.Count -eq 0) {
        Write-Host "  Khong tim thay Office" -Fore DarkGray
    }
    $Script:AuditReport.Office = $officeList
    Write-Host ""

    # ──────────────────────────────────────────────────────────
    #  3.3 Microsoft Project
    # ──────────────────────────────────────────────────────────
    Write-Step "INFO" "Dang kiem tra Microsoft Project..."
    $projectList = @()
    foreach ($o in $officeList) {
        if ($o.LicenseName -match "Project") {
            $projectList += $o
            Write-Host "  Project: $($o.LicenseName) - $($o.LicenseStatus)" -Fore Cyan
        }
    }
    # Tim qua Registry
    $projReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -EA SilentlyContinue
    if ($projReg -and $projReg.ProductReleaseIds -match "Project") {
        Write-Host "  Project (C2R): $($projReg.ProductReleaseIds)" -Fore Cyan
    }
    if ($projectList.Count -eq 0) {
        Write-Host "  Khong tim thay Project" -Fore DarkGray
    }
    $Script:AuditReport.Project = $projectList
    Write-Host ""

    # ──────────────────────────────────────────────────────────
    #  3.4 Microsoft Visio
    # ──────────────────────────────────────────────────────────
    Write-Step "INFO" "Dang kiem tra Microsoft Visio..."
    $visioList = @()
    foreach ($o in $officeList) {
        if ($o.LicenseName -match "Visio") {
            $visioList += $o
            Write-Host "  Visio: $($o.LicenseName) - $($o.LicenseStatus)" -Fore Cyan
        }
    }
    if ($projReg -and $projReg.ProductReleaseIds -match "Visio") {
        Write-Host "  Visio (C2R): $($projReg.ProductReleaseIds)" -Fore Cyan
    }
    if ($visioList.Count -eq 0) {
        Write-Host "  Khong tim thay Visio" -Fore DarkGray
    }
    $Script:AuditReport.Visio = $visioList
    Write-Host ""

    # ──────────────────────────────────────────────────────────
    #  3.5 Visual Studio
    # ──────────────────────────────────────────────────────────
    Write-Step "INFO" "Dang kiem tra Visual Studio..."
    $vsList = @()
    $vsRegPaths = @(
        "HKLM:\SOFTWARE\Microsoft\VisualStudio",
        "HKCU:\SOFTWARE\Microsoft\VisualStudio",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio"
    )
    # Tim VS installations qua vswhere
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vsInstalls = & $vswhere -all -format json 2>&1
        try {
            $vsData = $vsInstalls | ConvertFrom-Json
            foreach ($vs in $vsData) {
                $vsInfo = @{
                    Name    = $vs.displayName
                    Version = $vs.installationVersion
                    Path    = $vs.installPath
                    Channel = $vs.channelId
                    Status  = "Installed"
                }
                $vsList += $vsInfo
                Write-Host "  VS: $($vs.displayName) v$($vs.installationVersion)" -Fore Cyan
            }
        } catch {
            Write-Step "WARN" "Khong the parse VS data" "WARN"
        }
    }
    # Tim qua Registry
    foreach ($rp in @("HKLM:\SOFTWARE\Microsoft\VisualStudio\17.0", "HKLM:\SOFTWARE\Microsoft\VisualStudio\16.0", "HKLM:\SOFTWARE\Microsoft\VisualStudio\15.0")) {
        if (Test-Path $rp) {
            $ver = Split-Path $rp -Leaf
            if ($vsList.Count -eq 0 -or -not ($vsList | Where-Object { $_.Version -match $ver })) {
                Write-Host "  VS Registry: $ver" -Fore DarkGray
            }
        }
    }
    if ($vsList.Count -eq 0) { Write-Host "  Khong tim thay Visual Studio" -Fore DarkGray }
    $Script:AuditReport.VisualStudio = $vsList
    Write-Host ""

    # ──────────────────────────────────────────────────────────
    #  3.6 SQL Server
    # ──────────────────────────────────────────────────────────
    Write-Step "INFO" "Dang kiem tra SQL Server..."
    $sqlList = @()
    $sqlServices = Get-Service *sql* -EA SilentlyContinue
    if ($sqlServices) {
        foreach ($svc in $sqlServices) {
            $sqlInfo = @{ ServiceName = $svc.Name; DisplayName = $svc.DisplayName; Status = $svc.Status; StartType = $svc.StartType }
            $sqlList += $sqlInfo
            Write-Host "  SQL: $($svc.DisplayName) [$($svc.Status)]" -Fore Cyan
        }
    }
    # SQL Edition tu Registry
    $sqlRegPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server"
    )
    foreach ($rp in $sqlRegPaths) {
        if (Test-Path $rp) {
            $instances = (Get-ItemProperty "$rp\Instance Names\SQL" -EA SilentlyContinue)
            if ($instances) {
                foreach ($prop in $instances.PSObject.Properties) {
                    if ($prop.Name -notmatch "^PS") {
                        Write-Host "  SQL Instance: $($prop.Name) = $($prop.Value)" -Fore Cyan
                    }
                }
            }
        }
    }
    if ($sqlList.Count -eq 0) { Write-Host "  Khong tim thay SQL Server" -Fore DarkGray }
    $Script:AuditReport.SQLServer = $sqlList
    Write-Host ""

    # ──────────────────────────────────────────────────────────
    #  3.7 Microsoft 365 / Subscription
    # ──────────────────────────────────────────────────────────
    Write-Step "INFO" "Dang kiem tra Microsoft 365..."
    $m365Status = @{ Found = $false; Type = ""; Status = "" }
    $c2rReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -EA SilentlyContinue
    if ($c2rReg) {
        $m365Status.Found = $true
        $m365Status.Type = $c2rReg.ProductReleaseIds
        $m365Status.Channel = $c2rReg.UpdateChannel
        $m365Status.Version = $c2rReg.ClientVersionToReport
        Write-Host "  M365/C2R: $($m365Status.Type)" -Fore Cyan
        Write-Host "  Channel:  $($m365Status.Channel)" -Fore Cyan
        Write-Host "  Version:  $($m365Status.Version)" -Fore Cyan
    }
    # Shared Computer Activation
    if ($c2rReg -and $c2rReg.SharedComputerLicensing -eq "1") {
        $m365Status.SharedComputerActivation = $true
        Write-Host "  Shared Computer Activation: Enabled" -Fore Yellow
    }
    $Script:AuditReport.Microsoft365 = $m365Status
    Write-Host ""

    # ──────────────────────────────────────────────────────────
    #  3.8 Exchange Server
    # ──────────────────────────────────────────────────────────
    Write-Step "INFO" "Dang kiem tra Exchange Server..."
    $exchSvc = Get-Service *exchange* -EA SilentlyContinue
    if ($exchSvc) {
        foreach ($svc in $exchSvc) {
            Write-Host "  Exchange: $($svc.DisplayName) [$($svc.Status)]" -Fore Cyan
        }
        $Script:AuditReport.ExchangeServer = @{ Found = $true; Services = @($exchSvc | ForEach-Object { $_.DisplayName }) }
    } else {
        Write-Host "  Khong tim thay Exchange Server" -Fore DarkGray
        $Script:AuditReport.ExchangeServer = @{ Found = $false }
    }
    Write-Host ""

    # ──────────────────────────────────────────────────────────
    #  3.9 Remote Desktop
    # ──────────────────────────────────────────────────────────
    Write-Step "INFO" "Dang kiem tra Remote Desktop..."
    $rdSvc = Get-Service TermService -EA SilentlyContinue
    $rdLicenseSvc = Get-Service "TermServLicensing" -EA SilentlyContinue
    if ($rdLicenseSvc) {
        Write-Host "  RD Licensing: $($rdLicenseSvc.Status)" -Fore Cyan
        $Script:AuditReport.RemoteDesktop = @{ Found = $true; Licensing = $rdLicenseSvc.Status }
    } else {
        Write-Host "  Khong tim thay RD Licensing" -Fore DarkGray
        $Script:AuditReport.RemoteDesktop = @{ Found = $false }
    }
    if ($rdSvc) {
        Write-Host "  Remote Desktop: $($rdSvc.Status)" -Fore White
    }
    Write-Host ""

    # ──────────────────────────────────────────────────────────
    #  3.10 Windows Server (neu la Server)
    # ──────────────────────────────────────────────────────────
    if ($Script:AuditReport.SystemInfo.ProductName -match "Server") {
        Write-Step "INFO" "Phat hien Windows Server..."
        $Script:AuditReport.WindowsServer = @{
            Edition = $Script:AuditReport.SystemInfo.CurrentEdition
            Product = $Script:AuditReport.SystemInfo.ProductName
        }
        Write-Host "  Windows Server: $($Script:AuditReport.SystemInfo.ProductName)" -Fore Cyan
        Write-Host ""
    }
}

function Get-LicenseClassification {
    param([string]$Channel, [string]$KMSMachine, [bool]$Licensed)

    # Neu khong kich hoat -> Can xu ly
    if (-not $Licensed) { return "CAN_XU_LY" }

    # Retail, OEM, MAK, CSP -> Hop le
    if ($Channel -match "Retail|OEM|CSP") { return "HOP_LE" }

    # Volume_KMSCLIENT -> Can xem xet (co the la KMS doanh nghiep hop le)
    if ($Channel -match "Volume_KMSCLIENT" -or $KMSMachine) {
        return "CAN_XEM_XET"
    }

    # Volume_MAK -> Hop le (nhung can xem xet so luong)
    if ($Channel -match "Volume_MAK") { return "HOP_LE" }

    # Default
    return "CAN_XEM_XET"
}

function Get-OfficeChannel {
    param([string]$LicenseName)
    if ($LicenseName -match "Retail|RTM")    { return "Retail" }
    if ($LicenseName -match "Volume|VL")     { return "Volume_KMSCLIENT" }
    if ($LicenseName -match "OEM")           { return "OEM" }
    if ($LicenseName -match "Subscription")  { return "Subscription" }
    if ($LicenseName -match "M365|365")      { return "Microsoft365" }
    return "Unknown"
}

# ============================================================
#  PHASE 4: PHAT HIEN KICH HOAT KHONG HOP LE
# ============================================================
function Detect-InvalidActivation {
    Write-Header "PHASE 4: PHAT HIEN DAU HIEU KICH HOAT KHONG HOP LE"
    $issues = @()

    # ── 4.1 KMS Server ──
    Write-Step "INFO" "Kiem tra KMS Server..."
    $wl = $Script:AuditReport.Windows
    if ($wl.KMSMachine) {
        $issues += @{ Type="KMS"; Severity="WARN"; Product="Windows"; Detail="KMS Server: $($wl.KMSMachine)" }
        Write-Step "WARN" "Windows KMS: $($wl.KMSMachine)" "WARN"
    } else {
        Write-Step "OK" "Windows: Khong co KMS Server" "OK"
    }
    foreach ($o in $Script:AuditReport.Office) {
        if ($o.KMSMachine) {
            $issues += @{ Type="KMS"; Severity="WARN"; Product="Office"; Detail="KMS Server: $($o.KMSMachine)" }
            Write-Step "WARN" "Office KMS: $($o.KMSMachine)" "WARN"
        }
    }

    # ── 4.2 Channel ──
    Write-Step "INFO" "Kiem tra channel..."
    if ($wl.Channel -in @("Volume_KMSCLIENT", "Volume_MAK")) {
        $issues += @{ Type="CHANNEL"; Severity="WARN"; Product="Windows"; Detail="Channel: $($wl.Channel)" }
        Write-Step "WARN" "Windows Channel: $($wl.Channel)" "WARN"
    } else {
        Write-Step "OK" "Windows Channel: $($wl.Channel)" "OK"
    }

    # ── 4.3 DNS KMS ──
    Write-Step "INFO" "Kiem tra DNS KMS..."
    try {
        $dns = nslookup -type=srv _vlmcs._tcp 2>&1
        if ($dns -match "service|svr|SRV") {
            $issues += @{ Type="DNS"; Severity="WARN"; Product="System"; Detail="DNS KMS record (_vlmcs._tcp) phat hien" }
            Write-Step "WARN" "DNS KMS record phat hien" "WARN"
        } else {
            Write-Step "OK" "Khong co DNS KMS record" "OK"
        }
    } catch {
        Write-Step "OK" "Khong the kiem tra DNS KMS" "OK"
    }

    # ── 4.4 Scheduled Tasks ──
    Write-Step "INFO" "Kiem tra Scheduled Tasks..."
    $suspiciousTasks = @()
    Get-ScheduledTask -EA SilentlyContinue | ForEach-Object {
        foreach ($kw in $Script:KMSSoftwareKeywords) {
            if ($_.TaskName -match $kw -or $_.TaskPath -match $kw) {
                $suspiciousTasks += $_
                $issues += @{ Type="TASK"; Severity="WARN"; Product="System"; Detail="Task: $($_.TaskPath)$($_.TaskName)" }
                Write-Step "WARN" "Task dang ngo: $($_.TaskName)" "WARN"
            }
        }
    }
    if ($suspiciousTasks.Count -eq 0) { Write-Step "OK" "Tasks sach" "OK" }

    # ── 4.5 Windows Services ──
    Write-Step "INFO" "Kiem tra dich vu dang ngo..."
    $suspiciousServices = @()
    foreach ($kw in $Script:KMSServiceNames) {
        $svc = Get-Service "*$kw*" -EA SilentlyContinue
        if ($svc) {
            foreach ($s in $svc) {
                $suspiciousServices += $s
                $issues += @{ Type="SERVICE"; Severity="ERROR"; Product="System"; Detail="Service: $($s.Name) [$($s.Status)]" }
                Write-Step "WARN" "Service dang ngo: $($s.Name)" "WARN"
            }
        }
    }
    if ($suspiciousServices.Count -eq 0) { Write-Step "OK" "Services sach" "OK" }

    # ── 4.6 Startup Programs ──
    Write-Step "INFO" "Kiem tra Startup..."
    $suspiciousStartup = @()
    $startupPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"
    )
    foreach ($sp in $startupPaths) {
        if (Test-Path $sp) {
            $props = Get-ItemProperty $sp -EA SilentlyContinue
            foreach ($prop in $props.PSObject.Properties) {
                foreach ($kw in $Script:KMSSoftwareKeywords) {
                    if ($prop.Name -match $kw -or $prop.Value -match $kw) {
                        $suspiciousStartup += @{ Path=$sp; Name=$prop.Name; Value=$prop.Value }
                        $issues += @{ Type="STARTUP"; Severity="ERROR"; Product="System"; Detail="Startup: $($prop.Name) -> $($prop.Value)" }
                        Write-Step "WARN" "Startup dang ngo: $($prop.Name)" "WARN"
                    }
                }
            }
        }
    }
    if ($suspiciousStartup.Count -eq 0) { Write-Step "OK" "Startup sach" "OK" }

    # ── 4.7 Installed Programs ──
    Write-Step "INFO" "Kiem tra phan mem da cai dat..."
    $suspiciousPrograms = @()
    $uninstallPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($key in $uninstallPaths) {
        Get-ItemProperty $key -EA SilentlyContinue | ForEach-Object {
            if ($_.DisplayName) {
                foreach ($kw in $Script:KMSSoftwareKeywords) {
                    if ($_.DisplayName -match $kw) {
                        $suspiciousPrograms += $_
                        $issues += @{ Type="PROGRAM"; Severity="ERROR"; Product="System"; Detail="Phan mem: $($_.DisplayName)" }
                        Write-Step "WARN" "Phan mem: $($_.DisplayName)" "WARN"
                    }
                }
            }
        }
    }
    if ($suspiciousPrograms.Count -eq 0) { Write-Step "OK" "Phan mem sach" "OK" }

    # ── 4.8 Defender Status ──
    Write-Step "INFO" "Kiem tra Defender..."
    try {
        $mp = Get-MpPreference -EA SilentlyContinue
        $mpStatus = Get-MpComputerStatus -EA SilentlyContinue

        if ($mp.DisableRealtimeMonitoring) {
            $issues += @{ Type="DEFENDER"; Severity="WARN"; Product="System"; Detail="Real-time protection bi tat" }
            Write-Step "WARN" "Defender: Real-time bi tat" "WARN"
        } else {
            Write-Step "OK" "Defender: Real-time enabled" "OK"
        }

        if ($mpStatus -and -not $mpStatus.TamperProtection) {
            $issues += @{ Type="DEFENDER"; Severity="WARN"; Product="System"; Detail="Tamper Protection tat" }
            Write-Step "WARN" "Defender: Tamper Protection tat" "WARN"
        }

        # Exclusions
        if ($mp.ExclusionPath -and $mp.ExclusionPath.Count -gt 0) {
            Write-Step "WARN" "Defender Exclusions: $($mp.ExclusionPath.Count) duong dan" "WARN"
            foreach ($ex in $mp.ExclusionPath) {
                $issues += @{ Type="DEFENDER"; Severity="WARN"; Product="System"; Detail="Exclusion: $ex" }
            }
        }
        $Script:AuditReport.Defender = @{
            RealTimeEnabled  = -not $mp.DisableRealtimeMonitoring
            TamperProtection = $mpStatus.TamperProtection
            ExclusionCount   = if($mp.ExclusionPath){ $mp.ExclusionPath.Count } else { 0 }
            Exclusions       = $mp.ExclusionPath
        }
    } catch {
        Write-Step "WARN" "Khong the kiem tra Defender" "WARN"
    }
    Write-Host ""

    # ── 4.9 KMS Files & Directories ──
    Write-Step "INFO" "Kiem tra file KMS..."
    $kfc = 0
    foreach ($d in $Script:KMSDirectories) {
        if (Test-Path $d) {
            $kfc++
            $issues += @{ Type="FILE"; Severity="ERROR"; Product="System"; Detail="Thu muc KMS: $d" }
            Write-Step "WARN" "Tim thay: $d" "WARN"
        }
    }
    foreach ($f in $Script:KMSFiles) {
        if (Test-Path $f) {
            $kfc++
            $issues += @{ Type="FILE"; Severity="ERROR"; Product="System"; Detail="File KMS: $f" }
            Write-Step "WARN" "Tim thay: $f" "WARN"
        }
    }
    if ($kfc -eq 0) { Write-Step "OK" "File KMS sach" "OK" }

    # ── 4.10 Registry Keys ──
    Write-Step "INFO" "Kiem tra Registry..."
    $rc = 0
    foreach ($e in $Script:KMSRegistryKeys) {
        try {
            if ($e.Name) {
                if (Get-ItemProperty $e.Path -Name $e.Name -EA SilentlyContinue) {
                    $rc++
                    $issues += @{ Type="REGISTRY"; Severity="ERROR"; Product="System"; Detail="Registry: $($e.Path) -> $($e.Name)" }
                }
            } else {
                if (Test-Path $e.Path) {
                    $rc++
                    $issues += @{ Type="REGISTRY"; Severity="ERROR"; Product="System"; Detail="Registry: $($e.Path)" }
                }
            }
        } catch {}
    }
    if ($rc -eq 0) { Write-Step "OK" "Registry sach" "OK" } else { Write-Step "WARN" "Phat hien $rc registry entries" "WARN" }

    # ── 4.11 Hosts File ──
    Write-Step "INFO" "Kiem tra Hosts..."
    $hostsIssues = @()
    if (Test-Path $Script:HostsPath) {
        $hostsContent = Get-Content $Script:HostsPath
        $hostsKeywords = @("activation", "kms", "crack", "kmspico", "kmsauto", "office", "microsoft.com", "login.microsoftonline.com")
        foreach ($line in $hostsContent) {
            foreach ($kw in $hostsKeywords) {
                if ($line -match $kw -and $line -notmatch "^\s*#") {
                    $hostsIssues += $line.Trim()
                    $issues += @{ Type="HOSTS"; Severity="WARN"; Product="System"; Detail="Hosts: $($line.Trim())" }
                    Write-Step "WARN" "Hosts: $($line.Trim())" "WARN"
                }
            }
        }
    }
    if ($hostsIssues.Count -eq 0) { Write-Step "OK" "Hosts sach" "OK" }

    # ── 4.12 Office Software Protection Platform ──
    Write-Step "INFO" "Kiem tra Office SPP Registry..."
    $osppReg = "HKLM:\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform"
    if (Test-Path $osppReg) {
        $osppProps = Get-ItemProperty $osppReg -EA SilentlyContinue
        if ($osppProps.KeyManagementServiceName) {
            $issues += @{ Type="KMS"; Severity="WARN"; Product="Office"; Detail="Office KMS Registry: $($osppProps.KeyManagementServiceName)" }
            Write-Step "WARN" "Office KMS Registry: $($osppProps.KeyManagementServiceName)" "WARN"
        }
    }

    # ── 4.13 Event Logs ──
    Write-Step "INFO" "Kiem tra Event Logs..."
    try {
        $activationEvents = Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='SoftwareLicensingService','Security-SPP'} -MaxEvents 10 -EA SilentlyContinue
        if ($activationEvents) {
            Write-Step "INFO" "Tim thay $($activationEvents.Count) activation events" "INFO"
        }
    } catch {}

    # ── 4.14 Certificates ──
    Write-Step "INFO" "Kiem tra Certificates..."
    try {
        $rootCerts = Get-ChildItem Cert:\LocalMachine\Root -EA SilentlyContinue
        $pubCerts  = Get-ChildItem Cert:\LocalMachine\TrustedPublisher -EA SilentlyContinue
        $suspiciousCerts = @($rootCerts; $pubCerts) | Where-Object {
            $_.Subject -match "kms|activator|crack" -or $_.Issuer -match "kms|activator"
        }
        if ($suspiciousCerts.Count -gt 0) {
            foreach ($cert in $suspiciousCerts) {
                $issues += @{ Type="CERT"; Severity="WARN"; Product="System"; Detail="Certificate: $($cert.Subject)" }
                Write-Step "WARN" "Certificate dang ngo: $($cert.Subject)" "WARN"
            }
        } else {
            Write-Step "OK" "Certificates OK" "OK"
        }
    } catch {
        Write-Step "OK" "Khong the kiem tra Certificates" "OK"
    }

    # ── Summary ──
    Write-Host ""
    if ($issues.Count -eq 0) {
        Write-Host "  -> He thong SACH - Khong phat hien van de" -Fore Green
        $Script:AuditReport.RiskLevel = "HOP_LE"
    } else {
        $errCount = ($issues | Where-Object { $_.Severity -eq "ERROR" }).Count
        $warnCount = ($issues | Where-Object { $_.Severity -eq "WARN" }).Count
        Write-Host "  -> Phat hien $($issues.Count) van de ($errCount ERROR, $warnCount WARN)" -Fore Yellow
        if ($errCount -gt 0) { $Script:AuditReport.RiskLevel = "CAN_XU_LY" }
        else { $Script:AuditReport.RiskLevel = "CAN_XEM_XET" }
    }
    $Script:AuditReport.Issues = $issues
}

# ============================================================
#  PHASE 5: XAC NHAN VA LAM SACH
# ============================================================
function Confirm-And-Cleanup {
    Write-Header "PHASE 5: XAC NHAN VA LAM SACH"
    $issues = $Script:AuditReport.Issues

    if ($issues.Count -eq 0) {
        Write-Host "  He thong sach. Khong can lam sach." -Fore Green
        return
    }

    # ── Hien thi phan loai ──
    Write-Host "  ═══ BANG PHAN LOAI PHAT HIEN ═══" -Fore Cyan
    Write-Host ""

    $hopLe = @($Script:AuditReport.Windows) | Where-Object { $_.Classification -eq "HOP_LE" }
    $canXemXet = @($Script:AuditReport.Windows) | Where-Object { $_.Classification -eq "CAN_XEM_XET" }
    $canXuLy = @($Script:AuditReport.Windows) | Where-Object { $_.Classification -eq "CAN_XU_LY" }

    # Windows
    Write-Host "  ── Windows ─────────────────────────────────────────────" -Fore Cyan
    $wl = $Script:AuditReport.Windows
    Write-Host "  Edition:       $($Script:AuditReport.SystemInfo.CurrentEdition)" -Fore White
    Write-Host "  Channel:       $($wl.Channel)" -Fore White
    Write-Host "  Trang thai:    " -NoNewline; Write-Host $wl.Status -Fore $(if($wl.Licensed){"Green"}else{"Red"})
    Write-Host "  Phan loai:     " -NoNewline
    $clColor = switch($wl.Classification){"HOP_LE"{"Green"}"CAN_XEM_XET"{"Yellow"}"CAN_XU_LY"{"Red"}default{"White"}}
    Write-Host $wl.Classification -Fore $clColor
    if ($wl.KMSMachine) { Write-Host "  KMS Server:    " -NoNewline; Write-Host $wl.KMSMachine -Fore Yellow }
    Write-Host ""

    # Office
    if ($Script:AuditReport.Office.Count -gt 0) {
        Write-Host "  ── Office ──────────────────────────────────────────────" -Fore Cyan
        foreach ($o in $Script:AuditReport.Office) {
            Write-Host "  $($o.LicenseName)" -Fore White
            Write-Host "    Status:      $($o.LicenseStatus)" -Fore $(if($o.LicenseStatus -match "LICENSED"){"Green"}else{"Red"})
            if ($o.KMSMachine) { Write-Host "    KMS:         $($o.KMSMachine)" -Fore Yellow }
        }
        Write-Host ""
    }

    # Issues
    Write-Host "  ── Van de phat hien ────────────────────────────────────" -Fore Cyan
    foreach ($i in $issues) {
        $c = switch($i.Severity) { "ERROR"{"Red"} "WARN"{"Yellow"} default{"White"} }
        Write-Host "    [$($i.Type)] $($i.Detail)" -Fore $c
    }
    Write-Host ""

    # ── Xac nhan ──
    $hasKMS    = $issues | Where-Object { $_.Type -eq "KMS" }
    $hasTasks  = $issues | Where-Object { $_.Type -eq "TASK" }
    $hasHosts  = $issues | Where-Object { $_.Type -eq "HOSTS" }
    $hasDef    = $issues | Where-Object { $_.Type -eq "DEFENDER" }
    $hasFile   = $issues | Where-Object { $_.Type -eq "FILE" }
    $hasReg    = $issues | Where-Object { $_.Type -eq "REGISTRY" }
    $hasSvc    = $issues | Where-Object { $_.Type -eq "SERVICE" }
    $hasStartup = $issues | Where-Object { $_.Type -eq "STARTUP" }
    $hasProg   = $issues | Where-Object { $_.Type -eq "PROGRAM" }

    Write-Host "  ═══ CHON HANH DONG ═══" -Fore Green
    Write-Host ""
    $n = 0; $opts = @()

    if ($hasKMS)     { $n++; Write-Host "    [$n] Go cau hinh KMS (Windows + Office)" -Fore White; $opts += "RemoveKMS" }
    if ($hasTasks)   { $n++; Write-Host "    [$n] Xoa Scheduled Tasks dang ngo" -Fore White; $opts += "RemoveTasks" }
    if ($hasSvc)     { $n++; Write-Host "    [$n] Xoa Services dang ngo" -Fore White; $opts += "RemoveServices" }
    if ($hasStartup) { $n++; Write-Host "    [$n] Xoa Startup entries dang ngo" -Fore White; $opts += "RemoveStartup" }
    if ($hasProg)    { $n++; Write-Host "    [$n] Go phan mem KMS/crack" -Fore White; $opts += "RemovePrograms" }
    if ($hasFile)    { $n++; Write-Host "    [$n] Xoa file/thu muc KMS" -Fore White; $opts += "RemoveFiles" }
    if ($hasReg)     { $n++; Write-Host "    [$n] Xoa Registry entries dang ngo" -Fore White; $opts += "RemoveRegistry" }
    if ($hasHosts)   { $n++; Write-Host "    [$n] Khoi phuc file Hosts" -Fore White; $opts += "RestoreHosts" }
    if ($hasDef)     { $n++; Write-Host "    [$n] Khoi phuc Defender" -Fore White; $opts += "RestoreDefender" }
    $n++; Write-Host "    [$n] Sua loi he thong (DISM + SFC)" -Fore White; $opts += "Repair"
    $n++; Write-Host "    [$n] THUC HIEN TAT CA CAC MUC TREN" -Fore Green; $opts += "All"
    Write-Host "    [0] Bo qua - Khong lam gi" -Fore Red
    Write-Host ""

    $ch = Read-Host "  Chon (so, nhieu so cach dau phay, hoac 'all')"
    if ($ch -eq "0" -or $ch -eq "") { return }

    # Xu ly lua chon
    if ($ch -eq "all" -or $ch -eq "$n") {
        $acts = $opts | Where-Object { $_ -ne "All" }
    } elseif ($ch -match "^[0-9,\s]+$") {
        $idxs = $ch -split "[,\s]+" | ForEach-Object { [int]$_ - 1 }
        $acts = @()
        foreach ($i in $idxs) {
            if ($i -ge 0 -and $i -lt $opts.Count) { $acts += $opts[$i] }
        }
    } else {
        Write-Step "WARN" "Lua chon khong hop le" "WARN"
        return
    }

    # ── Tao backup ──
    Write-Step "INFO" "Tao backup truoc khi lam sach..."
    if (!(Test-Path $Script:BackupDir)) { New-Item -ItemType Directory $Script:BackupDir -Force | Out-Null }
    # Backup Hosts
    if (Test-Path $Script:HostsPath) { Copy-Item $Script:HostsPath "$Script:BackupDir\hosts.backup" -Force }
    # Backup Registry
    reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" "$Script:BackupDir\spp_backup.reg" /y 2>&1 | Out-Null
    reg export "HKLM\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform" "$Script:BackupDir\ospp_backup.reg" /y 2>&1 | Out-Null
    Write-Step "OK" "Backup tai: $Script:BackupDir" "OK"

    # ── Thuc hien ──
    $results = @()
    foreach ($act in $acts) {
        switch ($act) {
            "RemoveKMS" {
                Write-Step "DEL" "Go cau hinh KMS..."
                Run-Slmgr "/upk" "Go Product Key"
                Run-Slmgr "/cpky" "Xoa Registry Key"
                Run-Slmgr "/ckms" "Xoa KMS Server"
                Run-Slmgr "/rearm" "Reset Activation"
                # Office KMS
                $osppPaths = @(
                    "$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS",
                    "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS"
                )
                foreach ($ospp in $osppPaths) {
                    if (Test-Path $ospp) {
                        Write-Step "DEL" "Go Office KMS..."
                        & cscript //NoLogo $ospp /remhst 2>&1 | Out-Null
                        & cscript //NoLogo $ospp /cnsstsku 2>&1 | Out-Null
                    }
                }
                $results += @{ Action="RemoveKMS"; Status="OK" }
            }
            "RemoveTasks" {
                Write-Step "DEL" "Xoa Scheduled Tasks dang ngo..."
                foreach ($t in $Script:KMSTasks) {
                    Unregister-ScheduledTask -TaskName $t -Confirm:$false -EA SilentlyContinue
                }
                # Xoa task phat hien tu phase 4
                foreach ($i in ($issues | Where-Object { $_.Type -eq "TASK" })) {
                    if ($i.Detail -match "Task:\s*(.+)") {
                        $taskName = $Matches[1]
                        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -EA SilentlyContinue
                    }
                }
                $results += @{ Action="RemoveTasks"; Status="OK" }
            }
            "RemoveServices" {
                Write-Step "DEL" "Xoa Services dang ngo..."
                foreach ($kw in $Script:KMSServiceNames) {
                    $svcs = Get-Service "*$kw*" -EA SilentlyContinue
                    foreach ($svc in $svcs) {
                        Stop-Service $svc.Name -Force -EA SilentlyContinue
                        & sc.exe delete $svc.Name 2>&1 | Out-Null
                        Write-Step "DEL" "Da xoa service: $($svc.Name)" "DEL"
                    }
                }
                $results += @{ Action="RemoveServices"; Status="OK" }
            }
            "RemoveStartup" {
                Write-Step "DEL" "Xoa Startup entries dang ngo..."
                foreach ($sp in $startupPaths) {
                    foreach ($i in ($issues | Where-Object { $_.Type -eq "STARTUP" })) {
                        if ($i.Detail -match "Startup:\s*(\S+)") {
                            $name = $Matches[1]
                            Remove-ItemProperty -Path $sp -Name $name -Force -EA SilentlyContinue
                            Write-Step "DEL" "Da xoa startup: $name" "DEL"
                        }
                    }
                }
                $results += @{ Action="RemoveStartup"; Status="OK" }
            }
            "RemovePrograms" {
                Write-Step "DEL" "Go phan mem KMS/crack..."
                foreach ($i in ($issues | Where-Object { $_.Type -eq "PROGRAM" })) {
                    if ($i.Detail -match "Phan mem:\s*(.+)") {
                        $progName = $Matches[1]
                        Write-Step "INFO" "Thu go: $progName"
                        # Thu go qua uninstall string
                        $uninstallKeys = @(
                            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
                            "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
                        )
                        foreach ($uk in $uninstallKeys) {
                            Get-ItemProperty $uk -EA SilentlyContinue | Where-Object { $_.DisplayName -eq $progName } | ForEach-Object {
                                if ($_.UninstallString) {
                                    Write-Step "INFO" "Uninstall: $($_.UninstallString)"
                                    Start-Process cmd.exe -Arg "/c $($_.UninstallString) /silent" -Wait -WindowStyle Hidden -EA SilentlyContinue
                                }
                            }
                        }
                    }
                }
                $results += @{ Action="RemovePrograms"; Status="OK" }
            }
            "RemoveFiles" {
                Write-Step "DEL" "Xoa file/thu muc KMS..."
                foreach ($d in $Script:KMSDirectories) {
                    if (Test-Path $d) {
                        Remove-Item $d -Recurse -Force -EA SilentlyContinue
                        Write-Step "DEL" "Da xoa: $d" "DEL"
                    }
                }
                foreach ($f in $Script:KMSFiles) {
                    if (Test-Path $f) {
                        takeown /f $f 2>$null | Out-Null
                        icacls $f /grant administrators:F 2>$null | Out-Null
                        Remove-Item $f -Force -EA SilentlyContinue
                        Write-Step "DEL" "Da xoa: $f" "DEL"
                    }
                }
                $results += @{ Action="RemoveFiles"; Status="OK" }
            }
            "RemoveRegistry" {
                Write-Step "DEL" "Xoa Registry entries dang ngo..."
                foreach ($e in $Script:KMSRegistryKeys) {
                    try {
                        if ($e.Name) {
                            Remove-ItemProperty $e.Path -Name $e.Name -Force -EA SilentlyContinue
                        } else {
                            Remove-Item $e.Path -Recurse -Force -EA SilentlyContinue
                        }
                    } catch {}
                }
                # Xoa Office KMS Registry
                $osppReg = "HKLM:\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform"
                if (Test-Path "$osppReg\KMS") {
                    Remove-Item "$osppReg\KMS" -Recurse -Force -EA SilentlyContinue
                }
                $results += @{ Action="RemoveRegistry"; Status="OK" }
            }
            "RestoreHosts" {
                Write-Step "DEL" "Khoi phuc Hosts..."
                if (Test-Path $Script:HostsPath) {
                    $content = Get-Content $Script:HostsPath
                    $keywords = @("activation", "kms", "crack", "kmspico", "kmsauto", "office", "microsoft.com")
                    $clean = $content | Where-Object {
                        $line = $_
                        $keep = $true
                        foreach ($kw in $keywords) {
                            if ($line -match $kw -and $line -notmatch "^\s*#") { $keep = $false; break }
                        }
                        $keep
                    }
                    $clean | Set-Content $Script:HostsPath -Force -Encoding ASCII
                    Write-Step "OK" "Hosts da duoc khoi phuc" "OK"
                }
                $results += @{ Action="RestoreHosts"; Status="OK" }
            }
            "RestoreDefender" {
                Write-Step "DEL" "Khoi phuc Defender..."
                try {
                    Set-MpPreference -DisableRealtimeMonitoring $false -EA SilentlyContinue
                    # Xoa exclusions
                    $mp = Get-MpPreference -EA SilentlyContinue
                    if ($mp.ExclusionPath) {
                        foreach ($ex in $mp.ExclusionPath) { Remove-MpPreference -ExclusionPath $ex -EA SilentlyContinue }
                    }
                    if ($mp.ExclusionProcess) {
                        foreach ($ex in $mp.ExclusionProcess) { Remove-MpPreference -ExclusionProcess $ex -EA SilentlyContinue }
                    }
                    Write-Step "OK" "Defender da duoc khoi phuc" "OK"
                } catch {
                    Write-Step "WARN" "Khong the khoi phuc Defender: $_" "WARN"
                }
                $results += @{ Action="RestoreDefender"; Status="OK" }
            }
            "Repair" {
                Write-Step "INFO" "Sua loi he thong..."
                Write-Step "INFO" "DISM RestoreHealth (co the mat vai phut)..."
                & DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-Null
                Write-Step "OK" "DISM OK" "OK"
                Write-Step "INFO" "SFC /scannow..."
                & sfc /scannow 2>&1 | Out-Null
                Write-Step "OK" "SFC OK" "OK"
                $results += @{ Action="Repair"; Status="OK" }
            }
        }
    }

    # Khoi phuc Windows Update
    try {
        Set-Service wuauserv -StartupType Automatic -EA SilentlyContinue
        Start-Service wuauserv -EA SilentlyContinue
    } catch {}

    Write-Host ""
    Write-Host "  HOAN TAT LAM SACH!" -Fore Green
    Write-Host "  Backup: $Script:BackupDir" -Fore Cyan
    $Script:AuditReport.CleanupResults = $results
}

# ============================================================
#  PHASE 6: CHUYEN EDITION
# ============================================================
function Invoke-EditionUpgrade {
    Write-Header "PHASE 6: CHUYEN EDITION"
    $sys = $Script:AuditReport.SystemInfo

    if ($sys.TargetEditions.Count -eq 0) {
        Write-Step "WARN" "Khong co edition nao de nang cap" "WARN"
        return
    }

    Write-Host "  Edition hien tai:  $($sys.CurrentEdition)" -Fore Cyan
    Write-Host "  Co the nang cap:   $($sys.TargetEditions -join ', ')" -Fore Green
    Write-Host ""

    # Hien thi options
    Write-Host "  [0] Bo qua" -Fore Red
    $n = 0
    $editionOpts = @()
    foreach ($te in $sys.TargetEditions) {
        $n++
        $genericKey = if ($Script:GenericKeys.ContainsKey($te)) { $Script:GenericKeys[$te] } else { "N/A" }
        Write-Host "  [$n] $te (Generic Key: $genericKey)" -Fore White
        $editionOpts += $te
    }
    Write-Host ""
    $ch = Read-Host "  Chon edition [0-$n]"
    if ($ch -eq "0" -or $ch -eq "") { return }

    $idx = [int]$ch - 1
    if ($idx -lt 0 -or $idx -ge $editionOpts.Count) {
        Write-Step "WARN" "Lua chon khong hop le" "WARN"
        return
    }

    $targetEdition = $editionOpts[$idx]
    $targetKey = $Script:GenericKeys[$targetEdition]

    Write-Host ""
    Write-Host "  [1] Dung Generic Key ($targetKey)" -Fore White
    Write-Host "  [2] Nhap key rieng" -Fore White
    Write-Host "  [3] Dung DISM chuyen edition" -Fore White
    Write-Host "  [0] Bo qua" -Fore Red
    $method = Read-Host "  Chon phuong phap [0-3]"

    switch ($method) {
        "1" {
            if ($targetKey -and $targetKey -ne "N/A") {
                & cscript //NoLogo $Script:Slmgr /ipk $targetKey 2>&1 | Out-Null
                & cscript //NoLogo $Script:Slmgr /ato 2>&1 | Out-Null
                Write-Step "OK" "Da chuyen sang $targetEdition" "OK"
            } else {
                Write-Step "WARN" "Khong co generic key cho $targetEdition" "WARN"
            }
        }
        "2" {
            $k = Read-Host "  Nhap Product Key"
            if (![string]::IsNullOrWhiteSpace($k)) {
                $ck = $k.Trim() -replace '\s+', ''
                & cscript //NoLogo $Script:Slmgr /ipk $ck 2>&1 | Out-Null
                & cscript //NoLogo $Script:Slmgr /ato 2>&1 | Out-Null
                Write-Step "OK" "Da nhap key va kich hoat" "OK"
            }
        }
        "3" {
            $k = Read-Host "  Nhap Product Key cho $targetEdition"
            if (![string]::IsNullOrWhiteSpace($k)) {
                $ck = $k.Trim() -replace '\s+', ''
                & DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-Null
                & DISM /Online /Set-Edition:$targetEdition /ProductKey:$ck /AcceptEula 2>&1 | Out-Null
                Write-Step "OK" "DISM chuyen edition hoan tat" "OK"
            }
        }
    }
}

# ============================================================
#  PHASE 7: KICH HOAT
# ============================================================
function Invoke-Activation {
    Write-Header "PHASE 7: KICH HOAT GIAY PHEP"
    $oemKey = (Get-CimInstance -ClassName SoftwareLicensingService -EA SilentlyContinue).OA3xOriginalProductKey

    Write-Host "  [1] Nhap Product Key + kich hoat online" -Fore White
    Write-Host "  [2] Dung DISM + Product Key" -Fore White
    if ($oemKey) {
        Write-Host "  [3] Su dung OEM Key tu BIOS ($oemKey)" -Fore Green
    } else {
        Write-Host "  [3] OEM Key (Khong co trong BIOS)" -Fore DarkGray
    }
    Write-Host "  [4] Kich hoat qua Phone (slui 4)" -Fore White
    Write-Host "  [0] Bo qua" -Fore Red
    Write-Host ""

    $ch = Read-Host "  Chon [0-4]"
    switch ($ch) {
        "1" {
            $k = Read-Host "  Nhap Product Key"
            if (![string]::IsNullOrWhiteSpace($k)) {
                $ck = $k.Trim() -replace '\s+', ''
                Write-Step "INFO" "Dang nhap key..."
                & cscript //NoLogo $Script:Slmgr /ipk $ck 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Step "OK" "Nhap key thanh cong" "OK"
                    Write-Step "INFO" "Dang kich hoat online..."
                    & cscript //NoLogo $Script:Slmgr /ato 2>&1 | Out-Null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Step "OK" "Kich hoat thanh cong!" "OK"
                    } else {
                        Write-Step "WARN" "Kich hoat online that bai. Thu phuong phap khac." "WARN"
                    }
                } else {
                    Write-Step "WARN" "Nhap key that bai. Thu DISM..." "WARN"
                    & DISM /Online /Set-Edition:Professional /ProductKey:$ck /AcceptEula 2>&1 | Out-Null
                }
            }
        }
        "2" {
            $k = Read-Host "  Nhap Product Key"
            if (![string]::IsNullOrWhiteSpace($k)) {
                $ck = $k.Trim() -replace '\s+', ''
                & DISM /Online /Set-Edition:Professional /ProductKey:$ck /AcceptEula 2>&1 | Out-Null
                Write-Step "OK" "DISM hoan tat" "OK"
            }
        }
        "3" {
            if ($oemKey) {
                Write-Step "INFO" "Su dung OEM Key: $oemKey"
                & cscript //NoLogo $Script:Slmgr /ipk $oemKey 2>&1 | Out-Null
                & cscript //NoLogo $Script:Slmgr /ato 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Step "OK" "Kich hoat OEM thanh cong!" "OK"
                } else {
                    Write-Step "WARN" "Kich hoat OEM that bai" "WARN"
                }
            } else {
                Write-Step "WARN" "Khong co OEM Key trong BIOS" "WARN"
            }
        }
        "4" {
            Write-Step "INFO" "Mo giao dien kich hoat Phone..."
            Start-Process "slui.exe" -Arg "4"
        }
    }
}

# ============================================================
#  PHASE 8: XAC MINH KET QUA
# ============================================================
function Verify-Activation {
    Write-Header "PHASE 8: XAC MINH KET QUA"

    Write-Host "  ── Thoi han kich hoat ──────────────────────────────────" -Fore Cyan
    & cscript //NoLogo $Script:Slmgr /xpr 2>&1 | ForEach-Object {
        if ($_.Trim()) { Write-Host "  $_" }
    }
    Write-Host ""

    Write-Host "  ── Chi tiet license ────────────────────────────────────" -Fore Cyan
    & cscript //NoLogo $Script:Slmgr /dli 2>&1 | ForEach-Object {
        if ($_.Trim()) { Write-Host "  $_" }
    }
    Write-Host ""

    # Phan tich ket qua
    $dli = & cscript //NoLogo $Script:Slmgr /dli 2>&1
    $ls = ""
    foreach ($l in $dli) {
        if ($l -match "License Status:\s*(.+)") { $ls = $Matches[1].Trim() }
    }

    if ($ls -match "Licensed") {
        Write-Step "PASS" "Windows da kich hoat hop le!" "PASS"
        $Script:AuditReport.ActivationResult = @{ Status = "Licensed"; Permanent = $true; Detail = $ls }
    } else {
        Write-Step "FAIL" "Chua kich hoat: $ls" "FAIL"
        $Script:AuditReport.ActivationResult = @{ Status = $ls; Permanent = $false; Detail = $ls }
    }

    # Re-check Office
    if ($Script:AuditReport.Office.Count -gt 0) {
        Write-Host ""
        Write-Host "  ── Office License ──────────────────────────────────────" -Fore Cyan
        $osppPaths = @(
            "$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS"
        )
        foreach ($ospp in $osppPaths) {
            if (Test-Path $ospp) {
                & cscript //NoLogo $ospp /dstatus 2>&1 | ForEach-Object {
                    if ($_.Trim()) { Write-Host "  $_" }
                }
            }
        }
    }
}

# ============================================================
#  PHASE 9: KIEM TRA SUC KHOE HE THONG
# ============================================================
function Test-SystemHealth {
    Write-Header "PHASE 9: KIEM TRA SUC KHOE HE THONG"
    $h = @{}

    # Windows Update
    $wu = Get-Service wuauserv -EA SilentlyContinue
    if ($wu -and $wu.Status -eq "Running") {
        Write-Step "PASS" "Windows Update: Running" "PASS"; $h.WU = "OK"
    } else {
        Write-Step "WARN" "Windows Update: $($wu.Status)" "WARN"; $h.WU = $wu.Status
    }

    # Software Protection
    $sp = Get-Service sppsvc -EA SilentlyContinue
    if ($sp -and $sp.Status -eq "Running") {
        Write-Step "PASS" "Software Protection: Running" "PASS"; $h.SP = "OK"
    } else {
        Write-Step "WARN" "Software Protection: $($sp.Status)" "WARN"; $h.SP = $sp.Status
    }

    # Windows License Manager
    $wlmsvc = Get-Service LicenseManager -EA SilentlyContinue
    if ($wlmsvc -and $wlmsvc.Status -eq "Running") {
        Write-Step "PASS" "License Manager: Running" "PASS"; $h.LM = "OK"
    } else {
        Write-Step "WARN" "License Manager: $($wlmsvc.Status)" "WARN"; $h.LM = $wlmsvc.Status
    }

    # Defender
    try {
        $def = Get-MpComputerStatus -EA SilentlyContinue
        if ($def.AntivirusEnabled) {
            Write-Step "PASS" "Defender: Enabled" "PASS"; $h.Def = "OK"
        } else {
            Write-Step "WARN" "Defender: Disabled" "WARN"; $h.Def = "Disabled"
        }
    } catch { $h.Def = "Unknown" }

    # Firewall
    try {
        $fw = Get-NetFirewallProfile -EA SilentlyContinue
        if (($fw | Where-Object { $_.Enabled }).Count -gt 0) {
            Write-Step "PASS" "Firewall: Enabled" "PASS"; $h.FW = "OK"
        } else {
            Write-Step "WARN" "Firewall: Disabled" "WARN"; $h.FW = "Disabled"
        }
    } catch { $h.FW = "Unknown" }

    # BITS
    $bits = Get-Service bits -EA SilentlyContinue
    if ($bits -and $bits.Status -eq "Running") {
        Write-Step "PASS" "BITS: Running" "PASS"; $h.BITS = "OK"
    } else {
        Write-Step "WARN" "BITS: $($bits.Status)" "WARN"; $h.BITS = $bits.Status
    }

    # Cryptographic Services
    $crypt = Get-Service cryptsvc -EA SilentlyContinue
    if ($crypt -and $crypt.Status -eq "Running") {
        Write-Step "PASS" "Cryptographic Services: Running" "PASS"; $h.Crypt = "OK"
    } else {
        Write-Step "WARN" "Cryptographic Services: $($crypt.Status)" "WARN"; $h.Crypt = $crypt.Status
    }

    # System Drive Free Space
    $sys = $Script:AuditReport.SystemInfo
    if ($sys.FreeSpace_GB) {
        if ($sys.FreeSpace_GB -ge 20) {
            Write-Step "PASS" "Free Space: $($sys.FreeSpace_GB) GB" "PASS"; $h.Disk = "OK"
        } else {
            Write-Step "WARN" "Free Space thap: $($sys.FreeSpace_GB) GB" "WARN"; $h.Disk = "Low"
        }
    }

    Write-Host ""
    $Script:AuditReport.HealthStatus = $h
}

# ============================================================
#  PHASE 10: XUAT BAO CAO
# ============================================================
function Export-AuditReport {
    Write-Header "PHASE 10: XUAT BAO CAO"
    if (!(Test-Path $Script:ReportDir)) { New-Item -ItemType Directory $Script:ReportDir -Force | Out-Null }
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $mn = $env:COMPUTERNAME
    $r = $Script:AuditReport
    $s = $r.SystemInfo
    $w = $r.Windows

    # ──────────────────────────────────────────────────────────
    #  TXT Report
    # ──────────────────────────────────────────────────────────
    Write-Step "INFO" "Xuat bao cao TXT..."
    $txt = @()
    $txt += "=" * 70
    $txt += "  MICROSOFT LICENSE AUDIT REPORT"
    $txt += "  Pho Tue SoftWare Solutions JSC | HiTechCloud"
    $txt += "=" * 70
    $txt += "  May tinh:    $mn"
    $txt += "  Ngay:        $($r.AuditDate)"
    $txt += "  Tool:        v$($r.ToolVersion)"
    $txt += ""

    # System
    $txt += "--- HE THONG ---"
    $txt += "San pham:      $($s.ProductName)"
    $txt += "Edition:       $($s.CurrentEdition)"
    $txt += "Build:         $($s.CurrentBuild).$($s.UBR) ($($s.DisplayVersion))"
    $txt += "CPU:           $($s.CPU) ($($s.CPUCores) cores)"
    $txt += "RAM:           $($s.RAM_GB) GB"
    $txt += "Disk:          $($s.DiskSize_GB) GB ($($s.PartitionStyle))"
    $txt += "TPM:           $($s.TPMPresent) / $($s.TPMVersion)"
    $txt += "Secure Boot:   $($s.SecureBoot)"
    $txt += "Boot Mode:     $($s.BootMode)"
    $txt += ""

    # Windows License
    $txt += "--- WINDOWS LICENSE ---"
    $txt += "Trang thai:    $($w.Status)"
    $txt += "Channel:       $($w.Channel)"
    $txt += "Mo ta:         $($w.Description)"
    $txt += "Key 5 ky tu:   $($w.PartialKey)"
    $txt += "Het han:       $($w.Expiration)"
    $txt += "Phan loai:     $($w.Classification)"
    if ($w.OEMKey)     { $txt += "OEM Key:       $($w.OEMKey)" }
    if ($w.KMSMachine) { $txt += "KMS Server:    $($w.KMSMachine)" }
    $txt += ""

    # Office
    if ($r.Office.Count -gt 0) {
        $txt += "--- OFFICE ---"
        foreach ($o in $r.Office) {
            $txt += "$($o.LicenseName): $($o.LicenseStatus)"
            if ($o.KMSMachine) { $txt += "  KMS: $($o.KMSMachine)" }
            $txt += "  Key: $($o.PartialKey)"
        }
        $txt += ""
    }

    # Project
    if ($r.Project.Count -gt 0) {
        $txt += "--- PROJECT ---"
        foreach ($p in $r.Project) { $txt += "$($p.LicenseName): $($p.LicenseStatus)" }
        $txt += ""
    }

    # Visio
    if ($r.Visio.Count -gt 0) {
        $txt += "--- VISIO ---"
        foreach ($v in $r.Visio) { $txt += "$($v.LicenseName): $($v.LicenseStatus)" }
        $txt += ""
    }

    # Visual Studio
    if ($r.VisualStudio.Count -gt 0) {
        $txt += "--- VISUAL STUDIO ---"
        foreach ($vs in $r.VisualStudio) { $txt += "$($vs.Name) v$($vs.Version)" }
        $txt += ""
    }

    # SQL Server
    if ($r.SQLServer.Count -gt 0) {
        $txt += "--- SQL SERVER ---"
        foreach ($sql in $r.SQLServer) { $txt += "$($sql.DisplayName) [$($sql.Status)]" }
        $txt += ""
    }

    # Microsoft 365
    if ($r.Microsoft365 -and $r.Microsoft365.Found) {
        $txt += "--- MICROSOFT 365 ---"
        $txt += "Type:    $($r.Microsoft365.Type)"
        $txt += "Channel: $($r.Microsoft365.Channel)"
        $txt += "Version: $($r.Microsoft365.Version)"
        $txt += ""
    }

    # Issues
    if ($r.Issues.Count -gt 0) {
        $txt += "--- VAN DE PHAT HIEN ---"
        foreach ($i in $r.Issues) { $txt += "[$($i.Severity)] [$($i.Type)] $($i.Detail)" }
        $txt += ""
    }

    # Windows 11
    $txt += "--- WINDOWS 11 ---"
    foreach ($d in $r.Win11Ready.Details) { $txt += "$($d.Item): $($d.Status) - $($d.Detail)" }
    $txt += ""

    # Health
    $txt += "--- SUC KHOE HE THONG ---"
    foreach ($k in $r.HealthStatus.Keys) { $txt += "$k : $($r.HealthStatus[$k])" }
    $txt += ""

    $txt += "--- DANH GIA TONG HOP ---"
    $txt += "Risk Level:    $($r.RiskLevel)"
    $txt += "Tong van de:   $($r.Issues.Count)"
    $txt += "=" * 70

    $txtPath = Join-Path $Script:ReportDir "Audit_${mn}_${ts}.txt"
    $txt | Out-File $txtPath -Encoding UTF8
    Write-Step "OK" "TXT: $txtPath" "OK"

    # ──────────────────────────────────────────────────────────
    #  JSON Report
    # ──────────────────────────────────────────────────────────
    Write-Step "INFO" "Xuat bao cao JSON..."
    $jsonPath = Join-Path $Script:ReportDir "Audit_${mn}_${ts}.json"
    $r | ConvertTo-Json -Depth 10 | Out-File $jsonPath -Encoding UTF8
    Write-Step "OK" "JSON: $jsonPath" "OK"

    # ──────────────────────────────────────────────────────────
    #  CSV Report (Issues)
    # ──────────────────────────────────────────────────────────
    if ($r.Issues.Count -gt 0) {
        Write-Step "INFO" "Xuat bao cao CSV..."
        $csvPath = Join-Path $Script:ReportDir "Audit_${mn}_${ts}_issues.csv"
        $r.Issues | ForEach-Object { [PSCustomObject]$_ } | Export-Csv $csvPath -NoTypeInformation -Encoding UTF8
        Write-Step "OK" "CSV: $csvPath" "OK"
    }

    # ──────────────────────────────────────────────────────────
    #  HTML Report
    # ──────────────────────────────────────────────────────────
    Write-Step "INFO" "Xuat bao cao HTML..."
    $htmlPath = Join-Path $Script:ReportDir "Audit_${mn}_${ts}.html"

    $sc = if ($w.Licensed) { "#3fb950" } elseif ($w.Status -match "Notification") { "#d29922" } else { "#f85149" }

    # Issues rows
    $ir = ""
    foreach ($i in $r.Issues) {
        $ic = if ($i.Severity -eq "ERROR") { "#f85149" } elseif ($i.Severity -eq "WARN") { "#d29922" } else { "#58a6ff" }
        $ir += "<tr><td><span class=`"badge`" style=`"background:$ic`">$($i.Severity)</span></td><td>$($i.Type)</td><td>$($i.Product)</td><td>$($i.Detail)</td></tr>"
    }

    # Win11 rows
    $wr = ""
    foreach ($d in $r.Win11Ready.Details) {
        $wc = if ($d.Status -eq "PASS") { "#3fb950" } else { "#f85149" }
        $wi = if ($d.Status -eq "PASS") { "fa-check-circle" } else { "fa-times-circle" }
        $wr += "<tr><td>$($d.Item)</td><td><i class=`"fas $wi`" style=`"color:$wc`"></i> <span style=`"color:$wc; font-weight:bold`">$($d.Status)</span></td><td>$($d.Detail)</td></tr>"
    }

    # Health rows
    $hr = ""
    foreach ($k in $r.HealthStatus.Keys) {
        $hc = if ($r.HealthStatus[$k] -eq "OK") { "#3fb950" } else { "#d29922" }
        $hi = if ($r.HealthStatus[$k] -eq "OK") { "fa-check-circle" } else { "fa-exclamation-triangle" }
        $hr += "<tr><td>$k</td><td><i class=`"fas $hi`" style=`"color:$hc`"></i> <span style=`"color:$hc`">$($r.HealthStatus[$k])</span></td></tr>"
    }

    # Office rows
    $or = ""
    foreach ($o in $r.Office) {
        $oc = if ($o.LicenseStatus -match "LICENSED") { "#3fb950" } else { "#d29922" }
        $or += "<tr><td>$($o.LicenseName)</td><td><span style=`"color:$oc; font-weight:bold`">$($o.LicenseStatus)</span></td><td>$($o.PartialKey)</td><td>$($o.KMSMachine)</td></tr>"
    }

    # Project/Visio rows
    $pvRows = ""
    foreach ($p in $r.Project) {
        $pc = if ($p.LicenseStatus -match "LICENSED") { "#3fb950" } else { "#d29922" }
        $pvRows += "<tr><td>Project</td><td>$($p.LicenseName)</td><td style=`"color:$pc`">$($p.LicenseStatus)</td></tr>"
    }
    foreach ($v in $r.Visio) {
        $vc = if ($v.LicenseStatus -match "LICENSED") { "#3fb950" } else { "#d29922" }
        $pvRows += "<tr><td>Visio</td><td>$($v.LicenseName)</td><td style=`"color:$vc`">$($v.LicenseStatus)</td></tr>"
    }

    # VS rows
    $vsRows = ""
    foreach ($vs in $r.VisualStudio) {
        $vsRows += "<tr><td>$($vs.Name)</td><td>$($vs.Version)</td><td>$($vs.Path)</td></tr>"
    }

    # SQL rows
    $sqlRows = ""
    foreach ($sql in $r.SQLServer) {
        $sqlc = if ($sql.Status -eq "Running") { "#3fb950" } else { "#d29922" }
        $sqlRows += "<tr><td>$($sql.DisplayName)</td><td style=`"color:$sqlc`">$($sql.Status)</td><td>$($sql.StartType)</td></tr>"
    }

    # Risk level badge
    $riskColor = switch ($r.RiskLevel) { "HOP_LE" { "#3fb950" } "CAN_XEM_XET" { "#d29922" } "CAN_XU_LY" { "#f85149" } default { "#8b949e" } }
    $riskText = switch ($r.RiskLevel) { "HOP_LE" { "HOP LE" } "CAN_XEM_XET" { "CAN XEM XET" } "CAN_XU_LY" { "CAN XU LY" } default { "UNKNOWN" } }

    $html = @"
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Microsoft License Audit - $mn</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
    <style>
        :root {
            --bg-primary: #0d1117;
            --bg-secondary: #161b22;
            --bg-tertiary: #21262d;
            --border: #30363d;
            --text-primary: #e6edf3;
            --text-secondary: #8b949e;
            --accent: #58a6ff;
            --success: #3fb950;
            --warning: #d29922;
            --danger: #f85149;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: var(--bg-primary);
            color: var(--text-primary);
            line-height: 1.6;
        }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header {
            background: linear-gradient(135deg, #1a1f36 0%, #0d1117 100%);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 30px;
            margin-bottom: 30px;
            text-align: center;
        }
        .header h1 {
            color: var(--accent);
            font-size: 1.8em;
            margin-bottom: 10px;
        }
        .header .subtitle { color: var(--text-secondary); font-size: 0.95em; }
        .header .meta {
            margin-top: 15px;
            display: flex;
            justify-content: center;
            gap: 30px;
            flex-wrap: wrap;
        }
        .header .meta span {
            background: var(--bg-tertiary);
            padding: 6px 16px;
            border-radius: 20px;
            font-size: 0.85em;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: 10px;
            padding: 20px;
            text-align: center;
        }
        .stat-card .value {
            font-size: 2em;
            font-weight: 700;
            margin-bottom: 5px;
        }
        .stat-card .label {
            color: var(--text-secondary);
            font-size: 0.85em;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .section {
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: 10px;
            margin-bottom: 20px;
            overflow: hidden;
        }
        .section-header {
            background: var(--bg-tertiary);
            padding: 15px 20px;
            border-bottom: 1px solid var(--border);
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .section-header h2 {
            font-size: 1.1em;
            color: var(--accent);
            margin: 0;
        }
        .section-header i { color: var(--accent); font-size: 1.1em; }
        .section-body { padding: 0; }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 12px 16px;
            text-align: left;
            border-bottom: 1px solid var(--border);
            font-size: 0.9em;
        }
        th {
            background: var(--bg-tertiary);
            color: var(--accent);
            font-weight: 600;
            text-transform: uppercase;
            font-size: 0.75em;
            letter-spacing: 0.5px;
        }
        tr:last-child td { border-bottom: none; }
        tr:hover { background: rgba(88, 166, 255, 0.05); }
        .badge {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 12px;
            font-size: 0.75em;
            font-weight: 600;
            color: white;
        }
        .risk-badge {
            display: inline-block;
            padding: 8px 24px;
            border-radius: 20px;
            font-size: 1em;
            font-weight: 700;
            color: white;
            background: $riskColor;
        }
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 0;
        }
        .info-row {
            display: flex;
            border-bottom: 1px solid var(--border);
        }
        .info-row .info-label {
            width: 180px;
            min-width: 180px;
            padding: 10px 16px;
            background: var(--bg-tertiary);
            color: var(--text-secondary);
            font-size: 0.85em;
        }
        .info-row .info-value {
            flex: 1;
            padding: 10px 16px;
            font-size: 0.9em;
        }
        .footer {
            text-align: center;
            padding: 30px;
            color: var(--text-secondary);
            font-size: 0.85em;
            border-top: 1px solid var(--border);
            margin-top: 30px;
        }
        .footer a { color: var(--accent); text-decoration: none; }
        .no-data { color: var(--text-secondary); font-style: italic; padding: 20px; text-align: center; }
        @media (max-width: 768px) {
            .info-grid { grid-template-columns: 1fr; }
            .info-row { flex-direction: column; }
            .info-row .info-label { width: 100%; }
            .stats-grid { grid-template-columns: 1fr 1fr; }
        }
        @media print {
            body { background: white; color: #333; }
            .section { break-inside: avoid; }
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <h1><i class="fas fa-shield-alt"></i> Microsoft License Audit Report</h1>
            <p class="subtitle">Pho Tue SoftWare Solutions JSC | HiTechCloud - Microsoft Partner</p>
            <div class="meta">
                <span><i class="fas fa-desktop"></i> $mn</span>
                <span><i class="fas fa-calendar"></i> $($r.AuditDate)</span>
                <span><i class="fas fa-code-branch"></i> Tool v$($r.ToolVersion)</span>
                <span class="risk-badge"><i class="fas fa-exclamation-triangle"></i> Risk: $riskText</span>
            </div>
        </div>

        <!-- Stats -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="value" style="color:$sc">$($s.CurrentEdition)</div>
                <div class="label">Windows Edition</div>
            </div>
            <div class="stat-card">
                <div class="value" style="color:$sc">$($w.Status)</div>
                <div class="label">License Status</div>
            </div>
            <div class="stat-card">
                <div class="value" style="color:$(if($r.Issues.Count -eq 0){'#3fb950'}else{'#d29922'})">$($r.Issues.Count)</div>
                <div class="label">Issues Found</div>
            </div>
            <div class="stat-card">
                <div class="value" style="color:$(if($r.Win11Ready.Fail -eq 0){'#3fb950'}else{'#f85149'})">$($r.Win11Ready.Pass)/$($r.Win11Ready.Pass + $r.Win11Ready.Fail)</div>
                <div class="label">Win11 Ready</div>
            </div>
        </div>

        <!-- System Info -->
        <div class="section">
            <div class="section-header">
                <i class="fas fa-server"></i>
                <h2>Thong tin he thong</h2>
            </div>
            <div class="section-body">
                <div class="info-row"><div class="info-label">San pham</div><div class="info-value">$($s.ProductName)</div></div>
                <div class="info-row"><div class="info-label">Build</div><div class="info-value">$($s.CurrentBuild).$($s.UBR) ($($s.DisplayVersion))</div></div>
                <div class="info-row"><div class="info-label">CPU</div><div class="info-value">$($s.CPU) ($($s.CPUCores) cores / $($s.CPULogical) threads)</div></div>
                <div class="info-row"><div class="info-label">RAM</div><div class="info-value">$($s.RAM_GB) GB</div></div>
                <div class="info-row"><div class="info-label">Disk</div><div class="info-value">$($s.DiskSize_GB) GB ($($s.PartitionStyle)) - Free: $($s.FreeSpace_GB) GB</div></div>
                <div class="info-row"><div class="info-label">BIOS</div><div class="info-value">$($s.BIOSManufacturer) $($s.BIOSVersion)</div></div>
                <div class="info-row"><div class="info-label">Mainboard</div><div class="info-value">$($s.Motherboard)</div></div>
                <div class="info-row"><div class="info-label">TPM</div><div class="info-value">Present=$($s.TPMPresent) Ready=$($s.TPMReady) Version=$($s.TPMVersion)</div></div>
                <div class="info-row"><div class="info-label">Secure Boot</div><div class="info-value">$($s.SecureBoot)</div></div>
                <div class="info-row"><div class="info-label">Boot Mode</div><div class="info-value">$($s.BootMode)</div></div>
            </div>
        </div>

        <!-- Windows License -->
        <div class="section">
            <div class="section-header">
                <i class="fab fa-windows"></i>
                <h2>Windows License</h2>
            </div>
            <div class="section-body">
                <div class="info-row"><div class="info-label">Trang thai</div><div class="info-value" style="color:$sc; font-weight:bold">$($w.Status)</div></div>
                <div class="info-row"><div class="info-label">Channel</div><div class="info-value">$($w.Channel)</div></div>
                <div class="info-row"><div class="info-label">Mo ta</div><div class="info-value">$($w.Description)</div></div>
                <div class="info-row"><div class="info-label">Key</div><div class="info-value">*****$($w.PartialKey)</div></div>
                <div class="info-row"><div class="info-label">Het han</div><div class="info-value">$($w.Expiration)</div></div>
                <div class="info-row"><div class="info-label">Phan loai</div><div class="info-value"><span class="badge" style="background:$riskColor">$($w.Classification)</span></div></div>
$(if($w.OEMKey){"                <div class=`"info-row`"><div class=`"info-label`">OEM Key</div><div class=`"info-value`" style=`"color:#3fb950`">$($w.OEMKey)</div></div>"})
$(if($w.KMSMachine){"                <div class=`"info-row`"><div class=`"info-label`">KMS Server</div><div class=`"info-value`" style=`"color:#f85149`">$($w.KMSMachine)</div></div>"})
            </div>
        </div>

$(if ($r.Office.Count -gt 0) {
@"
        <!-- Office -->
        <div class="section">
            <div class="section-header">
                <i class="fas fa-file-word"></i>
                <h2>Microsoft Office</h2>
            </div>
            <div class="section-body">
                <table>
                    <thead><tr><th>San pham</th><th>Trang thai</th><th>Key</th><th>KMS</th></tr></thead>
                    <tbody>$or</tbody>
                </table>
            </div>
        </div>
"@
})

$(if ($pvRows) {
@"
        <!-- Project / Visio -->
        <div class="section">
            <div class="section-header">
                <i class="fas fa-project-diagram"></i>
                <h2>Project & Visio</h2>
            </div>
            <div class="section-body">
                <table>
                    <thead><tr><th>Loai</th><th>San pham</th><th>Trang thai</th></tr></thead>
                    <tbody>$pvRows</tbody>
                </table>
            </div>
        </div>
"@
})

$(if ($vsRows) {
@"
        <!-- Visual Studio -->
        <div class="section">
            <div class="section-header">
                <i class="fas fa-code"></i>
                <h2>Visual Studio</h2>
            </div>
            <div class="section-body">
                <table>
                    <thead><tr><th>Ten</th><th>Version</th><th>Duong dan</th></tr></thead>
                    <tbody>$vsRows</tbody>
                </table>
            </div>
        </div>
"@
})

$(if ($sqlRows) {
@"
        <!-- SQL Server -->
        <div class="section">
            <div class="section-header">
                <i class="fas fa-database"></i>
                <h2>SQL Server</h2>
            </div>
            <div class="section-body">
                <table>
                    <thead><tr><th>Dich vu</th><th>Trang thai</th><th>Start Type</th></tr></thead>
                    <tbody>$sqlRows</tbody>
                </table>
            </div>
        </div>
"@
})

        <!-- Windows 11 -->
        <div class="section">
            <div class="section-header">
                <i class="fas fa-laptop"></i>
                <h2>Windows 11 Compatibility ($($r.Win11Ready.Pass)/$($r.Win11Ready.Pass + $r.Win11Ready.Fatal)) PASS</h2>
            </div>
            <div class="section-body">
                <table>
                    <thead><tr><th>Tieu chi</th><th>Ket qua</th><th>Chi tiet</th></tr></thead>
                    <tbody>$wr</tbody>
                </table>
            </div>
        </div>

$(if ($r.Issues.Count -gt 0) {
@"
        <!-- Issues -->
        <div class="section">
            <div class="section-header">
                <i class="fas fa-exclamation-triangle"></i>
                <h2>Van de phat hien ($($r.Issues.Count))</h2>
            </div>
            <div class="section-body">
                <table>
                    <thead><tr><th>Muc do</th><th>Loai</th><th>San pham</th><th>Chi tiet</th></tr></thead>
                    <tbody>$ir</tbody>
                </table>
            </div>
        </div>
"@
})

        <!-- Health -->
        <div class="section">
            <div class="section-header">
                <i class="fas fa-heartbeat"></i>
                <h2>Suc khoe he thong</h2>
            </div>
            <div class="section-body">
                <table>
                    <thead><tr><th>Thanh phan</th><th>Trang thai</th></tr></thead>
                    <tbody>$hr</tbody>
                </table>
            </div>
        </div>

        <!-- Footer -->
        <div class="footer">
            <p><strong>PHO TUE SOFTWARE SOLUTIONS JSC</strong></p>
            <p>HiTechCloud - Microsoft Partner</p>
            <p>Website: <a href="https://photuesoftware.com">photuesoftware.com</a> | <a href="https://hitechcloud.vn">hitechcloud.vn</a></p>
            <p style="margin-top:10px; font-size:0.8em;">Microsoft Genuine License Audit & Recovery Tool v$($r.ToolVersion) | Generated: $($r.AuditDate)</p>
        </div>
    </div>
</body>
</html>
"@

    ($html -join "`n") | Out-File $htmlPath -Encoding UTF8
    Write-Step "OK" "HTML: $htmlPath" "OK"

    Write-Host ""
    Write-Host "  ═══ BAO CAO DA XUAT ═══" -Fore Green
    Write-Host "  Thu muc: $Script:ReportDir" -Fore Cyan
    Write-Host ""

    $o = Read-Host "  Mo bao cao HTML? (Y/N)"
    if ($o -eq 'Y' -or $o -eq 'y') { Start-Process $htmlPath }
}

# ============================================================
#  FULL AUDIT (CHAY TOAN BO)
# ============================================================
function Invoke-FullAudit {
    Get-SystemInventory
    Test-Windows11Compatibility
    Get-LicenseAudit
    Detect-InvalidActivation
    Confirm-And-Cleanup
    Invoke-EditionUpgrade
    Invoke-Activation
    Verify-Activation
    Test-SystemHealth
    Export-AuditReport

    Write-Host ""
    Write-Host "  $([string]::new([char]0x2550, 50))" -Fore Green
    Write-Host "  HOAN TAT KIEM TOAN VA PHUC HOI!" -Fore Green
    Write-Host "  $([string]::new([char]0x2550, 50))" -Fore Green
    Write-Host ""
}

# ============================================================
#  CAC CHUC NANG DON LE
# ============================================================
function Show-LicenseStatus {
    Write-Header "TRANG THAI LICENSE"
    Write-Host "  ── Windows License ─────────────────────────────────────" -Fore Cyan
    & cscript //NoLogo $Script:Slmgr /dlv
    Write-Host ""
    Write-Host "  ── Thoi han ────────────────────────────────────────────" -Fore Cyan
    & cscript //NoLogo $Script:Slmgr /xpr
    Write-Host ""
}

function Check-WindowsEdition {
    Write-Header "PHIEN BAN WINDOWS"
    & DISM /Online /Get-CurrentEdition 2>&1 | ForEach-Object { if ($_.Trim()) { Write-Host "  $_" } }
    Write-Host ""
    & DISM /Online /Get-TargetEditions 2>&1 | ForEach-Object { if ($_.Trim()) { Write-Host "  $_" } }
    Write-Host ""
    $oem = (Get-CimInstance -ClassName SoftwareLicensingService -EA SilentlyContinue).OA3xOriginalProductKey
    if ($oem) { Write-Host "  OEM Key: $oem" -Fore Green }
    Write-Host ""
    & cscript //NoLogo $Script:Slmgr /xpr
    Write-Host ""
}

function Activate-NewLicense {
    Write-Header "NHAP KEY MOI"
    $k = Read-Host "  Product Key"
    if ([string]::IsNullOrWhiteSpace($k)) { return }
    $ck = $k.Trim() -replace '\s+', ''

    Write-Step "INFO" "Dang nhap key..."
    & cscript //NoLogo $Script:Slmgr /ipk $ck 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Step "OK" "Nhap key thanh cong" "OK"
        Write-Step "INFO" "Dang kich hoat..."
        & cscript //NoLogo $Script:Slmgr /ato 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Step "OK" "Kich hoat thanh cong!" "OK"
        } else {
            Write-Step "WARN" "Kich hoat that bai. Thu DISM..." "WARN"
            & DISM /Online /Set-Edition:Professional /ProductKey:$ck /AcceptEula 2>&1 | Out-Null
        }
    } else {
        Write-Step "WARN" "slmgr loi. Thu DISM..." "WARN"
        & DISM /Online /Set-Edition:Professional /ProductKey:$ck /AcceptEula 2>&1 | Out-Null
    }
    Write-Host ""
    & cscript //NoLogo $Script:Slmgr /xpr
}

function Fix-SystemErrors {
    Write-Header "SUA LOI HE THONG"
    Write-Step "INFO" "DISM RestoreHealth (co the mat 5-15 phut)..."
    & DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-Null
    Write-Step "OK" "DISM hoan tat" "OK"

    Write-Step "INFO" "SFC /scannow..."
    & sfc /scannow 2>&1 | Out-Null
    Write-Step "OK" "SFC hoan tat" "OK"

    # Reset Windows Update cache
    Write-Step "INFO" "Reset Windows Update cache..."
    foreach ($s in @("wuauserv", "bits", "cryptsvc", "msiserver")) {
        Stop-Service $s -Force -EA SilentlyContinue
    }
    $sd = "$env:SystemRoot\SoftwareDistribution"
    $cr = "$env:SystemRoot\System32\catroot2"
    if (Test-Path $sd) { Rename-Item $sd "${sd}.old" -Force -EA SilentlyContinue }
    if (Test-Path $cr) { Rename-Item $cr "${cr}.old" -Force -EA SilentlyContinue }
    foreach ($s in @("wuauserv", "bits", "cryptsvc", "msiserver")) {
        Start-Service $s -EA SilentlyContinue
    }
    Write-Step "OK" "Da reset Windows Update cache" "OK"

    $r = Read-Host "  Khoi dong lai? (Y/N)"
    if ($r -eq 'Y' -or $r -eq 'y') { shutdown /r /t 10 /c "Sua loi he thong - Pho Tue Software" }
}

function Upgrade-HomeToPro {
    Write-Header "NANG CAP HOME -> PRO"
    $cr = & DISM /Online /Get-CurrentEdition 2>&1
    $ce = ""
    foreach ($l in $cr) {
        if ($l -match "Current Edition\s*:\s*(.+)") { $ce = $Matches[1].Trim() }
    }
    Write-Host "  Edition hien tai: $ce" -Fore Cyan

    if ($ce -match "Professional|Enterprise|Education") {
        Write-Step "OK" "Da la Pro hoac cao hon" "OK"
        return
    }

    Write-Host ""
    Write-Host "  [1] Generic Key (VK7JG...)" -Fore White
    Write-Host "  [2] Nhap key Pro rieng" -Fore White
    Write-Host "  [3] DISM chuyen edition" -Fore White
    Write-Host "  [0] Bo qua" -Fore Red
    $ch = Read-Host "  Chon"

    switch ($ch) {
        "1" {
            & cscript //NoLogo $Script:Slmgr /ipk $Script:GenericProKey 2>&1 | Out-Null
            & cscript //NoLogo $Script:Slmgr /ato 2>&1 | Out-Null
        }
        "2" {
            $k = Read-Host "  Nhap key Pro"
            if (![string]::IsNullOrWhiteSpace($k)) {
                $ck = $k.Trim() -replace '\s+', ''
                & cscript //NoLogo $Script:Slmgr /ipk $ck 2>&1 | Out-Null
                & cscript //NoLogo $Script:Slmgr /ato 2>&1 | Out-Null
            }
        }
        "3" {
            $k = Read-Host "  Nhap key Pro"
            if (![string]::IsNullOrWhiteSpace($k)) {
                $ck = $k.Trim() -replace '\s+', ''
                & DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-Null
                & DISM /Online /Set-Edition:Professional /ProductKey:$ck /AcceptEula 2>&1 | Out-Null
            }
        }
    }

    $r = Read-Host "  Khoi dong lai? (Y/N)"
    if ($r -eq 'Y' -or $r -eq 'y') { shutdown /r /t 10 /c "Nang cap Pro - Pho Tue Software" }
}

function Invoke-FullCleanup {
    Write-Header "LAM SACH TOAN BO"

    Write-Step "INFO" "Tao backup..."
    if (!(Test-Path $Script:BackupDir)) { New-Item -ItemType Directory $Script:BackupDir -Force | Out-Null }
    if (Test-Path $Script:HostsPath) { Copy-Item $Script:HostsPath "$Script:BackupDir\hosts.backup" -Force }
    reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" "$Script:BackupDir\spp_backup.reg" /y 2>&1 | Out-Null
    Write-Step "OK" "Backup: $Script:BackupDir" "OK"

    Run-Slmgr "/upk"  "Go Product Key"
    Run-Slmgr "/cpky" "Xoa Registry Key"
    Run-Slmgr "/ckms" "Xoa KMS Server"
    Run-Slmgr "/rearm" "Reset Activation"

    # KMS Registry
    foreach ($e in $Script:KMSRegistryKeys) {
        try {
            if ($e.Name) { Remove-ItemProperty $e.Path -Name $e.Name -Force -EA SilentlyContinue }
            else { Remove-Item $e.Path -Recurse -Force -EA SilentlyContinue }
        } catch {}
    }

    # KMS Files
    foreach ($d in $Script:KMSDirectories) {
        if (Test-Path $d) { Remove-Item $d -Recurse -Force -EA SilentlyContinue }
    }
    foreach ($f in $Script:KMSFiles) {
        if (Test-Path $f) {
            takeown /f $f 2>$null | Out-Null
            icacls $f /grant administrators:F 2>$null | Out-Null
            Remove-Item $f -Force -EA SilentlyContinue
        }
    }

    # Scheduled Tasks
    foreach ($t in $Script:KMSTasks) {
        Unregister-ScheduledTask $t -Confirm:$false -EA SilentlyContinue
    }

    # Services
    foreach ($kw in $Script:KMSServiceNames) {
        $svcs = Get-Service "*$kw*" -EA SilentlyContinue
        foreach ($svc in $svcs) {
            Stop-Service $svc.Name -Force -EA SilentlyContinue
            & sc.exe delete $svc.Name 2>&1 | Out-Null
        }
    }

    # Hosts
    if (Test-Path $Script:HostsPath) {
        $content = Get-Content $Script:HostsPath
        $keywords = @("activation", "kms", "crack", "kmspico", "kmsauto", "office", "microsoft.com")
        $clean = $content | Where-Object {
            $line = $_; $keep = $true
            foreach ($kw in $keywords) {
                if ($line -match $kw -and $line -notmatch "^\s*#") { $keep = $false; break }
            }
            $keep
        }
        $clean | Set-Content $Script:HostsPath -Force -Encoding ASCII
    }

    # Defender
    try {
        Set-MpPreference -DisableRealtimeMonitoring $false -EA SilentlyContinue
    } catch {}

    # Windows Update
    try {
        Set-Service wuauserv -StartupType Automatic -EA SilentlyContinue
        Start-Service wuauserv -EA SilentlyContinue
    } catch {}

    Write-Host ""
    Write-Host "  HOAN TAT LAM SACH!" -Fore Green
    Write-Host "  Backup: $Script:BackupDir" -Fore Cyan

    $r = Read-Host "  Khoi dong lai? (Y/N)"
    if ($r -eq 'Y' -or $r -eq 'y') { shutdown /r /t 10 /c "Lam sach he thong - Pho Tue Software" }
}

function Export-QuickReport {
    Get-SystemInventory | Out-Null
    Get-LicenseAudit | Out-Null
    Test-Windows11Compatibility | Out-Null
    Detect-InvalidActivation | Out-Null
    Test-SystemHealth | Out-Null
    Export-AuditReport
}

# ============================================================
#  MULTI-LANGUAGE SYSTEM (i18n)
# ============================================================
$Script:Lang = "vi"
$Script:T = @{}

# Vietnamese
$Script:Lang_vi = @{
    # Menu
    MenuTitle       = "CONG CU KIEM TOAN VA PHUC HOI BAN QUYEN MICROSOFT"
    MenuAudit       = "KIEM TOAN VA PHUC HOI TONG HOP"
    MenuFull        = "Kiem toan toan dien (Audit + Cleanup + Activate + Report)"
    MenuSysInfo     = "Chi kiem tra thong tin he thong"
    MenuDetect      = "Chi phat hien van de ban quyen"
    MenuCleanup     = "Chi lam sach he thong (can xac nhan)"
    MenuHealth      = "Chi kiem tra suc khoe he thong"
    MenuReport      = "Xuat bao cao (HTML/JSON/TXT/CSV)"
    MenuWindows     = "WINDOWS"
    MenuOffice      = "OFFICE / PROJECT / VISIO"
    MenuOther       = "PHAN MEM KHAC"
    MenuSystem      = "HE THONG"
    MenuExit        = "Thoat"
    # Phases
    PhaseAudit      = "PHASE: KIEM TOAN DOC LAP (Chi doc)"
    PhaseComply     = "PHASE: KIEM TRA TIEU CHUAN DOANH NGHIEP"
    PhaseRecovery   = "PHASE: PHUC HOI LICENSE"
    PhaseDeploy     = "PHASE: TRIEN KHAI LICENSE (Batch)"
    PhaseWinUp      = "PHASE: NANG CAP WINDOWS"
    PhaseOffUp      = "PHASE: NANG CAP OFFICE"
    PhaseCenter     = "PHASE: TRUNG TAM SAN PHAM MICROSOFT"
    PhaseSecurity   = "PHASE: KIEM TRA BAO MAT"
    PhaseHealth     = "PHASE: KIEM TRA SUC KHOE"
    PhaseCleanup    = "PHASE: DON DEP HE THONG"
    PhaseBackup     = "PHASE: SAO LUU"
    PhaseRestore    = "PHASE: KHOI PHUC"
    # Status
    StatusPass      = "DAT"
    StatusFail      = "KHONG DAT"
    StatusWarn      = "CAN KIEM TRA"
    StatusOK        = "BINH THUONG"
    StatusMissing   = "KHONG TIM THAY"
    # Actions
    ActionProceed   = "Ban co muon tiep tuc?"
    ActionConfirm   = "Xac nhan"
    ActionCancel    = "Huy"
    ActionBackup    = "Dang tao backup..."
    ActionRepair    = "Dang sua chua..."
    ActionDone      = "HOAN TAT!"
    # Report
    ReportTitle     = "BAO CAO KIEM TOAN BAN QUYEN MICROSOFT"
    ReportMachine   = "May tinh"
    ReportDate      = "Ngay"
    ReportVersion   = "Phien ban"
}

# English
$Script:Lang_en = @{
    MenuTitle       = "MICROSOFT LICENSE AUDIT & RECOVERY TOOL"
    MenuAudit       = "AUDIT & RECOVERY"
    MenuFull        = "Full Audit (Audit + Cleanup + Activate + Report)"
    MenuSysInfo     = "System Information Only"
    MenuDetect      = "License Issues Detection Only"
    MenuCleanup     = "System Cleanup (requires confirmation)"
    MenuHealth      = "System Health Check Only"
    MenuReport      = "Export Report (HTML/JSON/TXT/CSV)"
    MenuWindows     = "WINDOWS"
    MenuOffice      = "OFFICE / PROJECT / VISIO"
    MenuOther       = "OTHER SOFTWARE"
    MenuSystem      = "SYSTEM"
    MenuExit        = "Exit"
    PhaseAudit      = "PHASE: READ-ONLY AUDIT"
    PhaseComply     = "PHASE: ENTERPRISE COMPLIANCE CHECK"
    PhaseRecovery   = "PHASE: LICENSE RECOVERY"
    PhaseDeploy     = "PHASE: LICENSE DEPLOYMENT (Batch)"
    PhaseWinUp      = "PHASE: WINDOWS UPGRADE"
    PhaseOffUp      = "PHASE: OFFICE UPGRADE"
    PhaseCenter     = "PHASE: MICROSOFT PRODUCT CENTER"
    PhaseSecurity   = "PHASE: SECURITY SCAN"
    PhaseHealth     = "PHASE: HEALTH CHECK"
    PhaseCleanup    = "PHASE: SYSTEM CLEANUP"
    PhaseBackup     = "PHASE: BACKUP"
    PhaseRestore    = "PHASE: RESTORE"
    StatusPass      = "PASS"
    StatusFail      = "FAIL"
    StatusWarn      = "NEEDS REVIEW"
    StatusOK        = "OK"
    StatusMissing   = "NOT FOUND"
    ActionProceed   = "Do you want to proceed?"
    ActionConfirm   = "Confirm"
    ActionCancel    = "Cancel"
    ActionBackup    = "Creating backup..."
    ActionRepair    = "Repairing..."
    ActionDone      = "DONE!"
    ReportTitle     = "MICROSOFT LICENSE AUDIT REPORT"
    ReportMachine   = "Machine"
    ReportDate      = "Date"
    ReportVersion   = "Version"
}

# Japanese
$Script:Lang_ja = @{
    MenuTitle       = "Microsoft ライセンス監査・回復ツール"
    MenuFull        = "フル監査 (監査+クリーンアップ+アクティベート+レポート)"
    MenuExit        = "終了"
    StatusPass      = "合格"
    StatusFail      = "不合格"
    ActionDone      = "完了!"
}

# Chinese
$Script:Lang_zh = @{
    MenuTitle       = "Microsoft 许可审计与恢复工具"
    MenuFull        = "完整审计 (审计+清理+激活+报告)"
    MenuExit        = "退出"
    StatusPass      = "通过"
    StatusFail      = "未通过"
    ActionDone      = "完成!"
}

# German
$Script:Lang_de = @{
    MenuTitle       = "Microsoft Lizenz-Audit- & Wiederherstellungstool"
    MenuFull        = "Vollständiges Audit (Audit+Cleanup+Aktivierung+Bericht)"
    MenuExit        = "Beenden"
    StatusPass      = "BESTANDEN"
    StatusFail      = "NICHT BESTANDEN"
    ActionDone      = "FERTIG!"
}

# French
$Script:Lang_fr = @{
    MenuTitle       = "Outil d'audit et de récupération de licences Microsoft"
    MenuFull        = "Audit complet (Audit+Nettoyage+Activation+Rapport)"
    MenuExit        = "Quitter"
    StatusPass      = "RÉUSSI"
    StatusFail      = "ÉCHOUÉ"
    ActionDone      = "TERMINÉ!"
}

function Set-Language {
    param([string]$Code)
    $Script:Lang = $Code
    $langVar = "Lang_$Code"
    if (Get-Variable -Name $langVar -Scope Script -EA SilentlyContinue) {
        $Script:T = (Get-Variable -Name $langVar -Scope Script).Value
    } else {
        $Script:T = $Script:Lang_vi
    }
}

function Get-T {
    param([string]$Key)
    if ($Script:T.ContainsKey($Key)) { return $Script:T[$Key] }
    if ($Script:Lang_vi.ContainsKey($Key)) { return $Script:Lang_vi[$Key] }
    return $Key
}

# Default language
Set-Language "vi"

# ============================================================
#  PHASE: AUDIT DOC LAP (Chi doc - khong thay doi)
# ============================================================
function Invoke-ReadOnlyAudit {
    Write-Header "AUDIT DOC LAP (Chi doc - khong thay doi he thong)"
    Write-Host "  Muc chi: Chi thu thap va hien thi thong tin, KHONG thay doi gi." -Fore Yellow
    Write-Host ""

    $auditData = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Machine   = $env:COMPUTERNAME
        Products  = @{}
    }

    # Windows
    Write-Step "INFO" "── Windows ─────────────────────────────────────────────"
    $nt = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -EA SilentlyContinue
    $winInfo = @{
        ProductName    = $nt.ProductName
        DisplayVersion = $nt.DisplayVersion
        CurrentBuild   = $nt.CurrentBuild
        UBR            = $nt.UBR
    }
    $dli = & cscript //NoLogo $Script:Slmgr /dli 2>&1
    foreach ($l in $dli) {
        if ($l -match "License Status:\s*(.+)")     { $winInfo.LicenseStatus = $Matches[1].Trim() }
        if ($l -match "Product Key Channel:\s*(.+)") { $winInfo.Channel = $Matches[1].Trim() }
        if ($l -match "Partial Product Key:\s*(.+)") { $winInfo.PartialKey = $Matches[1].Trim() }
        if ($l -match "KMS Machine Name:\s*(.+)")    { $winInfo.KMSMachine = $Matches[1].Trim() }
    }
    $xpr = & cscript //NoLogo $Script:Slmgr /xpr 2>&1
    $winInfo.Expiration = ($xpr | Where-Object { $_ -match "\S" } | Select-Object -Last 1)
    try { $winInfo.OEMKey = (Get-CimInstance SoftwareLicensingService -EA SilentlyContinue).OA3xOriginalProductKey } catch {}
    $auditData.Products.Windows = $winInfo
    Write-Host "  Product:       $($winInfo.ProductName)" -Fore White
    Write-Host "  Build:         $($winInfo.CurrentBuild).$($winInfo.UBR)" -Fore White
    Write-Host "  License:       $($winInfo.LicenseStatus)" -Fore $(if($winInfo.LicenseStatus -match "Licensed"){"Green"}else{"Red"})
    Write-Host "  Channel:       $($winInfo.Channel)" -Fore White
    Write-Host "  Expiration:    $($winInfo.Expiration)" -Fore White
    if ($winInfo.OEMKey) { Write-Host "  OEM Key:       $($winInfo.OEMKey)" -Fore Green }
    Write-Host ""

    # Office / Project / Visio
    Write-Step "INFO" "── Office / Project / Visio ────────────────────────────"
    $osppPaths = @(
        "$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS",
        "$env:ProgramFiles\Microsoft Office\Office15\OSPP.VBS"
    )
    $ospp = $osppPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    $officeProducts = @()
    if ($ospp) {
        $out = & cscript //NoLogo $ospp /dstatus 2>&1
        $cur = @{}
        foreach ($l in $out) {
            if ($l -match "LICENSE NAME:\s*(.+)")        { $cur.LicenseName = $Matches[1].Trim() }
            if ($l -match "LICENSE STATUS:\s*(.+)")      { $cur.LicenseStatus = $Matches[1].Trim() }
            if ($l -match "Last 5 characters.*:\s*(.+)") { $cur.PartialKey = $Matches[1].Trim() }
            if ($l -match "KMS machine name:\s*(.+)")    { $cur.KMSMachine = $Matches[1].Trim() }
            if ($l -match "---") {
                if ($cur.LicenseName) {
                    $officeProducts += $cur.Clone()
                    $type = if ($cur.LicenseName -match "Project") { "Project" } elseif ($cur.LicenseName -match "Visio") { "Visio" } else { "Office" }
                    Write-Host "  $type`: $($cur.LicenseName)" -Fore Cyan
                    Write-Host "    Status:  $($cur.LicenseStatus)" -Fore $(if($cur.LicenseStatus -match "LICENSED"){"Green"}else{"Yellow"})
                    if ($cur.KMSMachine) { Write-Host "    KMS:     $($cur.KMSMachine)" -Fore Yellow }
                }
                $cur = @{}
            }
        }
        if ($cur.LicenseName) { $officeProducts += $cur.Clone() }
    } else {
        Write-Host "  Khong tim thay Office" -Fore DarkGray
    }
    $auditData.Products.Office = $officeProducts
    Write-Host ""

    # Visual Studio
    Write-Step "INFO" "── Visual Studio ───────────────────────────────────────"
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $vsList = @()
    if (Test-Path $vswhere) {
        try {
            $vsData = (& $vswhere -all -format json 2>&1) | ConvertFrom-Json
            foreach ($vs in $vsData) {
                $vsList += @{ Name=$vs.displayName; Version=$vs.installationVersion; Path=$vs.installPath }
                Write-Host "  $($vs.displayName) v$($vs.installationVersion)" -Fore Cyan
            }
        } catch {}
    }
    if ($vsList.Count -eq 0) { Write-Host "  Khong tim thay Visual Studio" -Fore DarkGray }
    $auditData.Products.VisualStudio = $vsList
    Write-Host ""

    # SQL Server
    Write-Step "INFO" "── SQL Server ──────────────────────────────────────────"
    $sqlSvc = Get-Service *sql* -EA SilentlyContinue
    $sqlList = @()
    if ($sqlSvc) {
        foreach ($s in $sqlSvc) {
            $sqlList += @{ Name=$s.DisplayName; Status=$s.Status; StartType=$s.StartType }
            Write-Host "  $($s.DisplayName) [$($s.Status)]" -Fore Cyan
        }
    } else { Write-Host "  Khong tim thay SQL Server" -Fore DarkGray }
    $auditData.Products.SQLServer = $sqlList
    Write-Host ""

    # Microsoft 365
    Write-Step "INFO" "── Microsoft 365 ───────────────────────────────────────"
    $c2r = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -EA SilentlyContinue
    if ($c2r) {
        Write-Host "  Products:  $($c2r.ProductReleaseIds)" -Fore Cyan
        Write-Host "  Channel:   $($c2r.UpdateChannel)" -Fore Cyan
        Write-Host "  Version:   $($c2r.ClientVersionToReport)" -Fore Cyan
        $auditData.Products.M365 = @{ Products=$c2r.ProductReleaseIds; Channel=$c2r.UpdateChannel; Version=$c2r.ClientVersionToReport }
    } else { Write-Host "  Khong tim thay Microsoft 365" -Fore DarkGray }
    Write-Host ""

    # OneDrive
    Write-Step "INFO" "── OneDrive ────────────────────────────────────────────"
    $odSvc = Get-Service OneSyncSvc* -EA SilentlyContinue
    $odPath = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
    if (Test-Path $odPath) {
        $odVer = (Get-Item $odPath).VersionInfo.ProductVersion
        Write-Host "  OneDrive: $odVer" -Fore Cyan
        $auditData.Products.OneDrive = @{ Version=$odVer; Path=$odPath }
    } else { Write-Host "  Khong tim thay OneDrive" -Fore DarkGray }
    Write-Host ""

    # Teams
    Write-Step "INFO" "── Microsoft Teams ─────────────────────────────────────"
    $teamsPaths = @(
        "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe",
        "$env:ProgramFiles\Teams Installer\Teams.exe",
        "${env:ProgramFiles(x86)}\Teams Installer\Teams.exe",
        "$env:LOCALAPPDATA\Microsoft\Teams\current\teams.exe"
    )
    $teamsFound = $false
    foreach ($tp in $teamsPaths) {
        if (Test-Path $tp) {
            $tv = (Get-Item $tp).VersionInfo.ProductVersion
            Write-Host "  Teams: $tv" -Fore Cyan
            $auditData.Products.Teams = @{ Version=$tv; Path=$tp }
            $teamsFound = $true; break
        }
    }
    # New Teams (Windows 11)
    $newTeams = Get-AppxPackage -AllUsers *MSTeams* -EA SilentlyContinue
    if ($newTeams) {
        Write-Host "  New Teams: $($newTeams.Version)" -Fore Cyan
        $auditData.Products.NewTeams = @{ Version=$newTeams.Version }
        $teamsFound = $true
    }
    if (-not $teamsFound) { Write-Host "  Khong tim thay Teams" -Fore DarkGray }
    Write-Host ""

    # Edge Enterprise
    Write-Step "INFO" "── Microsoft Edge ──────────────────────────────────────"
    $edgePath = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    if (Test-Path $edgePath) {
        $edgeVer = (Get-Item $edgePath).VersionInfo.ProductVersion
        Write-Host "  Edge: $edgeVer" -Fore Cyan
        # Check if enterprise
        $edgeReg = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -EA SilentlyContinue
        if ($edgeReg) { Write-Host "  Enterprise Policy: Yes" -Fore Yellow }
        $auditData.Products.Edge = @{ Version=$edgeVer; Enterprise=($null -ne $edgeReg) }
    } else { Write-Host "  Khong tim thay Edge" -Fore DarkGray }
    Write-Host ""

    # Defender
    Write-Step "INFO" "── Defender ────────────────────────────────────────────"
    try {
        $def = Get-MpComputerStatus -EA SilentlyContinue
        Write-Host "  Antivirus:     $($def.AntivirusEnabled)" -Fore $(if($def.AntivirusEnabled){"Green"}else{"Red"})
        Write-Host "  Real-time:     $($def.RealTimeProtectionEnabled)" -Fore $(if($def.RealTimeProtectionEnabled){"Green"}else{"Red"})
        Write-Host "  Signatures:    $($def.AntivirusSignatureLastUpdated)" -Fore White
        Write-Host "  Tamper:        $($def.TamperProtection)" -Fore $(if($def.TamperProtection){"Green"}else{"Red"})
        $auditData.Products.Defender = @{
            Enabled=$def.AntivirusEnabled; RealTime=$def.RealTimeProtectionEnabled
            Signatures=$def.AntivirusSignatureLastUpdated; Tamper=$def.TamperProtection
        }
    } catch { Write-Host "  Khong the truy cap Defender" -Fore DarkGray }
    Write-Host ""

    # Windows Server
    if ($nt.ProductName -match "Server") {
        Write-Step "INFO" "── Windows Server ──────────────────────────────────────"
        Write-Host "  Edition: $($nt.ProductName)" -Fore Cyan
        $auditData.Products.WindowsServer = @{ Edition=$nt.ProductName }
        Write-Host ""
    }

    # Luu audit data
    $Script:AuditReport.ReadOnlyAudit = $auditData

    # Xuat bao cao
    Write-Step "INFO" "Xuat bao cao audit..."
    if (!(Test-Path $Script:ReportDir)) { New-Item -ItemType Directory $Script:ReportDir -Force | Out-Null }
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $jsonPath = Join-Path $Script:ReportDir "ReadOnlyAudit_${env:COMPUTERNAME}_${ts}.json"
    $auditData | ConvertTo-Json -Depth 10 | Out-File $jsonPath -Encoding UTF8
    Write-Step "OK" "JSON: $jsonPath" "OK"
    Write-Host ""
    Write-Host "  Audit hoan tat. Khong co thay doi nao duoc thuc hien." -Fore Green
    Write-Host ""
}

# ============================================================
#  PHASE: KIEM TRA TIEU CHUAN DOANH NGHIEP (COMPLIANCE)
# ============================================================
function Invoke-ComplianceCheck {
    Write-Header "KIEM TRA TIEU CHUAN DOANH NGHIEP (COMPLIANCE)"
    $results = @()

    function Check-Comply {
        param([string]$Name, [bool]$Passed, [string]$Detail)
        $status = if ($Passed) { "PASS" } else { "FAIL" }
        $icon = if ($Passed) { "[OK]" } else { "[!!]" }
        $color = if ($Passed) { "Green" } else { "Red" }
        Write-Host "  $icon $Name - $Detail" -Fore $color
        $results += @{ Item=$Name; Status=$status; Detail=$Detail }
    }

    # Secure Boot
    try { $sb = Confirm-SecureBootUEFI -EA SilentlyContinue } catch { $sb = $false }
    Check-Comply "Secure Boot" ($sb -eq $true) $(if($sb){"Enabled"}else{"Disabled"})

    # TPM
    try {
        $tpm = Get-Tpm -EA SilentlyContinue
        Check-Comply "TPM 2.0" ($tpm.TpmPresent -and $tpm.SpecVersion -match "^2\.") "Present=$($tpm.TpmPresent) Version=$($tpm.SpecVersion)"
    } catch { Check-Comply "TPM 2.0" $false "Not available" }

    # BitLocker
    try {
        $bl = Get-BitLockerVolume -MountPoint $env:SystemDrive -EA SilentlyContinue
        $blOn = $bl.ProtectionStatus -eq "On"
        Check-Comply "BitLocker" $blOn "Protection=$($bl.ProtectionStatus)"
    } catch { Check-Comply "BitLocker" $false "Not available" }

    # Defender
    try {
        $def = Get-MpComputerStatus -EA SilentlyContinue
        Check-Comply "Defender" $def.AntivirusEnabled "Enabled=$($def.AntivirusEnabled)"
        Check-Comply "Tamper Protection" $def.TamperProtection "Status=$($def.TamperProtection)"
    } catch { Check-Comply "Defender" $false "Not available" }

    # Firewall
    try {
        $fw = Get-NetFirewallProfile -EA SilentlyContinue
        $fwAll = ($fw | Where-Object { $_.Enabled }).Count -eq $fw.Count
        Check-Comply "Firewall" $fwAll "$(($fw|?{$_.Enabled}).Count)/$($fw.Count) profiles enabled"
    } catch { Check-Comply "Firewall" $false "Not available" }

    # Windows Update
    $wu = Get-Service wuauserv -EA SilentlyContinue
    Check-Comply "Windows Update" ($wu.Status -eq "Running") "Status=$($wu.Status)"

    # Genuine License
    $dli = & cscript //NoLogo $Script:Slmgr /dli 2>&1
    $licStatus = ""; foreach ($l in $dli) { if ($l -match "License Status:\s*(.+)") { $licStatus = $Matches[1].Trim() } }
    Check-Comply "Genuine License" ($licStatus -match "Licensed") "Status=$licStatus"

    # Microsoft Account
    $maLogged = (Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue).PartOfDomain
    $maUser = whoami 2>&1
    Check-Comply "Domain/Account" ($maLogged -or $maUser -match "\\") "User=$maUser"

    # Local Security Policy
    try {
        $secPol = secedit /export /cfg "$env:TEMP\secpol.cfg" 2>&1
        $minPwLen = (Get-Content "$env:TEMP\secpol.cfg" | Where-Object { $_ -match "MinimumPasswordLength" })
        Check-Comply "Security Policy" ($null -ne $minPwLen) "Password policy exists"
        Remove-Item "$env:TEMP\secpol.cfg" -Force -EA SilentlyContinue
    } catch { Check-Comply "Security Policy" $false "Cannot read" }

    # RDP
    $rdp = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -EA SilentlyContinue
    $rdpEnabled = $rdp.fDenyTSConnections -eq 0
    Check-Comply "RDP" $rdpEnabled $(if($rdpEnabled){"Enabled"}else{"Disabled"})

    # SMB
    $smbSvc = Get-Service LanmanServer -EA SilentlyContinue
    Check-Comply "SMB" ($smbSvc.Status -eq "Running") "Status=$($smbSvc.Status)"

    # PowerShell Execution Policy
    $psPolicy = Get-ExecutionPolicy -Scope LocalMachine
    Check-Comply "PowerShell Policy" ($psPolicy -ne "Unrestricted") "Policy=$psPolicy"

    # Device Guard
    try {
        $dg = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -EA SilentlyContinue
        $dgEnabled = $dg.VirtualizationBasedSecurityStatus -eq 2
        Check-Comply "Device Guard / VBS" $dgEnabled "VBS=$($dg.VirtualizationBasedSecurityStatus)"
    } catch { Check-Comply "Device Guard / VBS" $false "Not available" }

    # Credential Guard
    try {
        $cg = (Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -EA SilentlyContinue).SecurityServicesRunning
        $cgEnabled = $cg -contains 1
        Check-Comply "Credential Guard" $cgEnabled "Running=$cg"
    } catch { Check-Comply "Credential Guard" $false "Not available" }

    # HVCI
    try {
        $hvci = (Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -EA SilentlyContinue).SecurityServicesRunning
        $hvciEnabled = $hvci -contains 2
        Check-Comply "HVCI" $hvciEnabled "Running=$hvci"
    } catch { Check-Comply "HVCI" $false "Not available" }

    # SmartScreen
    $ssReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name SmartScreenEnabled -EA SilentlyContinue
    $ssEnabled = $ssReg.SmartScreenEnabled -ne "Off"
    Check-Comply "SmartScreen" $ssEnabled "Value=$($ssReg.SmartScreenEnabled)"

    # Summary
    Write-Host ""
    $passCount = ($results | Where-Object { $_.Status -eq "PASS" }).Count
    $failCount = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
    $total = $results.Count
    if ($failCount -eq 0) {
        Write-Host "  -> DAT TAT CA TIEU CHUAN ($passCount/$total)" -Fore Green
    } else {
        Write-Host "  -> KHONG DAT $failCount / $total tieu chuan" -Fore Red
        Write-Host "  -> Cac muc khong dat:" -Fore Yellow
        $results | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
            Write-Host "    [-] $($_.Item): $($_.Detail)" -Fore Red
        }
    }
    $Script:AuditReport.Compliance = $results
    Write-Host ""
}

# ============================================================
#  PHASE: PHUC HOI LICENSE (EXTENDED)
# ============================================================
function Invoke-LicenseRecovery {
    Write-Header "PHUC HOI LICENSE"
    Write-Host "  Cac buoc phuc hoi:" -Fore Cyan
    Write-Host "    [1] Remove KMS Configuration" -Fore White
    Write-Host "    [2] Remove Invalid Product Key" -Fore White
    Write-Host "    [3] Remove Activation Cache" -Fore White
    Write-Host "    [4] Restore Hosts" -Fore White
    Write-Host "    [5] Restore Defender" -Fore White
    Write-Host "    [6] Restore Registry" -Fore White
    Write-Host "    [7] Repair SPP (Software Protection)" -Fore White
    Write-Host "    [8] Repair Windows (DISM + SFC)" -Fore White
    Write-Host "    [9] Repair Office (OSPP)" -Fore White
    Write-Host "   [10] Repair Licensing Service" -Fore White
    Write-Host "   [11] THUC HIEN TAT CA" -Fore Green
    Write-Host "    [0] Bo qua" -Fore Red
    Write-Host ""
    $ch = Read-Host "  Chon (so, nhieu so cach dau phay, hoac 'all')"

    if ($ch -eq "0" -or $ch -eq "") { return }

    # Backup
    Write-Step "INFO" "Tao backup..."
    if (!(Test-Path $Script:BackupDir)) { New-Item -ItemType Directory $Script:BackupDir -Force | Out-Null }
    reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" "$Script:BackupDir\spp.reg" /y 2>&1 | Out-Null
    if (Test-Path $Script:HostsPath) { Copy-Item $Script:HostsPath "$Script:BackupDir\hosts" -Force }

    $acts = if ($ch -eq "all" -or $ch -eq "11") { 1..10 } else { $ch -split "[,\s]+" | ForEach-Object { [int]$_ } }

    foreach ($act in $acts) {
        switch ($act) {
            1 {
                Write-Step "DEL" "Remove KMS Configuration..."
                Run-Slmgr "/ckms" "Xoa KMS Server"
                foreach ($e in $Script:KMSRegistryKeys) {
                    try {
                        if ($e.Name) { Remove-ItemProperty $e.Path -Name $e.Name -Force -EA SilentlyContinue }
                        else { Remove-Item $e.Path -Recurse -Force -EA SilentlyContinue }
                    } catch {}
                }
            }
            2 {
                Write-Step "DEL" "Remove Invalid Product Key..."
                Run-Slmgr "/upk" "Go Product Key"
                Run-Slmgr "/cpky" "Xoa Registry Key"
            }
            3 {
                Write-Step "DEL" "Remove Activation Cache..."
                Run-Slmgr "/rearm" "Reset Activation"
            }
            4 {
                Write-Step "DEL" "Restore Hosts..."
                if (Test-Path $Script:HostsPath) {
                    $content = Get-Content $Script:HostsPath
                    $kws = @("activation","kms","crack","kmspico","kmsauto","office","microsoft.com")
                    $clean = $content | Where-Object { $l=$_; $k=$true; foreach($w in $kws){if($l-match $w-and $l-notmatch "^\s*#"){$k=$false}}; $k }
                    $clean | Set-Content $Script:HostsPath -Force -Encoding ASCII
                    Write-Step "OK" "Hosts da khoi phuc" "OK"
                }
            }
            5 {
                Write-Step "DEL" "Restore Defender..."
                try {
                    Set-MpPreference -DisableRealtimeMonitoring $false -EA SilentlyContinue
                    $mp = Get-MpPreference -EA SilentlyContinue
                    if ($mp.ExclusionPath) { foreach ($ex in $mp.ExclusionPath) { Remove-MpPreference -ExclusionPath $ex -EA SilentlyContinue } }
                    if ($mp.ExclusionProcess) { foreach ($ex in $mp.ExclusionProcess) { Remove-MpPreference -ExclusionProcess $ex -EA SilentlyContinue } }
                    Write-Step "OK" "Defender da khoi phuc" "OK"
                } catch {}
            }
            6 {
                Write-Step "DEL" "Restore Registry..."
                foreach ($e in $Script:KMSRegistryKeys) {
                    try {
                        if ($e.Name) { Remove-ItemProperty $e.Path -Name $e.Name -Force -EA SilentlyContinue }
                    } catch {}
                }
                # Remove Office KMS registry
                $osppReg = "HKLM:\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform"
                if (Test-Path "$osppReg\KMS") { Remove-Item "$osppReg\KMS" -Recurse -Force -EA SilentlyContinue }
                Write-Step "OK" "Registry da khoi phuc" "OK"
            }
            7 {
                Write-Step "INFO" "Repair SPP..."
                try { Stop-Service sppsvc -Force -EA SilentlyContinue } catch {}
                Start-Sleep 2
                try { Start-Service sppsvc -EA SilentlyContinue; Write-Step "OK" "SPP restarted" "OK" } catch { Write-Step "WARN" "Khong the restart SPP" "WARN" }
            }
            8 {
                Write-Step "INFO" "Repair Windows (DISM + SFC)..."
                & DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-Null
                Write-Step "OK" "DISM OK" "OK"
                & sfc /scannow 2>&1 | Out-Null
                Write-Step "OK" "SFC OK" "OK"
            }
            9 {
                Write-Step "INFO" "Repair Office..."
                $ospp = @("$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS","${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS") | Where-Object { Test-Path $_ } | Select-Object -First 1
                if ($ospp) {
                    & cscript //NoLogo $ospp /remhst 2>&1 | Out-Null
                    Write-Step "OK" "Office KMS removed" "OK"
                } else { Write-Step "WARN" "Khong tim thay OSPP.VBS" "WARN" }
            }
            10 {
                Write-Step "INFO" "Repair Licensing Service..."
                try {
                    Set-Service sppsvc -StartupType Automatic -EA SilentlyContinue
                    Start-Service sppsvc -EA SilentlyContinue
                    Set-Service wuauserv -StartupType Automatic -EA SilentlyContinue
                    Start-Service wuauserv -EA SilentlyContinue
                    Write-Step "OK" "Licensing services running" "OK"
                } catch { Write-Step "WARN" "Co loi khi khoi dong services" "WARN" }
            }
        }
    }
    Write-Host ""
    Write-Host "  PHUC HOI HOAN TAT!" -Fore Green
    Write-Host ""
}

# ============================================================
#  PHASE: TRIEN KHAI LICENSE (BATCH)
# ============================================================
function Invoke-LicenseDeployment {
    Write-Header "TRIEN KHAI LICENSE (BATCH)"
    Write-Host "  Nhap key theo dinh dang: MAY_TINH | SAN_PHAM | KEY" -Fore Cyan
    Write-Host "  Vi du:" -Fore DarkGray
    Write-Host "    PC001 | Windows 11 Pro | VK7JG-NPHTM-C97JM-9MPGT-3V66T" -Fore DarkGray
    Write-Host "    PC002 | Office LTSC | XXXXX-XXXXX-XXXXX-XXXXX-XXXXX" -Fore DarkGray
    Write-Host ""
    Write-Host "  [1] Nhap thu cong (dang bang)" -Fore White
    Write-Host "  [2] Import tu file CSV" -Fore White
    Write-Host "  [3] Import tu file JSON" -Fore White
    Write-Host "  [0] Bo qua" -Fore Red
    Write-Host ""
    $ch = Read-Host "  Chon"

    $licenses = @()

    switch ($ch) {
        "1" {
            Write-Host "  Nhap danh sach (mo dong 1 entry, Enter de ket thuc):" -Fore Yellow
            while ($true) {
                $line = Read-Host "  "
                if ([string]::IsNullOrWhiteSpace($line)) { break }
                $parts = $line -split "\|"
                if ($parts.Count -ge 3) {
                    $licenses += @{
                        Machine = $parts[0].Trim()
                        Product = $parts[1].Trim()
                        Key     = $parts[2].Trim() -replace '\s+', ''
                    }
                }
            }
        }
        "2" {
            $csvPath = Read-Host "  Nhap duong dan file CSV"
            if (Test-Path $csvPath) {
                $csv = Import-Csv $csvPath
                foreach ($row in $csv) {
                    $licenses += @{
                        Machine = $row.Machine
                        Product = $row.Product
                        Key     = $row.Key -replace '\s+', ''
                    }
                }
            } else { Write-Step "ERROR" "Khong tim thay file" "ERROR"; return }
        }
        "3" {
            $jsonPath = Read-Host "  Nhap duong dan file JSON"
            if (Test-Path $jsonPath) {
                $json = Get-Content $jsonPath -Raw | ConvertFrom-Json
                foreach ($item in $json) {
                    $licenses += @{
                        Machine = $item.Machine
                        Product = $item.Product
                        Key     = $item.Key -replace '\s+', ''
                    }
                }
            } else { Write-Step "ERROR" "Khong tim thay file" "ERROR"; return }
        }
        "0" { return }
    }

    if ($licenses.Count -eq 0) {
        Write-Step "WARN" "Khong co license nao de trien khai" "WARN"
        return
    }

    Write-Host ""
    Write-Host "  ── Xac nhan trien khai ($($licenses.Count) licenses) ────────────────" -Fore Yellow
    foreach ($lic in $licenses) {
        Write-Host "    $($lic.Machine) | $($lic.Product) | $($lic.Key)" -Fore White
    }
    Write-Host ""
    if (-not (Confirm-Proceed "Trien khai tat ca?")) { return }

    $results = @()
    foreach ($lic in $licenses) {
        Write-Host ""
        Write-Step "INFO" "Xu ly: $($lic.Machine) - $($lic.Product)"
        $ck = $lic.Key -replace '\s+', ''

        # Chi xu ly local machine
        if ($lic.Machine -eq $env:COMPUTERNAME -or $lic.Machine -eq "." -or $lic.Machine -eq "localhost") {
            & cscript //NoLogo $Script:Slmgr /ipk $ck 2>&1 | Out-Null
            & cscript //NoLogo $Script:Slmgr /ato 2>&1 | Out-Null
            $dli = & cscript //NoLogo $Script:Slmgr /dli 2>&1
            $ls = ""; foreach ($l in $dli) { if ($l -match "License Status:\s*(.+)") { $ls = $Matches[1].Trim() } }
            Write-Step $(if($ls-match "Licensed"){"OK"}else{"WARN"}) "$($lic.Machine): $ls" $(if($ls-match "Licensed"){"OK"}else{"WARN"})
            $results += @{ Machine=$lic.Machine; Product=$lic.Product; Status=$ls }
        } else {
            Write-Step "SKIP" "$($lic.Machine): Chi ho tro local machine (dung PSRemoting cho remote)" "SKIP"
            $results += @{ Machine=$lic.Machine; Product=$lic.Product; Status="SKIP (remote)" }
        }
    }

    Write-Host ""
    Write-Host "  ── Ket qua ─────────────────────────────────────────────" -Fore Cyan
    foreach ($r in $results) {
        Write-Host "    $($r.Machine) | $($r.Product) | $($r.Status)" -Fore $(if($r.Status-match "Licensed"){"Green"}else{"Yellow"})
    }
    Write-Host ""
}

# ============================================================
#  PHASE: NANG CAP WINDOWS
# ============================================================
function Invoke-WindowsUpgrade {
    Write-Header "NANG CAP WINDOWS"

    $nt = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -EA SilentlyContinue
    $currentBuild = [int]$nt.CurrentBuild
    $currentVersion = $nt.DisplayVersion

    Write-Host "  Windows hien tai: $($nt.ProductName)" -Fore Cyan
    Write-Host "  Build:            $($nt.CurrentBuild).$($nt.UBR) ($currentVersion)" -Fore Cyan
    Write-Host ""

    # Kiem tra dieu kien
    Write-Step "INFO" "Kiem tra dieu kien nang cap..."
    $ready = $true

    # CPU
    $cpu = Get-CimInstance Win32_Processor -EA SilentlyContinue | Select-Object -First 1
    if ($cpu) {
        Write-Host "  CPU: $($cpu.Name)" -Fore White
    }

    # TPM
    try {
        $tpm = Get-Tpm -EA SilentlyContinue
        if ($tpm.TpmPresent -and $tpm.SpecVersion -match "^2\.") {
            Write-Step "PASS" "TPM 2.0: $($tpm.SpecVersion)" "PASS"
        } else {
            Write-Step "FAIL" "TPM 2.0: Khong ho tro" "FAIL"; $ready = $false
        }
    } catch { Write-Step "FAIL" "TPM: Not available" "FAIL"; $ready = $false }

    # RAM
    $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
    if ($ram -ge 4) { Write-Step "PASS" "RAM: $ram GB" "PASS" } else { Write-Step "FAIL" "RAM: $ram GB (< 4GB)" "FAIL"; $ready = $false }

    # Disk
    $disk = Get-Disk | Where-Object { $_.IsSystem -eq $true } | Select-Object -First 1
    $diskGB = [math]::Round($disk.Size / 1GB, 0)
    if ($diskGB -ge 64) { Write-Step "PASS" "Disk: $diskGB GB" "PASS" } else { Write-Step "FAIL" "Disk: $diskGB GB (< 64GB)" "FAIL"; $ready = $false }

    # GPT
    if ($disk.PartitionStyle -eq "GPT") { Write-Step "PASS" "GPT: $($disk.PartitionStyle)" "PASS" } else { Write-Step "FAIL" "GPT: $($disk.PartitionStyle)" "FAIL"; $ready = $false }

    # Secure Boot
    try { $sb = Confirm-SecureBootUEFI -EA SilentlyContinue } catch { $sb = $false }
    if ($sb) { Write-Step "PASS" "Secure Boot: Enabled" "PASS" } else { Write-Step "FAIL" "Secure Boot: Disabled" "FAIL"; $ready = $false }

    # UEFI
    $fw = Get-ComputerInfo -Property BiosFirmwareType -EA SilentlyContinue
    if ($fw.BiosFirmwareType -match "Uefi") { Write-Step "PASS" "UEFI: $($fw.BiosFirmwareType)" "PASS" } else { Write-Step "FAIL" "UEFI: $($fw.BiosFirmwareType)" "FAIL"; $ready = $false }

    Write-Host ""
    if (-not $ready) {
        Write-Host "  -> May tinh KHONG DAT dieu kien nang cap Windows 11" -Fore Red
        Write-Host "  -> Khac phuc cac van de tren truoc khi nang cap." -Fore Yellow
        return
    }

    Write-Host "  -> May tinh DAT dieu kien nang cap!" -Fore Green
    Write-Host ""
    Write-Host "  [1] Nang cap tu dong (Windows Update)" -Fore White
    Write-Host "  [2] Nang cap tu ISO" -Fore White
    Write-Host "  [3] Chi kiem tra (khong nang cap)" -Fore White
    Write-Host "  [0] Bo qua" -Fore Red
    Write-Host ""
    $ch = Read-Host "  Chon"

    switch ($ch) {
        "1" {
            Write-Step "INFO" "Mo Windows Update..."
            Start-Process "ms-settings:windowsupdate-action"
            Write-Host "  Windows Update da mo. Nhan 'Check for updates' de bat dau." -Fore Yellow
        }
        "2" {
            $isoPath = Read-Host "  Nhap duong dan file ISO"
            if (Test-Path $isoPath) {
                Write-Step "INFO" "Mount ISO..."
                $mount = Mount-DiskImage -ImagePath $isoPath -PassThru
                $driveLetter = ($mount | Get-Volume).DriveLetter
                Write-Step "OK" "Da mount tai ${driveLetter}:" "OK"
                Write-Step "INFO" "Bat dau nang cap..."
                Start-Process "${driveLetter}:\setup.exe" -Arg "/auto upgrade /quiet /noreboot" -Wait
                Write-Step "OK" "Nang cap hoan tat. Khoi dong lai de ap dung." "OK"
            } else {
                Write-Step "ERROR" "Khong tim thay file ISO" "ERROR"
            }
        }
        "3" {
            Write-Host "  Kiem tra hoan tat. May tinh dat dieu kien nang cap." -Fore Green
        }
    }
    Write-Host ""
}

# ============================================================
#  PHASE: NANG CAP OFFICE
# ============================================================
function Invoke-OfficeUpgrade {
    Write-Header "NANG CAP OFFICE"

    # Kiem tra Office hien tai
    Write-Step "INFO" "Kiem tra Office hien tai..."
    $c2r = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -EA SilentlyContinue
    $ospp = @("$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS","${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS") | Where-Object { Test-Path $_ } | Select-Object -First 1

    $currentOffice = "Unknown"
    $currentVersion = "Unknown"

    if ($c2r) {
        $currentOffice = $c2r.ProductReleaseIds
        $currentVersion = $c2r.ClientVersionToReport
    }

    if ($ospp) {
        $out = & cscript //NoLogo $ospp /dstatus 2>&1
        foreach ($l in $out) {
            if ($l -match "LICENSE NAME:\s*(.+)") { $currentOffice = $Matches[1].Trim(); break }
        }
    }

    Write-Host "  Office hien tai: $currentOffice" -Fore Cyan
    Write-Host "  Version:         $currentVersion" -Fore Cyan
    Write-Host ""

    Write-Host "  Duong dan nang cap:" -Fore Yellow
    Write-Host "    Office 2016/2019 -> Office LTSC 2024" -Fore White
    Write-Host "    Office 2021      -> Office LTSC 2024" -Fore White
    Write-Host "    Office LTSC      -> Microsoft 365 Apps" -Fore White
    Write-Host ""
    Write-Host "  [1] Nang cap len Office LTSC 2024" -Fore White
    Write-Host "  [2] Nang cap len Microsoft 365 Apps" -Fore White
    Write-Host "  [3] Su dung Office Deployment Tool (ODT)" -Fore White
    Write-Host "  [0] Bo qua" -Fore Red
    Write-Host ""
    $ch = Read-Host "  Chon"

    switch ($ch) {
        "1" {
            Write-Step "INFO" "Tai Office LTSC 2024 Deployment Tool..."
            $odtUrl = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/OfficeDeploymentTool_17531-20020.exe"
            $odtPath = "$env:TEMP\odt.exe"
            $configPath = "$env:TEMP\odt-config.xml"

            # Tao config
            $config = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="PerpetualVL2024">
    <Product ID="ProPlus2024Volume" PIDKEY="XJ2XN-FW8RK-P4HMP-DKDBV-GCVGB">
      <Language ID="vi-vn" />
      <Language ID="en-us" />
    </Product>
  </Add>
  <Display Level="Full" AcceptEULA="TRUE" />
  <Property Name="SharedComputerLicensing" Value="0" />
</Configuration>
"@
            $config | Out-File $configPath -Encoding UTF8
            Write-Host "  Config: $configPath" -Fore DarkGray
            Write-Host "  Su dung ODT de cai dat. Chi tiet: https://learn.microsoft.com/office/deployment-tool" -Fore Yellow
        }
        "2" {
            Write-Step "INFO" "Tai Microsoft 365 Apps..."
            Write-Host "  Truy cap: https://setup.office.com" -Fore Yellow
            Write-Host "  Hoac su dung ODT voi Product ID: O365ProPlusRetail" -Fore Yellow
        }
        "3" {
            Write-Step "INFO" "Office Deployment Tool"
            Write-Host "  Download: https://www.microsoft.com/en-us/download/details.aspx?id=49117" -Fore Yellow
            Write-Host "  Config:   https://config.office.com" -Fore Yellow
        }
    }
    Write-Host ""
}

# ============================================================
#  PHASE: TRUNG TAM SAN PHAM MICROSOFT
# ============================================================
function Invoke-ProductCenter {
    Write-Header "TRUNG TAM SAN PHAM MICROSOFT"

    $products = @{}

    # Windows
    Write-Step "INFO" "── Windows ─────────────────────────────────────────────"
    $nt = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -EA SilentlyContinue
    $dli = & cscript //NoLogo $Script:Slmgr /dli 2>&1
    $ls = ""; $ch = ""
    foreach ($l in $dli) {
        if ($l -match "License Status:\s*(.+)") { $ls = $Matches[1].Trim() }
        if ($l -match "Product Key Channel:\s*(.+)") { $ch = $Matches[1].Trim() }
    }
    $products.Windows = @{ Edition=$nt.ProductName; Build="$($nt.CurrentBuild).$($nt.UBR)"; Status=$ls; Channel=$ch }
    Write-Host "  $($nt.ProductName) - $ls ($ch)" -Fore $(if($ls-match "Licensed"){"Green"}else{"Red"})

    # Windows Server
    if ($nt.ProductName -match "Server") {
        $products.WindowsServer = @{ Edition=$nt.ProductName; Status=$ls }
        Write-Host "  Windows Server: $($nt.ProductName)" -Fore Cyan
    }
    Write-Host ""

    # Office / Project / Visio
    Write-Step "INFO" "── Office / Project / Visio ────────────────────────────"
    $ospp = @("$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS","${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS") | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($ospp) {
        $out = & cscript //NoLogo $ospp /dstatus 2>&1
        $cur = @{}
        foreach ($l in $out) {
            if ($l -match "LICENSE NAME:\s*(.+)")   { $cur.LicenseName = $Matches[1].Trim() }
            if ($l -match "LICENSE STATUS:\s*(.+)") { $cur.LicenseStatus = $Matches[1].Trim() }
            if ($l -match "---") {
                if ($cur.LicenseName) {
                    $type = if ($cur.LicenseName -match "Project") { "Project" } elseif ($cur.LicenseName -match "Visio") { "Visio" } else { "Office" }
                    $products[$type] = @{ Name=$cur.LicenseName; Status=$cur.LicenseStatus }
                    Write-Host "  $type`: $($cur.LicenseName) - $($cur.LicenseStatus)" -Fore $(if($cur.LicenseStatus-match "LICENSED"){"Green"}else{"Yellow"})
                }
                $cur = @{}
            }
        }
    } else { Write-Host "  Khong tim thay Office" -Fore DarkGray }
    Write-Host ""

    # Visual Studio
    Write-Step "INFO" "── Visual Studio ───────────────────────────────────────"
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        try {
            $vsData = (& $vswhere -all -format json 2>&1) | ConvertFrom-Json
            foreach ($vs in $vsData) {
                $products["VS_$($vs.displayName)"] = @{ Name=$vs.displayName; Version=$vs.installationVersion }
                Write-Host "  $($vs.displayName) v$($vs.installationVersion)" -Fore Cyan
            }
        } catch {}
    } else { Write-Host "  Khong tim thay Visual Studio" -Fore DarkGray }
    Write-Host ""

    # SQL Server
    Write-Step "INFO" "── SQL Server ──────────────────────────────────────────"
    $sqlSvc = Get-Service *sql* -EA SilentlyContinue
    if ($sqlSvc) {
        foreach ($s in $sqlSvc) {
            $products["SQL_$($s.Name)"] = @{ Name=$s.DisplayName; Status=$s.Status }
            Write-Host "  $($s.DisplayName) [$($s.Status)]" -Fore Cyan
        }
    } else { Write-Host "  Khong tim thay SQL Server" -Fore DarkGray }
    Write-Host ""

    # Exchange
    Write-Step "INFO" "── Exchange Server ─────────────────────────────────────"
    $exchSvc = Get-Service *exchange* -EA SilentlyContinue
    if ($exchSvc) {
        foreach ($s in $exchSvc) { Write-Host "  $($s.DisplayName) [$($s.Status)]" -Fore Cyan }
        $products.Exchange = @{ Found=$true }
    } else { Write-Host "  Khong tim thay Exchange" -Fore DarkGray }
    Write-Host ""

    # RDS CAL
    Write-Step "INFO" "── Remote Desktop (RDS CAL) ────────────────────────────"
    $rdSvc = Get-Service TermServLicensing -EA SilentlyContinue
    if ($rdSvc) {
        Write-Host "  RD Licensing: $($rdSvc.Status)" -Fore Cyan
        $products.RDS = @{ Status=$rdSvc.Status }
    } else { Write-Host "  Khong tim thay RD Licensing" -Fore DarkGray }
    Write-Host ""

    # Microsoft 365
    Write-Step "INFO" "── Microsoft 365 ───────────────────────────────────────"
    $c2r = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -EA SilentlyContinue
    if ($c2r) {
        Write-Host "  Products: $($c2r.ProductReleaseIds)" -Fore Cyan
        Write-Host "  Channel:  $($c2r.UpdateChannel)" -Fore Cyan
        $products.M365 = @{ Products=$c2r.ProductReleaseIds; Channel=$c2r.UpdateChannel }
    } else { Write-Host "  Khong tim thay Microsoft 365" -Fore DarkGray }
    Write-Host ""

    # Dynamics / Power BI
    Write-Step "INFO" "── Dynamics / Power BI ─────────────────────────────────"
    $dynPath = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Dynamics" -EA SilentlyContinue
    if ($dynPath) { Write-Host "  Dynamics: Found" -Fore Cyan; $products.Dynamics = @{ Found=$true } } else { Write-Host "  Khong tim thay Dynamics" -Fore DarkGray }
    $pbi = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft Power BI Desktop" -EA SilentlyContinue
    if ($pbi) { Write-Host "  Power BI: Found" -Fore Cyan; $products.PowerBI = @{ Found=$true } } else {
        $pbiApp = Get-AppxPackage *Microsoft.PowerBI* -EA SilentlyContinue
        if ($pbiApp) { Write-Host "  Power BI: $($pbiApp.Version)" -Fore Cyan; $products.PowerBI = @{ Version=$pbiApp.Version } }
        else { Write-Host "  Khong tim thay Power BI" -Fore DarkGray }
    }
    Write-Host ""

    $Script:AuditReport.ProductCenter = $products
    Write-Host "  Tong san pham phat hien: $($products.Count)" -Fore Green
    Write-Host ""
}

# ============================================================
#  PHASE: KIEM TRA BAO MAT
# ============================================================
function Invoke-SecurityScan {
    Write-Header "KIEM TRA BAO MAT"
    $secResults = @()

    function Check-Sec {
        param([string]$Name, [bool]$Passed, [string]$Detail)
        $icon = if ($Passed) { "[OK]" } else { "[!!]" }
        $color = if ($Passed) { "Green" } else { "Red" }
        Write-Host "  $icon $Name - $Detail" -Fore $color
        $secResults += @{ Item=$Name; Status=$(if($Passed){"PASS"}else{"FAIL"}); Detail=$Detail }
    }

    # Defender
    try {
        $def = Get-MpComputerStatus -EA SilentlyContinue
        Check-Sec "Windows Defender" $def.AntivirusEnabled "Enabled=$($def.AntivirusEnabled)"
        Check-Sec "Real-time Protection" $def.RealTimeProtectionEnabled "Enabled=$($def.RealTimeProtectionEnabled)"
        Check-Sec "Tamper Protection" $def.TamperProtection "Status=$($def.TamperProtection)"
    } catch { Check-Sec "Windows Defender" $false "Not available" }

    # Firewall
    try {
        $fw = Get-NetFirewallProfile -EA SilentlyContinue
        $fwAll = ($fw | Where-Object { $_.Enabled }).Count -eq $fw.Count
        Check-Sec "Firewall" $fwAll "$(($fw|?{$_.Enabled}).Count)/$($fw.Count) enabled"
    } catch { Check-Sec "Firewall" $false "Not available" }

    # Windows Update
    $wu = Get-Service wuauserv -EA SilentlyContinue
    Check-Sec "Windows Update" ($wu.Status -eq "Running") "Status=$($wu.Status)"

    # SmartScreen
    $ssReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name SmartScreenEnabled -EA SilentlyContinue
    Check-Sec "SmartScreen" ($ssReg.SmartScreenEnabled -ne "Off") "Value=$($ssReg.SmartScreenEnabled)"

    # UAC
    $uac = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -EA SilentlyContinue
    Check-Sec "UAC" ($uac.EnableLUA -eq 1) "EnableLUA=$($uac.EnableLUA)"

    # Credential Guard
    try {
        $dg = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -EA SilentlyContinue
        $cgEnabled = $dg.SecurityServicesRunning -contains 1
        Check-Sec "Credential Guard" $cgEnabled "Running=$($dg.SecurityServicesRunning)"
    } catch { Check-Sec "Credential Guard" $false "Not available" }

    # BitLocker
    try {
        $bl = Get-BitLockerVolume -MountPoint $env:SystemDrive -EA SilentlyContinue
        Check-Sec "BitLocker" ($bl.ProtectionStatus -eq "On") "Protection=$($bl.ProtectionStatus)"
    } catch { Check-Sec "BitLocker" $false "Not available" }

    # Secure Boot
    try { $sb = Confirm-SecureBootUEFI -EA SilentlyContinue } catch { $sb = $false }
    Check-Sec "Secure Boot" ($sb -eq $true) $(if($sb){"Enabled"}else{"Disabled"})

    # TPM
    try {
        $tpm = Get-Tpm -EA SilentlyContinue
        Check-Sec "TPM" ($tpm.TpmPresent -and $tpm.TpmReady) "Present=$($tpm.TpmPresent) Ready=$($tpm.TpmReady)"
    } catch { Check-Sec "TPM" $false "Not available" }

    # Summary
    Write-Host ""
    $passCount = ($secResults | Where-Object { $_.Status -eq "PASS" }).Count
    $failCount = ($secResults | Where-Object { $_.Status -eq "FAIL" }).Count
    if ($failCount -eq 0) {
        Write-Host "  -> BAO MAT TOT ($passCount/$($secResults.Count) PASS)" -Fore Green
    } else {
        Write-Host "  -> $failCount van de bao mat can khac phuc" -Fore Red
    }
    $Script:AuditReport.SecurityScan = $secResults
    Write-Host ""
}

# ============================================================
#  PHASE: KIEM TRA SUC KHOE (EXTENDED)
# ============================================================
function Invoke-HealthCheckExtended {
    Write-Header "KIEM TRA SUC KHOE HE THONG"

    # DISM
    Write-Step "INFO" "── DISM ────────────────────────────────────────────────"
    $dismResult = & DISM /Online /Cleanup-Image /CheckHealth 2>&1
    $dismOK = $dismResult -match "No component store corruption"
    Write-Host "  DISM: " -NoNewline
    if ($dismOK) { Write-Host "OK" -Fore Green } else { Write-Host "Co the co loi" -Fore Yellow }

    # SFC
    Write-Step "INFO" "── SFC ─────────────────────────────────────────────────"
    Write-Host "  SFC: Chay 'sfc /scannow' de kiem tra chi tiet" -Fore DarkGray

    # CHKDSK
    Write-Step "INFO" "── Disk ────────────────────────────────────────────────"
    $sysDrive = $env:SystemDrive
    $diskHealth = Get-PhysicalDisk -EA SilentlyContinue | Select-Object -First 1
    if ($diskHealth) {
        Write-Host "  Disk Health: $($diskHealth.HealthStatus)" -Fore $(if($diskHealth.HealthStatus-eq "Healthy"){"Green"}else{"Yellow"})
        Write-Host "  Media Type:  $($diskHealth.MediaType)" -Fore White
    }

    # Memory
    Write-Step "INFO" "── Memory ──────────────────────────────────────────────"
    $ram = Get-CimInstance Win32_PhysicalMemory -EA SilentlyContinue
    $totalRAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
    Write-Host "  Total RAM: $totalRAM GB ($($ram.Count) sticks)" -Fore White
    foreach ($m in $ram) {
        Write-Host "    $($m.DeviceLocator): $([math]::Round($m.Capacity/1GB,1)) GB $($m.Speed) MHz" -Fore DarkGray
    }

    # Storage SMART
    Write-Step "INFO" "── SMART ──────────────────────────────────────────────"
    try {
        $smart = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictStatus -EA SilentlyContinue
        if ($smart) {
            foreach ($s in $smart) {
                Write-Host "  Predict Failure: $($s.PredictFailure)" -Fore $(if($s.PredictFailure){"Red"}else{"Green"})
            }
        } else { Write-Host "  SMART: Khong the truy cap" -Fore DarkGray }
    } catch { Write-Host "  SMART: Not available" -Fore DarkGray }

    # Event Viewer (recent errors)
    Write-Step "INFO" "── Event Viewer (Recent Errors) ────────────────────────"
    try {
        $events = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-7)} -MaxEvents 5 -EA SilentlyContinue
        if ($events) {
            Write-Host "  $($events.Count) loi gan day:" -Fore Yellow
            foreach ($e in $events) {
                Write-Host "    [$($e.TimeCreated.ToString('MM-dd HH:mm'))] $($e.ProviderName): $($e.Message.Substring(0, [Math]::Min(80, $e.Message.Length)))" -Fore DarkGray
            }
        } else { Write-Host "  Khong co loi nao trong 7 ngay gan day" -Fore Green }
    } catch { Write-Host "  Khong the doc Event Log" -Fore DarkGray }

    # Drivers
    Write-Step "INFO" "── Drivers ─────────────────────────────────────────────"
    try {
        $badDrivers = Get-WindowsDriver -Online -EA SilentlyContinue | Where-Object { $_.Version -match "error" }
        if ($badDrivers) {
            Write-Host "  $($badDrivers.Count) driver co van de" -Fore Yellow
        } else {
            $driverCount = (Get-WindowsDriver -Online -EA SilentlyContinue | Measure-Object).Count
            Write-Host "  $driverCount drivers binh thuong" -Fore Green
        }
    } catch { Write-Host "  Khong the kiem tra drivers" -Fore DarkGray }

    # Pending Updates
    Write-Step "INFO" "── Pending Updates ─────────────────────────────────────"
    try {
        $wuSession = New-Object -ComObject Microsoft.Update.Session
        $searcher = $wuSession.CreateUpdateSearcher()
        $pending = $searcher.Search("IsInstalled=0")
        Write-Host "  Pending Updates: $($pending.Updates.Count)" -Fore $(if($pending.Updates.Count -gt 0){"Yellow"}else{"Green"})
    } catch { Write-Host "  Khong the kiem tra updates" -Fore DarkGray }

    Write-Host ""
    Write-Host "  Kiem tra suc khoe hoan tat!" -Fore Green
    Write-Host ""
}

# ============================================================
#  PHASE: DON DEP HE THONG (EXTENDED)
# ============================================================
function Invoke-SystemCleanup {
    Write-Header "DON DEP HE THONG"
    $totalFreed = 0

    function Remove-TempFolder {
        param([string]$Path, [string]$Name)
        if (Test-Path $Path) {
            $size = (Get-ChildItem $Path -Recurse -EA SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $sizeMB = [math]::Round($size / 1MB, 1)
            Remove-Item "$Path\*" -Recurse -Force -EA SilentlyContinue
            Write-Step "OK" "$Name`: $sizeMB MB da xoa" "OK"
            return $size
        } else {
            Write-Step "SKIP" "$Name`: Khong tim thay" "SKIP"
            return 0
        }
    }

    Write-Host "  Chon muc don dep:" -Fore Cyan
    Write-Host "    [1] Windows Temp" -Fore White
    Write-Host "    [2] Windows Logs" -Fore White
    Write-Host "    [3] Windows Update Cache" -Fore White
    Write-Host "    [4] Windows.old" -Fore White
    Write-Host "    [5] Office Cache" -Fore White
    Write-Host "    [6] Delivery Optimization" -Fore White
    Write-Host "    [7] Defender Cache" -Fore White
    Write-Host "    [8] Recycle Bin" -Fore White
    Write-Host "    [9] THUC HIEN TAT CA" -Fore Green
    Write-Host "    [0] Bo qua" -Fore Red
    Write-Host ""
    $ch = Read-Host "  Chon (so, nhieu so cach dau phay, hoac 'all')"

    if ($ch -eq "0" -or $ch -eq "") { return }

    $acts = if ($ch -eq "all" -or $ch -eq "9") { 1..8 } else { $ch -split "[,\s]+" | ForEach-Object { [int]$_ } }

    foreach ($act in $acts) {
        switch ($act) {
            1 { $totalFreed += Remove-TempFolder "$env:SystemRoot\Temp" "Windows Temp" }
            2 { $totalFreed += Remove-TempFolder "$env:SystemRoot\Logs" "Windows Logs" }
            3 {
                Write-Step "INFO" "Windows Update Cache..."
                Stop-Service wuauserv -Force -EA SilentlyContinue
                $totalFreed += Remove-TempFolder "$env:SystemRoot\SoftwareDistribution\Download" "WU Cache"
                Start-Service wuauserv -EA SilentlyContinue
            }
            4 {
                if (Test-Path "$env:SystemDrive\Windows.old") {
                    Write-Step "INFO" "Windows.old (can Disk Cleanup hoac xoa thu cong)"
                    cleanmgr /d $env:SystemDrive /sageset:1 2>&1 | Out-Null
                } else { Write-Step "SKIP" "Windows.old: Khong ton tai" "SKIP" }
            }
            5 {
                $totalFreed += Remove-TempFolder "$env:LOCALAPPDATA\Microsoft\Office\16.0\Groove" "Office Cache"
                $totalFreed += Remove-TempFolder "$env:LOCALAPPDATA\Microsoft\Office\OTele" "Office Telemetry"
            }
            6 {
                $totalFreed += Remove-TempFolder "$env:SystemRoot\SoftwareDistribution\DeliveryOptimization" "Delivery Opt"
            }
            7 {
                $totalFreed += Remove-TempFolder "$env:ProgramData\Microsoft\Windows Defender\Scans\History" "Defender Cache"
            }
            8 {
                Write-Step "INFO" "Emptying Recycle Bin..."
                Clear-RecycleBin -Force -EA SilentlyContinue
                Write-Step "OK" "Recycle Bin emptied" "OK"
            }
        }
    }

    $totalMB = [math]::Round($totalFreed / 1MB, 1)
    Write-Host ""
    Write-Host "  Da don dep: $totalMB MB" -Fore Green
    Write-Host ""
}

# ============================================================
#  PHASE: SAO LUU (BACKUP)
# ============================================================
function Invoke-SystemBackup {
    Write-Header "SAO LUU HE THONG"

    $backupDir = Join-Path $env:TEMP "MS_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory $backupDir -Force | Out-Null

    Write-Host "  Thu muc backup: $backupDir" -Fore Cyan
    Write-Host ""

    # Registry
    Write-Step "INFO" "Backup Registry..."
    reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" "$backupDir\winver.reg" /y 2>&1 | Out-Null
    reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" "$backupDir\spp.reg" /y 2>&1 | Out-Null
    reg export "HKLM\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform" "$backupDir\ospp.reg" /y 2>&1 | Out-Null
    reg export "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "$backupDir\startup_hklm.reg" /y 2>&1 | Out-Null
    reg export "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" "$backupDir\startup_hkcu.reg" /y 2>&1 | Out-Null
    Write-Step "OK" "Registry da backup" "OK"

    # License
    Write-Step "INFO" "Backup License..."
    & cscript //NoLogo $Script:Slmgr /dlv 2>&1 | Out-File "$backupDir\license_dlv.txt" -Encoding UTF8
    & cscript //NoLogo $Script:Slmgr /dli 2>&1 | Out-File "$backupDir\license_dli.txt" -Encoding UTF8
    Write-Step "OK" "License da backup" "OK"

    # Office License
    Write-Step "INFO" "Backup Office License..."
    $ospp = @("$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS","${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS") | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($ospp) {
        & cscript //NoLogo $ospp /dstatus 2>&1 | Out-File "$backupDir\office_license.txt" -Encoding UTF8
        Write-Step "OK" "Office License da backup" "OK"
    }

    # Hosts
    Write-Step "INFO" "Backup Hosts..."
    if (Test-Path $Script:HostsPath) {
        Copy-Item $Script:HostsPath "$backupDir\hosts.backup"
        Write-Step "OK" "Hosts da backup" "OK"
    }

    # BitLocker Recovery
    Write-Step "INFO" "Backup BitLocker Recovery Key..."
    try {
        $bl = Get-BitLockerVolume -MountPoint $env:SystemDrive -EA SilentlyContinue
        if ($bl.ProtectionStatus -eq "On") {
            $bl.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" } | ForEach-Object {
                (Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector | Out-File "$backupDir\bitlocker_recovery.txt"
            }
            Write-Step "OK" "BitLocker Recovery Key da backup" "OK"
        } else { Write-Step "SKIP" "BitLocker khong bat" "SKIP" }
    } catch { Write-Step "SKIP" "BitLocker khong kha dung" "SKIP" }

    # Installed Apps
    Write-Step "INFO" "Backup Installed Apps list..."
    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue |
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
        Export-Csv "$backupDir\installed_apps.csv" -NoTypeInformation -Encoding UTF8
    Write-Step "OK" "Installed Apps da backup" "OK"

    # System Info
    Write-Step "INFO" "Backup System Info..."
    systeminfo 2>&1 | Out-File "$backupDir\systeminfo.txt" -Encoding UTF8
    Write-Step "OK" "System Info da backup" "OK"

    Write-Host ""
    Write-Host "  BACKUP HOAN TAT!" -Fore Green
    Write-Host "  Thu muc: $backupDir" -Fore Cyan
    Write-Host ""
    $Script:AuditReport.BackupDir = $backupDir
}

# ============================================================
#  PHASE: KHOI PHUC (RESTORE)
# ============================================================
function Invoke-SystemRestore {
    Write-Header "KHOI PHUC HE THONG"

    $backupDirs = Get-ChildItem "$env:TEMP\MS_Backup_*" -Directory -EA SilentlyContinue | Sort-Object Name -Descending
    if ($backupDirs.Count -eq 0) {
        Write-Step "WARN" "Khong tim thay backup nao" "WARN"
        return
    }

    Write-Host "  Chon backup de khoi phuc:" -Fore Cyan
    $n = 0
    foreach ($bd in $backupDirs) {
        $n++
        Write-Host "    [$n] $($bd.Name)" -Fore White
    }
    Write-Host "    [0] Bo qua" -Fore Red
    Write-Host ""
    $ch = Read-Host "  Chon"
    if ($ch -eq "0" -or $ch -eq "") { return }

    $idx = [int]$ch - 1
    if ($idx -lt 0 -or $idx -ge $backupDirs.Count) { return }
    $selectedBackup = $backupDirs[$idx].FullName

    Write-Host "  Backup: $selectedBackup" -Fore Cyan
    Write-Host ""
    Write-Host "  Chon muc khoi phuc:" -Fore Cyan
    Write-Host "    [1] Registry" -Fore White
    Write-Host "    [2] Hosts" -Fore White
    Write-Host "    [3] License Info (chi xem)" -Fore White
    Write-Host "    [4] THUC HIEN TAT CA" -Fore Green
    Write-Host "    [0] Bo qua" -Fore Red
    Write-Host ""
    $ch2 = Read-Host "  Chon"
    if ($ch2 -eq "0" -or $ch2 -eq "") { return }

    $acts = if ($ch2 -eq "4") { 1..3 } else { $ch2 -split "[,\s]+" | ForEach-Object { [int]$_ } }

    foreach ($act in $acts) {
        switch ($act) {
            1 {
                Write-Step "INFO" "Restore Registry..."
                $regFiles = Get-ChildItem "$selectedBackup\*.reg" -EA SilentlyContinue
                foreach ($rf in $regFiles) {
                    reg import $rf.FullName 2>&1 | Out-Null
                    Write-Step "OK" "Import: $($rf.Name)" "OK"
                }
            }
            2 {
                Write-Step "INFO" "Restore Hosts..."
                if (Test-Path "$selectedBackup\hosts.backup") {
                    Copy-Item "$selectedBackup\hosts.backup" $Script:HostsPath -Force
                    Write-Step "OK" "Hosts da khoi phuc" "OK"
                } else { Write-Step "WARN" "Khong tim thay hosts backup" "WARN" }
            }
            3 {
                Write-Step "INFO" "License Info:"
                if (Test-Path "$selectedBackup\license_dlv.txt") {
                    Get-Content "$selectedBackup\license_dlv.txt" | ForEach-Object { Write-Host "  $_" -Fore DarkGray }
                }
            }
        }
    }
    Write-Host ""
    Write-Host "  KHOI PHUC HOAN TAT!" -Fore Green
    Write-Host ""
}

# ============================================================
#  CHON NGON NGU
# ============================================================
function Select-Language {
    Clear-Host
    $line = [string]::new([char]0x2550, 50)
    Write-Host ""
    Write-Host "  $line" -Fore Cyan
    Write-Host "   SELECT LANGUAGE / CHON NGON NGU" -Fore White
    Write-Host "  $line" -Fore Cyan
    Write-Host ""
    Write-Host "   [1] Tieng Viet" -Fore White
    Write-Host "   [2] English" -Fore White
    Write-Host "   [3] 日本語 (Japanese)" -Fore White
    Write-Host "   [4] 中文 (Chinese)" -Fore White
    Write-Host "   [5] Deutsch (German)" -Fore White
    Write-Host "   [6] Français (French)" -Fore White
    Write-Host ""
    $ch = Read-Host "  Chon / Select"
    switch ($ch) {
        "1" { Set-Language "vi" }
        "2" { Set-Language "en" }
        "3" { Set-Language "ja" }
        "4" { Set-Language "zh" }
        "5" { Set-Language "de" }
        "6" { Set-Language "fr" }
        default { Set-Language "vi" }
    }
    Write-Host "  Da chon: $Script:Lang" -Fore Green
}

# ============================================================
#  [21] MICROSOFT PRODUCT DISCOVERY
# ============================================================
function Invoke-ProductDiscovery {
    Write-Header "MICROSOFT PRODUCT DISCOVERY"
    $products = @()

    function Add-Product {
        param([string]$Name, [string]$Version, [string]$Status, [string]$Path)
        $products += @{ Name=$Name; Version=$Version; Status=$Status; Path=$Path }
        $sc = switch ($Status) { "Installed" { "Green" } "Running" { "Green" } default { "Yellow" } }
        Write-Host "  [+] $Name" -Fore $sc
        if ($Version) { Write-Host "      Version: $Version" -Fore DarkGray }
    }

    # Windows
    $nt = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -EA SilentlyContinue
    Add-Product "$($nt.ProductName)" "$($nt.CurrentBuild).$($nt.UBR) ($($nt.DisplayVersion))" "Installed" ""

    # Windows Server
    if ($nt.ProductName -match "Server") { Add-Product "Windows Server" "$($nt.DisplayVersion)" "Installed" "" }

    # Office (Click-to-Run)
    $c2r = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -EA SilentlyContinue
    if ($c2r) { Add-Product "Microsoft Office (C2R)" $c2r.ClientVersionToReport "Installed" $c2r.InstallationPath }

    # Microsoft 365
    if ($c2r -and $c2r.ProductReleaseIds -match "O365|M365") { Add-Product "Microsoft 365 Apps" $c2r.ClientVersionToReport "Installed" "" }

    # Office MSI
    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue | Where-Object {
        $_.DisplayName -match "Microsoft Office" -and $_.DisplayName -notmatch "Click-to-Run"
    } | ForEach-Object { Add-Product $_.DisplayName $_.DisplayVersion "Installed" $_.InstallLocation }

    # Visio / Project
    $osppPaths = @("$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS","${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS")
    $ospp = $osppPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($ospp) {
        $out = & cscript //NoLogo $ospp /dstatus 2>&1
        foreach ($l in $out) {
            if ($l -match "LICENSE NAME:\s*(.+?)\s*---") {
                $ln = $Matches[1].Trim()
                if ($ln -match "Visio") { Add-Product "Microsoft Visio" $ln "Licensed" "" }
                if ($ln -match "Project") { Add-Product "Microsoft Project" $ln "Licensed" "" }
            }
        }
    }

    # Visual Studio
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        try {
            $vsData = (& $vswhere -all -format json 2>&1) | ConvertFrom-Json
            foreach ($vs in $vsData) { Add-Product $vs.displayName $vs.installationVersion "Installed" $vs.installPath }
        } catch {}
    }

    # SQL Server
    Get-Service *sql* -EA SilentlyContinue | ForEach-Object {
        Add-Product $_.DisplayName "$($_.Status)" "Running" ""
    }
    # SQL Server Express / SSMS
    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue | Where-Object {
        $_.DisplayName -match "SQL Server|SSMS|Azure Data Studio"
    } | ForEach-Object { Add-Product $_.DisplayName $_.DisplayVersion "Installed" "" }

    # Power BI Desktop
    $pbi = Get-AppxPackage *Microsoft.PowerBI* -EA SilentlyContinue
    if ($pbi) { Add-Product "Power BI Desktop" $pbi.Version "Installed" "" }
    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue | Where-Object {
        $_.DisplayName -match "Power BI Desktop"
    } | ForEach-Object { Add-Product $_.DisplayName $_.DisplayVersion "Installed" "" }

    # Remote Desktop
    $rdp = Get-Service TermService -EA SilentlyContinue
    if ($rdp) { Add-Product "Remote Desktop Services" "$($rdp.Status)" "Running" "" }

    # RSAT
    Get-WindowsCapability -Online -Name "Rsat.*" -EA SilentlyContinue | Where-Object { $_.State -eq "Installed" } | ForEach-Object {
        Add-Product $_.Name "" "Installed" ""
    }

    # Windows Admin Center
    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue | Where-Object {
        $_.DisplayName -match "Windows Admin Center"
    } | ForEach-Object { Add-Product $_.DisplayName $_.DisplayVersion "Installed" "" }

    # Edge
    $edgePath = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    if (Test-Path $edgePath) { Add-Product "Microsoft Edge" (Get-Item $edgePath).VersionInfo.ProductVersion "Installed" $edgePath }

    # OneDrive
    $odPath = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
    if (Test-Path $odPath) { Add-Product "OneDrive" (Get-Item $odPath).VersionInfo.ProductVersion "Installed" $odPath }

    # Teams
    $teamsNew = Get-AppxPackage -AllUsers *MSTeams* -EA SilentlyContinue
    if ($teamsNew) { Add-Product "Microsoft Teams (New)" $teamsNew.Version "Installed" "" }
    $teamsClassic = "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe"
    if (Test-Path $teamsClassic) { Add-Product "Microsoft Teams (Classic)" (Get-Item $teamsClassic).VersionInfo.ProductVersion "Installed" $teamsClassic }

    # Skype for Business
    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue | Where-Object {
        $_.DisplayName -match "Skype for Business|Lync"
    } | ForEach-Object { Add-Product $_.DisplayName $_.DisplayVersion "Installed" "" }

    # PowerShell
    Add-Product "Windows PowerShell" $PSVersionTable.PSVersion.ToString() "Installed" ""
    $pwsh = Get-Command pwsh -EA SilentlyContinue
    if ($pwsh) { Add-Product "PowerShell 7" (& pwsh --version 2>&1) "Installed" $pwsh.Source }

    # Windows Terminal
    $wt = Get-AppxPackage *Microsoft.WindowsTerminal* -EA SilentlyContinue
    if ($wt) { Add-Product "Windows Terminal" $wt.Version "Installed" "" }

    # .NET Framework / .NET Runtime / SDK
    $dotnetFW = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -EA SilentlyContinue
    if ($dotnetFW) { Add-Product ".NET Framework" "$($dotnetFW.Version)" "Installed" "" }
    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue | Where-Object {
        $_.DisplayName -match "Microsoft .NET (Runtime|SDK|ASP\.NET)"
    } | ForEach-Object { Add-Product $_.DisplayName $_.DisplayVersion "Installed" "" }

    # VC++ Redistributable
    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue | Where-Object {
        $_.DisplayName -match "Visual C\+\+.*Redistributable"
    } | ForEach-Object { Add-Product $_.DisplayName $_.DisplayVersion "Installed" "" }

    # WebView2
    $wv2 = Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BEB-235B8DB0520F}" -EA SilentlyContinue
    if ($wv2) { Add-Product "Microsoft Edge WebView2 Runtime" $wv2.pv "Installed" "" }

    # Windows App SDK
    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue | Where-Object {
        $_.DisplayName -match "Windows App SDK|Windows App Runtime"
    } | ForEach-Object { Add-Product $_.DisplayName $_.DisplayVersion "Installed" "" }

    # OpenSSH
    $sshSvc = Get-Service sshd -EA SilentlyContinue
    if ($sshSvc) { Add-Product "OpenSSH Server" "$($sshSvc.Status)" "Running" "" }

    # Hyper-V
    $hv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -EA SilentlyContinue
    if ($hv -and $hv.State -eq "Enabled") { Add-Product "Hyper-V" "" "Enabled" "" }

    # WSL
    $wsl = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -EA SilentlyContinue
    if ($wsl -and $wsl.State -eq "Enabled") { Add-Product "WSL" "" "Enabled" "" }

    # IIS
    $iis = Get-Service W3SVC -EA SilentlyContinue
    if ($iis) { Add-Product "IIS (Web Server)" "$($iis.Status)" "Running" "" }

    # Defender
    try {
        $def = Get-MpComputerStatus -EA SilentlyContinue
        Add-Product "Windows Defender" "$($def.AntivirusSignatureVersion)" $(if($def.AntivirusEnabled){"Enabled"}else{"Disabled"}) ""
        if ($def.AMServiceEnabled) { Add-Product "Defender for Endpoint" "" "Enabled" "" }
    } catch {}

    # MSXML
    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue | Where-Object {
        $_.DisplayName -match "MSXML"
    } | ForEach-Object { Add-Product $_.DisplayName $_.DisplayVersion "Installed" "" }

    # DirectX
    $dxVer = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\DirectX" -EA SilentlyContinue).Version
    if ($dxVer) { Add-Product "DirectX" $dxVer "Installed" "" }

    Write-Host ""
    Write-Host "  Tong san pham phat hien: $($products.Count)" -Fore Green
    $Script:AuditReport.ProductDiscovery = $products
    Write-Host ""
}

# ============================================================
#  [22] MICROSOFT RUNTIME AUDIT
# ============================================================
function Invoke-RuntimeAudit {
    Write-Header "MICROSOFT RUNTIME AUDIT"
    $runtimes = @()

    function Check-Runtime {
        param([string]$Name, [string]$Version, [bool]$Found)
        $icon = if ($Found) { "[OK]" } else { "[--]" }
        $color = if ($Found) { "Green" } else { "DarkGray" }
        Write-Host "  $icon $Name" -Fore $color
        if ($Version) { Write-Host "      $Version" -Fore DarkGray }
        $runtimes += @{ Name=$Name; Version=$Version; Found=$Found }
    }

    # .NET Framework
    $fw4 = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -EA SilentlyContinue
    Check-Runtime ".NET Framework 4.x" "$($fw4.Version)" ($null -ne $fw4)
    $fw35 = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" -EA SilentlyContinue
    Check-Runtime ".NET Framework 3.5" "$($fw35.Version)" ($null -ne $fw35)

    # .NET Runtime
    $dotnetExe = Get-Command dotnet -EA SilentlyContinue
    if ($dotnetExe) {
        $dotnetVer = & dotnet --list-runtimes 2>&1
        foreach ($r in $dotnetVer) {
            if ($r -match "^([\w\.]+)\s+([\d\.]+)") { Check-Runtime "$($Matches[1])" $Matches[2] $true }
        }
    } else { Check-Runtime ".NET Runtime" "" $false }

    # .NET SDK
    if ($dotnetExe) {
        $sdkVer = & dotnet --list-sdks 2>&1
        foreach ($s in $sdkVer) {
            if ($s -match "^([\d\.]+)") { Check-Runtime ".NET SDK" $Matches[1] $true }
        }
    } else { Check-Runtime ".NET SDK" "" $false }

    # ASP.NET
    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue | Where-Object {
        $_.DisplayName -match "ASP\.NET"
    } | ForEach-Object { Check-Runtime "ASP.NET Runtime" $_.DisplayVersion $true }

    # Visual C++
    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue | Where-Object {
        $_.DisplayName -match "Visual C\+\+.*Redistributable"
    } | ForEach-Object { Check-Runtime $_.DisplayName $_.DisplayVersion $true }

    # MSXML
    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue | Where-Object {
        $_.DisplayName -match "MSXML"
    } | ForEach-Object { Check-Runtime $_.DisplayName $_.DisplayVersion $true }

    # DirectX
    $dxVer = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\DirectX" -EA SilentlyContinue).Version
    Check-Runtime "DirectX" $dxVer ($null -ne $dxVer)

    # Windows SDK
    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue | Where-Object {
        $_.DisplayName -match "Windows SDK"
    } | ForEach-Object { Check-Runtime $_.DisplayName $_.DisplayVersion $true }

    # Windows ADK
    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue | Where-Object {
        $_.DisplayName -match "Windows ADK|Assessment and Deployment"
    } | ForEach-Object { Check-Runtime $_.DisplayName $_.DisplayVersion $true }

    # Windows App SDK
    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue | Where-Object {
        $_.DisplayName -match "Windows App SDK|Windows App Runtime"
    } | ForEach-Object { Check-Runtime $_.DisplayName $_.DisplayVersion $true }

    # PowerShell
    Check-Runtime "Windows PowerShell" $PSVersionTable.PSVersion.ToString() $true
    $pwsh = Get-Command pwsh -EA SilentlyContinue
    if ($pwsh) { Check-Runtime "PowerShell 7" (& pwsh --version 2>&1) $true } else { Check-Runtime "PowerShell 7" "" $false }

    # WinGet
    $winget = Get-Command winget -EA SilentlyContinue
    if ($winget) { Check-Runtime "WinGet" (& winget --version 2>&1) $true } else { Check-Runtime "WinGet" "" $false }

    $Script:AuditReport.RuntimeAudit = $runtimes
    Write-Host ""
    Write-Host "  Tong runtimes: $($runtimes.Count)" -Fore Green
    Write-Host ""
}

# ============================================================
#  [23] MICROSOFT SERVICES AUDIT
# ============================================================
function Invoke-ServicesAudit {
    Write-Header "MICROSOFT SERVICES AUDIT"
    $svcList = @()
    $checkServices = @(
        @{ Name="sppsvc"; Display="Software Protection" },
        @{ Name="ClickToRunSvc"; Display="Office ClickToRun" },
        @{ Name="wuauserv"; Display="Windows Update" },
        @{ Name="BITS"; Display="BITS" },
        @{ Name="WinDefend"; Display="Windows Defender" },
        @{ Name="W32Time"; Display="Time Service" },
        @{ Name="CryptSvc"; Display="Cryptographic Service" },
        @{ Name="TrustedInstaller"; Display="TrustedInstaller" },
        @{ Name="msiserver"; Display="Windows Installer" },
        @{ Name="LicenseManager"; Display="License Manager" },
        @{ Name="DoSvc"; Display="Delivery Optimization" },
        @{ Name="ClipSVC"; Display="ClipSVC" },
        @{ Name="InstallService"; Display="Store Install Service" },
        @{ Name="OneSyncSvc"; Display="OneSync" },
        @{ Name="WpnService"; Display="Push Notifications" }
    )

    foreach ($cs in $checkServices) {
        $svc = Get-Service $cs.Name -EA SilentlyContinue
        if ($svc) {
            $sc = switch ($svc.Status) { "Running" { "Green" } "Stopped" { "Yellow" } default { "Yellow" } }
            Write-Host "  [OK] $($cs.Display)" -Fore $sc
            Write-Host "       Status: $($svc.Status) | StartType: $($svc.StartType)" -Fore DarkGray
            $svcList += @{ Name=$cs.Display; ServiceName=$svc.Name; Status=$svc.Status; StartType=$svc.StartType }
        } else {
            Write-Host "  [--] $($cs.Display)" -Fore DarkGray
            $svcList += @{ Name=$cs.Display; ServiceName=$cs.Name; Status="Not Found"; StartType="N/A" }
        }
    }

    $Script:AuditReport.ServicesAudit = $svcList
    Write-Host ""
    Write-Host "  Tong dich vu: $($svcList.Count) | Running: $(($svcList|?{$_.Status -eq 'Running'}).Count)" -Fore Green
    Write-Host ""
}

# ============================================================
#  [24] MICROSOFT STORE AUDIT
# ============================================================
function Invoke-StoreAudit {
    Write-Header "MICROSOFT STORE AUDIT"

    # Store App
    $store = Get-AppxPackage *Microsoft.WindowsStore* -EA SilentlyContinue
    if ($store) {
        Write-Host "  [OK] Microsoft Store: $($store.Version)" -Fore Green
    } else {
        Write-Host "  [--] Microsoft Store: Khong tim thay" -Fore Yellow
    }

    # Store Cache
    $storeCache = "$env:LOCALCache\Packages\Microsoft.WindowsStore_*"
    if (Test-Path $storeCache) { Write-Host "  [OK] Store Cache: Ton tai" -Fore Green } else { Write-Host "  [--] Store Cache: Khong co" -Fore DarkGray }

    # App Installer / WinGet
    $appInstaller = Get-AppxPackage *Microsoft.DesktopAppInstaller* -EA SilentlyContinue
    if ($appInstaller) { Write-Host "  [OK] Desktop App Installer: $($appInstaller.Version)" -Fore Green } else { Write-Host "  [--] Desktop App Installer" -Fore DarkGray }

    $winget = Get-Command winget -EA SilentlyContinue
    if ($winget) { Write-Host "  [OK] WinGet: $(& winget --version 2>&1)" -Fore Green } else { Write-Host "  [--] WinGet: Khong co" -Fore DarkGray }

    # Store License
    $storeLicense = Get-AppxPackage *WindowsStore* | Get-AppxPackageManifest -EA SilentlyContinue
    if ($storeLicense) { Write-Host "  [OK] Store License: Hop le" -Fore Green }

    # Store Account
    try {
        $accounts = Get-AppxPackage -PackageTypeFilter Bundle *Microsoft.AccountsControl* -EA SilentlyContinue
        if ($accounts) { Write-Host "  [OK] Store Account: Co" -Fore Green } else { Write-Host "  [--] Store Account: Khong ro" -Fore DarkGray }
    } catch {}

    Write-Host ""
}

# ============================================================
#  [25] MICROSOFT ACCOUNT AUDIT
# ============================================================
function Invoke-AccountAudit {
    Write-Header "MICROSOFT ACCOUNT AUDIT"

    $cs = Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue
    Write-Host "  Domain:           $($cs.Domain)" -Fore White
    Write-Host "  Part of Domain:   $($cs.PartOfDomain)" -Fore $(if($cs.PartOfDomain){"Green"}else{"Yellow"})

    # Current user
    $user = whoami 2>&1
    Write-Host "  Current User:     $user" -Fore White

    # Microsoft Account check
    $msAccount = Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\IdentityCRL\UserExtendedProperties" -EA SilentlyContinue
    if ($msAccount) {
        Write-Host "  Microsoft Account: Dang nhap" -Fore Green
    } else {
        Write-Host "  Microsoft Account: Chua dang nhap (Local)" -Fore Yellow
    }

    # Azure AD / Entra ID
    $aadReg = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo" -EA SilentlyContinue
    if ($aadReg) {
        Write-Host "  Azure AD / Entra ID: Joined" -Fore Green
    } else {
        Write-Host "  Azure AD / Entra ID: Khong" -Fore DarkGray
    }

    # Local accounts
    $localUsers = Get-LocalUser -EA SilentlyContinue
    Write-Host "  Local Accounts:   $($localUsers.Count)" -Fore White
    foreach ($u in $localUsers) {
        $sc = if ($u.Enabled) { "Green" } else { "DarkGray" }
        Write-Host "    $($u.Name) [$(if($u.Enabled){'Enabled'}else{'Disabled'})]" -Fore $sc
    }

    Write-Host ""
}

# ============================================================
#  [26] MICROSOFT UPDATE AUDIT
# ============================================================
function Invoke-UpdateAudit {
    Write-Header "MICROSOFT UPDATE AUDIT"

    # Windows Update service
    $wu = Get-Service wuauserv -EA SilentlyContinue
    Write-Host "  Windows Update:  $($wu.Status)" -Fore $(if($wu.Status -eq "Running"){"Green"}else{"Red"})

    # Last update install
    try {
        $hotfix = Get-HotFix -EA SilentlyContinue | Sort-Object InstalledOn -Descending | Select-Object -First 5
        Write-Host ""
        Write-Host "  ── 5 Updates gan nhat ──────────────────────────────────" -Fore Cyan
        foreach ($hf in $hotfix) {
            Write-Host "    $($hf.HotFixID) | $($hf.InstalledOn.ToString('yyyy-MM-dd')) | $($hf.Description)" -Fore White
        }
    } catch {}

    # Pending updates
    try {
        $wuSession = New-Object -ComObject Microsoft.Update.Session
        $searcher = $wuSession.CreateUpdateSearcher()
        $pending = $searcher.Search("IsInstalled=0")
        Write-Host ""
        Write-Host "  Pending Updates:     $($pending.Updates.Count)" -Fore $(if($pending.Updates.Count -gt 0){"Yellow"}else{"Green"})
        if ($pending.Updates.Count -gt 0) {
            foreach ($upd in $pending.Updates | Select-Object -First 10) {
                Write-Host "    $($upd.Title)" -Fore DarkGray
            }
        }
    } catch { Write-Host "  Pending Updates: Khong the truy cap" -Fore DarkGray }

    # Restart pending
    $restartPending = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA SilentlyContinue
    if ($restartPending) {
        Write-Host ""
        Write-Host "  [!!] YEU CAU KHOI DONG LAI" -Fore Red
    }

    # Failed updates
    try {
        $failedEvents = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WindowsUpdateClient'; Id=20; StartTime=(Get-Date).AddDays(-30)} -MaxEvents 5 -EA SilentlyContinue
        if ($failedEvents) {
            Write-Host ""
            Write-Host "  Failed Updates (30 ngay): $($failedEvents.Count)" -Fore Red
        }
    } catch {}

    Write-Host ""
}

# ============================================================
#  [27] MICROSOFT SECURITY AUDIT
# ============================================================
function Invoke-SecurityAuditFull {
    Write-Header "MICROSOFT SECURITY AUDIT"
    $secItems = @()

    function Check-SecurityItem {
        param([string]$Name, [bool]$Passed, [string]$Detail)
        $icon = if ($Passed) { "[OK]" } else { "[!!]" }
        $color = if ($Passed) { "Green" } else { "Red" }
        Write-Host "  $icon $Name - $Detail" -Fore $color
        $secItems += @{ Item=$Name; Status=$(if($Passed){"PASS"}else{"FAIL"}); Detail=$Detail }
    }

    # Defender
    try { $def = Get-MpComputerStatus -EA SilentlyContinue; Check-SecurityItem "Windows Defender" $def.AntivirusEnabled "AV=$($def.AntivirusEnabled)" } catch { Check-SecurityItem "Windows Defender" $false "N/A" }
    try { $def2 = Get-MpComputerStatus -EA SilentlyContinue; Check-SecurityItem "Real-time Protection" $def2.RealTimeProtectionEnabled "RTP=$($def2.RealTimeProtectionEnabled)" } catch {}
    try { $mp = Get-MpPreference -EA SilentlyContinue; Check-SecurityItem "Tamper Protection" (Get-MpComputerStatus).TamperProtection "Status=$((Get-MpComputerStatus).TamperProtection)" } catch {}

    # SmartScreen
    $ss = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name SmartScreenEnabled -EA SilentlyContinue
    Check-SecurityItem "SmartScreen" ($ss.SmartScreenEnabled -ne "Off") "$($ss.SmartScreenEnabled)"

    # Firewall
    try { $fw = Get-NetFirewallProfile -EA SilentlyContinue; Check-SecurityItem "Firewall" (($fw|?{$_.Enabled}).Count -eq $fw.Count) "$(($fw|?{$_.Enabled}).Count)/$($fw.Count)" } catch { Check-SecurityItem "Firewall" $false "N/A" }

    # BitLocker
    try { $bl = Get-BitLockerVolume -MountPoint $env:SystemDrive -EA SilentlyContinue; Check-SecurityItem "BitLocker" ($bl.ProtectionStatus -eq "On") "$($bl.ProtectionStatus)" } catch { Check-SecurityItem "BitLocker" $false "N/A" }

    # Credential Guard
    try { $dg = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -EA SilentlyContinue; Check-SecurityItem "Credential Guard" ($dg.SecurityServicesRunning -contains 1) "Running=$($dg.SecurityServicesRunning)" } catch { Check-SecurityItem "Credential Guard" $false "N/A" }

    # Device Guard
    try { $dg2 = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -EA SilentlyContinue; Check-SecurityItem "Device Guard" ($dg2.VirtualizationBasedSecurityStatus -eq 2) "VBS=$($dg2.VirtualizationBasedSecurityStatus)" } catch { Check-SecurityItem "Device Guard" $false "N/A" }

    # VBS
    try { $vbs = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -EA SilentlyContinue; Check-SecurityItem "Virtualization Based Security" ($vbs.VirtualizationBasedSecurityStatus -eq 2) "Status=$($vbs.VirtualizationBasedSecurityStatus)" } catch { Check-SecurityItem "VBS" $false "N/A" }

    # Core Isolation / Memory Integrity
    $ciReg = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -EA SilentlyContinue
    $ciEnabled = $ciReg.Enabled -eq 1
    Check-SecurityItem "Core Isolation / Memory Integrity" $ciEnabled "Enabled=$($ciReg.Enabled)"

    # Secure Boot
    try { $sb = Confirm-SecureBootUEFI -EA SilentlyContinue; Check-SecurityItem "Secure Boot" ($sb -eq $true) $(if($sb){"Enabled"}else{"Disabled"}) } catch { Check-SecurityItem "Secure Boot" $false "N/A" }

    # TPM
    try { $tpm = Get-Tpm -EA SilentlyContinue; Check-SecurityItem "TPM" ($tpm.TpmPresent -and $tpm.TpmReady) "Present=$($tpm.TpmPresent) Ready=$($tpm.TpmReady)" } catch { Check-SecurityItem "TPM" $false "N/A" }

    # Exploit Protection
    $epReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options" -EA SilentlyContinue
    Check-SecurityItem "Exploit Protection" ($null -ne $epReg) "Configured"

    # Controlled Folder Access
    try { $cfa = (Get-MpPreference).EnableControlledFolderAccess; Check-SecurityItem "Controlled Folder Access" ($cfa -eq 1) "Status=$cfa" } catch { Check-SecurityItem "Controlled Folder Access" $false "N/A" }

    # Windows Hello
    $whReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\UserTileOptions" -EA SilentlyContinue
    Check-SecurityItem "Windows Hello" ($null -ne $whReg) "Available"

    # Summary
    Write-Host ""
    $passCount = ($secItems | Where-Object { $_.Status -eq "PASS" }).Count
    $failCount = ($secItems | Where-Object { $_.Status -eq "FAIL" }).Count
    Write-Host "  PASS: $passCount | FAIL: $failCount | Total: $($secItems.Count)" -Fore $(if($failCount -eq 0){"Green"}else{"Red"})
    $Script:AuditReport.SecurityAuditFull = $secItems
    Write-Host ""
}

# ============================================================
#  [28] MICROSOFT OPTIONAL FEATURES
# ============================================================
function Invoke-OptionalFeatures {
    Write-Header "MICROSOFT OPTIONAL FEATURES"
    $features = @(
        "Microsoft-Hyper-V-All", "Containers-DisposableClientVM",
        "Microsoft-Windows-Subsystem-Linux", "VirtualMachinePlatform",
        "IIS-WebServer", "SMB1Protocol", "TelnetClient", "TFTP",
        "OpenSSH.Server~~~~0.0.1.0", "XPS.Viewer~~~~6.3.0.0",
        "WindowsMediaPlayer", "NetFX3", "Microsoft-Windows-NetFx3-OC-Package",
        "Microsoft.PowerShell.ISE~~~~0.0.1.0"
    )

    $enabledCount = 0
    foreach ($f in $features) {
        $feat = Get-WindowsOptionalFeature -Online -FeatureName $f -EA SilentlyContinue
        if ($feat) {
            $sc = if ($feat.State -eq "Enabled") { "Green" } else { "DarkGray" }
            $icon = if ($feat.State -eq "Enabled") { "[ON]" } else { "[--]" }
            Write-Host "  $icon $($feat.FeatureName): $($feat.State)" -Fore $sc
            if ($feat.State -eq "Enabled") { $enabledCount++ }
        }
    }

    # Additional capabilities
    Write-Host ""
    Write-Host "  ── Installed Capabilities ────────────────────────────" -Fore Cyan
    $caps = Get-WindowsCapability -Online -EA SilentlyContinue | Where-Object { $_.State -eq "Installed" }
    foreach ($c in $caps | Select-Object -First 20) {
        Write-Host "    [OK] $($c.Name)" -Fore Green
    }
    if ($caps.Count -gt 20) { Write-Host "    ... va $($caps.Count - 20) capabilities khac" -Fore DarkGray }

    Write-Host ""
    Write-Host "  Features Enabled: $enabledCount | Capabilities: $($caps.Count)" -Fore Green
    Write-Host ""
}

# ============================================================
#  [29] MICROSOFT DRIVERS AUDIT
# ============================================================
function Invoke-DriversAudit {
    Write-Header "MICROSOFT DRIVERS AUDIT"

    Write-Host "  ── Microsoft Drivers ───────────────────────────────────" -Fore Cyan
    $msDrivers = Get-WindowsDriver -Online -EA SilentlyContinue | Where-Object { $_.ProviderName -match "Microsoft" } | Select-Object -First 20
    foreach ($d in $msDrivers) {
        Write-Host "    $($d.Driver) | $($d.Version) | $($d.Date.ToString('yyyy-MM-dd'))" -Fore White
    }

    # Check for problematic drivers
    Write-Host ""
    Write-Host "  ── Problematic Drivers ─────────────────────────────────" -Fore Cyan
    try {
        $problemDevices = Get-PnpDevice | Where-Object { $_.Status -ne "OK" }
        if ($problemDevices) {
            foreach ($pd in $problemDevices | Select-Object -First 10) {
                Write-Host "    [!!] $($pd.FriendlyName): $($pd.Status)" -Fore Red
            }
        } else {
            Write-Host "    [OK] Khong co driver van de" -Fore Green
        }
    } catch { Write-Host "    Khong the kiem tra" -Fore DarkGray }

    # Key Microsoft drivers
    Write-Host ""
    Write-Host "  ── Key Drivers ────────────────────────────────────────" -Fore Cyan
    $keyDrivers = @("BasicDisplay", "Microsoft Print To PDF", "Hyper-V", "Virtual Disk", "Storage Spaces")
    foreach ($kd in $keyDrivers) {
        $drv = Get-WindowsDriver -Online -EA SilentlyContinue | Where-Object { $_.Driver -match $kd } | Select-Object -First 1
        if ($drv) { Write-Host "    [OK] $kd`: $($drv.Version)" -Fore Green } else { Write-Host "    [--] $kd" -Fore DarkGray }
    }
    Write-Host ""
}

# ============================================================
#  [30] MICROSOFT LICENSING COMPONENTS AUDIT
# ============================================================
function Invoke-LicensingComponents {
    Write-Header "MICROSOFT LICENSING COMPONENTS"

    # SPP
    $sppSvc = Get-Service sppsvc -EA SilentlyContinue
    Write-Host "  Software Protection Platform:  $($sppSvc.Status)" -Fore $(if($sppSvc.Status -eq "Running"){"Green"}else{"Yellow"})

    # Office SPP
    $osppSvc = Get-Service osppsvc -EA SilentlyContinue
    if ($osppSvc) { Write-Host "  Office Software Protection:    $($osppSvc.Status)" -Fore White }

    # ClipSVC
    $clipSvc = Get-Service ClipSVC -EA SilentlyContinue
    if ($clipSvc) { Write-Host "  ClipSVC:                       $($clipSvc.Status)" -Fore White }

    # Token Store
    $tokenPath = "$env:SystemRoot\ServiceProfiles\LocalService\AppData\Local\Microsoft\WSLicense"
    if (Test-Path $tokenPath) { Write-Host "  Token Store:                   Ton tai" -Fore Green } else { Write-Host "  Token Store:                   Khong co" -Fore DarkGray }

    # License info
    Write-Host ""
    Write-Host "  ── License Details ────────────────────────────────────" -Fore Cyan
    $dli = & cscript //NoLogo $Script:Slmgr /dli 2>&1
    foreach ($l in $dli) { if ($l.Trim()) { Write-Host "    $l" -Fore White } }

    # KMS Configuration
    Write-Host ""
    Write-Host "  ── KMS Configuration ──────────────────────────────────" -Fore Cyan
    $dlv = & cscript //NoLogo $Script:Slmgr /dlv 2>&1
    $hasKMS = $false
    foreach ($l in $dlv) {
        if ($l -match "KMS Machine Name") { Write-Host "    $l" -Fore Yellow; $hasKMS = $true }
        if ($l -match "Product Key Channel") { Write-Host "    $l" -Fore White }
        if ($l -match "License Status") { Write-Host "    $l" -Fore $(if($l-match "Licensed"){"Green"}else{"Red"}) }
    }
    if (-not $hasKMS) { Write-Host "    Khong co KMS configuration" -Fore Green }

    Write-Host ""
}

# ============================================================
#  [31] MICROSOFT CERTIFICATES AUDIT
# ============================================================
function Invoke-CertificatesAudit {
    Write-Header "MICROSOFT CERTIFICATES AUDIT"

    $certStores = @(
        @{ Store="Root"; Name="Trusted Root CA" },
        @{ Store="TrustedPublisher"; Name="Trusted Publisher" },
        @{ Store="My"; Name="Personal" }
    )

    foreach ($cs in $certStores) {
        Write-Host "  ── $($cs.Name) ──────────────────────────────────────" -Fore Cyan
        try {
            $certs = Get-ChildItem "Cert:\LocalMachine\$($cs.Store)" -EA SilentlyContinue
            $msCerts = $certs | Where-Object { $_.Issuer -match "Microsoft|Windows" }
            Write-Host "  Total: $($certs.Count) | Microsoft: $($msCerts.Count)" -Fore White
            foreach ($c in $msCerts | Select-Object -First 5) {
                $expired = if ($c.NotAfter -lt (Get-Date)) { " [EXPIRED]" } else { "" }
                Write-Host "    $($c.Subject.Substring(0, [Math]::Min(60, $c.Subject.Length)))" -Fore $(if($expired){"Red"}else{"Green"})
                Write-Host "      Expires: $($c.NotAfter.ToString('yyyy-MM-dd'))$expired" -Fore DarkGray
            }
        } catch { Write-Host "  Khong the truy cap" -Fore DarkGray }
        Write-Host ""
    }
}

# ============================================================
#  [32] MICROSOFT SCHEDULED TASKS AUDIT
# ============================================================
function Invoke-TasksAudit {
    Write-Header "MICROSOFT SCHEDULED TASKS AUDIT"

    $categories = @(
        @{ Pattern="Windows.*Update"; Name="Windows Update" },
        @{ Pattern="Defender|MpIdleScan|MpScheduled"; Name="Defender" },
        @{ Pattern="Office|ClickToRun|OfficeSvc"; Name="Office" },
        @{ Pattern="OneDrive"; Name="OneDrive" },
        @{ Pattern="WindowsStore|Store"; Name="Store" },
        @{ Pattern="MicrosoftEdge"; Name="Edge" },
        @{ Pattern="Feedback|Telemetry|CEIP|UsbCeip"; Name="Telemetry" },
        @{ Pattern="Windows.*Backup"; Name="Backup" },
        @{ Pattern="Disk.*Cleanup|CleanupManager"; Name="Disk Cleanup" }
    )

    $allTasks = Get-ScheduledTask -EA SilentlyContinue
    $totalMS = 0

    foreach ($cat in $categories) {
        $matched = $allTasks | Where-Object { $_.TaskName -match $cat.Pattern -or $_.TaskPath -match $cat.Pattern }
        if ($matched) {
            Write-Host "  ── $($cat.Name) ($($matched.Count)) ──────────────────────" -Fore Cyan
            foreach ($t in $matched | Select-Object -First 5) {
                $sc = switch ($t.State) { "Running" { "Green" } "Ready" { "White" } "Disabled" { "DarkGray" } default { "Yellow" } }
                Write-Host "    $($t.TaskName): $($t.State)" -Fore $sc
            }
            $totalMS += $matched.Count
        }
    }

    Write-Host ""
    Write-Host "  Tong Microsoft tasks: $totalMS / $($allTasks.Count) total" -Fore Green
    Write-Host ""
}

# ============================================================
#  [33] MICROSOFT REGISTRY AUDIT
# ============================================================
function Invoke-RegistryAudit {
    Write-Header "MICROSOFT REGISTRY AUDIT"

    $regPaths = @(
        @{ Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"; Name="Windows Licensing" },
        @{ Path="HKLM:\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform"; Name="Office Licensing" },
        @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"; Name="Windows Update Policy" },
        @{ Path="HKLM:\SOFTWARE\Microsoft\Windows Defender"; Name="Defender" },
        @{ Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore"; Name="Store" },
        @{ Path="HKLM:\SOFTWARE\Microsoft\OneDrive"; Name="OneDrive" },
        @{ Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="Edge Policy" },
        @{ Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies"; Name="Windows Policies" }
    )

    foreach ($rp in $regPaths) {
        if (Test-Path $rp.Path) {
            $props = Get-ItemProperty $rp.Path -EA SilentlyContinue
            $propCount = ($props.PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" }).Count
            Write-Host "  [OK] $($rp.Name): $propCount properties" -Fore Green
        } else {
            Write-Host "  [--] $($rp.Name): Khong ton tai" -Fore DarkGray
        }
    }
    Write-Host ""
}

# ============================================================
#  [34] MICROSOFT ENVIRONMENT AUDIT
# ============================================================
function Invoke-EnvironmentAudit {
    Write-Header "MICROSOFT ENVIRONMENT AUDIT"

    $nt = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -EA SilentlyContinue
    $cs = Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue
    $tz = Get-TimeZone

    Write-Host "  Edition:       $($nt.ProductName)" -Fore White
    Write-Host "  Build:         $($nt.CurrentBuild).$($nt.UBR)" -Fore White
    Write-Host "  Release:       $($nt.DisplayVersion)" -Fore White
    Write-Host "  Architecture:  $($cs.OSArchitecture)" -Fore White
    Write-Host "  Language:      $((Get-Culture).DisplayName)" -Fore White
    Write-Host "  Time Zone:     $($tz.DisplayName)" -Fore White
    Write-Host "  Locale:        $((Get-WinSystemLocale).Name)" -Fore White

    # Activation Channel
    $dli = & cscript //NoLogo $Script:Slmgr /dli 2>&1
    foreach ($l in $dli) {
        if ($l -match "Product Key Channel:\s*(.+)") { Write-Host "  Channel:       $($Matches[1].Trim())" -Fore Cyan }
    }

    Write-Host ""
}

# ============================================================
#  [35] MICROSOFT REPAIR CENTER
# ============================================================
function Invoke-RepairCenter {
    Write-Header "MICROSOFT REPAIR CENTER"
    Write-Host "  Chon doi tuong sua chua:" -Fore Cyan
    Write-Host "    [1] Windows Update" -Fore White
    Write-Host "    [2] Microsoft Store" -Fore White
    Write-Host "    [3] Office" -Fore White
    Write-Host "    [4] OneDrive" -Fore White
    Write-Host "    [5] Edge" -Fore White
    Write-Host "    [6] Defender" -Fore White
    Write-Host "    [7] Windows Installer" -Fore White
    Write-Host "    [8] Licensing Service" -Fore White
    Write-Host "    [9] THUC HIEN TAT CA" -Fore Green
    Write-Host "    [0] Bo qua" -Fore Red
    Write-Host ""
    $ch = Read-Host "  Chon"
    if ($ch -eq "0") { return }

    $acts = if ($ch -eq "9") { 1..8 } else { $ch -split "[,\s]+" | ForEach-Object { [int]$_ } }

    foreach ($act in $acts) {
        switch ($act) {
            1 {
                Write-Step "INFO" "Repair Windows Update..."
                Stop-Service wuauserv,bits,cryptsvc,msiserver -Force -EA SilentlyContinue
                Remove-Item "$env:SystemRoot\SoftwareDistribution" -Recurse -Force -EA SilentlyContinue
                Start-Service wuauserv,bits,cryptsvc,msiserver -EA SilentlyContinue
                & DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-Null
                Write-Step "OK" "Windows Update repaired" "OK"
            }
            2 {
                Write-Step "INFO" "Repair Microsoft Store..."
                Get-AppxPackage *WindowsStore* | Reset-AppxPackage -EA SilentlyContinue
                & wsreset.exe 2>&1 | Out-Null
                Write-Step "OK" "Store repaired" "OK"
            }
            3 {
                Write-Step "INFO" "Repair Office..."
                $c2rPath = "$env:ProgramFiles\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
                if (Test-Path $c2rPath) { Start-Process $c2rPath -Arg "/repair user" -Wait -EA SilentlyContinue }
                Write-Step "OK" "Office repair initiated" "OK"
            }
            4 {
                Write-Step "INFO" "Repair OneDrive..."
                $odPath = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
                if (Test-Path $odPath) { & $odPath /reset 2>&1 | Out-Null }
                Write-Step "OK" "OneDrive reset" "OK"
            }
            5 {
                Write-Step "INFO" "Repair Edge..."
                $edgePath = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
                if (Test-Path $edgePath) { & $edgePath --restore-last-session 2>&1 | Out-Null }
                Write-Step "OK" "Edge initiated" "OK"
            }
            6 {
                Write-Step "INFO" "Repair Defender..."
                & "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -RemoveDefinitions -All 2>&1 | Out-Null
                Update-MpSignature -EA SilentlyContinue
                Write-Step "OK" "Defender repaired" "OK"
            }
            7 {
                Write-Step "INFO" "Repair Windows Installer..."
                Stop-Service msiserver -Force -EA SilentlyContinue
                Start-Service msiserver -EA SilentlyContinue
                Write-Step "OK" "Windows Installer restarted" "OK"
            }
            8 {
                Write-Step "INFO" "Repair Licensing Service..."
                Stop-Service sppsvc -Force -EA SilentlyContinue
                Start-Sleep 2
                Start-Service sppsvc -EA SilentlyContinue
                Run-Slmgr "/rearm" "Reset licensing"
                Write-Step "OK" "Licensing service repaired" "OK"
            }
        }
    }
    Write-Host ""
    Write-Host "  SUA CHUA HOAN TAT!" -Fore Green
    Write-Host ""
}

# ============================================================
#  [36] MICROSOFT DOWNLOAD CENTER
# ============================================================
function Invoke-DownloadCenter {
    Write-Header "MICROSOFT DOWNLOAD CENTER"
    $downloads = @(
        @{ Name="Media Creation Tool (Win11)"; URL="https://www.microsoft.com/software-download/windows11" },
        @{ Name="Media Creation Tool (Win10)"; URL="https://www.microsoft.com/software-download/windows10" },
        @{ Name="Windows ISO"; URL="https://www.microsoft.com/en-us/software-download/windows11ISO" },
        @{ Name="Office Deployment Tool"; URL="https://www.microsoft.com/en-us/download/details.aspx?id=49117" },
        @{ Name="Visual Studio Installer"; URL="https://visualstudio.microsoft.com/downloads/" },
        @{ Name=".NET SDK"; URL="https://dotnet.microsoft.com/download" },
        @{ Name="PowerShell 7"; URL="https://github.com/PowerShell/PowerShell/releases" },
        @{ Name="WinGet"; URL="https://github.com/microsoft/winget-cli/releases" },
        @{ Name="Windows Terminal"; URL="https://aka.ms/terminal" }
    )

    $n = 0
    foreach ($dl in $downloads) {
        $n++
        Write-Host "    [$n] $($dl.Name)" -Fore White
        Write-Host "        $($dl.URL)" -Fore DarkGray
    }
    Write-Host "    [0] Bo qua" -Fore Red
    Write-Host ""
    $ch = Read-Host "  Chon de mo trang (so)"
    if ($ch -ne "0" -and $ch -ne "") {
        $idx = [int]$ch - 1
        if ($idx -ge 0 -and $idx -lt $downloads.Count) {
            Start-Process $downloads[$idx].URL
            Write-Step "OK" "Da mo: $($downloads[$idx].Name)" "OK"
        }
    }
    Write-Host ""
}

# ============================================================
#  [37] MICROSOFT HEALTH CHECK (EXTENDED)
# ============================================================
function Invoke-HealthCheckFull {
    Write-Header "MICROSOFT HEALTH CHECK (EXTENDED)"
    $health = @()

    function Check-HealthItem {
        param([string]$Name, [string]$Status, [string]$Detail)
        $sc = switch ($Status) { "OK" { "Green" } "WARN" { "Yellow" } "FAIL" { "Red" } default { "DarkGray" } }
        $icon = switch ($Status) { "OK" { "[OK]" } "WARN" { "[!]" } "FAIL" { "[!!]" } default { "[--]" } }
        Write-Host "  $icon $Name - $Detail" -Fore $sc
        $health += @{ Item=$Name; Status=$Status; Detail=$Detail }
    }

    # Windows Health
    Check-HealthItem "Windows" "OK" "$($Script:AuditReport.SystemInfo.ProductName) $($Script:AuditReport.SystemInfo.CurrentBuild)"
    # Office Health
    $c2r = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -EA SilentlyContinue
    if ($c2r) { Check-HealthItem "Office" "OK" "$($c2r.ProductReleaseIds) v$($c2r.ClientVersionToReport)" }
    # Activation Health
    $dli = & cscript //NoLogo $Script:Slmgr /dli 2>&1
    $ls = ""; foreach ($l in $dli) { if ($l -match "License Status:\s*(.+)") { $ls = $Matches[1].Trim() } }
    Check-HealthItem "Activation" $(if($ls-match "Licensed"){"OK"}else{"FAIL"}) $ls
    # Update Health
    $wu = Get-Service wuauserv -EA SilentlyContinue
    Check-HealthItem "Windows Update" $(if($wu.Status -eq "Running"){"OK"}else{"WARN"}) $wu.Status
    # Security Health
    try { $def = Get-MpComputerStatus -EA SilentlyContinue; Check-HealthItem "Defender" $(if($def.AntivirusEnabled){"OK"}else{"FAIL"}) "AV=$($def.AntivirusEnabled)" } catch {}
    # Storage Health
    $disk = Get-PhysicalDisk -EA SilentlyContinue | Select-Object -First 1
    if ($disk) { Check-HealthItem "Storage" $(if($disk.HealthStatus -eq "Healthy"){"OK"}else{"FAIL"}) "$($disk.HealthStatus)" }
    # System Health
    $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
    Check-HealthItem "System" "OK" "RAM: ${ram}GB"

    # Summary
    Write-Host ""
    $okCount = ($health | Where-Object { $_.Status -eq "OK" }).Count
    $warnCount = ($health | Where-Object { $_.Status -eq "WARN" }).Count
    $failCount = ($health | Where-Object { $_.Status -eq "FAIL" }).Count
    Write-Host "  OK: $okCount | WARN: $warnCount | FAIL: $failCount" -Fore $(if($failCount -eq 0){"Green"}else{"Red"})
    $Script:AuditReport.HealthCheckFull = $health
    Write-Host ""
}

# ============================================================
#  [38] MICROSOUBLESHOOTER
# ============================================================
function Invoke-Troubleshooter {
    Write-Header "MICROSOFT TROUBLESHOOTER"
    Write-Host "  Chon doi tuong kiem tra:" -Fore Cyan
    Write-Host "    [1] Activation" -Fore White
    Write-Host "    [2] Windows Update" -Fore White
    Write-Host "    [3] Microsoft Store" -Fore White
    Write-Host "    [4] Office" -Fore White
    Write-Host "    [5] Network" -Fore White
    Write-Host "    [6] Printing" -Fore White
    Write-Host "    [7] Audio" -Fore White
    Write-Host "    [0] Bo qua" -Fore Red
    Write-Host ""
    $ch = Read-Host "  Chon"
    if ($ch -eq "0") { return }

    $troubleshooters = @{
        "1" = @{ Name="Activation"; Cmd="msdt.exe /id ActivationDiagnostic" }
        "2" = @{ Name="Windows Update"; Cmd="msdt.exe /id WindowsUpdateDiagnostic" }
        "3" = @{ Name="Store"; Cmd="wsreset.exe" }
        "4" = @{ Name="Office"; Cmd="msdt.exe /id OfficeDiagnostic" }
        "5" = @{ Name="Network"; Cmd="msdt.exe /id NetworkDiagnosticsWeb" }
        "6" = @{ Name="Printing"; Cmd="msdt.exe /id PrinterDiagnostic" }
        "7" = @{ Name="Audio"; Cmd="msdt.exe /id AudioPlaybackDiagnostic" }
    }

    if ($troubleshooters.ContainsKey($ch)) {
        $ts = $troubleshooters[$ch]
        Write-Step "INFO" "Mo $($ts.Name) troubleshooter..."
        Start-Process cmd.exe -Arg "/c $($ts.Cmd)" -EA SilentlyContinue
        Write-Step "OK" "Troubleshooter da mo" "OK"
    }
    Write-Host ""
}

# ============================================================
#  [39] MICROSOFT LOG COLLECTOR
# ============================================================
function Invoke-LogCollector {
    Write-Header "MICROSOFT LOG COLLECTOR"

    $logDir = Join-Path $env:TEMP "MS_Logs_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory $logDir -Force | Out-Null

    Write-Step "INFO" "Thu thap logs..."

    # Event Viewer
    Write-Step "INFO" "Event Viewer..."
    wevtutil epl System "$logDir\System.evtx" /ow:true 2>&1 | Out-Null
    wevtutil epl Application "$logDir\Application.evtx" /ow:true 2>&1 | Out-Null
    Write-Step "OK" "Event logs exported" "OK"

    # CBS.log
    if (Test-Path "$env:SystemRoot\Logs\CBS\CBS.log") {
        Copy-Item "$env:SystemRoot\Logs\CBS\CBS.log" "$logDir\CBS.log" -Force
        Write-Step "OK" "CBS.log copied" "OK"
    }

    # DISM.log
    if (Test-Path "$env:SystemRoot\Logs\DISM\dism.log") {
        Copy-Item "$env:SystemRoot\Logs\DISM\dism.log" "$logDir\DISM.log" -Force
        Write-Step "OK" "DISM.log copied" "OK"
    }

    # WindowsUpdate.log
    try { Get-WindowsUpdateLog -LogPath "$logDir\WindowsUpdate.log" -EA SilentlyContinue } catch {}
    Write-Step "OK" "WindowsUpdate.log generated" "OK"

    # Defender
    & "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -GetFiles 2>&1 | Out-Null
    $defLog = "$env:ProgramData\Microsoft\Windows Defender\Support"
    if (Test-Path $defLog) { Copy-Item "$defLog\*" "$logDir\" -Force -EA SilentlyContinue }
    Write-Step "OK" "Defender logs copied" "OK"

    # System info
    systeminfo > "$logDir\systeminfo.txt" 2>&1

    Write-Host ""
    Write-Host "  Logs tai: $logDir" -Fore Cyan
    Write-Host ""
    $Script:AuditReport.LogDir = $logDir
}

# ============================================================
#  [40] MICROSOFT REPORT GENERATOR
# ============================================================
function Invoke-ReportGenerator {
    Write-Header "MICROSOFT REPORT GENERATOR"
    Write-Host "  Chon bao cao:" -Fore Cyan
    Write-Host "    [1] Inventory Report" -Fore White
    Write-Host "    [2] License Report" -Fore White
    Write-Host "    [3] Office Report" -Fore White
    Write-Host "    [4] Activation Report" -Fore White
    Write-Host "    [5] Windows 11 Report" -Fore White
    Write-Host "    [6] Health Report" -Fore White
    Write-Host "    [7] Security Report" -Fore White
    Write-Host "    [8] Repair Report" -Fore White
    Write-Host "    [9] TOAN BO BAO CAO" -Fore Green
    Write-Host "    [0] Bo qua" -Fore Red
    Write-Host ""
    $ch = Read-Host "  Chon"
    if ($ch -eq "0") { return }

    # Collect all data if not already
    Get-SystemInventory | Out-Null
    Get-LicenseAudit | Out-Null
    Test-Windows11Compatibility | Out-Null
    Detect-InvalidActivation | Out-Null
    Test-SystemHealth | Out-Null

    # Generate reports
    Export-AuditReport
    Write-Host ""
}

# ============================================================
#  [41] MICROSOFT QUICK ACTIONS
# ============================================================
function Invoke-QuickActions {
    Write-Header "MICROSOFT QUICK ACTIONS (1-TOUCH)"
    Write-Host "  Thuc hien nhanh cac thao tac pho bien:" -Fore Cyan
    Write-Host ""
    Write-Host "    [1] Scan Windows + Office + Security" -Fore Green
    Write-Host "    [2] Check Windows 11 + License + Updates" -Fore Green
    Write-Host "    [3] Repair All (Windows + Office + Store + Update)" -Fore Green
    Write-Host "    [4] Verify + Export Report" -Fore Green
    Write-Host "    [5] FULL: Scan + Repair + Verify + Report" -Fore Green
    Write-Host "    [0] Bo qua" -Fore Red
    Write-Host ""
    $ch = Read-Host "  Chon"

    switch ($ch) {
        "1" {
            Write-Host ""
            Get-SystemInventory | Out-Null
            Get-LicenseAudit | Out-Null
            Invoke-SecurityAuditFull
        }
        "2" {
            Write-Host ""
            Get-SystemInventory | Out-Null
            Test-Windows11Compatibility
            Get-LicenseAudit | Out-Null
            Invoke-UpdateAudit
        }
        "3" {
            Write-Host ""
            Invoke-RepairCenter
        }
        "4" {
            Write-Host ""
            Verify-Activation
            Export-AuditReport
        }
        "5" {
            Write-Host ""
            Get-SystemInventory | Out-Null
            Get-LicenseAudit | Out-Null
            Test-Windows11Compatibility | Out-Null
            Invoke-SecurityAuditFull | Out-Null
            Invoke-UpdateAudit | Out-Null
            Invoke-RepairCenter | Out-Null
            Verify-Activation | Out-Null
            Test-SystemHealth | Out-Null
            Export-AuditReport
        }
    }
    Write-Host ""
}

# ============================================================
#  CHUC NANG THEO TUNG SAN PHAM
# ============================================================

# ──────────────────────────────────────────────────────────
#  WINDOWS: Kiem tra + Go KMS + Khoi phuc
# ──────────────────────────────────────────────────────────
function Repair-WindowsLicense {
    Write-Header "WINDOWS: KIEM TRA + GO KMS + KHOI PHUC"

    # Step 1: Kiem tra trang thai hien tai
    Write-Step "INFO" "Buoc 1: Kiem tra trang thai Windows..."
    Write-Host ""
    Write-Host "  ── Trang thai hien tai ─────────────────────────────────" -Fore Cyan
    $dli = & cscript //NoLogo $Script:Slmgr /dli 2>&1
    foreach ($l in $dli) { if ($l.Trim()) { Write-Host "  $l" } }
    Write-Host ""
    $xpr = & cscript //NoLogo $Script:Slmgr /xpr 2>&1
    foreach ($l in $xpr) { if ($l.Trim()) { Write-Host "  $l" } }
    Write-Host ""

    # Phan tich
    $channel = ""; $kmsMachine = ""; $status = ""
    foreach ($l in $dli) {
        if ($l -match "License Status:\s*(.+)")     { $status = $Matches[1].Trim() }
        if ($l -match "Product Key Channel:\s*(.+)") { $channel = $Matches[1].Trim() }
        if ($l -match "KMS Machine Name:\s*(.+)")    { $kmsMachine = $Matches[1].Trim() }
    }

    Write-Host "  ── Phan tich ───────────────────────────────────────────" -Fore Cyan
    Write-Host "  Trang thai:  $status" -Fore $(if ($status -match "Licensed") { "Green" } else { "Red" })
    Write-Host "  Channel:     $channel" -Fore $(if ($channel -match "Volume_KMS") { "Yellow" } else { "White" })
    if ($kmsMachine) { Write-Host "  KMS Server:  $kmsMachine" -Fore Yellow }

    $hasKMS = ($channel -match "Volume_KMS" -or $kmsMachine)
    if (-not $hasKMS) {
        Write-Host ""
        Write-Step "OK" "Windows khong co cau hinh KMS. Khong can go." "OK"
        if ($status -match "Licensed") {
            Write-Step "PASS" "Windows da kich hoat hop le!" "PASS"
        }
        return
    }

    Write-Host ""
    Write-Host "  ── Cau hinh se go bo ───────────────────────────────────" -Fore Yellow
    Write-Host "    [x] Go Product Key hien tai" -Fore White
    Write-Host "    [x] Xoa KMS Server" -Fore White
    Write-Host "    [x] Xoa Registry Key" -Fore White
    Write-Host "    [x] Reset Activation (rearm)" -Fore White
    Write-Host "    [x] Xoa Registry KMS entries" -Fore White
    Write-Host "    [x] Xoa KMS files & thu muc" -Fore White
    Write-Host "    [x] Xoa KMS Scheduled Tasks" -Fore White
    Write-Host "    [x] Xoa KMS Services" -Fore White
    Write-Host ""
    if (-not (Confirm-Proceed "Ban co muon go KMS Windows?")) { return }

    # Step 2: Backup
    Write-Host ""
    Write-Step "INFO" "Buoc 2: Tao backup..."
    if (!(Test-Path $Script:BackupDir)) { New-Item -ItemType Directory $Script:BackupDir -Force | Out-Null }
    reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" "$Script:BackupDir\windows_spp_backup.reg" /y 2>&1 | Out-Null
    Write-Step "OK" "Backup: $Script:BackupDir\windows_spp_backup.reg" "OK"

    # Step 3: Go KMS Windows
    Write-Host ""
    Write-Step "INFO" "Buoc 3: Go cau hinh KMS Windows..."
    Run-Slmgr "/upk"  "Go Product Key"
    Run-Slmgr "/cpky" "Xoa Registry Key"
    Run-Slmgr "/ckms" "Xoa KMS Server"
    Run-Slmgr "/rearm" "Reset Activation"

    # Step 4: Xoa KMS Registry
    Write-Host ""
    Write-Step "INFO" "Buoc 4: Xoa KMS Registry..."
    $rc = 0
    foreach ($e in $Script:KMSRegistryKeys) {
        try {
            if ($e.Name) {
                if (Get-ItemProperty $e.Path -Name $e.Name -EA SilentlyContinue) {
                    Remove-ItemProperty $e.Path -Name $e.Name -Force -EA SilentlyContinue
                    $rc++
                }
            } else {
                if (Test-Path $e.Path) {
                    Remove-Item $e.Path -Recurse -Force -EA SilentlyContinue
                    $rc++
                }
            }
        } catch {}
    }
    Write-Step "OK" "Da xoa $rc registry entries" "OK"

    # Step 5: Xoa KMS Files
    Write-Host ""
    Write-Step "INFO" "Buoc 5: Xoa KMS files & thu muc..."
    $fc = 0
    foreach ($d in $Script:KMSDirectories) {
        if (Test-Path $d) {
            Remove-Item $d -Recurse -Force -EA SilentlyContinue
            Write-Step "DEL" "Da xoa: $d" "DEL"
            $fc++
        }
    }
    foreach ($f in $Script:KMSFiles) {
        if (Test-Path $f) {
            takeown /f $f 2>$null | Out-Null
            icacls $f /grant administrators:F 2>$null | Out-Null
            Remove-Item $f -Force -EA SilentlyContinue
            Write-Step "DEL" "Da xoa: $f" "DEL"
            $fc++
        }
    }
    if ($fc -eq 0) { Write-Step "OK" "Khong co KMS files" "OK" }

    # Step 6: Xoa KMS Tasks
    Write-Host ""
    Write-Step "INFO" "Buoc 6: Xoa KMS Scheduled Tasks..."
    foreach ($t in $Script:KMSTasks) {
        Unregister-ScheduledTask $t -Confirm:$false -EA SilentlyContinue
    }
    Write-Step "OK" "Da xoa KMS tasks" "OK"

    # Step 7: Xoa KMS Services
    Write-Host ""
    Write-Step "INFO" "Buoc 7: Xoa KMS Services..."
    foreach ($kw in $Script:KMSServiceNames) {
        $svcs = Get-Service "*$kw*" -EA SilentlyContinue
        foreach ($svc in $svcs) {
            Stop-Service $svc.Name -Force -EA SilentlyContinue
            & sc.exe delete $svc.Name 2>&1 | Out-Null
            Write-Step "DEL" "Da xoa service: $($svc.Name)" "DEL"
        }
    }

    # Step 8: Khoi phuc Windows Update
    Write-Host ""
    Write-Step "INFO" "Buoc 8: Khoi phuc dich vu he thong..."
    try {
        Set-Service wuauserv -StartupType Automatic -EA SilentlyContinue
        Start-Service wuauserv -EA SilentlyContinue
        Write-Step "OK" "Windows Update: Running" "OK"
    } catch {}

    # Step 9: Sua loi he thong
    Write-Host ""
    Write-Step "INFO" "Buoc 9: Sua loi he thong (DISM + SFC)..."
    & DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-Null
    Write-Step "OK" "DISM RestoreHealth hoan tat" "OK"
    & sfc /scannow 2>&1 | Out-Null
    Write-Step "OK" "SFC hoan tat" "OK"

    # Step 10: Xac minh
    Write-Host ""
    Write-Step "INFO" "Buoc 10: Xac minh ket qua..."
    Write-Host ""
    Write-Host "  ── Trang thai sau khi go ───────────────────────────────" -Fore Cyan
    & cscript //NoLogo $Script:Slmgr /dli 2>&1 | ForEach-Object { if ($_.Trim()) { Write-Host "  $_" } }
    Write-Host ""
    & cscript //NoLogo $Script:Slmgr /xpr 2>&1 | ForEach-Object { if ($_.Trim()) { Write-Host "  $_" } }

    Write-Host ""
    Write-Host "  ── HOAN TAT ────────────────────────────────────────────" -Fore Green
    Write-Host "  Windows da duoc go KMS va khoi phuc." -Fore Green
    Write-Host "  Ban can nhap Product Key hop le de kich hoat." -Fore Yellow
    Write-Host "  Su dung menu [9] de nhap key moi." -Fore Yellow
    Write-Host ""

    $r = Read-Host "  Khoi dong lai ngay? (Y/N)"
    if ($r -eq 'Y' -or $r -eq 'y') { shutdown /r /t 10 /c "Go KMS Windows - Pho Tue Software" }
}

# ──────────────────────────────────────────────────────────
#  OFFICE: Kiem tra + Go KMS + Khoi phuc
# ──────────────────────────────────────────────────────────
function Repair-OfficeLicense {
    Write-Header "OFFICE: KIEM TRA + GO KMS + KHOI PHUC"

    # Tim Office OSPP.VBS
    $osppPaths = @(
        "$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS",
        "$env:ProgramFiles\Microsoft Office\Office15\OSPP.VBS",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office15\OSPP.VBS"
    )
    $ospp = $osppPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $ospp) {
        Write-Step "WARN" "Khong tim thay Office (OSPP.VBS)" "WARN"
        # Thu tim qua Registry
        $c2r = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -EA SilentlyContinue
        if ($c2r) {
            Write-Host "  Office Click-to-Run: $($c2r.ProductReleaseIds)" -Fore Cyan
            Write-Host "  Version: $($c2r.ClientVersionToReport)" -Fore Cyan
        } else {
            Write-Step "WARN" "Khong tim thay Office nao tren he thong" "WARN"
        }
        return
    }

    # Step 1: Kiem tra trang thai
    Write-Step "INFO" "Buoc 1: Kiem tra trang thai Office..."
    Write-Host "  OSPP: $ospp" -Fore DarkGray
    Write-Host ""
    Write-Host "  ── Trang thai hien tai ─────────────────────────────────" -Fore Cyan
    $out = & cscript //NoLogo $ospp /dstatus 2>&1
    foreach ($l in $out) { if ($l.Trim()) { Write-Host "  $l" } }
    Write-Host ""

    # Phan tich
    $hasKMS = $false
    $licenseNames = @()
    $cur = @{}
    foreach ($l in $out) {
        if ($l -match "LICENSE NAME:\s*(.+)") { $cur.LicenseName = $Matches[1].Trim() }
        if ($l -match "LICENSE STATUS:\s*(.+)") { $cur.LicenseStatus = $Matches[1].Trim() }
        if ($l -match "KMS machine name:\s*(.+)") { $cur.KMSMachine = $Matches[1].Trim(); $hasKMS = $true }
        if ($l -match "---") {
            if ($cur.LicenseName) { $licenseNames += $cur.Clone() }
            $cur = @{}
        }
    }
    if ($cur.LicenseName) { $licenseNames += $cur.Clone() }

    Write-Host "  ── Phan tich ───────────────────────────────────────────" -Fore Cyan
    foreach ($ln in $licenseNames) {
        $sc = if ($ln.LicenseStatus -match "LICENSED") { "Green" } else { "Yellow" }
        Write-Host "  $($ln.LicenseName): " -NoNewline; Write-Host $ln.LicenseStatus -Fore $sc
        if ($ln.KMSMachine) { Write-Host "    KMS: $($ln.KMSMachine)" -Fore Yellow }
    }

    if (-not $hasKMS) {
        Write-Host ""
        Write-Step "OK" "Office khong co cau hinh KMS. Khong can go." "OK"
        return
    }

    Write-Host ""
    Write-Host "  ── Cau hinh se go bo ───────────────────────────────────" -Fore Yellow
    Write-Host "    [x] Xoa KMS Machine Name (remhst)" -Fore White
    Write-Host "    [x] Reset Office license (cnsstsku)" -Fore White
    Write-Host "    [x] Xoa Office KMS Registry" -Fore White
    Write-Host ""
    if (-not (Confirm-Proceed "Ban co muon go KMS Office?")) { return }

    # Step 2: Backup
    Write-Host ""
    Write-Step "INFO" "Buoc 2: Tao backup..."
    if (!(Test-Path $Script:BackupDir)) { New-Item -ItemType Directory $Script:BackupDir -Force | Out-Null }
    reg export "HKLM\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform" "$Script:BackupDir\office_ospp_backup.reg" /y 2>&1 | Out-Null
    Write-Step "OK" "Backup: $Script:BackupDir" "OK"

    # Step 3: Go KMS Office
    Write-Host ""
    Write-Step "INFO" "Buoc 3: Go cau hinh KMS Office..."
    Write-Step "INFO" "Xoa KMS Machine Name..."
    & cscript //NoLogo $ospp /remhst 2>&1 | Out-Null
    Write-Step "OK" "Da xoa KMS Machine Name" "OK"

    Write-Step "INFO" "Reset Office SKU..."
    & cscript //NoLogo $ospp /cnsstsku 2>&1 | Out-Null
    Write-Step "OK" "Da reset Office SKU" "OK"

    # Step 4: Xoa Office KMS Registry
    Write-Host ""
    Write-Step "INFO" "Buoc 4: Xoa Office KMS Registry..."
    $osppReg = "HKLM:\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform"
    if (Test-Path "$osppReg\KMS") {
        Remove-Item "$osppReg\KMS" -Recurse -Force -EA SilentlyContinue
        Write-Step "OK" "Da xoa Office KMS Registry" "OK"
    } else {
        Write-Step "OK" "Khong co Office KMS Registry" "OK"
    }

    # Step 5: Xoa KMS Tasks lien quan Office
    Write-Host ""
    Write-Step "INFO" "Buoc 5: Xoa KMS Tasks lien quan Office..."
    foreach ($t in @("OfficeKMS", "KMS_Activation", "HEU_KMS")) {
        Unregister-ScheduledTask $t -Confirm:$false -EA SilentlyContinue
    }
    Write-Step "OK" "Da xoa Office KMS tasks" "OK"

    # Step 6: Xac minh
    Write-Host ""
    Write-Step "INFO" "Buoc 6: Xac minh ket qua..."
    Write-Host ""
    Write-Host "  ── Trang thai sau khi go ───────────────────────────────" -Fore Cyan
    $out2 = & cscript //NoLogo $ospp /dstatus 2>&1
    foreach ($l in $out2) { if ($l.Trim()) { Write-Host "  $l" } }

    Write-Host ""
    Write-Host "  ── HOAN TAT ────────────────────────────────────────────" -Fore Green
    Write-Host "  Office da duoc go KMS va khoi phuc." -Fore Green
    Write-Host "  Ban can nhap Product Key Office hop le de kich hoat." -Fore Yellow
    Write-Host ""
}

# ──────────────────────────────────────────────────────────
#  PROJECT: Kiem tra + Go KMS
# ──────────────────────────────────────────────────────────
function Repair-ProjectLicense {
    Write-Header "PROJECT: KIEM TRA + GO KMS"

    $osppPaths = @(
        "$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS"
    )
    $ospp = $osppPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $ospp) { Write-Step "WARN" "Khong tim thay OSPP.VBS" "WARN"; return }

    Write-Step "INFO" "Kiem tra trang thai Project..."
    $out = & cscript //NoLogo $ospp /dstatus 2>&1
    $hasProject = $false; $hasKMS = $false; $cur = @{}
    $projectEntries = @()

    foreach ($l in $out) {
        if ($l -match "LICENSE NAME:\s*(.+)") { $cur.LicenseName = $Matches[1].Trim() }
        if ($l -match "LICENSE STATUS:\s*(.+)") { $cur.LicenseStatus = $Matches[1].Trim() }
        if ($l -match "KMS machine name:\s*(.+)") { $cur.KMSMachine = $Matches[1].Trim() }
        if ($l -match "---") {
            if ($cur.LicenseName -match "Project") {
                $hasProject = $true
                $projectEntries += $cur.Clone()
                if ($cur.KMSMachine) { $hasKMS = $true }
            }
            $cur = @{}
        }
    }
    if ($cur.LicenseName -match "Project") {
        $hasProject = $true
        $projectEntries += $cur.Clone()
        if ($cur.KMSMachine) { $hasKMS = $true }
    }

    if (-not $hasProject) {
        Write-Step "WARN" "Khong tim thay Project tren he thong" "WARN"
        return
    }

    Write-Host ""
    Write-Host "  ── Trang thai hien tai ─────────────────────────────────" -Fore Cyan
    foreach ($pe in $projectEntries) {
        $sc = if ($pe.LicenseStatus -match "LICENSED") { "Green" } else { "Yellow" }
        Write-Host "  $($pe.LicenseName): " -NoNewline; Write-Host $pe.LicenseStatus -Fore $sc
        if ($pe.KMSMachine) { Write-Host "    KMS: $($pe.KMSMachine)" -Fore Yellow }
    }

    if (-not $hasKMS) {
        Write-Host ""
        Write-Step "OK" "Project khong co cau hinh KMS. Khong can go." "OK"
        return
    }

    Write-Host ""
    if (-not (Confirm-Proceed "Ban co muon go KMS Project?")) { return }

    Write-Step "INFO" "Dang go KMS Project..."
    & cscript //NoLogo $ospp /remhst 2>&1 | Out-Null
    & cscript //NoLogo $ospp /cnsstsku 2>&1 | Out-Null
    Write-Step "OK" "Da go KMS Project" "OK"

    Write-Host ""
    Write-Host "  ── Trang thai sau khi go ───────────────────────────────" -Fore Cyan
    & cscript //NoLogo $ospp /dstatus 2>&1 | ForEach-Object {
        if ($_ -match "Project" -or $_ -match "LICENSE STATUS" -or $_ -match "LICENSE NAME") {
            Write-Host "  $_"
        }
    }
    Write-Host ""
    Write-Host "  Project da duoc go KMS. Nhap key hop le de kich hoat." -Fore Green
    Write-Host ""
}

# ──────────────────────────────────────────────────────────
#  VISIO: Kiem tra + Go KMS
# ──────────────────────────────────────────────────────────
function Repair-VisioLicense {
    Write-Header "VISIO: KIEM TRA + GO KMS"

    $osppPaths = @(
        "$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS"
    )
    $ospp = $osppPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $ospp) { Write-Step "WARN" "Khong tim thay OSPP.VBS" "WARN"; return }

    Write-Step "INFO" "Kiem tra trang thai Visio..."
    $out = & cscript //NoLogo $ospp /dstatus 2>&1
    $hasVisio = $false; $hasKMS = $false; $cur = @{}
    $visioEntries = @()

    foreach ($l in $out) {
        if ($l -match "LICENSE NAME:\s*(.+)") { $cur.LicenseName = $Matches[1].Trim() }
        if ($l -match "LICENSE STATUS:\s*(.+)") { $cur.LicenseStatus = $Matches[1].Trim() }
        if ($l -match "KMS machine name:\s*(.+)") { $cur.KMSMachine = $Matches[1].Trim() }
        if ($l -match "---") {
            if ($cur.LicenseName -match "Visio") {
                $hasVisio = $true
                $visioEntries += $cur.Clone()
                if ($cur.KMSMachine) { $hasKMS = $true }
            }
            $cur = @{}
        }
    }
    if ($cur.LicenseName -match "Visio") {
        $hasVisio = $true
        $visioEntries += $cur.Clone()
        if ($cur.KMSMachine) { $hasKMS = $true }
    }

    if (-not $hasVisio) {
        Write-Step "WARN" "Khong tim thay Visio tren he thong" "WARN"
        return
    }

    Write-Host ""
    Write-Host "  ── Trang thai hien tai ─────────────────────────────────" -Fore Cyan
    foreach ($ve in $visioEntries) {
        $sc = if ($ve.LicenseStatus -match "LICENSED") { "Green" } else { "Yellow" }
        Write-Host "  $($ve.LicenseName): " -NoNewline; Write-Host $ve.LicenseStatus -Fore $sc
        if ($ve.KMSMachine) { Write-Host "    KMS: $($ve.KMSMachine)" -Fore Yellow }
    }

    if (-not $hasKMS) {
        Write-Host ""
        Write-Step "OK" "Visio khong co cau hinh KMS. Khong can go." "OK"
        return
    }

    Write-Host ""
    if (-not (Confirm-Proceed "Ban co muon go KMS Visio?")) { return }

    Write-Step "INFO" "Dang go KMS Visio..."
    & cscript //NoLogo $ospp /remhst 2>&1 | Out-Null
    & cscript //NoLogo $ospp /cnsstsku 2>&1 | Out-Null
    Write-Step "OK" "Da go KMS Visio" "OK"

    Write-Host ""
    Write-Host "  ── Trang thai sau khi go ───────────────────────────────" -Fore Cyan
    & cscript //NoLogo $ospp /dstatus 2>&1 | ForEach-Object {
        if ($_ -match "Visio" -or $_ -match "LICENSE STATUS" -or $_ -match "LICENSE NAME") {
            Write-Host "  $_"
        }
    }
    Write-Host ""
    Write-Host "  Visio da duoc go KMS. Nhap key hop le de kich hoat." -Fore Green
    Write-Host ""
}

# ──────────────────────────────────────────────────────────
#  DEFENDER: Kiem tra + Khoi phuc
# ──────────────────────────────────────────────────────────
function Repair-Defender {
    Write-Header "DEFENDER: KIEM TRA + KHOI PHUC"

    Write-Step "INFO" "Kiem tra trang thai Defender..."
    try {
        $mp = Get-MpPreference -EA SilentlyContinue
        $mpStatus = Get-MpComputerStatus -EA SilentlyContinue

        Write-Host ""
        Write-Host "  ── Trang thai hien tai ─────────────────────────────────" -Fore Cyan
        Write-Host "  Real-time:        " -NoNewline
        if ($mp.DisableRealtimeMonitoring) {
            Write-Host "TAT" -Fore Red
        } else {
            Write-Host "BAT" -Fore Green
        }
        Write-Host "  Tamper Protection: " -NoNewline
        if ($mpStatus.TamperProtection) {
            Write-Host "BAT" -Fore Green
        } else {
            Write-Host "TAT" -Fore Red
        }
        Write-Host "  Antivirus:        " -NoNewline
        if ($mpStatus.AntivirusEnabled) {
            Write-Host "Enabled" -Fore Green
        } else {
            Write-Host "Disabled" -Fore Red
        }
        Write-Host "  Signatures:       " -NoNewline
        Write-Host "$($mpStatus.AntivirusSignatureLastUpdated)" -Fore White

        # Exclusions
        if ($mp.ExclusionPath -and $mp.ExclusionPath.Count -gt 0) {
            Write-Host ""
            Write-Host "  ── Exclusions ($($mp.ExclusionPath.Count)) ───────────────────────────────" -Fore Yellow
            foreach ($ex in $mp.ExclusionPath) { Write-Host "    $ex" -Fore Yellow }
        }
        if ($mp.ExclusionProcess -and $mp.ExclusionProcess.Count -gt 0) {
            Write-Host "  ── Exclusion Processes ($($mp.ExclusionProcess.Count)) ────────────────────" -Fore Yellow
            foreach ($ex in $mp.ExclusionProcess) { Write-Host "    $ex" -Fore Yellow }
        }

        # Kiem tra co van de khong
        $hasIssue = $mp.DisableRealtimeMonitoring -or (-not $mpStatus.TamperProtection) -or
                    ($mp.ExclusionPath -and $mp.ExclusionPath.Count -gt 0) -or
                    ($mp.ExclusionProcess -and $mp.ExclusionProcess.Count -gt 0)

        if (-not $hasIssue) {
            Write-Host ""
            Write-Step "OK" "Defender binh thuong. Khong can khoi phuc." "OK"
            return
        }

        Write-Host ""
        Write-Host "  ── Se khoi phuc ───────────────────────────────────────" -Fore Yellow
        if ($mp.DisableRealtimeMonitoring) { Write-Host "    [x] Bat Real-time Protection" -Fore White }
        if ($mp.ExclusionPath) { Write-Host "    [x] Xoa Exclusion Paths ($($mp.ExclusionPath.Count))" -Fore White }
        if ($mp.ExclusionProcess) { Write-Host "    [x] Xoa Exclusion Processes ($($mp.ExclusionProcess.Count))" -Fore White }
        Write-Host ""
        if (-not (Confirm-Proceed "Ban co muon khoi phuc Defender?")) { return }

        # Khoi phuc
        Write-Host ""
        Write-Step "INFO" "Dang khoi phuc Defender..."

        if ($mp.DisableRealtimeMonitoring) {
            Set-MpPreference -DisableRealtimeMonitoring $false -EA SilentlyContinue
            Write-Step "OK" "Da bat Real-time Protection" "OK"
        }

        foreach ($ex in $mp.ExclusionPath) {
            Remove-MpPreference -ExclusionPath $ex -EA SilentlyContinue
            Write-Step "DEL" "Da xoa exclusion: $ex" "DEL"
        }
        foreach ($ex in $mp.ExclusionProcess) {
            Remove-MpPreference -ExclusionProcess $ex -EA SilentlyContinue
            Write-Step "DEL" "Da xoa process exclusion: $ex" "DEL"
        }
        foreach ($ex in $mp.ExclusionExtension) {
            Remove-MpPreference -ExclusionExtension $ex -EA SilentlyContinue
        }

        # Cap nhat signatures
        Write-Step "INFO" "Dang cap nhat virus signatures..."
        try { Update-MpSignature -EA SilentlyContinue; Write-Step "OK" "Da cap nhat signatures" "OK" } catch {}

        Write-Host ""
        Write-Host "  ── Trang thai sau khi khoi phuc ───────────────────────" -Fore Cyan
        $mp2 = Get-MpPreference -EA SilentlyContinue
        Write-Host "  Real-time:  " -NoNewline
        if ($mp2.DisableRealtimeMonitoring) { Write-Host "TAT" -Fore Red } else { Write-Host "BAT" -Fore Green }
        Write-Host "  Exclusions: " -NoNewline
        Write-Host "$(($mp2.ExclusionPath | Measure-Object).Count) paths" -Fore White

        Write-Host ""
        Write-Host "  Defender da duoc khoi phuc!" -Fore Green
    } catch {
        Write-Step "ERROR" "Khong the truy cap Defender: $_" "ERROR"
    }
    Write-Host ""
}

# ──────────────────────────────────────────────────────────
#  HOSTS: Kiem tra + Khoi phuc
# ──────────────────────────────────────────────────────────
function Repair-HostsFile {
    Write-Header "HOSTS: KIEM TRA + KHOI PHUC"

    Write-Step "INFO" "Kiem tra file Hosts..."
    if (-not (Test-Path $Script:HostsPath)) {
        Write-Step "WARN" "Khong tim thay file Hosts" "WARN"
        return
    }

    $content = Get-Content $Script:HostsPath
    $keywords = @("activation", "kms", "crack", "kmspico", "kmsauto", "office", "microsoft.com", "login.microsoftonline.com", "login.live.com")
    $suspicious = @()

    Write-Host ""
    Write-Host "  ── Noi dung Hosts ─────────────────────────────────────" -Fore Cyan
    foreach ($line in $content) {
        if ($line.Trim() -eq "" -or $line.Trim().StartsWith("#")) {
            Write-Host "  $line" -Fore DarkGray
            continue
        }
        $isSus = $false
        foreach ($kw in $keywords) {
            if ($line -match $kw) { $isSus = $true; break }
        }
        if ($isSus) {
            Write-Host "  $line" -Fore Red
            $suspicious += $line
        } else {
            Write-Host "  $line" -Fore White
        }
    }

    Write-Host ""
    if ($suspicious.Count -eq 0) {
        Write-Step "OK" "Hosts sach. Khong can khoi phuc." "OK"
        return
    }

    Write-Host "  ── Phat hien $($suspicious.Count) dong dang ngo ────────────────" -Fore Yellow
    foreach ($s in $suspicious) { Write-Host "    $s" -Fore Red }
    Write-Host ""

    if (-not (Confirm-Proceed "Ban co muon xoa cac dong nay?")) { return }

    # Backup
    Copy-Item $Script:HostsPath "$Script:HostsPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
    Write-Step "OK" "Da backup Hosts" "OK"

    # Xoa dong dang ngo
    $clean = $content | Where-Object {
        $line = $_; $keep = $true
        foreach ($kw in $keywords) {
            if ($line -match $kw -and $line -notmatch "^\s*#") { $keep = $false; break }
        }
        $keep
    }
    $clean | Set-Content $Script:HostsPath -Force -Encoding ASCII
    Write-Step "OK" "Da xoa $($suspicious.Count) dong khoi Hosts" "OK"

    Write-Host ""
    Write-Host "  ── Noi dung sau khi khoi phuc ─────────────────────────" -Fore Cyan
    Get-Content $Script:HostsPath | ForEach-Object { Write-Host "  $_" -Fore $(if ($_ -match "^\s*#") { "DarkGray" } else { "White" }) }
    Write-Host ""
    Write-Host "  Hosts da duoc khoi phuc!" -Fore Green
    Write-Host ""
}

# ──────────────────────────────────────────────────────────
#  SCHEDULED TASKS: Kiem tra + Xoa
# ──────────────────────────────────────────────────────────
function Repair-ScheduledTasks {
    Write-Header "SCHEDULED TASKS: KIEM TRA + XOA KMS"

    Write-Step "INFO" "Quet Scheduled Tasks..."
    $suspicious = @()
    $kws = $Script:KMSSoftwareKeywords

    Get-ScheduledTask -EA SilentlyContinue | ForEach-Object {
        foreach ($kw in $kws) {
            if ($_.TaskName -match $kw -or $_.TaskPath -match $kw) {
                $suspicious += $_
            }
        }
    }

    Write-Host ""
    if ($suspicious.Count -eq 0) {
        Write-Step "OK" "Khong tim thay task dang ngo." "OK"
        return
    }

    Write-Host "  ── Tasks dang ngo ($($suspicious.Count)) ─────────────────────────" -Fore Yellow
    foreach ($t in $suspicious) {
        Write-Host "    $($t.TaskPath)$($t.TaskName)" -Fore Red
        Write-Host "      State: $($t.State)" -Fore DarkGray
    }
    Write-Host ""

    if (-not (Confirm-Proceed "Ban co muon xoa cac tasks nay?")) { return }

    foreach ($t in $suspicious) {
        Unregister-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -Confirm:$false -EA SilentlyContinue
        Write-Step "DEL" "Da xoa: $($t.TaskName)" "DEL"
    }
    Write-Host ""
    Write-Host "  Da xoa $($suspicious.Count) tasks!" -Fore Green
    Write-Host ""
}

# ──────────────────────────────────────────────────────────
#  SERVICES: Kiem tra + Xoa KMS
# ──────────────────────────────────────────────────────────
function Repair-Services {
    Write-Header "SERVICES: KIEM TRA + XOA KMS"

    Write-Step "INFO" "Quet Services dang ngo..."
    $suspicious = @()
    foreach ($kw in $Script:KMSServiceNames) {
        $svcs = Get-Service "*$kw*" -EA SilentlyContinue
        foreach ($svc in $svcs) { $suspicious += $svc }
    }

    Write-Host ""
    if ($suspicious.Count -eq 0) {
        Write-Step "OK" "Khong tim thay service dang ngo." "OK"
        return
    }

    Write-Host "  ── Services dang ngo ($($suspicious.Count)) ───────────────────────" -Fore Yellow
    foreach ($svc in $suspicious) {
        $sc = if ($svc.Status -eq "Running") { "Red" } else { "Yellow" }
        Write-Host "    $($svc.Name) [$($svc.Status)] - $($svc.DisplayName)" -Fore $sc
    }
    Write-Host ""

    if (-not (Confirm-Proceed "Ban co muon xoa cac services nay?")) { return }

    foreach ($svc in $suspicious) {
        Stop-Service $svc.Name -Force -EA SilentlyContinue
        & sc.exe delete $svc.Name 2>&1 | Out-Null
        Write-Step "DEL" "Da xoa service: $($svc.Name)" "DEL"
    }
    Write-Host ""
    Write-Host "  Da xoa $($suspicious.Count) services!" -Fore Green
    Write-Host ""
}

# ──────────────────────────────────────────────────────────
#  STARTUP: Kiem tra + Xoa KMS
# ──────────────────────────────────────────────────────────
function Repair-Startup {
    Write-Header "STARTUP: KIEM TRA + XOA KMS"

    Write-Step "INFO" "Quet Startup entries..."
    $suspicious = @()
    $startupPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"
    )

    foreach ($sp in $startupPaths) {
        if (Test-Path $sp) {
            $props = Get-ItemProperty $sp -EA SilentlyContinue
            foreach ($prop in $props.PSObject.Properties) {
                if ($prop.Name -match "^PS") { continue }
                foreach ($kw in $Script:KMSSoftwareKeywords) {
                    if ($prop.Name -match $kw -or $prop.Value -match $kw) {
                        $suspicious += @{ Path=$sp; Name=$prop.Name; Value=$prop.Value }
                    }
                }
            }
        }
    }

    Write-Host ""
    if ($suspicious.Count -eq 0) {
        Write-Step "OK" "Khong tim thay startup entry dang ngo." "OK"
        return
    }

    Write-Host "  ── Startup entries dang ngo ($($suspicious.Count)) ───────────────" -Fore Yellow
    foreach ($su in $suspicious) {
        Write-Host "    $($su.Name)" -Fore Red
        Write-Host "      Path: $($su.Path)" -Fore DarkGray
        Write-Host "      Value: $($su.Value)" -Fore DarkGray
    }
    Write-Host ""

    if (-not (Confirm-Proceed "Ban co muon xoa cac entries nay?")) { return }

    foreach ($su in $suspicious) {
        Remove-ItemProperty -Path $su.Path -Name $su.Name -Force -EA SilentlyContinue
        Write-Step "DEL" "Da xoa: $($su.Name)" "DEL"
    }
    Write-Host ""
    Write-Host "  Da xoa $($suspicious.Count) startup entries!" -Fore Green
    Write-Host ""
}

# ──────────────────────────────────────────────────────────
#  SQL SERVER: Kiem tra thong tin
# ──────────────────────────────────────────────────────────
function Show-SQLServerInfo {
    Write-Header "SQL SERVER: KIEM TRA THONG TIN"

    Write-Step "INFO" "Quet SQL Server..."
    $sqlServices = Get-Service *sql* -EA SilentlyContinue

    Write-Host ""
    if (-not $sqlServices) {
        Write-Step "WARN" "Khong tim thay SQL Server tren he thong" "WARN"
        return
    }

    Write-Host "  ── SQL Server Services ($($sqlServices.Count)) ─────────────────────" -Fore Cyan
    foreach ($svc in $sqlServices) {
        $sc = if ($svc.Status -eq "Running") { "Green" } else { "Yellow" }
        Write-Host "  $($svc.DisplayName)" -Fore White
        Write-Host "    Name:      $($svc.Name)" -Fore DarkGray
        Write-Host "    Status:    " -NoNewline; Write-Host $svc.Status -Fore $sc
        Write-Host "    StartType: $($svc.StartType)" -Fore DarkGray
    }

    # SQL Instances
    Write-Host ""
    Write-Host "  ── SQL Instances ───────────────────────────────────────" -Fore Cyan
    foreach ($rp in @("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server")) {
        if (Test-Path $rp) {
            $instances = Get-ItemProperty "$rp\Instance Names\SQL" -EA SilentlyContinue
            if ($instances) {
                foreach ($prop in $instances.PSObject.Properties) {
                    if ($prop.Name -notmatch "^PS") {
                        Write-Host "  Instance: $($prop.Name) = $($prop.Value)" -Fore White
                    }
                }
            }
        }
    }
    Write-Host ""
}

# ──────────────────────────────────────────────────────────
#  VISUAL STUDIO: Kiem tra thong tin
# ──────────────────────────────────────────────────────────
function Show-VisualStudioInfo {
    Write-Header "VISUAL STUDIO: KIEM TRA THONG TIN"

    Write-Step "INFO" "Quet Visual Studio..."
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

    Write-Host ""
    if (Test-Path $vswhere) {
        $vsInstalls = & $vswhere -all -format json 2>&1
        try {
            $vsData = $vsInstalls | ConvertFrom-Json
            if ($vsData.Count -eq 0) {
                Write-Step "WARN" "Khong tim thay Visual Studio" "WARN"
                return
            }
            Write-Host "  ── Visual Studio ($($vsData.Count)) ───────────────────────────" -Fore Cyan
            foreach ($vs in $vsData) {
                Write-Host "  $($vs.displayName)" -Fore White
                Write-Host "    Version:  $($vs.installationVersion)" -Fore DarkGray
                Write-Host "    Path:     $($vs.installPath)" -Fore DarkGray
                Write-Host "    Channel:  $($vs.channelId)" -Fore DarkGray
            }
        } catch {
            Write-Step "WARN" "Khong the parse VS data" "WARN"
        }
    } else {
        # Thu tim qua Registry
        $found = $false
        foreach ($ver in @("17.0", "16.0", "15.0")) {
            $rp = "HKLM:\SOFTWARE\Microsoft\VisualStudio\$ver"
            if (Test-Path $rp) {
                Write-Host "  Visual Studio $ver (Registry)" -Fore Cyan
                $found = $true
            }
        }
        if (-not $found) {
            Write-Step "WARN" "Khong tim thay Visual Studio" "WARN"
        }
    }
    Write-Host ""
}

# ──────────────────────────────────────────────────────────
#  MICROSOFT 365: Kiem tra thong tin
# ──────────────────────────────────────────────────────────
function Show-M365Info {
    Write-Header "MICROSOFT 365: KIEM TRA THONG TIN"

    Write-Step "INFO" "Quet Microsoft 365..."
    Write-Host ""

    $c2rReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -EA SilentlyContinue
    if (-not $c2rReg) {
        Write-Step "WARN" "Khong tim thay Microsoft 365 / Office Click-to-Run" "WARN"
        return
    }

    Write-Host "  ── Microsoft 365 / Click-to-Run ────────────────────────" -Fore Cyan
    Write-Host "  Products:      $($c2rReg.ProductReleaseIds)" -Fore White
    Write-Host "  Channel:       $($c2rReg.UpdateChannel)" -Fore White
    Write-Host "  Version:       $($c2rReg.ClientVersionToReport)" -Fore White
    Write-Host "  Platform:      $($c2rReg.Platform)" -Fore White

    if ($c2rReg.SharedComputerLicensing -eq "1") {
        Write-Host "  Shared CA:     " -NoNewline; Write-Host "Enabled" -Fore Yellow
    }

    # Subscription status
    $subReg = Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Licensing\LicensingNext" -EA SilentlyContinue
    if ($subReg) {
        Write-Host ""
        Write-Host "  ── Subscription ────────────────────────────────────────" -Fore Cyan
        foreach ($prop in $subReg.PSObject.Properties) {
            if ($prop.Name -notmatch "^PS") {
                Write-Host "  $($prop.Name): $($prop.Value)" -Fore DarkGray
            }
        }
    }
    Write-Host ""
}

# ============================================================
#  MENU CHINH
# ============================================================
function Show-Menu {
    $cont = $true
    while ($cont) {
        Clear-Host
        $line = [string]::new([char]0x2550, 67)
        Write-Host ""
        Write-Host "  $line" -Fore Cyan
        Write-Host "   MICROSOFT GENUINE LICENSE AUDIT & RECOVERY TOOL v$Script:Version" -Fore White
        Write-Host "   Pho Tue SoftWare Solutions JSC | HiTechCloud" -Fore DarkGray
        Write-Host "   Ngon ngu: $Script:Lang" -Fore DarkGray
        Write-Host "  $line" -Fore Cyan
        Write-Host ""
        Write-Host "   --- KIEM TOAN VA PHUC HOI TONG HOP ---" -Fore Yellow
        Write-Host "   [1] " -NoNewline; Write-Host "Kiem toan toan dien (Audit + Cleanup + Activate + Report)" -Fore Green
        Write-Host "   [2] Chi kiem tra thong tin he thong" -Fore White
        Write-Host "   [3] Chi phat hien van de ban quyen" -Fore White
        Write-Host "   [4] Chi lam sach he thong (can xac nhan)" -Fore White
        Write-Host "   [5] Chi kiem tra suc khoe he thong" -Fore White
        Write-Host "   [6] Xuat bao cao (HTML/JSON/TXT/CSV)" -Fore White
        Write-Host ""
        Write-Host "   --- WINDOWS ---" -Fore Yellow
        Write-Host "   [W1] " -NoNewline; Write-Host "Kiem tra + Go KMS Windows + Khoi phuc" -Fore Green
        Write-Host "   [W2] Kiem tra phien ban Windows" -Fore White
        Write-Host "   [W3] Kiem tra trang thai License" -Fore White
        Write-Host "   [W4] Nhap va kich hoat key moi" -Fore White
        Write-Host "   [W5] Nang cap Home -> Pro" -Fore White
        Write-Host "   [W6] " -NoNewline; Write-Host "Nang cap Windows (Win10->Win11)" -Fore Green
        Write-Host ""
        Write-Host "   --- OFFICE / PROJECT / VISIO ---" -Fore Yellow
        Write-Host "   [O1] " -NoNewline; Write-Host "Kiem tra + Go KMS Office + Khoi phuc" -Fore Green
        Write-Host "   [O2] Kiem tra + Go KMS Project" -Fore White
        Write-Host "   [O3] Kiem tra + Go KMS Visio" -Fore White
        Write-Host "   [O4] Kiem tra Microsoft 365 / Click-to-Run" -Fore White
        Write-Host "   [O5] " -NoNewline; Write-Host "Nang cap Office" -Fore Green
        Write-Host ""
        Write-Host "   --- PHAN MEM KHAC ---" -Fore Yellow
        Write-Host "   [S1] Kiem tra Visual Studio" -Fore White
        Write-Host "   [S2] Kiem tra SQL Server" -Fore White
        Write-Host ""
        Write-Host "   --- HE THONG ---" -Fore Yellow
        Write-Host "   [D1] " -NoNewline; Write-Host "Kiem tra + Khoi phuc Defender" -Fore Green
        Write-Host "   [D2] Kiem tra + Khoi phuc file Hosts" -Fore White
        Write-Host "   [D3] Kiem tra + Xoa Scheduled Tasks KMS" -Fore White
        Write-Host "   [D4] Kiem tra + Xoa Services KMS" -Fore White
        Write-Host "   [D5] Kiem tra + Xoa Startup KMS" -Fore White
        Write-Host "   [D6] Sua loi he thong (DISM + SFC)" -Fore White
        Write-Host "   [D7] Lam sach toan bo (khong kiem tra)" -Fore White
        Write-Host ""
        Write-Host "   --- PHASE MOI ---" -Fore Yellow
        Write-Host "   [P1] " -NoNewline; Write-Host "Audit doc lap (chi doc, khong thay doi)" -Fore Green
        Write-Host "   [P2] " -NoNewline; Write-Host "Kiem tra tieu chuan doanh nghiep (Compliance)" -Fore Green
        Write-Host "   [P3] " -NoNewline; Write-Host "Phuc hoi License (Recovery)" -Fore Green
        Write-Host "   [P4] " -NoNewline; Write-Host "Trien khai License (Batch Deploy)" -Fore Green
        Write-Host "   [P5] " -NoNewline; Write-Host "Trung tam san pham Microsoft" -Fore Green
        Write-Host "   [P6] " -NoNewline; Write-Host "Kiem tra bao mat (Security Scan)" -Fore Green
        Write-Host "   [P7] " -NoNewline; Write-Host "Kiem tra suc khoe mo rong (Health)" -Fore Green
        Write-Host "   [P8] " -NoNewline; Write-Host "Don dep he thong (Cleanup)" -Fore Green
        Write-Host "   [P9] " -NoNewline; Write-Host "Sao luu he thong (Backup)" -Fore Green
        Write-Host "   [PA] " -NoNewline; Write-Host "Khoi phuc he thong (Restore)" -Fore Green
        Write-Host ""
        Write-Host "   --- AUDIT MOI (21-41) ---" -Fore Yellow
        Write-Host "   [M1] " -NoNewline; Write-Host "Product Discovery (phat hien tat ca)" -Fore Green
        Write-Host "   [M2] " -NoNewline; Write-Host "Runtime Audit (.NET, VC++, DirectX...)" -Fore Green
        Write-Host "   [M3] " -NoNewline; Write-Host "Services Audit (SPP, WU, Defender...)" -Fore Green
        Write-Host "   [M4] " -NoNewline; Write-Host "Store Audit (MS Store, WinGet)" -Fore Green
        Write-Host "   [M5] " -NoNewline; Write-Host "Account Audit (MS/Azure AD/Domain)" -Fore Green
        Write-Host "   [M6] " -NoNewline; Write-Host "Update Audit (Windows/Office/Driver)" -Fore Green
        Write-Host "   [M7] " -NoNewline; Write-Host "Security Audit Full (17 checks)" -Fore Green
        Write-Host "   [M8] " -NoNewline; Write-Host "Optional Features (Hyper-V, WSL, IIS...)" -Fore Green
        Write-Host "   [M9] " -NoNewline; Write-Host "Drivers Audit" -Fore Green
        Write-Host "   [MA] " -NoNewline; Write-Host "Licensing Components Audit" -Fore Green
        Write-Host "   [MB] " -NoNewline; Write-Host "Certificates Audit" -Fore Green
        Write-Host "   [MC] " -NoNewline; Write-Host "Scheduled Tasks Audit" -Fore Green
        Write-Host "   [MD] " -NoNewline; Write-Host "Registry Audit" -Fore Green
        Write-Host "   [ME] " -NoNewline; Write-Host "Environment Audit" -Fore Green
        Write-Host "   [MF] " -NoNewline; Write-Host "Repair Center (8 doi tuong)" -Fore Green
        Write-Host "   [MG] " -NoNewline; Write-Host "Download Center" -Fore Green
        Write-Host "   [MH] " -NoNewline; Write-Host "Health Check Full" -Fore Green
        Write-Host "   [MI] " -NoNewline; Write-Host "Troubleshooter" -Fore Green
        Write-Host "   [MJ] " -NoNewline; Write-Host "Log Collector" -Fore Green
        Write-Host "   [MK] " -NoNewline; Write-Host "Report Generator" -Fore Green
        Write-Host "   [ML] " -NoNewline; Write-Host "Quick Actions (1-touch)" -Fore Green
        Write-Host ""
        Write-Host "   [L]  Ngon ngu / Language" -Fore Cyan
        Write-Host "   [0]  Thoat / Exit" -Fore Red
        Write-Host ""
        Write-Host "  $line" -Fore Cyan
        Write-Host ""
        $ch = Read-Host "  Chon chuc nang"

        switch ($ch) {
            # Kiem toan tong hop
            "1"  { Invoke-FullAudit }
            "2"  { Get-SystemInventory; Test-Windows11Compatibility; Get-LicenseAudit }
            "3"  { Get-LicenseAudit; Detect-InvalidActivation }
            "4"  { Detect-InvalidActivation; Confirm-And-Cleanup }
            "5"  { Test-SystemHealth }
            "6"  { Export-QuickReport }
            # Windows
            "W1" { Repair-WindowsLicense }
            "w1" { Repair-WindowsLicense }
            "W2" { Check-WindowsEdition }
            "w2" { Check-WindowsEdition }
            "W3" { Show-LicenseStatus }
            "w3" { Show-LicenseStatus }
            "W4" { Activate-NewLicense }
            "w4" { Activate-NewLicense }
            "W5" { Upgrade-HomeToPro }
            "w5" { Upgrade-HomeToPro }
            "W6" { Invoke-WindowsUpgrade }
            "w6" { Invoke-WindowsUpgrade }
            # Office / Project / Visio
            "O1" { Repair-OfficeLicense }
            "o1" { Repair-OfficeLicense }
            "O2" { Repair-ProjectLicense }
            "o2" { Repair-ProjectLicense }
            "O3" { Repair-VisioLicense }
            "o3" { Repair-VisioLicense }
            "O4" { Show-M365Info }
            "o4" { Show-M365Info }
            "O5" { Invoke-OfficeUpgrade }
            "o5" { Invoke-OfficeUpgrade }
            # Phan mem khac
            "S1" { Show-VisualStudioInfo }
            "s1" { Show-VisualStudioInfo }
            "S2" { Show-SQLServerInfo }
            "s2" { Show-SQLServerInfo }
            # He thong
            "D1" { Repair-Defender }
            "d1" { Repair-Defender }
            "D2" { Repair-HostsFile }
            "d2" { Repair-HostsFile }
            "D3" { Repair-ScheduledTasks }
            "d3" { Repair-ScheduledTasks }
            "D4" { Repair-Services }
            "d4" { Repair-Services }
            "D5" { Repair-Startup }
            "d5" { Repair-Startup }
            "D6" { Fix-SystemErrors }
            "d6" { Fix-SystemErrors }
            "D7" { Invoke-FullCleanup }
            "d7" { Invoke-FullCleanup }
            # Phase moi
            "P1" { Invoke-ReadOnlyAudit }
            "p1" { Invoke-ReadOnlyAudit }
            "P2" { Invoke-ComplianceCheck }
            "p2" { Invoke-ComplianceCheck }
            "P3" { Invoke-LicenseRecovery }
            "p3" { Invoke-LicenseRecovery }
            "P4" { Invoke-LicenseDeployment }
            "p4" { Invoke-LicenseDeployment }
            "P5" { Invoke-ProductCenter }
            "p5" { Invoke-ProductCenter }
            "P6" { Invoke-SecurityScan }
            "p6" { Invoke-SecurityScan }
            "P7" { Invoke-HealthCheckExtended }
            "p7" { Invoke-HealthCheckExtended }
            "P8" { Invoke-SystemCleanup }
            "p8" { Invoke-SystemCleanup }
            "P9" { Invoke-SystemBackup }
            "p9" { Invoke-SystemBackup }
            "PA" { Invoke-SystemRestore }
            "pa" { Invoke-SystemRestore }
            # Audit moi (21-41)
            "M1" { Invoke-ProductDiscovery }
            "m1" { Invoke-ProductDiscovery }
            "M2" { Invoke-RuntimeAudit }
            "m2" { Invoke-RuntimeAudit }
            "M3" { Invoke-ServicesAudit }
            "m3" { Invoke-ServicesAudit }
            "M4" { Invoke-StoreAudit }
            "m4" { Invoke-StoreAudit }
            "M5" { Invoke-AccountAudit }
            "m5" { Invoke-AccountAudit }
            "M6" { Invoke-UpdateAudit }
            "m6" { Invoke-UpdateAudit }
            "M7" { Invoke-SecurityAuditFull }
            "m7" { Invoke-SecurityAuditFull }
            "M8" { Invoke-OptionalFeatures }
            "m8" { Invoke-OptionalFeatures }
            "M9" { Invoke-DriversAudit }
            "m9" { Invoke-DriversAudit }
            "MA" { Invoke-LicensingComponents }
            "ma" { Invoke-LicensingComponents }
            "MB" { Invoke-CertificatesAudit }
            "mb" { Invoke-CertificatesAudit }
            "MC" { Invoke-TasksAudit }
            "mc" { Invoke-TasksAudit }
            "MD" { Invoke-RegistryAudit }
            "md" { Invoke-RegistryAudit }
            "ME" { Invoke-EnvironmentAudit }
            "me" { Invoke-EnvironmentAudit }
            "MF" { Invoke-RepairCenter }
            "mf" { Invoke-RepairCenter }
            "MG" { Invoke-DownloadCenter }
            "mg" { Invoke-DownloadCenter }
            "MH" { Invoke-HealthCheckFull }
            "mh" { Invoke-HealthCheckFull }
            "MI" { Invoke-Troubleshooter }
            "mi" { Invoke-Troubleshooter }
            "MJ" { Invoke-LogCollector }
            "mj" { Invoke-LogCollector }
            "MK" { Invoke-ReportGenerator }
            "mk" { Invoke-ReportGenerator }
            "ML" { Invoke-QuickActions }
            "ml" { Invoke-QuickActions }
            # Ngon ngu
            "L"  { Select-Language }
            "l"  { Select-Language }
            # Thoat
            "0"  { $cont = $false }
            default {
                Write-Host "  [!] Lua chon khong hop le." -Fore Red
                Start-Sleep 1
            }
        }

        if ($cont) {
            Write-Host ""
            pause
        }
    }

    Write-Host ""
    Write-Host "  $([string]::new([char]0x2550, 50))" -Fore Cyan
    Write-Host "  Cam on ban da su dung Tool!" -Fore Cyan
    Write-Host "  Pho Tue SoftWare Solutions JSC" -Fore DarkGray
    Write-Host "  Hotline: 0865.920.041" -Fore DarkGray
    Write-Host "  Website: photuesoftware.com | hitechcloud.vn" -Fore DarkGray
    Write-Host "  $([string]::new([char]0x2550, 50))" -Fore Cyan
    Write-Host ""
}

# ============================================================
#  BAT DAU CHUONG TRINH
# ============================================================
Write-Host ""
Write-Host "  Dang tai Microsoft Genuine License Audit & Recovery Tool v$Script:Version..." -Fore Cyan
Write-Host "  Pho Tue SoftWare Solutions JSC | HiTechCloud" -Fore DarkGray
Write-Host "  Ngay: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Fore DarkGray
Write-Host ""

# Chon ngon ngu
Select-Language

Show-Menu
