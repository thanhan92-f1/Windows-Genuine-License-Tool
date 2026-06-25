@echo off
chcp 65001 >nul 2>&1
title Windows License Cleanup Tool - Pho Tue Software Solutions JSC
color 0A

:: ============================================================
::  TOOL GỠ BỎ LICENSE WINDOWS LẬU & CHUẨN HÓA HỆ THỐNG
::  Công ty: Pho Tue SoftWare Solutions JSC
::  Phiên bản: 1.0
::  Ngày: 2026-06-25
:: ============================================================

:: Kiểm tra quyền Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo.
    echo  ═══════════════════════════════════════════════════════════
    echo   [LOI] Ban can chay voi quyen Administrator!
    echo   Nhap chuot phai vao file .bat chon "Run as administrator"
    echo  ═══════════════════════════════════════════════════════════
    echo.
    pause
    exit /b 1
)

:MENU
cls
echo.
echo  ╔═══════════════════════════════════════════════════════════════════╗
echo  ║     TOOL GỠ BỎ LICENSE WINDOWS LẬU & CHUẨN HÓA HỆ THỐNG       ║
echo  ║         Pho Tue SoftWare Solutions JSC - v1.0                    ║
echo  ╠═══════════════════════════════════════════════════════════════════╣
echo  ║                                                                   ║
echo  ║   [1] Gỡ bỏ License lậu & dọn dẹp hệ thống (TOÀN BỘ)           ║
echo  ║   [2] Chỉ gỡ Product Key hiện tại                                ║
echo  ║   [3] Chỉ xóa key khỏi Registry                                  ║
echo  ║   [4] Chỉ xóa thông tin KMS                                      ║
echo  ║   [5] Dọn dẹp file & thư mục KMS rác                             ║
echo  ║   [6] Dọn dẹp Scheduled Tasks liên quan KMS                      ║
echo  ║   [7] Sửa file Hosts (xóa block Microsoft)                       ║
echo  ║   [8] Kiểm tra trạng thái License hiện tại                       ║
echo  ║   [9] Thoát                                                       ║
echo  ║                                                                   ║
echo  ╚═══════════════════════════════════════════════════════════════════╝
echo.
set /p choice="  Chon chuc nang [1-9]: "

if "%choice%"=="1" goto FULL_CLEANUP
if "%choice%"=="2" goto UNINSTALL_KEY
if "%choice%"=="3" goto CLEAN_REGISTRY
if "%choice%"=="4" goto CLEAN_KMS
if "%choice%"=="5" goto CLEAN_FILES
if "%choice%"=="6" goto CLEAN_TASKS
if "%choice%"=="7" goto FIX_HOSTS
if "%choice%"=="8" goto CHECK_STATUS
if "%choice%"=="9" goto EXIT
echo  [!] Lua chon khong hop le. Vui long chon lai.
timeout /t 2 >nul
goto MENU

:: ============================================================
::  [1] GỠ BỎ TOÀN BỘ LICENSE LẬU & DỌN DẸP HỆ THỐNG
:: ============================================================
:FULL_CLEANUP
cls
echo.
echo  ═══════════════════════════════════════════════════════════
echo   BAT DAU QUY TRINH CHUAN HOA HE THONG TOAN DIEN
echo  ═══════════════════════════════════════════════════════════
echo.

:: Tạo log file
set LOGFILE=%~dp0cleanup_log_%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%.txt
set LOGFILE=%LOGFILE: =0%
echo  [LOG] Nhat ky luu tai: %LOGFILE%
echo  ========================================== >> "%LOGFILE%"
echo  Windows License Cleanup Log >> "%LOGFILE%"
echo  Ngay: %date% - %time% >> "%LOGFILE%"
echo  ========================================== >> "%LOGFILE%"
echo.

:: --- Buoc 1: Gỡ Product Key ---
echo  [1/7] Go Product Key hien tai...
echo  [1/7] Go Product Key hien tai... >> "%LOGFILE%"
slmgr.vbs /upk >nul 2>&1
if %errorlevel% equ 0 (
    echo        [OK] Da go Product key thanh cong.
    echo        [OK] Da go Product key thanh cong. >> "%LOGFILE%"
) else (
    echo        [!] Khong co Product key hoac da duoc go truoc do.
    echo        [!] Khong co Product key hoac da duoc go truoc do. >> "%LOGFILE%"
)
echo.

