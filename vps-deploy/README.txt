# HƯỚNG DẪN TRIỂ KHAI TRÊN VPS
# Pho Tue SoftWare Solutions JSC
# ====================================

## BƯỚC 1: Setup VPS (Chạy 1 lần duy nhất)

### Cách A: Upload file rồi chạy
1. Upload file `setup-vps.ps1` lên VPS
2. SSH vào VPS, chạy:
```powershell
powershell -ExecutionPolicy Bypass -File C:\path\to\setup-vps.ps1
```

### Cách B: Chạy trực tiếp từ URL (nếu đã upload lên GitHub)
```powershell
irm https://raw.githubusercontent.com/thanhan92-f1/Windows-Genuine-License-Tool/main/setup-vps.ps1 | iex
```

Script sẽ tự động:
- ✅ Tạo thư mục cài đặt tại C:\PhoTueScripts
- ✅ Tạo Cleanup Script
- ✅ Tạo Script Server
- ✅ Mở firewall port 8888
- ✅ Hỏi khởi động server ngay

---

## BƯỚC 2: Khởi động Server

Sau khi setup, khởi động server:
```powershell
powershell -File C:\PhoTueScripts\Start-Server.ps1
```

Server sẽ hiển thị:
```
  VPS SCRIPT SERVER - Pho Tue SoftWare Solutions JSC
  Server dang chay tren port: 8888

  Client su dung lenh:
  irm http://YOUR-VPS-IP:8888/Windows_License_Cleanup.ps1 | iex
```

---

## BƯỚC 3: Client sử dụng (Máy trạm / PC)

Mở PowerShell với quyền Administrator, gõ **1 lệnh duy nhất**:

```powershell
irm https://irm-genuine-license-windows.hitechcloud.vn | iex
```

Ví dụ (dùng IP trực tiếp):
```powershell
irm http://YOUR-VPS-IP:8888 | iex
```

Tool sẽ tự động tải về và chạy ngay lập tức!

---

## TÙY CHỌN NÂNG CAO

### Đổi port khác (ví dụ: 80)
```powershell
powershell -File C:\PhoTueScripts\Start-Server.ps1 -Port 80
```

### Chạy Server như Windows Service (tự động khởi động)
```powershell
# Tạo Scheduled Task để chạy khi khởi động
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File C:\PhoTueScripts\Start-Server.ps1"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "PhoTue-Script-Server" -Action $action -Trigger $trigger -User "SYSTEM" -RunLevel Highest
```

### Tạo file .bat cho nhân viên kỹ thuật
Tạo file `Chay-Cleanup.bat`:
```bat
@echo off
echo.
echo  Dang tai va chay Tool chuan hoa he thong...
echo  Vui long cho...
echo.
powershell -ExecutionPolicy Bypass -Command "irm https://irm-genuine-license-windows.hitechcloud.vn | iex"
pause
```

Nhân viên chỉ cần double-click file .bat!

---

## LƯU Ý

| Vấn đề | Giải pháp |
|--------|-----------|
| Lỗi SSL | Dùng HTTP thay vì HTTPS (trong mạng nội bộ) |
| Lỗi Execution Policy | Thêm `-ExecutionPolicy Bypass` |
| Port bị chặn | Kiểm tra firewall VPS & nhà cung cấp |
| Chạy trên Bootrom | Mở Super OS trước, chạy tool, đóng Super |

---

## YÊU CẦU HỆ THỐNG

- **VPS:** Windows Server 2016+ hoặc Windows 10+ với PowerShell 5.1+
- **Client:** Windows 7+ với PowerShell 3.0+
- **Domain:** irm-genuine-license-windows.hitechcloud.vn
- **Mạng:** Client phải truy cập được domain hoặc IP VPS qua port 443/8888
