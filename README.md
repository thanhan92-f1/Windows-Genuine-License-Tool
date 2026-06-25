# 🛡️ Windows Genuine License Tool

> **Công cụ chuẩn hóa bản quyền Windows** - Gỡ bỏ license lậu (KMS, AutoKMS, KMSpico...) và khôi phục Windows nguyên bản.

**Pho Tue SoftWare Solutions JSC**

---

## 🚀 Sử dụng ngay (1 lệnh duy nhất)

Mở **PowerShell với quyền Administrator** và chạy:

```powershell
irm https://irm-genuine-license-windows.hitechcloud.vn | iex
```

Tool sẽ tự động tải về và chạy ngay trên máy tính của bạn!

---

## 📋 Chức năng

| # | Chức năng | Mô tả |
|---|-----------|--------|
| 1 | **Gỡ bỏ toàn bộ** | Quy trình 8 bước: gỡ key, xóa registry, xóa KMS, reset license, dọn file, xóa tasks, sửa hosts, khôi phục dịch vụ |
| 2 | Gỡ Product Key | `slmgr /upk` - Gỡ key hiện tại |
| 3 | Xóa Registry Key | `slmgr /cpky` - Xóa key khỏi registry |
| 4 | Xóa thông tin KMS | `slmgr /ckms` + `/rearm` |
| 5 | Dọn file KMS | Xóa KMSpico, KMSAuto, KMS-R@1n... |
| 6 | Xóa Scheduled Tasks | Xóa AutoKMS, SvcRestartTask... |
| 7 | Sửa file Hosts | Xóa dòng block Microsoft |
| 8 | Kiểm tra License | `slmgr /dlv` + `/xpr` |

---

## 🔧 Triển khai trên VPS

### Cách 1: Setup tự động (1 lệnh)

SSH vào VPS Windows, chạy:

```powershell
irm https://raw.githubusercontent.com/thanhan92-f1/Windows-Genuine-License-Tool/main/setup-vps.ps1 | iex
```

### Cách 2: Thủ công

```powershell
# 1. Clone repo
git clone https://github.com/thanhan92-f1/Windows-Genuine-License-Tool.git
cd Windows-Genuine-License-Tool

# 2. Chạy server
powershell -ExecutionPolicy Bypass -File vps-deploy\Start-Server.ps1
```

---

## 📡 Cách hoạt động

```
Client (Máy trạm)                    VPS (Server)
       │                                    │
       │  irm https://domain | iex          │
       ├───────────────────────────────────►│
       │                                    │
       │  ← Windows_License_Cleanup.ps1    │
       │◄───────────────────────────────────┤
       │                                    │
       │  Tool chạy tự động trên máy        │
       │  (gỡ license lậu, dọn dẹp hệ thống)│
```

---

## ⚠️ Lưu ý

- Tool **không cung cấp** giấy phép phần mềm
- Tool chỉ **gỡ bỏ** các công cụ crack và **chuẩn hóa** hệ thống
- Sau khi gỡ xong, cần **nhập key bản quyền** chính hãng để kích hoạt Windows
- Nên chạy trên **Image đang mở Super** (đối với hệ thống Bootrom)

---

## 📞 Liên hệ

**Pho Tue SoftWare Solutions JSC**

- 🌐 Website: [photuesoftware.com](https://photuesoftware.com)
- 📧 Email: info@photuesoftware.com
- ☎️ Hotline: 0865.920.041
- 📍 Địa chỉ: Căn hộ OT03, Tòa nhà The Landmark 81, 720A Đ. Điện Biên Phủ, TP.HCM

---

## 📄 License

This tool is provided for system maintenance and standardization purposes only.
