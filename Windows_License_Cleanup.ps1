#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Microsoft Genuine License Audit & Recovery Tool v2.0
.DESCRIPTION
    Kiem tra toan bo san pham Microsoft, phat hien kich hoat khong hop le,
    go bo cau hinh KMS, nang cap edition, kich hoat bang giay phep hop le,
    va xuat bao cao chi tiet (HTML/JSON/TXT).
.AUTHOR
    Pho Tue SoftWare And Technology Solutions Joint Stock Company
    HiTechCloud - Microsoft Partner
.VERSION
    2.0
.NOTES
    Chay voi quyen Administrator
    Su dung: irm https://irm-genuine-license-windows.hitechcloud.vn | iex
#>

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "`n  [LOI] Ban can chay voi quyen Administrator!" -ForegroundColor Red
    pause; return
}

# ============================================================
#  BIEN TOAN CAU
# ============================================================
$Script:LogFile = Join-Path $env:TEMP "MS_License_Audit_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$Script:ReportDir = Join-Path $env:TEMP "MS_License_Audit_Reports"
$Script:HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$Script:HostsBackup = "$Script:HostsPath.backup_$(Get-Date -Format 'yyyyMMdd')"
$Script:GenericProKey = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"
$Script:Slmgr = "$env:SystemRoot\System32\slmgr.vbs"

$Script:KMSDirectories = @(
    "$env:ProgramFiles\KMSpico", "${env:ProgramFiles(x86)}\KMSpico",
    "$env:ProgramData\KMSAutoS", "$env:ProgramData\KMSAuto",
    "$env:SystemRoot\KMS-R@1n", "$env:ProgramFiles\KMSAuto",
    "$env:ProgramFiles\KMSAuto Net", "$env:ProgramFiles\KMS_VL_ALL",
    "$env:ProgramData\Microsoft\KMS"
)
$Script:KMSFiles = @(
    "$env:SystemRoot\System32\SppExtComObjHook.dll",
    "$env:SystemRoot\System32\skc.dll",
    "$env:SystemRoot\System32\KMS-R@1n.dll",
    "$env:SystemRoot\SysWOW64\SppExtComObjHook.dll"
)
$Script:KMSTasks = @(
    "AutoKMS","KMSAuto","KMSAutoNet","SvcRestartTask","KMSpico",
    "KMS-R@1n","KMS Activation","MASHWID","Online_KMS",
    "Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTask"
)
$Script:KMSRegistryKeys = @(
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform\KMSActivation";Name=$null}
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run";Name="KMSAuto"}
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run";Name="KMSpico"}
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run";Name="AutoKMS"}
    @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run";Name="KMSAuto"}
    @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run";Name="KMSpico"}
    @{Path="HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run";Name="KMSAuto"}
    @{Path="HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run";Name="KMSpico"}
)
$Script:KMSKeywords = @("kms","kmspico","kmsauto","autoKMS","reloader","microsoft toolkit","hwid","ohook")
$Script:AuditReport = @{
    MachineName=$env:COMPUTERNAME; AuditDate=Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Windows=@{}; Office=@(); OtherProducts=@(); Win11Ready=@{}
    Issues=@(); Actions=@(); CleanupResults=@(); ActivationResult=@{}; HealthStatus=@{}
}

# ============================================================
#  HAM HO TRO
# ============================================================
function Write-Log { param([string]$M); "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $M" | Out-File $Script:LogFile -Append -Encoding UTF8 }
function Write-Header { param([string]$T); Write-Host ""; Write-Host "  $([string]::new([char]0x2550,60))" -Fore Cyan; Write-Host "  $T" -Fore White; Write-Host "  $([string]::new([char]0x2550,60))" -Fore Cyan; Write-Host "" }
function Write-Step { param([string]$S,[string]$M,[string]$St="INFO"); $c=@{OK="Green";WARN="Yellow";ERROR="Red";DEL="Magenta";INFO="White";PASS="Green";FAIL="Red"}[$St]; if(!$c){$c="White"}; $i=@{OK="[+]";WARN="[!]";ERROR="[-]";DEL="[x]";INFO="[i]";PASS="[OK]";FAIL="[!!]"}[$St]; if(!$i){$i="[i]"}; Write-Host "  $i $M" -Fore $c; Write-Log "$St - $M" }
function Run-Slmgr { param([string]$A,[string]$D); Write-Step "INFO" "$D..."; try{$p=Start-Process cscript.exe -Arg "//NoLogo",$Script:Slmgr,$A -Wait -PassThru -Win Hidden; if($p.ExitCode-eq 0){Write-Step "OK" "$D - OK" "OK"}else{Write-Step "WARN" "$D - Co the da thuc hien" "WARN"}}catch{Write-Step "ERROR" "$D - Loi: $_" "ERROR"} }