:: --- Buoc 2: Xóa key khỏi Registry ---
echo  [2/7] Xoa key khoi Registry...
echo  [2/7] Xoa key khoi Registry... >> "%LOGFILE%"
slmgr.vbs /cpky >nul 2>&1
if %errorlevel% equ 0 (
    echo        [OK] Da xoa key khoi Registry thanh cong.
    echo        [OK] Da xoa key khoi Registry thanh cong. >> "%LOGFILE%"
) else (
    echo        [!] Khong the xoa key khoi Registry.
    echo        [!] Khong the xoa key khoi Registry. >> "%LOGFILE%"
)
echo.

:: --- Buoc 3: Xóa thông tin KMS ---
echo  [3/7] Xoa thong tin KMS server gia...
echo  [3/7] Xoa thong tin KMS server gia... >> "%LOGFILE%"
slmgr.vbs /ckms >nul 2>&1
if %errorlevel% equ 0 (
    echo        [OK] Da xoa thong tin KMS thanh cong.
    echo        [OK] Da xoa thong tin KMS thanh cong. >> "%LOGFILE%"
) else (
    echo        [!] Khong the xoa thong tin KMS.
    echo        [!] Khong the xoa thong tin KMS. >> "%LOGFILE%"
)
echo.

:: --- Buoc 4: Reset trạng thái License ---
echo  [4/7] Reset trang thai License ve mac dinh...
echo  [4/7] Reset trang thai License ve mac dinh... >> "%LOGFILE%"
slmgr.vbs /rearm >nul 2>&1
if %errorlevel% equ 0 (
    echo        [OK] Da reset trang thai License thanh cong.
    echo        [OK] Da reset trang thai License thanh cong. >> "%LOGFILE%"
) else (
    echo        [!] Khong the reset trang thai License.
    echo        [!] Khong the reset trang thai License. >> "%LOGFILE%"
)
echo.

:: --- Buoc 5: Dọn dẹp file & thư mục KMS ---
echo  [5/7] Don dep file va thu muc KMS rac...
echo  [5/7] Don dep file va thu muc KMS rac... >> "%LOGFILE%"

set "CLEANED=0"

:: Danh sách các thư mục/file KMS thường gặp
for %%D in (
    "%ProgramFiles%\KMSpico"
    "%ProgramFiles%\KMSpico\AutoPico.exe"
    "%ProgramFiles(x86)%\KMSpico"
    "%ProgramData%\KMSAutoS"
    "%ProgramData%\KMSAuto"
    "%ProgramData%\KMSAutoS\KMSAuto.exe"
    "%SystemRoot%\KMS-R@1n"
    "%SystemRoot%\KMS-R@1n\KMS-R@1n.exe"
    "%ProgramFiles%\KMSAuto"
    "%ProgramFiles%\KMSAuto Net"
    "%ProgramFiles%\KMS_VL_ALL"
    "%ProgramData%\Microsoft\KMS"
    "%SystemRoot%\System32\SppExtComObjHook.dll"
    "%SystemRoot%\System32\KMS-R@1n.dll"
    "%SystemRoot%\System32\skc.dll"
) do (
    if exist %%D (
        rd /s /q %%D 2>nul
        del /f /q %%D 2>nul
        echo        [X] Da xoa: %%D
        echo        [X] Da xoa: %%D >> "%LOGFILE%"
        set /a CLEANED+=1
    )
)

:: Xóa các file thực thi KMS trong System32
for %%F in (
    "%SystemRoot%\System32\SppExtComObjHook.dll"
    "%SystemRoot%\System32\KMS*.dll"
    "%SystemRoot%\System32\kms*.dll"
    "%SystemRoot%\SysWOW64\SppExtComObjHook.dll"
) do (
    if exist %%F (
        del /f /q %%F 2>nul
        echo        [X] Da xoa: %%F
        echo        [X] Da xoa: %%F >> "%LOGFILE%"
        set /a CLEANED+=1
    )
)

if %CLEANED% equ 0 (
    echo        [OK] Khong tim thay file/thu muc KMS nao.
    echo        [OK] Khong tim thay file/thu muc KMS nao. >> "%LOGFILE%"
)
echo.

:: --- Buoc 6: Dọn dẹp Scheduled Tasks ---
echo  [6/7] Don dep Scheduled Tasks lien quan KMS...
echo  [6/7] Don dep Scheduled Tasks lien quan KMS... >> "%LOGFILE%"

