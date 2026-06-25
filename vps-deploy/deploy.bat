@echo off
chcp 65001 >nul 2>&1
title VPS Deploy - Pho Tue Software Solutions JSC
color 0A

echo.
echo  ============================================================
echo   VPS DEPLOY TOOL - Pho Tue SoftWare Solutions JSC
echo  ============================================================
echo.
echo  Script nay se:
echo    1. Tao thu muc scripts tren VPS
echo    2. Upload file Cleanup script len VPS
echo    3. Khoi dong Script Server tren VPS
echo.
echo  ============================================================
echo.

set /p VPS_IP="  Nhap IP VPS: "
set /p VPS_USER="  Nhap user VPS (mac dinh: root): "

if "%VPS_USER%"=="" set VPS_USER=root

echo.
echo  [1/3] Tao thu muc tren VPS...
ssh %VPS_USER%@%VPS_IP% "mkdir -p /opt/scripts"

echo  [2/3] Upload file len VPS...
scp "%~dp0scripts\Windows_License_Cleanup.ps1" %VPS_USER%@%VPS_IP%:/opt/scripts/

echo  [3/3] Upload Server script...
scp "%~dp0Start-Server.ps1" %VPS_USER%@%VPS_IP%:/opt/scripts/

echo.
echo  ============================================================
echo   HOAN TAT! Bay gio SSH vao VPS va chay:
echo.
echo   powershell -File /opt/scripts/Start-Server.ps1
echo.
echo  Sau do client chi can chay:
echo.
echo   irm http://%VPS_IP%:8888/Windows_License_Cleanup.ps1 ^| iex
echo  ============================================================
echo.
pause