# ============================================================
#  PHASE 1: THU THAP THONG TIN HE THONG
# ============================================================
function Get-SystemInventory {
    Write-Header "PHASE 1: THU THAP THONG TIN HE THONG"
    $sys = @{}
    Write-Step "INFO" "Dang thu thap thong tin Windows..."
    $nt = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -EA SilentlyContinue
    $sys.ProductName=$nt.ProductName; $sys.DisplayVersion=$nt.DisplayVersion
    $sys.CurrentBuild=$nt.CurrentBuild; $sys.UBR=$nt.UBR
    Write-Host "  May tinh:      $env:COMPUTERNAME" -Fore White
    Write-Host "  San pham:      $($sys.ProductName)" -Fore White
    Write-Host "  Build:         $($sys.CurrentBuild).$($sys.UBR) ($($sys.DisplayVersion))" -Fore White

    Write-Step "INFO" "Dang kiem tra edition..."
    & DISM /Online /Get-CurrentEdition 2>&1 | ForEach-Object { if($_ -match "Current Edition\s*:\s*(.+)"){$sys.CurrentEdition=$Matches[1].Trim(); Write-Host "  Edition:       $($sys.CurrentEdition)" -Fore Cyan} }
    $sys.TargetEditions=@(); & DISM /Online /Get-TargetEditions 2>&1 | ForEach-Object { if($_ -match "Target Edition\s*:\s*(.+)"){$sys.TargetEditions+=$Matches[1].Trim()} }
    if($sys.TargetEditions.Count -gt 0){Write-Host "  Nang cap duoc: $($sys.TargetEditions -join ', ')" -Fore Green}
    Write-Host ""

    Write-Step "INFO" "Dang kiem tra phan cung..."
    $cpu=Get-CimInstance Win32_Processor -EA SilentlyContinue|Select -First 1
    if($cpu){$sys.CPU=$cpu.Name; $sys.CPUCores=$cpu.NumberOfCores; Write-Host "  CPU:           $($sys.CPU) ($($sys.CPUCores) cores)" -Fore White}
    $ram=[math]::Round((Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue).TotalPhysicalMemory/1GB,1); $sys.RAM_GB=$ram
    Write-Host "  RAM:           $ram GB" -Fore White
    $disk=Get-Disk|?{$_.IsSystem-eq $true}|Select -First 1
    if($disk){$sys.DiskSize_GB=[math]::Round($disk.Size/1GB,0); $sys.PartitionStyle=$disk.PartitionStyle; Write-Host "  Disk:          $($sys.DiskSize_GB) GB ($($sys.PartitionStyle))" -Fore White}
    $bios=Get-CimInstance Win32_BIOS -EA SilentlyContinue; if($bios){$sys.BIOSVersion=$bios.SMBIOSBIOSVersion; $sys.BIOSManufacturer=$bios.Manufacturer; Write-Host "  BIOS:          $($sys.BIOSManufacturer) $($sys.BIOSVersion)" -Fore White}
    $mb=Get-CimInstance Win32_BaseBoard -EA SilentlyContinue; if($mb){$sys.Motherboard="$($mb.Manufacturer) $($mb.Product)"; Write-Host "  Mainboard:     $($sys.Motherboard)" -Fore White}
    try{$tpm=Get-Tpm -EA SilentlyContinue; if($tpm){$sys.TPMPresent=$tpm.TpmPresent;$sys.TPMReady=$tpm.TpmReady;$sys.TPMVersion=$tpm.SpecVersion; Write-Host "  TPM:           Present=$($tpm.TpmPresent) Version=$($tpm.SpecVersion)" -Fore White}}catch{$sys.TPMPresent=$false}
    try{$sys.SecureBoot=Confirm-SecureBootUEFI -EA SilentlyContinue}catch{$sys.SecureBoot=$false}
    Write-Host "  Secure Boot:   $($sys.SecureBoot)" -Fore White
    $fw=Get-ComputerInfo -Property BiosFirmwareType -EA SilentlyContinue; if($fw){$sys.BootMode=$fw.BiosFirmwareType; Write-Host "  Boot Mode:     $($sys.BootMode)" -Fore White}
    Write-Host ""
    $Script:AuditReport.SystemInfo=$sys; return $sys
}

# ============================================================
#  PHASE 2: KIEM TRA DIEU KIEN WINDOWS 11
# ============================================================
function Test-Windows11Compatibility {
    Write-Header "PHASE 2: KIEM TRA DIEU KIEN WINDOWS 11"
    $sys=$Script:AuditReport.SystemInfo; $ready=@{Pass=0;Fail=0;Details=@()}
    function Check-Item { param([string]$N,[bool]$P,[string]$D); if($P){Write-Step "PASS" "$N - $D" "PASS";$ready.Pass++}else{Write-Step "FAIL" "$N - $D" "FAIL";$ready.Fail++}; $ready.Details+=@{Item=$N;Status=$(if($P){"PASS"}else{"FAIL"});Detail=$D} }

    Check-Item "TPM 2.0" ($sys.TPMPresent-eq $true -and ($sys.TPMVersion-match "^2\." -or $sys.TPMReady-eq $true)) $(if($sys.TPMPresent){"Version: $($sys.TPMVersion)"}else{"Khong tim thay"})
    Check-Item "Secure Boot" ($sys.SecureBoot-eq $true) $(if($sys.SecureBoot){"Enabled"}else{"Disabled"})
    Check-Item "GPT Disk" ($sys.PartitionStyle-eq "GPT") "$($sys.PartitionStyle)"
    Check-Item "UEFI Boot" ($sys.BootMode-match "Uefi") "$($sys.BootMode)"
    Check-Item "RAM >= 4GB" ($sys.RAM_GB-ge 4) "$($sys.RAM_GB) GB"
    Check-Item "Storage >= 64GB" ($sys.DiskSize_GB-ge 64) "$($sys.DiskSize_GB) GB"
    Check-Item "CPU ho tro" $true "$($sys.CPU)"

    Write-Host ""
    if($ready.Fail-eq 0){Write-Host "  -> May tinh DAT yeu cau Windows 11" -Fore Green}else{Write-Host "  -> CHUA DAT $($ready.Fail) yeu cau" -Fore Red}
    $Script:AuditReport.Win11Ready=$ready
}