set "TASK_CLEANED=0"

for %%T in (
    "AutoKMS"
    "KMSAuto"
    "KMSAutoNet"
    "SvcRestartTask"
    "KMSpico"
    "KMS-R@1n"
    "KMS Activation"
    "Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTask"
) do (
    schtasks /delete /tn "%%~T" /f >nul 2>&1
    if %errorlevel% equ 0 (
        echo        [X] Da xoa task: %%~T
        echo        [X] Da xoa task: %%~T >> "%LOGFILE%"
        set /a TASK_CLEANED+=1
    )
)

if %TASK_CLEANED% equ 0 (
    echo        [OK] Khong tim thay Scheduled Tasks KMS nao.
    echo        [OK] Khong tim thay Scheduled Tasks KMS nao. >> "%LOGFILE%"
)
echo.

:: --- Buoc 7: Sửa file Hosts ---
echo  [7/7] Sua file Hosts - xoa block Microsoft...
echo  [7/7] Sua file Hosts - xoa block Microsoft... >> "%LOGFILE%"

set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"
set "HOSTS_BACKUP=%SystemRoot%\System32\drivers\etc\hosts.backup_%date:~-4%%date:~3,2%%date:~0,2%"
set HOSTS_BACKUP=%HOSTS_BACKUP: =0%

:: Sao lưu file hosts
if exist "%HOSTS%" (
    copy /y "%HOSTS%" "%HOSTS_BACKUP%" >nul 2>&1
    echo        [OK] Da sao luu file hosts tai: %HOSTS_BACKUP%
    echo        [OK] Da sao luu file hosts tai: %HOSTS_BACKUP% >> "%LOGFILE%"
)

:: Tạo file hosts mới (loại bỏ các dòng block Microsoft)
if exist "%HOSTS%" (
    :: Tạo file temp chỉ chứa các dòng không liên quan đến KMS/crack
    (for /f "usebackq tokens=* delims=" %%L in ("%HOSTS%") do (
        echo %%L | findstr /i /c:"activation.microsoft.com" >nul 2>&1
        if errorlevel 1 (
            echo %%L | findstr /i /c:"validation.sls.microsoft.com" >nul 2>&1
            if errorlevel 1 (
                echo %%L | findstr /i /c:"microsoft.com" | findstr /i /c:"kms" >nul 2>&1
                if errorlevel 1 (
                    echo %%L | findstr /i /c:"kms" >nul 2>&1
                    if errorlevel 1 (
                        echo %%L | findstr /i /c:"crack" >nul 2>&1
                        if errorlevel 1 (
                            echo %%L
                        )
                    )
                )
            )
        )
    )) > "%TEMP%\hosts_clean"
    
    copy /y "%TEMP%\hosts_clean" "%HOSTS%" >nul 2>&1
    del /f /q "%TEMP%\hosts_clean" >nul 2>&1
    echo        [OK] Da xoa cac dong block Microsoft trong file hosts.
    echo        [OK] Da xoa cac dong block Microsoft trong file hosts. >> "%LOGFILE%"
) else (
    echo        [!] Khong tim thay file hosts.
    echo        [!] Khong tim thay file hosts. >> "%LOGFILE%"
)
echo.

:: --- Dọn dẹp Registry Keys liên quan KMS ---
echo  [EXTRA] Don dep Registry keys lien quan KMS...
echo  [EXTRA] Don dep Registry keys lien quan KMS... >> "%LOGFILE%"

:: Xóa KMS client key trong registry
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform\KMSActivation" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "KMSAuto" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "KMSpico" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AutoKMS" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "KMSAuto" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "KMSpico" /f >nul 2>&1

:: Xóa key trong Wow6432Node (64-bit)
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" /v "KMSAuto" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" /v "KMSpico" /f >nul 2>&1

echo        [OK] Da don dep Registry keys lien quan KMS.
echo        [OK] Da don dep Registry keys lien quan KMS. >> "%LOGFILE%"
echo.

:: --- Dừng dịch vụ KMS nếu đang chạy ---
echo  [EXTRA] Kiem tra va dung dich vu KMS dang chay...
echo  [EXTRA] Kiem tra va dung dich vu KMS dang chay... >> "%LOGFILE%"

:: Reset lại Windows Update service
sc config wuauserv start= auto >nul 2>&1
net start wuauserv >nul 2>&1

