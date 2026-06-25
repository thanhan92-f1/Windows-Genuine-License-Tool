# HƯỚNG DẪN TRIỂ KHAI TRÊN VPS LINUX
# Pho Tue SoftWare Solutions JSC
# ====================================

## BƯỚC 1: Setup VPS (Chạy 1 lần duy nhất)

### Cách A: Chạy trực tiếp từ URL (Khuyến nghị)

SSH vào VPS Linux, chạy:

    curl -sSL https://raw.githubusercontent.com/thanhan92-f1/Windows-Genuine-License-Tool/main/vps-deploy/setup.sh | sudo bash

Script sẽ tự động:
  ✅ Cài đặt Python3 (nếu chưa có)
  ✅ Download scripts từ GitHub
  ✅ Mở firewall port 8888
  ✅ Tạo systemd service (tự khởi động khi reboot)
  ✅ Khởi động server ngay

### Cách B: Upload file rồi chạy

1. Upload file setup.sh lên VPS
2. SSH vào VPS, chạy:
       chmod +x setup.sh
       sudo ./setup.sh

---

## BƯỚC 2: Server tự động chạy

Sau khi setup, server đã tự động chạy. Không cần thao tác thêm!

Quản lý service:
    systemctl status pho-tue-scripts      # Xem trạng thái
    systemctl restart pho-tue-scripts      # Khởi động lại
    systemctl stop pho-tue-scripts         # Dừng service
    journalctl -u pho-tue-scripts -f       # Xem log realtime

---

## BƯỚC 3: Client sử dụng (Máy trạm / PC Windows)

Mở PowerShell với quyền Administrator, gõ 1 lệnh duy nhất:

    irm https://irm-genuine-license-windows.hitechcloud.vn | iex

Ví dụ (dùng IP trực tiếp):

    irm http://YOUR-VPS-IP:8888 | iex

Tool sẽ tự động tải về và chạy ngay lập tức!

---

## TÙY CHỌN NÂNG CAO

### Đổi port (mặc định: 8888)

Chỉnh sửa file service:

    sudo systemctl stop pho-tue-scripts
    sudo nano /etc/systemd/system/pho-tue-scripts.service

Thêm dòng: Environment=PORT=80

Sau đó:
    sudo systemctl daemon-reload
    sudo systemctl start pho-tue-scripts

### Cấu hình Nginx reverse proxy + SSL

    sudo apt install nginx certbot python3-certbot-nginx

Tạo file /etc/nginx/sites-available/pho-tue:

    server {
        listen 443 ssl;
        server_name irm-genuine-license-windows.hitechcloud.vn;
        ssl_certificate /etc/letsencrypt/live/irm-genuine-license-windows.hitechcloud.vn/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/irm-genuine-license-windows.hitechcloud.vn/privkey.pem;
        location / {
            proxy_pass http://127.0.0.1:8888;
            proxy_set_header Host $host;
        }
    }
    server {
        listen 80;
        server_name irm-genuine-license-windows.hitechcloud.vn;
        return 301 https://$host$request_uri;
    }

Kích hoạt:
    sudo ln -s /etc/nginx/sites-available/pho-tue /etc/nginx/sites-enabled/
    sudo certbot --nginx -d irm-genuine-license-windows.hitechcloud.vn
    sudo systemctl restart nginx

### Tạo file .bat cho nhân viên kỹ thuật

Tạo file Chay-Cleanup.bat:

    @echo off
    echo.
    echo  Dang tai va chay Tool chuan hoa he thong...
    echo  Vui long cho...
    echo.
    powershell -ExecutionPolicy Bypass -Command "irm https://irm-genuine-license-windows.hitechcloud.vn | iex"
    pause

Nhân viên chỉ cần double-click file .bat!

---

## LƯU Ý

| Vấn đề                | Giải pháp                                    |
|------------------------|----------------------------------------------|
| Lỗi SSL                | Dùng HTTP hoặc cấu hình Nginx + SSL          |
| Port bị chặn           | Kiểm tra firewall VPS & nhà cung cấp         |
| Chạy trên Bootrom      | Mở Super OS trước, chạy tool, đóng Super     |
| Python chưa có         | Script setup sẽ tự cài                       |

---

## YÊU CẦU HỆ THỐNG

- VPS:    Linux (Ubuntu/Debian/CentOS) với Python 3.6+
- Client: Windows 7+ với PowerShell 3.0+
- Domain:  irm-genuine-license-windows.hitechcloud.vn
- Mạng:   Client phải truy cập được domain hoặc IP VPS

---

## CẤU TRÚC THƯ MỤC

    /opt/pho-tue-scripts/
    ├── server.py                           # Python HTTP Server
    ├── scripts/
    │   └── Windows_License_Cleanup.ps1     # Tool cleanup chính
    └── HUONG_DAN_SU_DUNG_IRM.txt          # Hướng dẫn
