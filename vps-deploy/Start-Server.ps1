<#
.SYNOPSIS
    VPS Script Server - Phuc vu file PowerShell cho clients
.DESCRIPTION
    Tao HTTP Server don gian tren VPS de phuc vu file .ps1
    Khong can cai Nginx/Apache, chi can PowerShell 5.1+
.NOTES
    Chay voi quyen Administrator tren VPS
#>

param(
    [int]$Port = 8888,
    [string]$ScriptDir = "$PSScriptRoot\scripts"
)

# Kiem tra thu muc scripts
if (-not (Test-Path $ScriptDir)) {
    New-Item -ItemType Directory -Path $ScriptDir -Force | Out-Null
    Write-Host "  [+] Da tao thu muc: $ScriptDir" -ForegroundColor Green
}

# Tat firewall cho port
try {
    New-NetFirewallRule -DisplayName "PS-Script-Server-$Port" -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow -ErrorAction SilentlyContinue | Out-Null
    Write-Host "  [+] Da mo firewall port $Port" -ForegroundColor Green
} catch {}

# Lay IP public
try {
    $publicIP = (Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 5)
} catch {
    $publicIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne '127.0.0.1' } | Select-Object -First 1).IPAddress
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://+:$Port/")
$listener.Start()

Write-Host ""
Write-Host "  $('=' * 60)" -ForegroundColor Cyan
Write-Host "  VPS SCRIPT SERVER - Pho Tue SoftWare Solutions JSC" -ForegroundColor White
Write-Host "  $('=' * 60)" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Server dang chay tren port: $Port" -ForegroundColor Green
Write-Host "  Thu muc scripts: $ScriptDir" -ForegroundColor Green
Write-Host ""
Write-Host "  Client su dung lenh:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  irm https://irm-genuine-license-windows.hitechcloud.vn | iex" -ForegroundColor White
Write-Host "  (hoac: irm http://${publicIP}:${Port} | iex)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Nhan Ctrl+C de tat server" -ForegroundColor DarkGray
Write-Host "  $('=' * 60)" -ForegroundColor Cyan
Write-Host ""

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $requestedFile = $request.Url.LocalPath.TrimStart('/')
        Write-Host "  [$(Get-Date -Format 'HH:mm:ss')] Request: $requestedFile" -ForegroundColor DarkGray

        # Tim file script chinh (uu tien Windows_License_Cleanup.ps1)
        $mainScript = Get-ChildItem -Path $ScriptDir -Filter "*.ps1" -ErrorAction SilentlyContinue | Select-Object -First 1

        if ($requestedFile -eq "" -or $requestedFile -eq "index") {
            # Phuc vu script chinh truc tiep tai root
            if ($mainScript) {
                $content = Get-Content -Path $mainScript.FullName -Raw -Encoding UTF8
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
                $response.ContentType = "text/plain; charset=utf-8"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                Write-Host "  [$(Get-Date -Format 'HH:mm:ss')] -> Phuc vu: $($mainScript.Name) ($($buffer.Length) bytes)" -ForegroundColor Green
            } else {
                $msg = "# Khong tim thay script nao trong thu muc scripts"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($msg)
                $response.StatusCode = 404
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
        }
        else {
            $filePath = Join-Path $ScriptDir $requestedFile
            if (Test-Path $filePath) {
                $content = Get-Content -Path $filePath -Raw -Encoding UTF8
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
                $response.ContentType = "text/plain; charset=utf-8"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                Write-Host "  [$(Get-Date -Format 'HH:mm:ss')] -> Phuc vu: $requestedFile ($($buffer.Length) bytes)" -ForegroundColor Green
            }
            else {
                $msg = "# File not found: $requestedFile"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($msg)
                $response.StatusCode = 404
                $response.ContentType = "text/plain"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                Write-Host "  [$(Get-Date -Format 'HH:mm:ss')] -> 404: $requestedFile" -ForegroundColor Red
            }
        }

        $response.OutputStream.Close()
    }
    catch {
        if ($listener.IsListening) {
            Write-Host "  [!] Error: $_" -ForegroundColor Red
        }
    }
}