:: Reset Software Protection service
net stop sppsvc >nul 2>&1
net start sppsvc >nul 2>&1

echo        [OK] Da khoi phuc dich vu he thong.
echo        [OK] Da khoi phuc dich vu he thong. >> "%LOGFILE%"
echo.

echo  ═══════════════════════════════════════════════════════════
echo   HOAN TAT QUY TRINH CHUAN HOA HE THONG!
echo  ═══════════════════════════════════════════════════════════
echo.
echo  [!] BAN NEN KHOI DONG LAI MAY TINH DE CAP NHAT HOAN TOAN.
echo  [!] Sau do, nhap key ban quyen chinh hang de kich hoat Windows.
echo.
echo  Nhat ky da duoc luu tai: %LOGFILE%
echo.

set /p REBOOT="  Ban co muon khoi dong lai may bay gio? (Y/N): "
if /i "%REBOOT%"=="Y" (
    echo  Dang khoi dong lai may tinh...
    shutdown /r /t 10 /c "Khoi dong lai de hoan tat chuan hoa he thong"
    echo  May tinh se tu dong khoi dong lai sau 10 giay.
) else (
    echo  [!] Hay khoi dong lai may tinh khi ban san sang.
)
echo.
pause
goto MENU

:: ============================================================
::  [2] CHỈ GỠ PRODUCT KEY HIỆN TẠI
:: ============================================================
:UNINSTALL_KEY
cls
echo.
echo  ═══════════════════════════════════════════════════════════
echo   GO PRODUCT KEY HIEN TAI
echo  ═══════════════════════════════════════════════════════════
echo.
echo  Dang go Product key...
slmgr.vbs /upk
echo.
pause
goto MENU

:: ============================================================
::  [3] CHỈ XÓA KEY KHỎI REGISTRY
:: ============================================================
:CLEAN_REGISTRY
cls
echo.
echo  ═══════════════════════════════════════════════════════════
echo   XOA KEY KHOI REGISTRY
echo  ═══════════════════════════════════════════════════════════
echo.
echo  Dang xoa key khoi Registry...
slmgr.vbs /cpky
echo.
pause
goto MENU

:: ============================================================
::  [4] CHỈ XÓA THÔNG TIN KMS
:: ============================================================
:CLEAN_KMS
cls
echo.
echo  ═══════════════════════════════════════════════════════════
echo   XOA THONG TIN KMS SERVER GIA
echo  ═══════════════════════════════════════════════════════════
echo.
echo  Dang xoa thong tin KMS...
slmgr.vbs /ckms
echo.
echo  Dang reset trang thai License...
slmgr.vbs /rearm
echo.
pause
goto MENU

:: ============================================================
::  [5] DỌN DẸP FILE & THƯ MỤC KMS
:: ============================================================
:CLEAN_FILES
cls
echo.
echo  ═══════════════════════════════════════════════════════════
echo   DON DEP FILE VA THU MUC KMS RAC
echo  ═══════════════════════════════════════════════════════════
echo.

set "COUNT=0"

for %%D in (
    "%ProgramFiles%\KMSpico"
    "%ProgramFiles(x86)%\KMSpico"
    "%ProgramData%\KMSAutoS"
    "%ProgramData%\KMSAuto"
    "%SystemRoot%\KMS-R@1n"
    "%ProgramFiles%\KMSAuto"
    "%ProgramFiles%\KMSAuto Net"
    "%ProgramFiles%\KMS_VL_ALL"
    "%ProgramData%\Microsoft\KMS"
) do (
    if exist %%D (
        echo  [X] Dang xoa: %%D
        rd /s /q %%D 2>nul
        if not exist %%D (
            echo       -> Da xoa thanh cong!
        ) else (
            echo       -> Khong the xoa (co the dang duoc su dung).
        )
        set /a COUNT+=1
    )
)

:: Xóa file trong System32
for %%F in (
    "%SystemRoot%\System32\SppExtComObjHook.dll"
    "%SystemRoot%\System32\skc.dll"
) do (
    if exist %%F (
        echo  [X] Dang xoa: %%F
        takeown /f %%F >nul 2>&1
        icacls %%F /grant administrators:F >nul 2>&1
        del /f /q %%F 2>nul
        set /a COUNT+=1
    )
)