# ============================================================
#  PHASE 3: KIEM TRA BAN QUYEN
# ============================================================
function Get-LicenseAudit {
    Write-Header "PHASE 3: KIEM TRA BAN QUYEN"
    $winLic=@{Status="Unknown";Channel="Unknown";Description="";PartialKey="";KMSMachine="";Licensed=$false;OEMKey=""}

    Write-Step "INFO" "Dang kiem tra ban quyen Windows..."
    $dli=& cscript //NoLogo $Script:Slmgr /dli 2>&1
    foreach($l in $dli){
        if($l -match "License Status:\s*(.+)"){$winLic.Status=$Matches[1].Trim()}
        if($l -match "Partial Product Key:\s*(.+)"){$winLic.PartialKey=$Matches[1].Trim()}
        if($l -match "Product Key Channel:\s*(.+)"){$winLic.Channel=$Matches[1].Trim()}
        if($l -match "Description:\s*(.+)"){$winLic.Description=$Matches[1].Trim()}
        if($l -match "KMS Machine Name:\s*(.+)"){$winLic.KMSMachine=$Matches[1].Trim()}
    }
    $xpr=& cscript //NoLogo $Script:Slmgr /xpr 2>&1; $winLic.Expiration=($xpr|?{$_-match "\S"}|Select -Last 1)
    $winLic.Licensed=($winLic.Status-match "Licensed")
    try{$winLic.OEMKey=(Get-CimInstance -ClassName SoftwareLicensingService -EA SilentlyContinue).OA3xOriginalProductKey}catch{}

    $sc=if($winLic.Licensed){"Green"}elseif($winLic.Status-match "Notification"){"Yellow"}else{"Red"}}
    Write-Host "  ── Windows License ─────────────────────────────────────" -Fore Cyan
    Write-Host "  Trang thai:    " -No; Write-Host $winLic.Status -Fore $sc
    Write-Host "  Channel:       $($winLic.Channel)" -Fore White
    Write-Host "  Mo ta:         $($winLic.Description)" -Fore White
    Write-Host "  Key (5 kt):    $($winLic.PartialKey)" -Fore White
    Write-Host "  Het han:       $($winLic.Expiration)" -Fore White
    if($winLic.OEMKey){Write-Host "  OEM Key:       $($winLic.OEMKey)" -Fore Green}
    if($winLic.KMSMachine){Write-Host "  KMS Server:    $($winLic.KMSMachine)" -Fore Yellow}
    $Script:AuditReport.Windows=$winLic; Write-Host ""

    # Office
    Write-Step "INFO" "Dang kiem tra ban quyen Office..."
    $officeList=@()
    $osppPaths=@("$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS","${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS","$env:ProgramFiles\Microsoft Office\Office15\OSPP.VBS")
    foreach($ospp in $osppPaths){
        if(Test-Path $ospp){
            Write-Host "  ── Office ───────────────────────────────────────────────" -Fore Cyan
            $out=& cscript //NoLogo $ospp /dstatus 2>&1; $cur=@{}
            foreach($l in $out){
                if($l -match "LICENSE NAME:\s*(.+)"){$cur.LicenseName=$Matches[1].Trim()}
                if($l -match "LICENSE STATUS:\s*(.+)"){$cur.LicenseStatus=$Matches[1].Trim()}
                if($l -match "REMAINING GRACE:\s*(.+)"){$cur.Grace=$Matches[1].Trim()}
                if($l -match "Last 5 characters.*:\s*(.+)"){$cur.PartialKey=$Matches[1].Trim()}
                if($l -match "KMS machine name:\s*(.+)"){$cur.KMSMachine=$Matches[1].Trim()}
                if($l -match "---"){
                    if($cur.LicenseName){$officeList+=$cur.Clone(); $oc=if($cur.LicenseStatus-match "LICENSED"){"Green"}else{"Yellow"}; Write-Host "  $($cur.LicenseName): " -No; Write-Host $cur.LicenseStatus -Fore $oc; if($cur.KMSMachine){Write-Host "  KMS: $($cur.KMSMachine)" -Fore Yellow}}
                    $cur=@{}
                }
            }
            if($cur.LicenseName){$officeList+=$cur.Clone(); $oc=if($cur.LicenseStatus-match "LICENSED"){"Green"}else{"Yellow"}; Write-Host "  $($cur.LicenseName): " -No; Write-Host $cur.LicenseStatus -Fore $oc}
        }
    }
    if($officeList.Count-eq 0){Write-Host "  Khong tim thay Office" -Fore DarkGray}
    $Script:AuditReport.Office=$officeList; Write-Host ""

    # Other products
    $sqlSvc=Get-Service *sql* -EA SilentlyContinue; if($sqlSvc){Write-Host "  SQL Server:    $($sqlSvc.Count) dich vu" -Fore White}
    Write-Host ""
}

# ============================================================
#  PHASE 4: PHAT HIEN KICH HOAT KHONG HOP LE
# ============================================================
function Detect-InvalidActivation {
    Write-Header "PHASE 4: PHAT HIEN KICH HOAT KHONG HOP LE"
    $issues=@()

    Write-Step "INFO" "Kiem tra KMS Server..."
    $wl=$Script:AuditReport.Windows
    if($wl.KMSMachine){$issues+=@{Type="KMS";Severity="WARN";Detail="Windows KMS: $($wl.KMSMachine)"}; Write-Step "WARN" "Windows KMS: $($wl.KMSMachine)" "WARN"}else{Write-Step "OK" "Khong co KMS Server" "OK"}
    foreach($o in $Script:AuditReport.Office){if($o.KMSMachine){$issues+=@{Type="KMS";Severity="WARN";Detail="Office KMS: $($o.KMSMachine)"}; Write-Step "WARN" "Office KMS: $($o.KMSMachine)" "WARN"}}

    Write-Step "INFO" "Kiem tra channel..."
    if($wl.Channel-in @("Volume_KMSCLIENT","Volume_MAK")){$issues+=@{Type="CHANNEL";Severity="WARN";Detail="Channel: $($wl.Channel)"}; Write-Step "WARN" "Channel: $($wl.Channel)" "WARN"}else{Write-Step "OK" "Channel: $($wl.Channel)" "OK"}

    Write-Step "INFO" "Kiem tra DNS KMS..."
    try{$dns=nslookup -type=srv _vlmcs._tcp 2>&1; if($dns-match "service"){$issues+=@{Type="DNS";Severity="WARN";Detail="DNS KMS record phat hien"}; Write-Step "WARN" "DNS KMS record phat hien" "WARN"}else{Write-Step "OK" "Khong co DNS KMS" "OK"}}catch{Write-Step "OK" "Khong the kiem tra DNS" "OK"}

    Write-Step "INFO" "Kiem tra Scheduled Tasks..."
    Get-ScheduledTask -EA SilentlyContinue | ForEach-Object { foreach($kw in $Script:KMSKeywords){if($_.TaskName-match $kw){$issues+=@{Type="TASK";Severity="WARN";Detail="Task: $($_.TaskName)"}; Write-Step "WARN" "Task: $($_.TaskName)" "WARN"}}}
    if(!($issues|?{$_.Type-eq "TASK"})){Write-Step "OK" "Tasks sach" "OK"}

    Write-Step "INFO" "Kiem tra phan mem..."
    foreach($key in @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")){
        Get-ItemProperty $key -EA SilentlyContinue | ForEach-Object { if($_.DisplayName){foreach($kw in $Script:KMSKeywords){if($_.DisplayName-match $kw){$issues+=@{Type="PROGRAM";Severity="ERROR";Detail="Phan mem: $($_.DisplayName)"}; Write-Step "WARN" "Phan mem: $($_.DisplayName)" "WARN"}}}}
    }
    if(!($issues|?{$_.Type-eq "PROGRAM"})){Write-Step "OK" "Phan mem sach" "OK"}

    Write-Step "INFO" "Kiem tra Hosts..."
    if(Test-Path $Script:HostsPath){Get-Content $Script:HostsPath | ForEach-Object { foreach($kw in @("activation","kms","crack")){if($_-match $kw-and $_-notmatch "^#"){$issues+=@{Type="HOSTS";Severity="WARN";Detail="Hosts: $($_.Trim())"}; Write-Step "WARN" "Hosts: $($_.Trim())" "WARN"}}}}
    if(!($issues|?{$_.Type-eq "HOSTS"})){Write-Step "OK" "Hosts sach" "OK"}

    Write-Step "INFO" "Kiem tra Defender..."
    try{$mp=Get-MpPreference -EA SilentlyContinue; if($mp.DisableRealtimeMonitoring){$issues+=@{Type="DEFENDER";Severity="WARN";Detail="Defender bi tat"}; Write-Step "WARN" "Defender bi tat" "WARN"}else{Write-Step "OK" "Defender OK" "OK"}}catch{}

    Write-Step "INFO" "Kiem tra file KMS..."
    $kfc=0; foreach($d in $Script:KMSDirectories){if(Test-Path $d){$kfc++; Write-Step "WARN" "Tim thay: $d" "WARN"}}
    foreach($f in $Script:KMSFiles){if(Test-Path $f){$kfc++; Write-Step "WARN" "Tim thay: $f" "WARN"}}
    if($kfc-eq 0){Write-Step "OK" "File KMS sach" "OK"}

    Write-Step "INFO" "Kiem tra Registry..."
    $rc=0; foreach($e in $Script:KMSRegistryKeys){if($e.Name){if(Get-ItemProperty $e.Path -Name $e.Name -EA SilentlyContinue){$rc++}}else{if(Test-Path $e.Path){$rc++}}}
    if($rc-eq 0){Write-Step "OK" "Registry sach" "OK"}else{Write-Step "WARN" "Phat hien $rc registry entries" "WARN"}

    Write-Host ""
    if($issues.Count-eq 0){Write-Host "  -> He thong SACH" -Fore Green}else{Write-Host "  -> Phat hien $($issues.Count) van de" -Fore Yellow}
    $Script:AuditReport.Issues=$issues
}

