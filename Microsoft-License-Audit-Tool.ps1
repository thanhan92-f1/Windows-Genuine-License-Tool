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
        Write-Host ""
        Write-Host "   --- OFFICE / PROJECT / VISIO ---" -Fore Yellow
        Write-Host "   [O1] " -NoNewline; Write-Host "Kiem tra + Go KMS Office + Khoi phuc" -Fore Green
        Write-Host "   [O2] Kiem tra + Go KMS Project" -Fore White
        Write-Host "   [O3] Kiem tra + Go KMS Visio" -Fore White
        Write-Host "   [O4] Kiem tra Microsoft 365 / Click-to-Run" -Fore White
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
        Write-Host "   [0] Thoat" -Fore Red
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
            # Office / Project / Visio
            "O1" { Repair-OfficeLicense }
            "o1" { Repair-OfficeLicense }
            "O2" { Repair-ProjectLicense }
            "o2" { Repair-ProjectLicense }
            "O3" { Repair-VisioLicense }
            "o3" { Repair-VisioLicense }
            "O4" { Show-M365Info }
            "o4" { Show-M365Info }
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
Show-Menu
