# Hướng Dẫn Chạy Tool Qua VPS Bằng `irm`

## 1. Upload file lên VPS

### Cách A: Upload lên GitHub (Miễn phí - Khuyến nghị)

1. Tạo repository mới trên GitHub (có thể là **Private**)
2. Upload file `Windows_License_Cleanup.ps1` lên repository
3. Lấy link **Raw** của file:
   ```
   https://raw.githubusercontent.com/TEN-USER/TEN-REPO/main/Windows_License_Cleanup.ps1
   ```

### Cách B: Upload lên VPS (Nginx/Apache)

1. **SSH vào VPS:**
   ```bash
   ssh root@YOUR-VPS-IP
   ```

2. **Tạo thư mục public:**
   ```bash
   mkdir -p /var/www/scripts
   ```

3. **Upload file từ máy local lên VPS** (chạy trên máy local):
   ```powershell
   scp "D:\Pho Tue SoftWare Solutions JSC\Windowns\Windows_License_Cleanup.ps1" root@YOUR-VPS-IP:/var/www/scripts/
   ```

4. **Cấu hình Nginx** để serve file `.ps1`:
   ```nginx
   server {
       listen 80;
       server_name scripts.your-domain.com;

       location / {
           root /var/www/scripts;
           default_type application/octet-stream;
           add_header Content-Disposition "attachment";
       }
   }
   ```

5. **Reload Nginx:**
   ```bash
   nginx -t && systemctl reload nginx
   ```

### Cách C: Upload lên bất kỳ hosting nào

Upload file `.ps1` lên bất kỳ dịch vụ hosting nào hỗ trợ serve file tĩnh:
- **Cloudflare Pages** (miễn phí)
- **Vercel** (miễn phí)
- **Netlify** (miễn phí)
- **Google Drive** (dùng link direct download)

---

## 2. Cách sử dụng `irm` để chạy

### Chạy trên máy trạm / máy cá nhân

Mở **PowerShell với quyền Administrator** và chạy:

```powershell
irm https://YOUR-DOMAIN.COM/Windows_License_Cleanup.ps1 | iex
```

### Ví dụ cụ thể:

```powershell
# Nếu dùng GitHub Raw:
irm https://raw.githubusercontent.com/TEN-USER/TEN-REPO/main/Windows_License_Cleanup.ps1 | iex

# Nếu dùng VPS với domain:
irm https://scripts.your-domain.com/Windows_License_Cleanup.ps1 | iex

# Nếu dùng VPS với IP:
irm http://YOUR-VPS-IP/Windows_License_Cleanup.ps1 | iex
```

### Chạy cho nhiều máy trong hệ thống Bootrom (qua Server):

```powershell
# Tạo file Run-Cleanup.bat trên Server, chứa:
@echo off
powershell -ExecutionPolicy Bypass -Command "irm https://YOUR-DOMAIN.COM/Windows_License_Cleanup.ps1 | iex"
pause
```

---

## 3. Câu lệnh rút gọn (cho nhân viên kỹ thuật)

Tạo shortcut hoặc file `.bat` trên Server để nhân viên chỉ cần click:

### File `Chay-Cleanup.bat`:
```bat
@echo off
echo.
echo  Dang tai va chay Tool chuan hoa he thong...
echo  Vui long cho...
echo.
powershell -ExecutionPolicy Bypass -Command "irm https://YOUR-DOMAIN.COM/Windows_License_Cleanup.ps1 | iex"
pause
```

---

## 4. Lưu ý quan trọng

| Vấn đề | Giải pháp |
|--------|-----------|
| **Lỗi Execution Policy** | Dùng `-ExecutionPolicy Bypass` hoặc chạy `Set-ExecutionPolicy RemoteSigned` |
| **Lỗi SSL/TLS** | Chạy `[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12` trước |
| **File bị Windows Defender chặn** | Thêm exception trong Defender hoặc ký số file `.ps1` |
| **Chạy trên máy trạm Bootrom** | Chạy trên Image đang mở Super, sau đó đóng Super để đồng bộ |

### Fix lỗi SSL nếu cần:
```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
irm https://YOUR-DOMAIN.COM/Windows_License_Cleanup.ps1 | iex
```

### Hoặc dùng lệnh đầy đủ (an toàn nhất):
```powershell
powershell -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://YOUR-DOMAIN.COM/Windows_License_Cleanup.ps1 | iex"
```

---

## 5. Bảo mật

- ✅ Nên dùng **HTTPS** thay vì HTTP
- ✅ Nên đặt file trong **thư mục riêng** không public quá rộng
- ✅ Có thể đặt **Basic Auth** trên Nginx để bảo vệ
- ✅ Nên ký số file `.ps1` nếu triển khai quy mô lớn
- ✅ Xem log tại `%TEMP%\Windows_Cleanup_Log_*.txt`