# ============================================================
#  PHASE 5: XAC NHAN & LAM SACH
# ============================================================
function Confirm-And-Cleanup {
    Write-Header "PHASE 5: XAC NHAN & LAM SACH"
    $issues=$Script:AuditReport.Issues
    if($issues.Count-eq 0){Write-Host "  He thong sach. Khong can lam sach." -Fore Green; return}

    Write-Host "  Van de phat hien:" -Fore Yellow
    foreach($i in $issues){$c=if($i.Severity-eq "ERROR"){"Red"}elseif($i.Severity-eq "WARN"){"Yellow"}else{"White"}; Write-Host "    [$($i.Type)] $($i.Detail)" -Fore $c}
    Write-Host ""

    $hasKMS=$issues|?{$_.Type-eq "KMS"}; $hasTasks=$issues|?{$_.Type-eq "TASK"}; $hasHosts=$issues|?{$_.Type-eq "HOSTS"}; $hasDef=$issues|?{$_.Type-eq "DEFENDER"}
    $n=0; $opts=@()
    if($hasKMS){$n++; Write-Host "    [$n] Go cau hinh KMS" -Fore White; $opts+="RemoveKMS"}
    if($hasTasks){$n++; Write-Host "    [$n] Xoa Tasks dang ngo" -Fore White; $opts+="RemoveTasks"}
    if($hasHosts){$n++; Write-Host "    [$n] Khoi phuc Hosts" -Fore White; $opts+="RestoreHosts"}
    if($hasDef){$n++; Write-Host "    [$n] Khoi phuc Defender" -Fore White; $opts+="RestoreDef"}
    $n++; Write-Host "    [$n] Sua loi he thong (DISM+SFC)" -Fore White; $opts+="Repair"
    $n++; Write-Host "    [$n] THUC HIEN TAT CA" -Fore Green; $opts+="All"
    Write-Host "    [0] Bo qua" -Fore Red; Write-Host ""

    $ch=Read-Host "  Chon (so, nhieu so cach phay, hoac 'all')"
    if($ch-eq "0"-or $ch-eq ""){return}
    if($ch-eq "all"-or $ch-eq "$n"){$acts=$opts|?{$_-ne "All"}}else{$idxs=$ch-split "[,\s]+"|%{[int]$_-1}; $acts=@(); foreach($i in $idxs){if($i-ge 0-and $i-lt $opts.Count){$acts+=$opts[$i]}}}

    # Execute cleanup
    foreach($act in $acts){
        switch($act){
            "RemoveKMS" {
                Write-Step "DEL" "Go cau hinh KMS..."
                Run-Slmgr "/upk" "Go Key"; Run-Slmgr "/cpky" "Xoa Registry Key"; Run-Slmgr "/ckms" "Xoa KMS"; Run-Slmgr "/rearm" "Reset"
                foreach($e in $Script:KMSRegistryKeys){try{if($e.Name){Remove-ItemProperty $e.Path -Name $e.Name -Force -EA SilentlyContinue}else{Remove-Item $e.Path -Recurse -Force -EA SilentlyContinue}}catch{}}
                foreach($d in $Script:KMSDirectories){if(Test-Path $d){Remove-Item $d -Recurse -Force -EA SilentlyContinue}}
                foreach($f in $Script:KMSFiles){if(Test-Path $f){takeown /f $f 2>$null|Out-Null; icacls $f /grant administrators:F 2>$null|Out-Null; Remove-Item $f -Force -EA SilentlyContinue}}
            }
            "RemoveTasks" { Write-Step "DEL" "Xoa Tasks..."; foreach($t in $Script:KMSTasks){Unregister-ScheduledTask $t -Confirm:$false -EA SilentlyContinue} }
            "RestoreHosts" {
                Write-Step "DEL" "Khoi phuc Hosts..."
                if(Test-Path $Script:HostsPath){Copy-Item $Script:HostsPath $Script:HostsBackup -Force -EA SilentlyContinue; $c=Get-Content $Script:HostsPath; $p=@("activation","kms","crack","kmspico","kmsauto"); $cl=$c|?{$l=$_;$k=$true;foreach($pp in $p){if($l-match $pp-and $l-notmatch "^#"){$k=$false;break}};$k}; $cl|Set-Content $Script:HostsPath -Force -Encoding ASCII}
            }
            "RestoreDef" { Write-Step "DEL" "Khoi phuc Defender..."; try{Set-MpPreference -DisableRealtimeMonitoring $false -EA SilentlyContinue}catch{} }
            "Repair" { Write-Step "INFO" "Sua loi he thong..."; & DISM /Online /Cleanup-Image /RestoreHealth 2>&1|Out-Null; & sfc /scannow 2>&1|Out-Null; Write-Step "OK" "Sua loi xong" "OK" }
        }
    }
    try{Set-Service wuauserv -StartupType Automatic -EA SilentlyContinue; Start-Service wuauserv -EA SilentlyContinue}catch{}
    Write-Host ""; Write-Host "  HOAN TAT LAM SACH!" -Fore Green
}