if %COUNT% equ 0 (
    echo  [OK] Khong tim thay file/thu muc KMS nao trong he thong.
) else (
    echo.
    echo  [i] Da xoa %COUNT% muc.
)
echo.
pause
goto MENU

:: ============================================================
::  [6] DỌN DẸP SCHEDULED TASKS
:: ============================================================
:CLEAN_TASKS
cls
echo.
echo  ═══════════════════════════════════════════════════════════
echo   DON DEP SCHEDULED TASKS LIEN QUAN KMS
echo  ═══════════════════════════════════════════════════════════
echo.

set "TASK_COUNT=0"

for %%T in (
    "AutoKMS"
    "KMSAuto"
    "KMSAutoNet"
    "SvcRestartTask"
    "KMSpico"
    "KMS-R@1n"
    "KMS Activation"
    "Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTask"
) do (
    schtasks /query /tn "%%~T" >nul 2>&1
    if %errorlevel% equ 0 (
        echo  [X] Tim thay task: %%~T - Dang xoa...
        schtasks /delete /tn "%%~T" /f >nul 2>&1
        echo       -> Da xoa thanh cong!
        set /a TASK_COUNT+=1
    )
)

if %TASK_COUNT% equ 0 (
    echo  [OK] Khong tim thay Scheduled Tasks lien quan KMS nao.
) else (
    echo.
    echo  [i] Da xoa %TASK_COUNT% scheduled tasks.
)
echo.
pause
goto MENU

:: ============================================================
::  [7] SỬA FILE HOSTS
:: ============================================================
:FIX_HOSTS
cls
echo.
echo  ═══════════════════════════════════════════════════════════
echo   SUA FILE HOSTS - XOA BLOCK MICROSOFT
echo  ═══════════════════════════════════════════════════════════
echo.

set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"

if not exist "%HOSTS%" (
    echo  [!] Khong tim thay file hosts.
    pause
    goto MENU
)

echo  Noi dung hien tai cua file hosts:
echo  ─────────────────────────────────────
type "%HOSTS%"
echo  ─────────────────────────────────────
echo.

:: Sao lưu
set "BACKUP=%HOSTS%.backup"
copy /y "%HOSTS%" "%BACKUP%" >nul 2>&1
echo  [OK] Da sao luu tai: %BACKUP%
echo.

:: Tạo file hosts sạch
(for /f "usebackq tokens=* delims=" %%L in ("%HOSTS%") do (
    echo %%L | findstr /i /c:"activation.microsoft.com" >nul 2>&1
    if errorlevel 1 (
        echo %%L | findstr /i /c:"validation.sls.microsoft.com" >nul 2>&1
        if errorlevel 1 (
            echo %%L | findstr /i /c:"kms" >nul 2>&1
            if errorlevel 1 (
                echo %%L | findstr /i /c:"crack" >nul 2>&1
                if errorlevel 1 (
                    echo %%L
                )
            )
        )
    )
)) > "%TEMP%\hosts_clean_tmp"

copy /y "%TEMP%\hosts_clean_tmp" "%HOSTS%" >nul 2>&1
del /f /q "%TEMP%\hosts_clean_tmp" >nul 2>&1

echo  Noi dung file hosts sau khi xu ly:
echo  ─────────────────────────────────────
type "%HOSTS%"
echo  ─────────────────────────────────────
echo.
echo  [OK] Da xu ly file hosts thanh cong!
echo.
pause
goto MENU

:: ============================================================
::  [8] KIỂM TRA TRẠNG THÁI LICENSE
:: ============================================================
:CHECK_STATUS
cls
echo.
echo  ═══════════════════════════════════════════════════════════
echo   KIEM TRA TRANG THAI LICENSE HIEN TAI
echo  ═══════════════════════════════════════════════════════════
echo.
echo  Dang kiem tra...
echo.
slmgr.vbs /dlv
echo.
echo  ─────────────────────────────────────
echo.
echo  Thong tin ban quyen chi tiet:
echo.
slmgr.vbs /xpr
echo.
pause
goto MENU

:: ============================================================
::  THOÁT
:: ============================================================
:EXIT
cls
echo.
echo  ═══════════════════════════════════════════════════════════
echo   Cam on ban da su dung Tool!
echo   Pho Tue SoftWare Solutions JSC
echo   Hotline: 0865.920.041
echo   Email: info@photuesoftware.com
echo  ═══════════════════════════════════════════════════════════
echo.
timeout /t 3 >nul
exit /b 0
