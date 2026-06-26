# 🛡️ Windows Genuine License Tool

> **Công cụ chuẩn hóa bản quyền Windows** - Gỡ bỏ license lậu (KMS, AutoKMS, KMSpico...) và khôi phục Windows nguyên bản.

**CÔNG TY CỔ PHẦN GIẢI PHÁP CÔNG NGHỆ VÀ PHẦN MỀM PHỔ TUỆ**

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
| 9 | Nhập & kích hoạt key mới | Nhập key Pro và kích hoạt online |
| A | **Kiểm tra phiên bản** | Xem edition hiện tại, OEM key, target editions |
| B | **Sửa lỗi hệ thống** | DISM RestoreHealth + SFC + xóa cache Windows Update |
| C | **Nâng cấp Home → Pro** | 3 cách: generic key, key trực tiếp, DISM |
| D | **Nâng cấp toàn diện** | Cleanup + sửa lỗi + upgrade + activate (1 lần) |

---

## 🔧 Triển khai trên VPS Linux (Khuyến nghị)

### Setup tự động (1 lệnh duy nhất)

SSH vào VPS Linux, chạy:

```bash
curl -sSL https://raw.githubusercontent.com/thanhan92-f1/Windows-Genuine-License-Tool/main/vps-deploy/bootstrap.sh | sudo bash
```

Script sẽ tự động:
- ✅ Cài đặt Python3 (nếu chưa có)
- ✅ Download scripts từ GitHub
- ✅ Mở firewall port 8888
- ✅ Tạo systemd service (tự khởi động khi reboot)
- ✅ Khởi động server ngay

### Quản lý service

```bash
systemctl status pho-tue-scripts      # Xem trạng thái
systemctl restart pho-tue-scripts      # Khởi động lại
systemctl stop pho-tue-scripts         # Dừng service
journalctl -u pho-tue-scripts -f       # Xem log realtime
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

**CÔNG TY CỔ PHẦN GIẢI PHÁP CÔNG NGHỆ VÀ PHẦN MỀM PHỔ TUỆ**

- 🌐 Website: [photuesoftware.com](https://photuesoftware.com)
- 🌐 Website: [hitechcloud.vn](https://hitechcloud.vn)

- 📧 Email: info@photuesoftware.com
- ☎️ Hotline: 0865.920.041
- 📍 Địa chỉ: 128 Đường Bình Mỹ, xã Bình Mỹ, Thành phố Hồ Chí Minh, Việt Nam
- 📍 Văn phòng làm việc Q. Bình Thạnh: Căn hộ OT03, Tòa nhà The Landmark 81, 720A Đ. Điện Biên Phủ, Vinhomes Tân Cảng, P. Thạnh Mỹ Tây, Tp. Hồ Chí Minh

---

## 📄 License

This tool is provided for system maintenance and standardization purposes only.