# ============================================================
#  PHASE 6-7: CHUYEN EDITION & KICH HOAT
# ============================================================
function Invoke-EditionUpgrade {
    Write-Header "PHASE 6: CHUYEN EDITION"
    $sys=$Script:AuditReport.SystemInfo
    if($sys.TargetEditions-notcontains "Professional"){Write-Step "WARN" "Khong the nang cap len Pro" "WARN"; return}
    Write-Host "  Hien tai: $($sys.CurrentEdition)" -Fore Cyan
    Write-Host "  [1] Generic key  [2] Key Pro + kich hoat  [3] DISM + key  [0] Bo qua" -Fore White
    $ch=Read-Host "  Chon [0-3]"
    switch($ch){
        "1"{& cscript //NoLogo $Script:Slmgr /ipk $Script:GenericProKey 2>&1|Out-Null; & cscript //NoLogo $Script:Slmgr /ato 2>&1|Out-Null; Write-Step "OK" "Da chuyen sang Pro" "OK"}
        "2"{$k=Read-Host "  Nhap key Pro"; if(![string]::IsNullOrWhiteSpace($k)){$ck=$k.Trim()-replace '\s+',''; & cscript //NoLogo $Script:Slmgr /ipk $ck 2>&1|Out-Null; & cscript //NoLogo $Script:Slmgr /ato 2>&1|Out-Null}}
        "3"{$k=Read-Host "  Nhap key Pro"; if(![string]::IsNullOrWhiteSpace($k)){$ck=$k.Trim()-replace '\s+',''; & DISM /Online /Cleanup-Image /RestoreHealth 2>&1|Out-Null; & DISM /Online /Set-Edition:Professional /ProductKey:$ck /AcceptEula 2>&1|Out-Null}}
    }
}

function Invoke-Activation {
    Write-Header "PHASE 7: KICH HOAT"
    Write-Host "  [1] Nhap key + kich hoat online  [2] DISM  [3] OEM Key (BIOS)  [0] Bo qua" -Fore White
    $ch=Read-Host "  Chon [0-3]"
    switch($ch){
        "1"{$k=Read-Host "  Nhap key"; if(![string]::IsNullOrWhiteSpace($k)){$ck=$k.Trim()-replace '\s+',''; & cscript //NoLogo $Script:Slmgr /ipk $ck 2>&1|Out-Null; & cscript //NoLogo $Script:Slmgr /ato 2>&1|Out-Null; if($LASTEXITCODE-eq 0){Write-Step "OK" "Kich hoat thanh cong!" "OK"}else{Write-Step "WARN" "Kich hoat that bai" "WARN"}}}
        "2"{$k=Read-Host "  Nhap key"; if(![string]::IsNullOrWhiteSpace($k)){& DISM /Online /Set-Edition:Professional /ProductKey:$($k.Trim()-replace '\s+','') /AcceptEula 2>&1|Out-Null}}
        "3"{$oem=(Get-CimInstance -ClassName SoftwareLicensingService -EA SilentlyContinue).OA3xOriginalProductKey; if($oem){Write-Step "INFO" "OEM Key: $oem"; & cscript //NoLogo $Script:Slmgr /ipk $oem 2>&1|Out-Null; & cscript //NoLogo $Script:Slmgr /ato 2>&1|Out-Null}else{Write-Step "WARN" "Khong co OEM Key" "WARN"}}
    }
}

# ============================================================
#  PHASE 8: XAC MINH
# ============================================================
function Verify-Activation {
    Write-Header "PHASE 8: XAC MINH"
    Write-Host "  ── Thoi han ─────────────────────────────────────────────" -Fore Cyan
    & cscript //NoLogo $Script:Slmgr /xpr 2>&1 | ForEach-Object { if($_.Trim()){Write-Host "  $_"} }
    Write-Host ""
    Write-Host "  ── Chi tiet ─────────────────────────────────────────────" -Fore Cyan
    & cscript //NoLogo $Script:Slmgr /dli 2>&1 | ForEach-Object { if($_.Trim()){Write-Host "  $_"} }
    Write-Host ""
    $dli=& cscript //NoLogo $Script:Slmgr /dli 2>&1; $ls=""; foreach($l in $dli){if($l -match "License Status:\s*(.+)"){$ls=$Matches[1].Trim()}}
    if($ls-match "Licensed"){Write-Step "PASS" "Windows da kich hoat hop le!" "PASS"; $Script:AuditReport.ActivationResult=@{Status="Licensed";Permanent=$true}}
    else{Write-Step "FAIL" "Chua kich hoat: $ls" "FAIL"; $Script:AuditReport.ActivationResult=@{Status=$ls;Permanent=$false}}
}

# ============================================================
#  PHASE 9: SUC KHOE HE THONG
# ============================================================
function Test-SystemHealth {
    Write-Header "PHASE 9: SUC KHOE HE THONG"
    $h=@{}
    $wu=Get-Service wuauserv -EA SilentlyContinue
    if($wu-and $wu.Status-eq "Running"){Write-Step "PASS" "Windows Update: Running" "PASS"; $h.WU="OK"}else{Write-Step "WARN" "Windows Update: $($wu.Status)" "WARN"; $h.WU=$wu.Status}
    $sp=Get-Service sppsvc -EA SilentlyContinue
    if($sp-and $sp.Status-eq "Running"){Write-Step "PASS" "Software Protection: Running" "PASS"; $h.SP="OK"}else{Write-Step "WARN" "Software Protection: $($sp.Status)" "WARN"; $h.SP=$sp.Status}
    try{$def=Get-MpComputerStatus -EA SilentlyContinue; if($def.AntivirusEnabled){Write-Step "PASS" "Defender: Enabled" "PASS"; $h.Def="OK"}else{Write-Step "WARN" "Defender: Disabled" "WARN"; $h.Def="Disabled"}}catch{$h.Def="Unknown"}
    try{$fw=Get-NetFirewallProfile -EA SilentlyContinue; if(($fw|?{$_.Enabled}).Count -gt 0){Write-Step "PASS" "Firewall: Enabled" "PASS"; $h.FW="OK"}else{Write-Step "WARN" "Firewall: Disabled" "WARN"; $h.FW="Disabled"}}catch{$h.FW="Unknown"}
    Write-Host ""
    $Script:AuditReport.HealthStatus=$h
}

# ============================================================
#  PHASE 10: XUAT BAO CAO
# ============================================================
function Export-AuditReport {
    Write-Header "PHASE 10: XUAT BAO CAO"
    if(!(Test-Path $Script:ReportDir)){New-Item -ItemType Directory $Script:ReportDir -Force|Out-Null}
    $ts=Get-Date -Format "yyyyMMdd_HHmmss"; $mn=$env:COMPUTERNAME

    # TXT
    Write-Step "INFO" "Xuat TXT..."
    $txt=@(); $txt+="="*60; $txt+="MICROSOFT LICENSE AUDIT REPORT"; $txt+="="*60
    $txt+="May tinh: $mn"; $txt+="Ngay: $($Script:AuditReport.AuditDate)"; $txt+=""
    $sys=$Script:AuditReport.SystemInfo
    $txt+="--- HE THONG ---"; $txt+="San pham: $($sys.ProductName)"; $txt+="Edition: $($sys.CurrentEdition)"; $txt+="Build: $($sys.CurrentBuild).$($sys.UBR)"
    $txt+="CPU: $($sys.CPU)"; $txt+="RAM: $($sys.RAM_GB) GB"; $txt+="Disk: $($sys.DiskSize_GB) GB ($($sys.PartitionStyle))"
    $txt+="TPM: $($sys.TPMPresent) / $($sys.TPMVersion)"; $txt+="Secure Boot: $($sys.SecureBoot)"; $txt+=""
    $wl=$Script:AuditReport.Windows
    $txt+="--- WINDOWS LICENSE ---"; $txt+="Trang thai: $($wl.Status)"; $txt+="Channel: $($wl.Channel)"; $txt+="Key: $($wl.PartialKey)"
    if($wl.KMSMachine){$txt+="KMS: $($wl.KMSMachine)"}; $txt+=""
    if($Script:AuditReport.Office.Count -gt 0){$txt+="--- OFFICE ---"; foreach($o in $Script:AuditReport.Office){$txt+="$($o.LicenseName): $($o.LicenseStatus)"}
    $txt+=""}
    if($Script:AuditReport.Issues.Count -gt 0){$txt+="--- VAN DE ---"; foreach($i in $Script:AuditReport.Issues){$txt+="[$($i.Severity)] $($i.Type): $($i.Detail)"}; $txt+=""}
    $txt+="--- WINDOWS 11 ---"; foreach($d in $Script:AuditReport.Win11Ready.Details){$txt+="$($d.Item): $($d.Status) - $($d.Detail)"}; $txt+=""
    $txt+="="*60
    $txtPath=Join-Path $Script:ReportDir "Audit_${mn}_${ts}.txt"
    $txt|Out-File $txtPath -Encoding UTF8; Write-Step "OK" "TXT: $txtPath" "OK"

    # JSON
    Write-Step "INFO" "Xuat JSON..."
    $jsonPath=Join-Path $Script:ReportDir "Audit_${mn}_${ts}.json"
    $Script:AuditReport|ConvertTo-Json -Depth 10|Out-File $jsonPath -Encoding UTF8; Write-Step "OK" "JSON: $jsonPath" "OK"

    # HTML
    Write-Step "INFO" "Xuat HTML..."
    $htmlPath=Join-Path $Script:ReportDir "Audit_${mn}_${ts}.html"
    $r=$Script:AuditReport; $s=$r.SystemInfo; $w=$r.Windows
    $sc=if($w.Licensed){"#3fb950"}elseif($w.Status-match "Notification"){"#d29922"}else{"#f85149"}
    $ir=""; foreach($i in $r.Issues){$ic=if($i.Severity-eq "ERROR"){"#f85149"}elseif($i.Severity-eq "WARN"){"#d29922"}else{"#58a6ff"}; $ir+="<tr><td style=`"color:$ic`">$($i.Severity)</td><td>$($i.Type)</td><td>$($i.Detail)</td></tr>"}
    $wr=""; foreach($d in $r.Win11Ready.Details){$wc=if($d.Status-eq "PASS"){"#3fb950"}else{"#f85149"}; $wr+="<tr><td>$($d.Item)</td><td style=`"color:$wc; font-weight:bold`">$($d.Status)</td><td>$($d.Detail)</td></tr>"}
    $hr=""; foreach($k in $r.HealthStatus.Keys){$hc=if($r.HealthStatus[$k]-eq "OK"){"#3fb950"}else{"#d29922"}; $hr+="<tr><td>$k</td><td style=`"color:$hc`">$($r.HealthStatus[$k])</td></tr>"}
    $or=""; foreach($o in $r.Office){$oc=if($o.LicenseStatus-match "LICENSED"){"#3fb950"}else{"#d29922"}; $or+="<tr><td>$($o.LicenseName)</td><td style=`"color:$oc`">$($o.LicenseStatus)</td><td>$($o.PartialKey)</td><td>$($o.KMSMachine)</td></tr>"}

    $html=@"<!DOCTYPE html><html lang="vi"><head><meta charset="UTF-8"><title>Audit - $mn</title>
<style>body{font-family:-apple-system,sans-serif;background:#0d1117;color:#e6edf3;margin:0;padding:20px}.c{max-width:1000px;margin:0 auto}h1{color:#58a6ff;border-bottom:2px solid #30363d;padding-bottom:10px}h2{color:#58a6ff;margin-top:30px}table{width:100%;border-collapse:collapse;margin:15px 0}th,td{padding:10px 14px;text-align:left;border-bottom:1px solid #30363d}th{background:#161b22;color:#58a6ff}.card{background:#161b22;border:1px solid #30363d;border-radius:8px;padding:20px;margin:15px 0}.grid{display:grid;grid-template-columns:1fr 1fr;gap:15px}.stat{padding:15px;background:#0d1117;border-radius:6px;text-align:center}.stat .v{font-size:2em;font-weight:bold;color:#3fb950}.stat .l{color:#8b949e;font-size:0.9em}.footer{text-align:center;padding:30px;color:#8b949e;font-size:0.85em;border-top:1px solid #30363d;margin-top:40px}</style></head><body><div class="c">
<h1>Microsoft License Audit Report</h1><p>May tinh: <strong>$mn</strong> | Ngay: <strong>$($r.AuditDate)</strong></p>
<div class="grid"><div class="card"><div class="stat"><div class="v">$($s.CurrentEdition)</div><div class="l">Windows Edition</div></div></div>
<div class="card"><div class="stat"><div class="v" style="color:$sc">$($w.Status)</div><div class="l">License Status</div></div></div></div>
<h2>He thong</h2><div class="card"><table><tr><th>Thuoc tinh</th><th>Gia tri</th></tr>
<tr><td>San pham</td><td>$($s.ProductName)</td></tr><tr><td>Build</td><td>$($s.CurrentBuild).$($s.UBR) ($($s.DisplayVersion))</td></tr>
<tr><td>CPU</td><td>$($s.CPU)</td></tr><tr><td>RAM</td><td>$($s.RAM_GB) GB</td></tr>
<tr><td>Disk</td><td>$($s.DiskSize_GB) GB ($($s.PartitionStyle))</td></tr>
<tr><td>TPM</td><td>$($s.TPMPresent) / $($s.TPMVersion)</td></tr>
<tr><td>Secure Boot</td><td>$($s.SecureBoot)</td></tr><tr><td>Boot Mode</td><td>$($s.BootMode)</td></tr>
</table></div>
<h2>Windows License</h2><div class="card"><table><tr><th>Thuoc tinh</th><th>Gia tri</th></tr>
<tr><td>Trang thai</td><td style="color:$sc; font-weight:bold">$($w.Status)</td></tr>
<tr><td>Channel</td><td>$($w.Channel)</td></tr><tr><td>Mo ta</td><td>$($w.Description)</td></tr>
<tr><td>Key</td><td>$($w.PartialKey)</td></tr><tr><td>Het han</td><td>$($w.Expiration)</td></tr>
$(if($w.OEMKey){"<tr><td>OEM Key</td><td>$($w.OEMKey)</td></tr>"})
$(if($w.KMSMachine){"<tr><td>KMS Server</td><td style='color:#f85149'>$($w.KMSMachine)</td></tr>"})
</table></div>
$(if($r.Office.Count-gt 0){"<h2>Office</h2><div class='card'><table><tr><th>San pham</th><th>Trang thai</th><th>Key</th><th>KMS</th></tr>$or</table></div>"})
<h2>Windows 11 ($($r.Win11Ready.Pass)/$($r.Win11Ready.Pass+$r.Win11Ready.Fail) PASS)</h2>
<div class="card"><table><tr><th>Tieu chi</th><th>Ket qua</th><th>Chi tiet</th></tr>$wr</table></div>
$(if($r.Issues.Count-gt 0){"<h2>Van de ($($r.Issues.Count))</h2><div class='card'><table><tr><th>Muc do</th><th>Loai</th><th>Chi tiet</th></tr>$ir</table></div>"})
<h2>Suc khoe</h2><div class="card"><table><tr><th>Thanh phan</th><th>Trang thai</th></tr>$hr</table></div>
<div class="footer"><p>Pho Tue SoftWare Solutions JSC | HiTechCloud - Microsoft Partner</p>
<p>Microsoft Genuine License Audit & Recovery Tool v2.0</p></div></div></body></html>"@
    $html|Out-File $htmlPath -Encoding UTF8; Write-Step "OK" "HTML: $htmlPath" "OK"

    Write-Host ""
    Write-Host "  Bao cao: $Script:ReportDir" -Fore Cyan; Write-Host ""
    $o=Read-Host "  Mo bao cao HTML? (Y/N)"
    if($o-eq 'Y'-or $o-eq 'y'){Start-Process $htmlPath}
}

# ============================================================
#  FULL AUDIT
# ============================================================
function Invoke-FullAudit {
    Get-SystemInventory; Test-Windows11Compatibility; Get-LicenseAudit; Detect-InvalidActivation
    Confirm-And-Cleanup; Invoke-EditionUpgrade; Invoke-Activation; Verify-Activation; Test-SystemHealth; Export-AuditReport
    Write-Host ""; Write-Host "  HOAN TAT KIEM TOAN & PHUC HOI!" -Fore Green; Write-Host ""
}

# ============================================================
#  CHUC NANG DON LE
# ============================================================
function Show-LicenseStatus { Write-Header "TRANG THAI LICENSE"; & cscript //NoLogo $Script:Slmgr /dlv; Write-Host ""; & cscript //NoLogo $Script:Slmgr /xpr; Write-Host "" }
function Check-WindowsEdition { Write-Header "PHIEN BAN WINDOWS"; & DISM /Online /Get-CurrentEdition 2>&1|%{if($_.Trim()){Write-Host "  $_"}}; Write-Host ""; & DISM /Online /Get-TargetEditions 2>&1|%{if($_.Trim()){Write-Host "  $_"}}; Write-Host ""; $oem=(Get-CimInstance -ClassName SoftwareLicensingService -EA SilentlyContinue).OA3xOriginalProductKey; if($oem){Write-Host "  OEM Key: $oem" -Fore Green}; Write-Host ""; & cscript //NoLogo $Script:Slmgr /xpr; Write-Host "" }
function Activate-NewLicense { Write-Header "NHAP KEY MOI"; $k=Read-Host "  Product Key"; if([string]::IsNullOrWhiteSpace($k)){return}; $ck=$k.Trim()-replace '\s+',''; & cscript //NoLogo $Script:Slmgr /ipk $ck 2>&1|Out-Null; if($LASTEXITCODE-eq 0){Write-Step "OK" "Nhap key OK" "OK"; & cscript //NoLogo $Script:Slmgr /ato 2>&1|Out-Null; if($LASTEXITCODE-eq 0){Write-Step "OK" "Kich hoat OK!" "OK"}else{Write-Step "WARN" "Kich hoat that bai" "WARN"}}else{Write-Step "WARN" "slmgr loi. Thu DISM..." "WARN"; & DISM /Online /Set-Edition:Professional /ProductKey:$ck /AcceptEula 2>&1|Out-Null}; Write-Host ""; & cscript //NoLogo $Script:Slmgr /xpr }
function Fix-SystemErrors { Write-Header "SUA LOI HE THONG"; Write-Step "INFO" "DISM RestoreHealth..."; & DISM /Online /Cleanup-Image /RestoreHealth 2>&1|Out-Null; Write-Step "OK" "DISM OK" "OK"; Write-Step "INFO" "SFC..."; & sfc /scannow 2>&1|Out-Null; Write-Step "OK" "SFC OK" "OK"; foreach($s in @("wuauserv","bits","cryptsvc","msiserver")){Stop-Service $s -Force -EA SilentlyContinue}; $sd="$env:SystemRoot\SoftwareDistribution"; $cr="$env:SystemRoot\System32\catroot2"; if(Test-Path $sd){Rename-Item $sd "${sd}.old" -Force -EA SilentlyContinue}; if(Test-Path $cr){Rename-Item $cr "${cr}.old" -Force -EA SilentlyContinue}; foreach($s in @("wuauserv","bits","cryptsvc","msiserver")){Start-Service $s -EA SilentlyContinue}; Write-Step "OK" "Da xoa cache WU" "OK"; $r=Read-Host "  Khoi dong lai? (Y/N)"; if($r-eq 'Y'){shutdown /r /t 10 /c "Sua loi he thong"} }
function Upgrade-HomeToPro { Write-Header "NANG CAP HOME->PRO"; $cr=& DISM /Online /Get-CurrentEdition 2>&1; $ce=""; foreach($l in $cr){if($l-match "Current Edition\s*:\s*(.+)"){$ce=$Matches[1].Trim()}}; Write-Host "  Hien tai: $ce" -Fore Cyan; if($ce-match "Professional|Enterprise|Education"){Write-Step "OK" "Da la Pro" "OK"; return}; Write-Host "  [1] Generic key  [2] Key Pro  [3] DISM  [0] Bo qua" -Fore White; $ch=Read-Host "  Chon"; switch($ch){"1"{& cscript //NoLogo $Script:Slmgr /ipk $Script:GenericProKey 2>&1|Out-Null; & cscript //NoLogo $Script:Slmgr /ato 2>&1|Out-Null}"2"{$k=Read-Host "  Key"; if(![string]::IsNullOrWhiteSpace($k)){$ck=$k.Trim()-replace '\s+',''; & cscript //NoLogo $Script:Slmgr /ipk $ck 2>&1|Out-Null; & cscript //NoLogo $Script:Slmgr /ato 2>&1|Out-Null}}"3"{$k=Read-Host "  Key"; if(![string]::IsNullOrWhiteSpace($k)){$ck=$k.Trim()-replace '\s+',''; & DISM /Online /Cleanup-Image /RestoreHealth 2>&1|Out-Null; & DISM /Online /Set-Edition:Professional /ProductKey:$ck /AcceptEula 2>&1|Out-Null}}}; $r=Read-Host "  Khoi dong lai? (Y/N)"; if($r-eq 'Y'){shutdown /r /t 10 /c "Nang cap Pro"} }
function Invoke-FullCleanup { Write-Header "LAM SACH TOAN BO"; Run-Slmgr "/upk" "Go Key"; Run-Slmgr "/cpky" "Xoa Registry"; Run-Slmgr "/ckms" "Xoa KMS"; Run-Slmgr "/rearm" "Reset"; foreach($e in $Script:KMSRegistryKeys){try{if($e.Name){Remove-ItemProperty $e.Path -Name $e.Name -Force -EA SilentlyContinue}else{Remove-Item $e.Path -Recurse -Force -EA SilentlyContinue}}catch{}}; foreach($d in $Script:KMSDirectories){if(Test-Path $d){Remove-Item $d -Recurse -Force -EA SilentlyContinue}}; foreach($t in $Script:KMSTasks){Unregister-ScheduledTask $t -Confirm:$false -EA SilentlyContinue}; if(Test-Path $Script:HostsPath){Copy-Item $Script:HostsPath $Script:HostsBackup -Force -EA SilentlyContinue; $c=Get-Content $Script:HostsPath; $p=@("activation","kms","crack","kmspico"); $cl=$c|?{$l=$_;$k=$true;foreach($pp in $p){if($l-match $pp-and $l-notmatch "^#"){$k=$false;break}};$k}; $cl|Set-Content $Script:HostsPath -Force -Encoding ASCII}; try{Set-Service wuauserv -StartupType Automatic -EA SilentlyContinue; Start-Service wuauserv -EA SilentlyContinue}catch{}; Write-Host ""; Write-Host "  HOAN TAT!" -Fore Green; $r=Read-Host "  Khoi dong lai? (Y/N)"; if($r-eq 'Y'){shutdown /r /t 10 /c "Lam sach he thong"} }

# ============================================================
#  MENU
# ============================================================
function Show-Menu {
    $cont=$true
    while($cont){
        Clear-Host
        Write-Host ""
        Write-Host "  $([string]::new([char]0x2550,65))" -Fore Cyan
        Write-Host "   MICROSOFT GENUINE LICENSE AUDIT & RECOVERY TOOL v2.0" -Fore White
        Write-Host "   Pho Tue SoftWare Solutions JSC | HiTechCloud" -Fore DarkGray
        Write-Host "  $([string]::new([char]0x2550,65))" -Fore Cyan
        Write-Host ""
        Write-Host "   --- KIEM TOAN & PHUC HOI ---" -Fore Yellow
        Write-Host "   [1] Kiem toan toan dien (Audit + Cleanup + Activate + Report)" -Fore Green
        Write-Host "   [2] Chi kiem tra thong tin he thong" -Fore White
        Write-Host "   [3] Chi phat hien van de ban quyen" -Fore White
        Write-Host "   [4] Chi lam sach he thong (can xac nhan)" -Fore White
        Write-Host "   [5] Chi kiem tra suc khoe he thong" -Fore White
        Write-Host "   [6] Xuat bao cao (HTML/JSON/TXT)" -Fore White
        Write-Host ""
        Write-Host "   --- CHUC NANG DON LE ---" -Fore Yellow
        Write-Host "   [7] Kiem tra phien ban Windows" -Fore White
        Write-Host "   [8] Kiem tra trang thai License" -Fore White
        Write-Host "   [9] Nhap & kich hoat key moi" -Fore White
        Write-Host "   [A] Sua loi he thong (DISM + SFC)" -Fore White
        Write-Host "   [B] Nang cap Home -> Pro" -Fore White
        Write-Host ""
        Write-Host "   [0] Thoat" -Fore Red
        Write-Host ""
        Write-Host "  $([string]::new([char]0x2550,65))" -Fore Cyan
        Write-Host ""
        $ch=Read-Host "  Chon"
        switch($ch){
            "1"{Invoke-FullAudit}
            "2"{Get-SystemInventory; Test-Windows11Compatibility; Get-LicenseAudit}
            "3"{Get-LicenseAudit; Detect-InvalidActivation}
            "4"{Detect-InvalidActivation; Confirm-And-Cleanup}
            "5"{Test-SystemHealth}
            "6"{Get-SystemInventory; Get-LicenseAudit; Test-Windows11Compatibility; Detect-InvalidActivation; Test-SystemHealth; Export-AuditReport}
            "7"{Check-WindowsEdition}
            "8"{Show-LicenseStatus}
            "9"{Activate-NewLicense}
            "a"{Fix-SystemErrors}
            "b"{Upgrade-HomeToPro}
            "0"{$cont=$false}
            default{Write-Host "  [!] Khong hop le." -Fore Red; Start-Sleep 1}
        }
        if($cont){Write-Host ""; pause}
    }
    Write-Host ""; Write-Host "  Cam on ban da su dung Tool!" -Fore Cyan; Write-Host "  Pho Tue SoftWare Solutions JSC | Hotline: 0865.920.041" -Fore DarkGray; Write-Host ""
}

# ============================================================
#  BAT DAU
# ============================================================
Write-Host ""
Write-Host "  Dang tai Microsoft Genuine License Audit & Recovery Tool v2.0..." -Fore Cyan
Write-Host "  Pho Tue SoftWare Solutions JSC | HiTechCloud" -Fore DarkGray
Write-Host ""
Show-Menu
